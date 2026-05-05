# Implementation Plan: Entries UX Fixes and Analysis Chart Axes

**Branch**: `010-entries-ux-fixes` | **Date**: 2026-04-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/010-entries-ux-fixes/spec.md`

## Summary

Four localized UX corrections on the existing SFinance app:

1. Quitar el botón "Eliminar" del `TransactionRow` en la vista Entradas (conservándolo en Recurrentes).
2. Corregir el overflow vertical (9 px) del icono de recurrencia cuando muestra `recurringDetail` debajo del avatar.
3. Añadir etiquetas en ejes X (fecha) e Y (importe) a los gráficos de línea de la vista Análisis (fl_chart `SideTitles`).
4. Añadir un filtro de categoría como segundo `Wrap` de chips en la vista Entradas, combinado en AND con el filtro de temporalidad existente.

Sin cambios de modelo ni de base de datos. Sin nuevas dependencias. Todo el trabajo se concentra en `my_apps/apps/sfinance/lib/ui/` y en `packages/shared_ui/lib/src/widgets/transaction_row.dart`.

## Technical Context

**Language/Version**: Dart 3.x — Flutter stable  
**Primary Dependencies**: flutter_riverpod, go_router, drift ^2.20.0, fl_chart, intl, shared_ui, shared_models, shared_services  
**Storage**: SQLite (Drift) local on-device — sin cambios de esquema  
**Testing**: flutter_test + Riverpod test utilities (providers unit tests, widget tests)  
**Target Platform**: Flutter desktop (Windows primario, Android planificado)  
**Project Type**: Desktop app dentro de un monorepo Melos  
**Performance Goals**: 60 fps en la vista Entradas con hasta 1 000 filas; repintado < 16 ms al cambiar filtro.  
**Constraints**: Offline-first, sin telemetría, WCAG AA en contraste, keyboard-navigable.  
**Scale/Scope**: Usuario único; ~500–2 000 entradas totales en escenario realista; 3 gráficas de línea en Análisis.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Notes |
|-----------|-------|-------|
| I. Monorepo & Shared Code | Código nuevo ¿va a `packages/`? ¿Hay breaking changes en APIs públicas? | `TransactionRow` (shared_ui) pierde callers que usan `onDelete` desde Entradas. El parámetro es opcional y se mantiene; no hay breaking change. |
| II. Riverpod-Only State | ¿Sin `setState`, sin otras libs, providers globales? | El nuevo filtro de categoría se añade como `StateProvider` global (`selectedCategoryFilterProvider`), mismo patrón que `selectedTimeRangeProvider`. La vista Análisis ya usa `setState` local para `_balanceRange`, `_gastosRange`, `_ingresosRange` — **violación preexistente**, no se introduce nueva. |
| III. UI/Business Logic Separation | ¿Cero lógica de negocio en widgets? ¿Routing central? ¿Modelos Dart puros? | Cálculo de intervalos de ejes y formato de etiquetas se encapsula en helpers puros en `domain/` o en el propio widget de gráfica (presentacional). Filtrado por categoría se realiza en el provider, no en el widget. |
| IV. Test-First for Financial Logic | ¿Tests financieros antes de implementación? | No hay lógica financiera nueva. El filtro de categoría no altera cálculos. Se añadirán tests unitarios para el helper de intervalos del eje Y (formateo de valores en céntimos → etiqueta) antes de implementar. |
| V. Offline-First & Privacy | ¿Sin red, sin datos sensibles en logs? | No se introducen llamadas de red ni logs nuevos. |
| VI. Financial UX Clarity | ¿Moneda/fecha/signo correctos, accesibilidad, patrones touch-compatibles? | Etiquetas del eje Y usan `CurrencyFormatter` con símbolo de divisa. Eje X usa `DateFormatter` abreviado. ChoiceChips son keyboard-navigables y touch-friendly. |
| VII. Simplicity | ¿Dependencias justificadas, sin abstracciones prematuras, arquitectura legible? | Ninguna dependencia nueva. Ninguna nueva capa. Se extiende `TimeRangeSelector`-like con un segundo selector hermano. |

**Violaciones**: ninguna nueva introducida. La violación preexistente de `setState` en `AnalisisView` queda fuera del alcance de este feature (no se toca esa parte del archivo salvo el widget de gráfica interno).

## Project Structure

### Documentation (this feature)

```text
specs/010-entries-ux-fixes/
├── plan.md              # Este fichero
├── research.md          # Phase 0 output
├── quickstart.md        # Phase 1 output
├── checklists/
│   └── requirements.md  # Generada por /speckit.specify
└── tasks.md             # Phase 2 output (generada por /speckit.tasks)
```

No se genera `data-model.md` — no hay entidades nuevas ni cambios de esquema.
No se genera `contracts/` — la app no expone interfaces externas; los únicos "contratos" son providers Riverpod y widgets, documentados en código.

### Source Code (repository root)

```text
my_apps/
├── apps/
│   └── sfinance/
│       ├── lib/
│       │   ├── domain/
│       │   │   └── category_filter.dart            # NUEVO — enum + lógica pura
│       │   ├── providers/
│       │   │   └── transaction_providers.dart      # MODIFICADO — nuevo StateProvider + filtrado
│       │   └── ui/
│       │       ├── entradas/
│       │       │   ├── entradas_view.dart          # MODIFICADO — quita delete, añade filtro categoría
│       │       │   └── category_filter_selector.dart # NUEVO — widget selector (chips)
│       │       └── analisis/
│       │           └── analysis_line_chart.dart    # MODIFICADO — SideTitles X e Y
│       └── test/
│           ├── domain/
│           │   └── category_filter_test.dart       # NUEVO
│           ├── providers/
│           │   └── transaction_providers_filter_test.dart # NUEVO
│           └── ui/
│               ├── entradas/
│               │   └── entradas_no_delete_test.dart # NUEVO (widget test)
│               └── analisis/
│                   └── analysis_line_chart_axes_test.dart # NUEVO
└── packages/
    └── shared_ui/
        └── lib/src/widgets/
            └── transaction_row.dart                # MODIFICADO — fix overflow en leading
```

**Structure Decision**: Monorepo Melos existente. Todo el trabajo se queda dentro de `apps/sfinance/` salvo el fix de overflow, que pertenece al widget compartido `transaction_row.dart` en `packages/shared_ui/` (regla del Principio I: vive donde ya está compartido).

## Complexity Tracking

*No se aplican desviaciones nuevas al constitucional. Queda registrada la deuda preexistente de `setState` en `AnalisisView` como fuera de alcance.*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (ninguna nueva) | — | — |
