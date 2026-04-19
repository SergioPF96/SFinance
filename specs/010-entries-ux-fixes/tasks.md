# Tasks: Entries UX Fixes and Analysis Chart Axes

**Input**: Design documents from `/specs/010-entries-ux-fixes/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, quickstart.md ✅

**Tests**: Se incluyen tests unitarios para lógica de dominio pura (CategoryFilter, niceInterval) antes de implementación (Principio IV del Constitucional); y widget tests para las correcciones visuales tras implementación.

**Organization**: Tareas agrupadas por historia de usuario. US1 y US2 son independientes entre sí y pueden ejecutarse en paralelo. US4 depende de la tarea fundacional T002.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Se puede paralelizar (distintos ficheros, sin dependencias incompletas)
- **[Story]**: Historia de usuario a la que pertenece la tarea

## Path Conventions

- **App SFinance**: `my_apps/apps/sfinance/lib/`, tests en `my_apps/apps/sfinance/test/`
- **Shared UI**: `my_apps/packages/shared_ui/lib/src/widgets/`
- **Providers**: `my_apps/apps/sfinance/lib/providers/`
- **Domain puro**: `my_apps/apps/sfinance/lib/domain/`
- **Widgets UI**: `my_apps/apps/sfinance/lib/ui/`

---

## Phase 1: Setup

**Purpose**: Ninguna estructura nueva de proyecto necesaria. Solo confirmar el directorio de tests del dominio.

- [x] T001 Crear directorios de test faltantes: `my_apps/apps/sfinance/test/domain/`, `test/providers/`, `test/ui/entradas/`, `test/ui/analisis/` (si no existen)

---

## Phase 2: Foundational (Blocking Prerequisite para US4)

**Purpose**: Añadir el campo `rawCategory` a `TransactionDisplay` — necesario para que el filtro de categoría de US4 compare contra el valor raw almacenado en BD. US1, US2 y US3 no dependen de esta tarea.

**⚠️ US4 no puede comenzar hasta completar T002**

- [x] T002 Añadir campo `rawCategory: String` a `TransactionDisplay` y propagarlo en `_toDisplay` en `my_apps/apps/sfinance/lib/providers/transaction_providers.dart`

**Checkpoint**: `rawCategory` disponible en todos los `TransactionDisplay` — US4 puede comenzar.

---

## Phase 3: User Story 1 — Entries Cannot Be Deleted (Priority: P1) 🎯 MVP

**Goal**: Quitar el botón/icono de eliminar de cada fila en la vista Entradas; conservarlo en Recurrentes.

**Independent Test**: Abrir la app en la pestaña Entradas y verificar que ninguna fila tiene icono de papelera. Abrir un template en Recurrentes y confirmar que el control de borrado sigue presente.

### Tests para US1

> **Escribir PRIMERO, confirmar que FALLAN antes de implementar**

- [x] T003 [P] [US1] Escribir widget test en `my_apps/apps/sfinance/test/ui/entradas/entradas_no_delete_test.dart`: renderizar `EntradasView` con entradas mockeadas (una one-off, una recurrente) y verificar que `find.byIcon(Icons.delete_outline)` no encuentra ningún widget

### Implementation para US1

- [x] T004 [US1] En `my_apps/apps/sfinance/lib/ui/entradas/entradas_view.dart`: eliminar el parámetro `onDelete` del `TransactionRow` (líneas 75–77) y eliminar los métodos `_confirmDeleteRecurring`, `_confirmDeleteOneOff` y sus imports no usados (`dao_providers.dart`, `transactionDaoProvider`, `showConfirmationDialog`)

**Checkpoint**: US1 completa — ningún botón de borrado visible en Entradas, tests verdes.

---

## Phase 4: User Story 2 — Eliminar Overflow en Iconos (Priority: P1)

**Goal**: El texto de desbordamiento "Bottom overflowed by 9.0 pixels" desaparece de los iconos de entrada recurrente.

**Independent Test**: Renderizar `TransactionRow` con `isRecurring=true` y `recurringDetail='Día 15 de cada mes'`; consola libre de overflow; el detalle aparece en el subtitle.

### Tests para US2

> **Escribir PRIMERO, confirmar que FALLAN antes de implementar**

- [x] T005 [P] [US2] Escribir widget test en `my_apps/apps/sfinance/test/ui/shared_ui/transaction_row_overflow_test.dart` (dentro del package `shared_ui` o en `sfinance/test`): montar `TransactionRow` con `isRecurring=true`, `recurringDetail='Día 15 de cada mes'`; verificar `tester.takeException()` es null y que `find.textContaining('Día 15 de cada mes')` aparece en el subtítulo

### Implementation para US2

- [x] T006 [US2] En `my_apps/packages/shared_ui/lib/src/widgets/transaction_row.dart`: mover `recurringDetail` del bloque `leading` al subtitle, concatenándolo con el string existente (`'$categoryLabel · ${DateFormatter.format(date)}${recurringDetail != null ? " · $recurringDetail" : ""}'`); eliminar el `Column` wrapper del `leading` y dejar solo el `avatar` (con el badge `Icons.repeat` superpuesto via `Stack` cuando `isRecurring`)

**Checkpoint**: US2 completa — cero warnings de overflow en consola, `recurringDetail` visible en subtitle, tests verdes.

---

## Phase 5: User Story 3 — Ejes con Referencias en Gráficas (Priority: P2)

**Goal**: Las tres gráficas de línea de la vista Análisis muestran etiquetas de importe en el eje Y y etiquetas de fecha en el eje X.

**Independent Test**: Abrir la vista Análisis con datos en al menos dos periodos; verificar etiquetas visibles en ambos ejes en las tres gráficas; cambiar el rango y verificar que las etiquetas se recalculan.

### Tests para US3

> **Escribir PRIMERO, confirmar que FALLAN antes de implementar**

- [x] T007 [P] [US3] Escribir unit test en `my_apps/apps/sfinance/test/domain/chart_axis_test.dart`: tests para `niceInterval` con inputs (0, 100, 500, 1234, 12345, 999999, 1000000) y sus intervalos esperados; verificar formato abreviado de etiqueta Y (`formatAxisLabel`) con casos €0, €42, €1.2k, €25k, €1.2M

### Implementation para US3

- [x] T008 [US3] Crear `my_apps/apps/sfinance/lib/domain/chart_axis.dart` con las funciones puras: `double niceInterval(double range)` y `String formatAxisLabel(double cents)` (formato `€X`, `€Xk`, `€XM` con locale es_ES)
- [x] T009 [US3] En `my_apps/apps/sfinance/lib/ui/analisis/analysis_line_chart.dart`: importar `chart_axis.dart`; activar `leftTitles` con `SideTitles(showTitles: true, reservedSize: 44, interval: niceInterval(maxY - minY), getTitlesWidget: ...)` usando `formatAxisLabel`; activar `bottomTitles` con `SideTitles(showTitles: true, reservedSize: 22, interval: max(1, (N/5).ceil()).toDouble(), getTitlesWidget: ...)` usando `DateFormat('d MMM', 'es').format(dataPoints[index].date)`

**Checkpoint**: US3 completa — etiquetas visibles en ejes X e Y de las tres gráficas, unit tests verdes.

---

## Phase 6: User Story 4 — Filtro de Categoría en Entradas (Priority: P2)

**Goal**: Un segundo selector de chips aparece en la vista Entradas permitiendo filtrar por categoría (Todas, Producto, Servicio, Suscripcion, Suministro variable, Financiacion, Salario, Venta); el filtro se combina en AND con el de temporalidad y se resetea al salir de la vista.

**Independent Test**: Seleccionar chip "Suscripcion" → solo entradas de esa categoría visibles; cambiar temporalidad → ambos filtros aplicados; navegar fuera y volver → chips en "Todas".

> **⚠️ Requiere T002 completado (campo `rawCategory`)**

### Tests para US4

> **Escribir PRIMERO, confirmar que FALLAN antes de implementar**

- [x] T010 [P] [US4] Escribir unit test en `my_apps/apps/sfinance/test/domain/category_filter_test.dart`: verificar `CategoryFilter.all.matches('suscripcion')` → true; `CategoryFilter.suscripcion.matches('suscripcion')` → true; `CategoryFilter.suscripcion.matches('producto')` → false; verificar que todos los valores tienen `label` no vacío
- [x] T011 [P] [US4] Escribir unit test en `my_apps/apps/sfinance/test/providers/transaction_providers_filter_test.dart`: dado un `unifiedEntriesProvider` con entradas de categorías mixtas, verificar que `filteredEntriesProvider` con `CategoryFilter.suscripcion` devuelve solo entradas con `rawCategory == 'suscripcion'`

### Implementation para US4

- [x] T012 [P] [US4] Crear `my_apps/apps/sfinance/lib/domain/category_filter.dart` con enum `CategoryFilter { all, producto, servicio, suscripcion, suministroVariable, financiacion, salario, venta }` + getters `label` (strings en español) + método `bool matches(String rawCategory)`
- [x] T013 [US4] En `my_apps/apps/sfinance/lib/providers/transaction_providers.dart`: añadir `final selectedCategoryFilterProvider = StateProvider.autoDispose<CategoryFilter>((ref) => CategoryFilter.all)` y `final filteredEntriesProvider = Provider.autoDispose<AsyncValue<List<TransactionDisplay>>>((ref) {...})` que watchea `selectedTimeRangeProvider`, `selectedCategoryFilterProvider` y `unifiedEntriesProvider`, aplicando `CategoryFilter.matches(e.rawCategory)` (depende de T012 y T002)
- [x] T014 [P] [US4] Crear `my_apps/apps/sfinance/lib/ui/entradas/category_filter_selector.dart`: widget `CategoryFilterSelector` análogo a `TimeRangeSelector` — `Wrap` de `ChoiceChip` para todos los valores de `CategoryFilter`; colores `AppColors.balance.withOpacity(0.2)` / `AppColors.surfaceVariant`; pasa callback `ValueChanged<CategoryFilter>`
- [x] T015 [US4] En `my_apps/apps/sfinance/lib/ui/entradas/entradas_view.dart`: convertir a `ConsumerStatefulWidget`; en `dispose` llamar a `ref.invalidate(selectedCategoryFilterProvider)`; reemplazar `ref.watch(unifiedEntriesProvider(...))` por `ref.watch(filteredEntriesProvider)`; añadir `CategoryFilterSelector` debajo del `TimeRangeSelector` en el `Padding` de la cabecera (separados por `SizedBox(height: 8)`) (depende de T013, T014)

**Checkpoint**: US4 completa — filtro de categoría funcional con reset al navegar, todos los tests verdes.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [x] T016 [P] Ejecutar `flutter analyze` en `my_apps/apps/sfinance` y en `my_apps/packages/shared_ui`; corregir cualquier warning introducido por este feature
- [x] T017 Ejecutar suite completa de tests: `flutter test` en `my_apps/apps/sfinance` y `my_apps/packages/shared_ui`; confirmar 0 fallos
- [x] T018 Validación manual según `specs/010-entries-ux-fixes/quickstart.md`: recorrer US1–US4 con la app corriendo en Windows

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias — empezar inmediatamente
- **Foundational (Phase 2)**: Solo bloquea a US4 (T010–T015)
- **US1 (Phase 3)**: Sin dependencias — puede empezar tras Phase 1
- **US2 (Phase 4)**: Sin dependencias — puede empezar tras Phase 1
- **US3 (Phase 5)**: Sin dependencias — puede empezar tras Phase 1
- **US4 (Phase 6)**: Depende de T002 (Foundational)
- **Polish (Phase 7)**: Depende de todas las historias completadas

### User Story Dependencies

- **US1 (P1)**: Independiente
- **US2 (P1)**: Independiente (distinto fichero que US1)
- **US3 (P2)**: Independiente de US1 y US2
- **US4 (P2)**: Depende de T002; toca el mismo fichero `entradas_view.dart` que US1 → completar US1 antes o coordinar merge

### Within Each User Story

- Tests (T003, T005, T007, T010, T011) → escritos y confirmados FAILING antes de implementar
- Dominio puro (T008, T012) → antes de providers/widgets que lo usan
- Providers (T013) → antes del widget que los watchea (T015)

### Parallel Opportunities

- T003, T005, T007, T010, T011 son todos paralelos entre sí (distintos ficheros de test)
- T012 y T014 son paralelos entre sí (dentro de US4, ficheros independientes)
- US1, US2, US3 pueden ejecutarse en paralelo una vez terminada Phase 1

---

## Parallel Example

```
# Iniciar en paralelo (ficheros distintos, sin dependencias):
T003 — widget test entradas_no_delete_test.dart
T005 — widget test transaction_row_overflow_test.dart
T007 — unit test chart_axis_test.dart
T010 — unit test category_filter_test.dart
T011 — unit test transaction_providers_filter_test.dart

