# Implementation Plan: Vista de Templates Recurrentes

**Branch**: `009-recurring-templates-view` | **Date**: 2026-04-18 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/009-recurring-templates-view/spec.md`

## Summary

Añadir una 4ª pestaña "Recurrentes" a la navegación de SFinance que muestra todos los templates recurrentes activos en una lista compacta. Al pulsar una fila se abre un modal de detalle con la información completa, opción de editar el monto (solo entradas futuras) y de eliminar el template con confirmación. El stack no cambia (Flutter, Riverpod, Drift, go_router). No hay migración de esquema — `amountCents` ya existe. La lógica de negocio nueva es: (1) `computeNextPaymentDate` — función pura con tests obligatorios antes de implementar; (2) `TemplateDao.updateAmount` — escribe solo `amountCents`.

## Technical Context

**Language/Version**: Dart 3.x — Flutter stable  
**Primary Dependencies**: flutter_riverpod, go_router, drift ^2.20.0, shared_ui, shared_models, shared_services  
**Storage**: SQLite local vía Drift. Sin cambio de esquema (v3 se mantiene).  
**Testing**: `flutter_test` + Riverpod test utilities. Tests en `apps/sfinance/test/` y `packages/shared_services/test/`.  
**Target Platform**: Desktop (Windows, primary). Android planeado.  
**Project Type**: Desktop app Flutter (monorepo Melos)  
**Performance Goals**: Lista carga < 2 s (StreamProvider desde DB local — trivial).  
**Constraints**: Solo datos locales. Sin red. Sin telemetría.  
**Scale/Scope**: Pocos templates por usuario (< 20). Sin paginación necesaria.

## Constitution Check

*GATE: revisado antes de Phase 0 research. Re-chequeado tras Phase 1.*

| Principio | Check | Notas |
|-----------|-------|-------|
| I. Monorepo & Shared Code | `updateAmount()` va a `shared_services/daos/template_dao.dart` ✓. `TemplateDisplay` + `computeNextPaymentDate` quedan en `apps/sfinance/lib/providers/` (lógica de presentación específica de app) ✓. `RecurrentesView` y `TemplateDetailModal` en `apps/sfinance/lib/ui/recurrentes/` ✓. No se rompe ninguna API pública de packages (se añade un método nuevo). | Añadir campos a `TemplateDisplay` es un cambio que requiere actualizar el único punto de construcción (`_toDisplay()`). No hay API pública rota. |
| II. Riverpod-Only State | Estado del modal → `StateNotifierProvider.autoDispose` ✓. No `setState`. No otros state managers. Todos los providers globalmente scoped ✓. | `autoDispose` se destruye al cerrar el modal, evitando estado stale. |
| III. UI/Business Logic Separation | `computeNextPaymentDate` se invoca desde `_toDisplay()` (capa de provider) ✓. Validación de monto en el notifier ✓. Widgets puramente presentacionales ✓. Routing centralizado en `app_router.dart` ✓. | El modal llama acciones del notifier; nunca escribe en DB directamente desde el widget. |
| IV. Test-First para Financial Logic | `computeNextPaymentDate` y validación de monto → tests escritos y en rojo ANTES de implementar (ver research.md §Test plan). | GATE: no se implementan estas funciones sin sus tests fallando primero. |
| V. Offline-First & Privacy | Sin llamadas de red. Sin telemetría. El monto no aparece en logs. ✓ | |
| VI. Financial UX Clarity | Monto en formato `€ X.XX` (intl). Fechas en `dd/MM/yyyy`. Confirmación de eliminación con texto explícito. WCAG AA para contraste. Tap-friendly en todos los elementos interactivos (futuro Android). ✓ | El campo de edición de monto muestra error inline visible. |
| VII. Simplicity | Sin dependencias nuevas. Sin abstracciones prematuras. 2 archivos nuevos de UI + 1 archivo de test + 4 archivos modificados. | |

> No hay violaciones. Complejidad Tracking vacío.

## Project Structure

### Documentation (this feature)

```text
specs/009-recurring-templates-view/
├── plan.md              # este archivo
├── research.md          # Phase 0 — decisiones y hallazgos
├── data-model.md        # Phase 1 — modelo de datos y contratos
└── tasks.md             # Phase 2 output (/speckit.tasks — por generar)
```

### Source Code

```text
my_apps/
├── apps/sfinance/
│   ├── lib/
│   │   ├── providers/
│   │   │   └── template_providers.dart       # MODIFICAR: +amountCents, +paymentDay, +nextPaymentDate en TemplateDisplay; +computeNextPaymentDate; +templateDetailNotifier
│   │   ├── routing/
│   │   │   └── app_router.dart               # MODIFICAR: añadir GoRoute /recurrentes en ShellRoute
│   │   └── ui/
│   │       ├── shell/
│   │       │   └── app_shell.dart            # MODIFICAR: 4º tab Recurrentes + _currentIndex case 3
│   │       └── recurrentes/
│   │           ├── recurrentes_view.dart     # NUEVO
│   │           └── template_detail_modal.dart # NUEVO
│   └── test/
│       └── providers/
│           └── template_providers_test.dart  # NUEVO: computeNextPaymentDate + validación monto
└── packages/shared_services/
    └── lib/src/database/daos/
        └── template_dao.dart                 # MODIFICAR: +updateAmount()
```

**Structure Decision**: Monorepo Flutter (Melos). Lógica compartida en `packages/`, lógica específica de app en `apps/sfinance/`. Sin cambio de estructura de paquetes.

## Complexity Tracking

> No hay violaciones de constitución que justificar.
