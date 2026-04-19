# Research: Entries UX Fixes and Analysis Chart Axes

**Feature**: 010-entries-ux-fixes  
**Date**: 2026-04-19

Este documento consolida las decisiones técnicas para las cuatro correcciones. No hay NEEDS CLARIFICATION en el spec; las decisiones aquí resuelven ambigüedades de implementación.

---

## R1. Retirar el botón de borrado en Entradas

**Decision**:
- Eliminar la invocación de `onDelete` en `entradas_view.dart` (líneas 75–77 del archivo actual) al construir `TransactionRow`.
- Eliminar los helpers `_confirmDeleteRecurring` y `_confirmDeleteOneOff` y sus imports asociados (`dao_providers`, `showConfirmationDialog`, `transactionDaoProvider`).
- **No tocar** `TransactionRow` en `shared_ui`: mantenemos `onDelete` como parámetro opcional para futuros usos (p. ej. pantalla de administración). `ResumenView` ya no pasa `onDelete`; `TemplateDetailModal` no usa `TransactionRow`; por tanto nadie en el repo invoca ahora `onDelete` fuera de Entradas.

**Rationale**: Cambio mínimo y reversible. Conservar el slot opcional es consistente con Principio I (no romper APIs públicas sin migración).

**Alternatives considered**:
- **Eliminar `onDelete` completamente del widget**: rompe la API pública de `shared_ui` sin beneficio (el parámetro es opcional). Descartado.
- **Mover el botón a un menú overflow**: añade fricción pero no cumple el requisito (FR-001 pide eliminarlo del todo). Descartado.

---

## R2. Corregir el overflow "Bottom overflowed by 9.0 pixels"

**Diagnóstico**: En `TransactionRow`, cuando `isRecurring && recurringDetail != null`, el `leading` del `ListTile` se convierte en una `Column` con el avatar (48 px) + `SizedBox(height: 2)` + `Text(fontSize: 10)`. El `ListTile` restringe la altura del `leading` al mínimo vertical de la fila (~56 px por defecto en `ListTile` estándar de dos líneas), provocando 9 px de desbordamiento.

**Decision**: Trasladar `recurringDetail` desde el `leading` al `subtitle`, concatenándolo con el subtítulo existente (`"$categoryLabel · ${DateFormatter.format(date)}"`). Formato resultante:

```
Suscripcion · 19 abr 2026 · Día 19 de cada mes
```

El `leading` pasa a ser únicamente el `CircleAvatar` (con badge `Icons.repeat` superpuesto vía `Stack` cuando `isRecurring`). Sin `Column`, sin overflow posible.

**Rationale**:
- Elimina el overflow por construcción (no por ajuste fino de padding).
- Mejora la legibilidad: la información de recurrencia queda alineada con el resto del subtítulo, en lugar de flotando bajo el icono con fontSize 10.
- Reduce código del widget.

**Alternatives considered**:
- **Envolver la columna en `SizedBox(height: X)` con `FittedBox`**: Conserva la posición bajo el icono pero el texto se vuelve ilegible a tamaños < 10 px; además deja la lógica frágil ante cambios de tipografía. Descartado.
- **Usar `ListTile.isThreeLine: true`**: obliga a que el subtítulo ocupe 2 líneas incluso cuando no hay `recurringDetail`. Descartado.
- **Custom Row sin `ListTile`**: demasiado invasivo; el widget está en `shared_ui` y se usa en Resumen y Entradas. Descartado.

**Test**: widget test que renderiza el row con `isRecurring=true` y `recurringDetail='Día 15 de cada mes'` y verifica:
- `expect(tester.takeException(), isNull)` (sin overflow).
- El texto del detalle aparece en el subtitle (`find.text('Suscripcion · ... · Día 15 de cada mes')`).

---

## R3. Etiquetas en ejes X e Y de las gráficas de Análisis

**Decision**: Activar `SideTitles` con `showTitles: true` en `bottomTitles` (eje X, fechas) y `leftTitles` (eje Y, importes en céntimos) de `LineChart` en `analysis_line_chart.dart`.

**Eje Y (importes)**:
- `getTitlesWidget`: recibe un `value` en céntimos (double) y devuelve un `Text` con formato abreviado:
  - `< 1 000 €`: `"€42"`, `"€150"`
  - `1 000–999 999 €`: `"€1,2k"`, `"€25k"`
  - `≥ 1 000 000 €`: `"€1,2M"`
- Se usa `intl` `NumberFormat` con locale `es_ES` (coma decimal, punto miles) y sufijos k/M manuales.
- `interval`: calculado dinámicamente a partir de `(maxY - minY) / 4` y redondeado a una potencia de 10 "bonita" (1, 2, 5, 10, 20, 50, 100…).
- `reservedSize`: 44 px (suficiente para `"€1,2M"`).