# Tras confirmar que los tests fallan, implementar:
T004 — eliminar onDelete en entradas_view.dart       (US1)
T006 — fix overflow en transaction_row.dart           (US2)
T008+T009 — chart_axis.dart + analysis_line_chart.dart (US3)
T012+T013+T014+T015 — CategoryFilter + provider + widget + view (US4)
```

---

## Implementation Strategy

### MVP (US1 + US2 — correcciones críticas)

1. Phase 1: T001
2. T003 → T004 → checkpoint US1
3. T005 → T006 → checkpoint US2
4. **STOP y VALIDAR**: app sin botones de borrado, sin overflow

### Incremental Delivery

1. T001 → T002 → Foundation lista
2. T003 → T004 → US1 ✅ (sin borrado)
3. T005 → T006 → US2 ✅ (sin overflow)
4. T007 → T008 → T009 → US3 ✅ (ejes en gráficas)
5. T010 → T011 → T012 → T013 → T014 → T015 → US4 ✅ (filtro categoría)
6. T016 → T017 → T018 → Feature completo

---

## Notes

- [P] = ficheros distintos, sin dependencias incompletas
- [Story] = traza la tarea a una historia de usuario del spec
- US1 y US2 tocan ficheros distintos (`entradas_view.dart` vs `transaction_row.dart`) → paralelos
- US4 toca `entradas_view.dart` igual que US1 → completar US1 antes de T015 para evitar conflictos
- `niceInterval` y `CategoryFilter` son Dart puro → testeables sin widget harness
- Commit tras cada checkpoint de historia (T004, T006, T009, T015)
