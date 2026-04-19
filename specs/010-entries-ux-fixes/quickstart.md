# Quickstart: Entries UX Fixes and Analysis Chart Axes

**Feature**: 010-entries-ux-fixes

Guía rápida para implementar y validar el feature localmente.

## Prerrequisitos

- Flutter stable instalado y configurado.
- Dependencias del workspace resueltas: desde la raíz del repo,
  ```bash
  /c/Users/Sergio/AppData/Local/Pub/Cache/bin/melos.bat bootstrap
  ```

## Ejecutar la app

```bash
cd my_apps/apps/sfinance
flutter run -d windows
```

## Validar cada historia manualmente

### US1 — Eliminar borrado en Entradas

1. Crear al menos una transacción one-off (botón "+ Gasto") y una entrada generada por un template recurrente activo (botón "+ Gasto" con periodicidad mensual/anual).
2. Ir a la pestaña **Entradas**.
3. Verificar que **ninguna fila** muestra el icono/botón rojo de papelera a la derecha.
4. Ir a la pestaña **Recurrentes**.
5. Verificar que al abrir un template en el modal, **sí** aparece el botón de eliminar programación.

**Pasa si**: 0 papeleras en Entradas, papelera presente en detalle de Recurrentes.

### US2 — Sin overflow en iconos

1. En la pestaña **Entradas**, con al menos una entrada recurrente visible, observar el icono circular de la izquierda.
2. Verificar en consola (`flutter run`) que **no** aparece el warning `A RenderFlex overflowed by 9.0 pixels on the bottom`.
3. Verificar visualmente que no hay franja amarilla/negra de overflow sobre el icono.
4. El detalle de recurrencia (ej. "Día 15 de cada mes") debe aparecer ahora como parte del subtítulo, después de la fecha.

**Pasa si**: consola limpia de overflow y detalle visible en el subtítulo.

### US3 — Ejes con referencias en Análisis

1. Ir a la pestaña **Análisis**.
2. Para cada una de las tres gráficas (Balance, Gastos, Ingresos):
   - El **eje Y** muestra etiquetas a la izquierda con importes (`€10`, `€1,2k`, `€25k`…) a intervalos regulares.
   - El **eje X** muestra etiquetas abajo con fechas abreviadas (`19 abr`, `21 abr`…) sin solapamiento.
3. Cambiar el rango temporal con los chips (`Últimos 7 días` → `Último año`) y verificar que las etiquetas se recalculan.
4. Con un único punto de datos, verificar que las etiquetas siguen siendo legibles.

**Pasa si**: ambas gráficas tienen etiquetas numéricas en los dos ejes en todos los rangos probados.

### US4 — Filtro de categoría

1. Con entradas de al menos 3 categorías distintas (ej. Suscripción, Producto, Salario), ir a la pestaña **Entradas**.
2. Verificar que debajo del filtro de temporalidad aparece un segundo `Wrap` con chips: `Todas, Producto, Servicio, Suscripcion, Suministro variable, Financiacion, Salario, Venta`.
3. Seleccionar `Suscripcion` → la lista debe mostrar solo entradas de esa categoría.
4. Cambiar el filtro de temporalidad a `Último año` manteniendo `Suscripcion` → ambos filtros aplicados en AND.
5. Seleccionar un filtro que deje 0 entradas (ej. `Venta` sin entradas de venta) → debe mostrarse el estado vacío "Sin entradas para este período".
6. Navegar a otra pestaña (ej. **Resumen**) y volver a **Entradas** → el filtro debe estar en `Todas`.

**Pasa si**: los 6 casos se comportan como se describe.

## Ejecutar tests

Todo el test suite:

```bash
/c/Users/Sergio/AppData/Local/Pub/Cache/bin/melos.bat run test
```

Solo la app SFinance:

```bash
cd my_apps/apps/sfinance
flutter test
```

Tests específicos del feature:

```bash
cd my_apps/apps/sfinance
flutter test test/domain/category_filter_test.dart
flutter test test/domain/chart_axis_test.dart
flutter test test/providers/transaction_providers_filter_test.dart
flutter test test/ui/entradas/entradas_no_delete_test.dart
flutter test test/ui/analisis/analysis_line_chart_axes_test.dart
```

## Análisis estático y formato

```bash
cd my_apps/apps/sfinance
flutter analyze
dart format .
```

## Criterio de aceptación global

- `flutter analyze` → 0 issues nuevos.
- `flutter test` → todos verdes.
- Las 4 validaciones manuales (US1–US4) pasan.
- Consola de la app libre de warnings de overflow.