**Eje X (fechas)**:
- El `FlSpot.x` es el índice de `dataPoints` (entero 0..N-1), no una timestamp. Necesitamos mapa índice → fecha. Solución: el widget recibe ya `dataPoints` ordenados y usa `value.toInt()` como índice para indexar.
- `getTitlesWidget` devuelve `Text(DateFormat('d MMM', 'es').format(date))` → p. ej. `"19 abr"`.
- `interval`: 1 etiqueta cada `(N / 5).ceil()` índices (máximo 5–6 etiquetas visibles, evita solapamiento).
- `reservedSize`: 22 px.

**Color / tipografía**: `AppColors.onBackgroundMuted`, `fontSize: 10`.

**Lógica "bonita" del intervalo Y (pseudocódigo)**:
```dart
double niceInterval(double range) {
  if (range <= 0) return 1;
  final rough = range / 4;
  final mag = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final norm = rough / mag;
  final nice = norm < 1.5 ? 1.0 : norm < 3 ? 2.0 : norm < 7 ? 5.0 : 10.0;
  return nice * mag;
}
```

Encapsulado en `lib/domain/chart_axis.dart` (Dart puro, sin Flutter) para ser testeable unitariamente.

**Caso borde — un solo punto**: `minY == maxY`. Se añade un padding mínimo de 500 céntimos (ya presente en el código actual), el intervalo resultante es 100–200 céntimos, el eje muestra 2–3 etiquetas.

**Caso borde — sin datos**: ya se gestiona con un `SizedBox` vacío; no entra a construir `LineChart`.

**Rationale**:
- `fl_chart.SideTitles` es la solución idiomática y ya tenemos la dependencia.
- Formato abreviado (`k`, `M`) evita solapamiento con importes grandes.
- Lógica "nice interval" encapsulada en pure Dart → testeable sin widget.

**Alternatives considered**:
- **`DateTimeAxis` con timestamps reales en `FlSpot.x`**: requiere remodelar `DataPoint` e implica cambios en el provider. Más invasivo. Descartado para este feature (se puede hacer en una refactorización futura).
- **Librería `charts_flutter`**: ya usamos `fl_chart`. Cambiar es excesivo.

**Test**: unit test sobre `niceInterval` con valores representativos (0, 1, 100, 1234, 12_345, 999_999) verificando los intervalos esperados.

---

## R4. Filtro de categoría en la vista Entradas

### 4.1 Alcance de categorías visibles

**Decision**: El filtro muestra **todas las categorías definidas en el modelo**, unión de `ExpenseCategory` e `IncomeCategory`, deduplicando por `displayLabel` (ej. "Servicio" existe en ambas). Lista final:

| Key interno | Label mostrado |
|-------------|----------------|
| `all` | Todas |
| `producto` | Producto |
| `servicio` | Servicio |
| `suscripcion` | Suscripcion |
| `suministroVariable` | Suministro variable |
| `financiacion` | Financiacion |
| `salario` | Salario |
| `venta` | Venta |

**Rationale**: El usuario citó "financiación, suscripción, producto" como ejemplos en la descripción, pero la vista Entradas muestra ingresos y gastos en una sola lista unificada. Filtrar solo por 3 de las 5 categorías de gasto dejaría visibles entradas de "Servicio" o "Suministro variable" al aplicar "Todas" pero invisibles al aplicar cualquier otro filtro, lo cual es confuso. Incluir todas las categorías es coherente con el modelo de datos y no añade complejidad (el selector es un `Wrap` scrollable).

**Alternatives considered**:
- **Solo 3 categorías literales del usuario**: rompería la consistencia con los datos reales. Descartado.
- **Dos selectores separados (ingresos / gastos)**: duplica UI. Descartado.
- **Categorías dinámicas (solo las presentes en los datos filtrados)**: requiere computar el conjunto en el provider y recalcular al cambiar rango. Aporta poco y añade complejidad. Descartado.

### 4.2 Modelo interno

**Decision**: Nuevo enum Dart puro en `lib/domain/category_filter.dart`:

```dart
enum CategoryFilter {
  all, producto, servicio, suscripcion,
  suministroVariable, financiacion, salario, venta;

  String get label { ... }
  bool matches(String rawCategory) =>
      this == CategoryFilter.all || rawCategory == name;
}
```

`name` del enum (ej. `'suscripcion'`) coincide literalmente con el valor almacenado en `TransactionRow.category` (como ya se usa en `_toDisplay` en `transaction_providers.dart` líneas 82–87). Match directo sin mapeo adicional.

**Rationale**: Consistente con el patrón de `TimeRange` (enum + label + método de comportamiento), y totalmente testeable en aislamiento.

### 4.3 Estado del filtro

**Decision**: Nuevo `StateProvider<CategoryFilter>` global:

```dart
final selectedCategoryFilterProvider =
    StateProvider<CategoryFilter>((ref) => CategoryFilter.all);
```

Equivalente al existente `selectedTimeRangeProvider`. Reset a `all` al salir de la vista: se implementa con un `ref.invalidate(selectedCategoryFilterProvider)` en `dispose`/via `ref.onDispose` del widget. Como `StateProvider` no es autoDispose por defecto, se marcará como `autoDispose` **solo si** la vista es destruida al navegar (confirmar con `GoRouter` shell); de lo contrario, se invalida manualmente en `initState` al entrar (reset siempre a all).

**Patrón elegido**: `StateProvider.autoDispose<CategoryFilter>` + `EntradasView` pasa a `ConsumerStatefulWidget` con `ref.invalidate(selectedCategoryFilterProvider)` en `dispose`. Esto resetea al abandonar la vista, cumpliendo FR-008.

**Rationale**: Coherente con la acepción del spec ("se restablece a Todas al abandonar la vista"). `autoDispose` solo libera cuando no hay watchers; la invalidación manual en `dispose` es el garante.

**Alternatives considered**:
- **Guardar el filtro entre navegaciones**: contradice FR-008. Descartado.
- **Usar `selectedTimeRangeProvider` con el mismo patrón de `autoDispose`**: cambiaría comportamiento existente del filtro de tiempo. Fuera de alcance. Descartado.

### 4.4 Aplicación del filtro

**Decision**: Filtrado en el lado del provider. Se añade un nuevo provider derivado:

```dart
final filteredEntriesProvider = Provider.autoDispose<AsyncValue<List<TransactionDisplay>>>((ref) {
  final range = ref.watch(selectedTimeRangeProvider).toDateRange();
  final category = ref.watch(selectedCategoryFilterProvider);
  final entriesAsync = ref.watch(unifiedEntriesProvider(
    DateTimeRange(start: range.start, end: range.end),
  ));
  return entriesAsync.whenData((list) => list
      .where((e) => category.matchesDisplay(e.categoryLabel, e.transactionType))
      .toList());
});
```

`EntradasView` watchea `filteredEntriesProvider` en lugar de componer manualmente los dos. Más limpio, más testeable.

**Nota**: El match se hace contra `categoryLabel` (displayLabel) o contra el raw? Decisión: el provider `unifiedEntriesProvider` ya transforma el raw en `categoryLabel`. Para filtrar por enum interno necesitamos conservar el raw. **Acción**: añadir campo `rawCategory: String` a `TransactionDisplay` y usarlo en `CategoryFilter.matches`. Coste mínimo.

**Rationale**: La lógica de filtrado vive en el provider (Principio III), no en el widget. El widget sólo lee.

**Alternatives considered**:
- **Filtrar en el widget (`.where` en el `itemBuilder`)**: violaría la separación UI/lógica. Descartado.
- **Filtrar en el DAO (nueva consulta SQL con cláusula WHERE category IN (...))**: más eficiente pero innecesario a esta escala; añade superficie de tests y complica el DAO. Descartado.

### 4.5 UI del selector

**Decision**: Nuevo widget `CategoryFilterSelector` análogo a `TimeRangeSelector`:

- Mismo patrón de `Wrap` de `ChoiceChip`.
- Etiquetas en español desde `CategoryFilter.label`.
- Colores: selected → `AppColors.balance.withOpacity(0.2)`, background → `AppColors.surfaceVariant`.
- Padding del padre en `EntradasView`: un `Column` con `TimeRangeSelector` arriba y `CategoryFilterSelector` debajo, ambos dentro del mismo `Padding(EdgeInsets.all(16))`, separados por `SizedBox(height: 8)`.

**Rationale**: Reutiliza el patrón ya validado visualmente. Los 8 chips de categoría caben en `Wrap` (pasan a una segunda línea en pantallas estrechas).

---

## Resumen de decisiones

| # | Decisión | Archivo afectado | Test |
|---|----------|-------------------|------|
| R1 | Quitar `onDelete` de la llamada en Entradas | `entradas_view.dart` | widget test |
| R2 | Mover `recurringDetail` a subtitle | `packages/shared_ui/.../transaction_row.dart` | widget test |
| R3 | Activar `SideTitles` con `niceInterval` puro | `analysis_line_chart.dart` + nuevo `domain/chart_axis.dart` | unit + widget |
| R4a | Enum `CategoryFilter` (8 valores + all) | nuevo `domain/category_filter.dart` | unit |
| R4b | `StateProvider.autoDispose` para el filtro | `transaction_providers.dart` | unit |
| R4c | Provider derivado `filteredEntriesProvider` | `transaction_providers.dart` | unit |
| R4d | Widget `CategoryFilterSelector` | nuevo `ui/entradas/category_filter_selector.dart` | widget |
| R4e | `rawCategory` en `TransactionDisplay` | `transaction_providers.dart` | — |

Todas las decisiones son compatibles con el Constitution Check. No se introduce ninguna dependencia nueva.
