# Tasks: Vista de Templates Recurrentes

**Input**: Design documents from `/specs/009-recurring-templates-view/`  
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓

**Tests**: Incluidos donde la Constitución lo exige (Principio IV — test-first para lógica financiera). Marcados explícitamente. NO son opcionales para `computeNextPaymentDate` y validación de monto.

**Organization**: Tareas agrupadas por User Story para implementación y testing independientes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencias incompletas)
- **[Story]**: User Story a la que pertenece la tarea (US1–US4)

## Path Conventions

- **App**: `my_apps/apps/sfinance/lib/`
- **Tests app**: `my_apps/apps/sfinance/test/`
- **DAO (shared_services)**: `my_apps/packages/shared_services/lib/src/database/daos/`
- **Providers**: `lib/providers/`
- **Widgets**: `lib/ui/`

---

## Phase 1: Setup

**Purpose**: Crear estructura de directorios necesaria. Sin nuevos packages ni dependencias.

- [X] T001 Crear directorio `my_apps/apps/sfinance/lib/ui/recurrentes/` con dos archivos stub vacíos: `recurrentes_view.dart` y `template_detail_modal.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Piezas compartidas que bloquean todas las User Stories: extensión del modelo de display, DAO, lógica de fecha (con tests previos), estado del modal, routing y tab de navegación.

**⚠️ CRITICAL**: Ninguna US puede comenzar hasta que esta fase esté completa.

- [X] T002 Añadir `orderBy([(t) => OrderingTerm.asc(t.createdAt)])` al método `watchActive()` en `my_apps/packages/shared_services/lib/src/database/daos/template_dao.dart` para que la lista salga ordenada por fecha de creación ascendente
- [X] T003 Añadir método `updateAmount(int id, int newAmountCents)` en `my_apps/packages/shared_services/lib/src/database/daos/template_dao.dart` — escribe solo `RecurringTemplatesCompanion(amountCents: Value(newAmountCents))`
- [X] T004 **[TEST-FIRST — debe estar en ROJO antes de T005]** Escribir tests de `computeNextPaymentDate` en `my_apps/apps/sfinance/test/providers/template_providers_test.dart` cubriendo: `paymentDay > today.day` (mismo mes), `paymentDay == today.day` (hoy mismo), `paymentDay < today.day` (mes siguiente), `paymentDay > días del mes destino` (último día del mes), `paymentDay` null (equivale a 1)
- [X] T005 Implementar función pura `DateTime computeNextPaymentDate(int paymentDay, DateTime today)` como top-level en `my_apps/apps/sfinance/lib/providers/template_providers.dart` — los tests T004 deben pasar en verde tras este paso
- [X] T006 Añadir campos `amountCents` (int), `paymentDay` (int?), `nextPaymentDate` (DateTime) a la clase `TemplateDisplay` en `my_apps/apps/sfinance/lib/providers/template_providers.dart` y actualizar `_toDisplay()` para poblarlos (usa `computeNextPaymentDate`)
- [X] T007 [P] Añadir clase `TemplateDetailState` y `TemplateDetailNotifier extends StateNotifier<TemplateDetailState>` con métodos `startEditing(int currentAmountCents)`, `setAmountText(String)`, `confirmEdit(int templateId, TemplateDao)`, `cancelEdit()`, `deleteTemplate(int id, TemplateDao)` en `my_apps/apps/sfinance/lib/providers/template_providers.dart`; añadir `final templateDetailProvider = StateNotifierProvider.autoDispose<TemplateDetailNotifier, TemplateDetailState>((ref) => ...)`
- [X] T008 [P] Añadir `GoRoute(path: '/recurrentes', builder: (_, __) => const RecurrentesView())` dentro del `ShellRoute` en `my_apps/apps/sfinance/lib/routing/app_router.dart` y el import necesario
- [X] T009 [P] Añadir `_NavTab(label: 'Recurrentes', selected: currentIndex == 3, onTap: () => context.go('/recurrentes'))` en `AppShell.build()` y el caso `if (location.startsWith('/recurrentes')) return 3;` en `_currentIndex()` en `my_apps/apps/sfinance/lib/ui/shell/app_shell.dart`

**Checkpoint**: Foundation lista — ejecutar `flutter test my_apps/apps/sfinance/test/providers/template_providers_test.dart` y confirmar que T004 pasa. Verificar que la app compila y la pestaña "Recurrentes" aparece en la barra de navegación (aunque la vista esté vacía).

---

## Phase 3: User Story 1 — Ver todos los compromisos recurrentes activos (Priority: P1) 🎯 MVP

**Goal**: Lista compacta de templates activos con nombre, monto (€), fecha del próximo pago (ej. "15 may. 2026") y fecha de fin (o "Sin fecha límite"). Estado vacío cuando no hay templates.

**Independent Test**: Con al menos un template activo en DB, abrir la pestaña "Recurrentes" y verificar que aparece la fila con todos sus datos formateados correctamente. Con lista vacía, verificar el mensaje de estado vacío.

### Implementation for User Story 1

- [X] T010 [US1] Implementar `RecurrentesView` en `my_apps/apps/sfinance/lib/ui/recurrentes/recurrentes_view.dart`: `ConsumerWidget` que observa `activeTemplatesProvider`; muestra `CircularProgressIndicator` mientras carga, lista de `_TemplateRow` widgets cuando hay datos, widget de estado vacío cuando la lista está vacía
- [X] T011 [US1] Implementar widget privado `_TemplateRow` dentro de `recurrentes_view.dart`: muestra nombre (bold), monto formateado como `€ X.XX` usando `intl` (NumberFormat), fecha del próximo pago formateada como `"d MMM yyyy"` en español (DateFormat), y fecha de fin formateada o texto "Sin fecha límite" si `endDate == null`; tap abre el modal (ver US2)
- [X] T012 [US1] Implementar widget privado `_EmptyState` dentro de `recurrentes_view.dart`: icono, título "Sin compromisos recurrentes" y subtítulo explicativo

**Checkpoint**: US1 completamente funcional. La pestaña "Recurrentes" muestra la lista con datos reales, formato correcto de euros y fechas, y estado vacío si no hay templates.

---

## Phase 4: User Story 2 — Consultar el detalle completo de un template (Priority: P2)

**Goal**: Al pulsar una fila se abre un modal con todos los campos del template (nombre, tipo/categoría, monto, día de pago, fecha inicio, fecha fin). Cierra al pulsar fuera o el botón X.

**Independent Test**: Pulsar una fila y verificar que el modal muestra exactamente el nombre, tipo, monto formateado, día de pago, fecha de inicio y fecha de fin (o "Sin fecha límite") del template seleccionado.

### Implementation for User Story 2

- [X] T013 [US2] Implementar `TemplateDetailModal` en `my_apps/apps/sfinance/lib/ui/recurrentes/template_detail_modal.dart`: `ConsumerWidget` que recibe un `TemplateDisplay`; usa `Dialog` con `ConstrainedBox(maxWidth: 480)`; muestra todos los campos en secciones legibles (nombre, tipo, monto, día de pago, fecha inicio, fecha fin); botón X de cierre
- [X] T014 [US2] Añadir `onTap` en `_TemplateRow` (en `recurrentes_view.dart`) que invoca `showDialog(context, builder: (_) => TemplateDetailModal(template: t))` para el template seleccionado
- [X] T015 [P] [US2] Verificar que el `Dialog` se cierra al pulsar fuera (comportamiento por defecto de `showDialog` con `barrierDismissible: true`) y que el botón X llama `Navigator.of(context).pop()`

**Checkpoint**: US2 completamente funcional. Tap en fila → modal con info completa → cierre por X o tap fuera.

---

## Phase 5: User Story 3 — Actualizar el monto sin alterar el historial (Priority: P3)

**Goal**: Botón "Editar monto" en el modal activa un campo de texto inline (dentro del mismo modal) con el monto actual pre-rellenado. Confirmar guarda solo `amountCents` en el template; las entradas previas no se modifican. Cancelar no cambia nada. Errores de validación se muestran inline.

**Independent Test**: Editar el monto de un template que ya tiene entradas generadas → verificar que el template muestra el nuevo monto → abrir Entradas y verificar que las entradas anteriores mantienen su importe original.

### Tests for User Story 3 (REQUIRED — Constitución Principio IV)

> **⚠️ Escribir PRIMERO, confirmar que están en ROJO antes de implementar T018**

- [X] T016 [US3] **[TEST-FIRST — debe estar en ROJO antes de T018]** Añadir tests de validación de monto al `TemplateDetailNotifier` en `my_apps/apps/sfinance/test/providers/template_providers_test.dart` cubriendo: string vacío → `amountError` no null; "0" → error; "-5" → error; "abc" → error; "9.99" (válido) → llama `updateAmount` y `isEditingAmount` vuelve a false

### Implementation for User Story 3

- [X] T017 [US3] Implementar `startEditing(int currentAmountCents)`, `setAmountText(String)`, `confirmEdit(int templateId)` y `cancelEdit()` en `TemplateDetailNotifier` con lógica de validación (vacío, ≤0, no numérico) en `my_apps/apps/sfinance/lib/providers/template_providers.dart` — los tests T016 deben pasar en verde tras este paso
- [X] T018 [US3] Añadir sección de edición de monto en `TemplateDetailModal`: cuando `state.isEditingAmount == false`, mostrar botón "Editar monto"; cuando `true`, mostrar `TextField` pre-rellenado con el monto actual (en euros), botones "Confirmar" y "Cancelar", y `Text` de error rojo si `state.amountError != null`; llamar acciones del notifier en `onChanged`/`onPressed`

**Checkpoint**: US3 completamente funcional. Editar monto → validación inline → confirmar → monto actualizado en el template. Historial de entradas intacto.

---

## Phase 6: User Story 4 — Eliminar un template con confirmación (Priority: P4)

**Goal**: Botón "Eliminar" en el modal abre un `AlertDialog` con texto que explica que no se generarán más entradas pero las existentes se conservan. Confirmar hace soft-delete y el template desaparece de la lista. Cancelar mantiene todo igual.

**Independent Test**: Pulsar "Eliminar" → confirmar en el dialog → verificar que el template desaparece de la lista y el modal se cierra. Las entradas de ese template siguen en la vista Entradas.

### Implementation for User Story 4

- [X] T019 [US4] Implementar `deleteTemplate(int id)` en `TemplateDetailNotifier` que llama a `_dao.softDelete(id)` en `my_apps/apps/sfinance/lib/providers/template_providers.dart`
- [X] T020 [US4] Añadir botón "Eliminar" (color rojo/destructivo) en `TemplateDetailModal` (`my_apps/apps/sfinance/lib/ui/recurrentes/template_detail_modal.dart`) cuyo `onPressed` muestra `showDialog` con un `AlertDialog` que contiene: título "¿Eliminar este template?", texto explicativo "No se generarán más entradas. Las entradas ya registradas se conservan.", botón "Cancelar" y botón "Eliminar" (destructivo)
- [X] T021 [US4] Al confirmar el `AlertDialog`, llamar `ref.read(templateDetailProvider.notifier).deleteTemplate(template.id)` y luego `Navigator.of(context).pop()` para cerrar el modal de detalle

**Checkpoint**: US4 completamente funcional. Eliminar → confirmar → template desaparece de lista → modal cerrado → historial intacto.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Calidad, accesibilidad y análisis estático.

- [X] T022 [P] Ejecutar `flutter test` desde `my_apps/apps/sfinance/` y verificar que los 55+ tests existentes + los nuevos tests de esta feature pasan; corregir cualquier regresión
- [X] T023 [P] Ejecutar `flutter analyze` desde `my_apps/apps/sfinance/` y desde `my_apps/packages/shared_services/` y corregir cualquier warning o error
- [X] T024 Revisar UX manualmente en la app: verificar contraste WCAG AA en todos los nuevos widgets, tap targets ≥ 44×44 dp en filas y botones, y que el modal es desplazable si el contenido supera la altura de pantalla

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias — puede empezar de inmediato
- **Foundational (Phase 2)**: Depende de Phase 1. **BLOQUEA todas las User Stories**
  - T004 (tests) DEBE estar en rojo antes de T005 (implementación)
  - T007, T008, T009 pueden ejecutarse en paralelo entre sí y con T002–T006
- **US1 (Phase 3)**: Depende de Phase 2 completa (especialmente T006, T008, T009)
- **US2 (Phase 4)**: Depende de Phase 3 (necesita `RecurrentesView` para el tap)
- **US3 (Phase 5)**: Depende de Phase 4 (el modal debe existir) y T003 (DAO updateAmount)
  - T016 (tests) DEBE estar en rojo antes de T017 (implementación)
- **US4 (Phase 6)**: Depende de Phase 4 (el modal debe existir)
- **Polish (Phase 7)**: Depende de todas las fases anteriores

### User Story Dependencies

- **US1 (P1)**: Puede empezar tras Phase 2 — sin dependencias en otras US
- **US2 (P2)**: Depende de US1 (necesita `RecurrentesView` con filas tapeables)
- **US3 (P3)**: Depende de US2 (se implementa dentro del mismo modal)
- **US4 (P4)**: Depende de US2 (se implementa dentro del mismo modal); puede hacerse en paralelo con US3 si se trabaja en secciones distintas del modal

### Within Each User Story

- Tests DEBEN ser escritos y estar en ROJO antes de la implementación correspondiente
- Foundational tasks bloquean todas las stories
- `_TemplateRow` antes del `onTap` que abre el modal (T011 antes de T014)

### Parallel Opportunities

- En Phase 2: T002+T003 (DAO) ‖ T004 (tests fecha) ‖ T007 (notifier) ‖ T008 (router) ‖ T009 (shell)
- En Phase 3: T010 (formato) puede trabajarse junto con T011 (estructura)
- En Phase 6: US3 y US4 pueden avanzar en paralelo en archivos distintos del modal

---

## Parallel Example: Phase 2

```
# Pueden ejecutarse en simultáneo:
T002: template_dao.dart — añadir orderBy a watchActive()
T003: template_dao.dart — añadir updateAmount()
T004: template_providers_test.dart — tests FAILING de computeNextPaymentDate

# En paralelo con lo anterior:
T008: app_router.dart — ruta /recurrentes
T009: app_shell.dart — 4ª tab

# Después de T004 en rojo:
T005: template_providers.dart — implementar computeNextPaymentDate (T004 → verde)
T006: template_providers.dart — extender TemplateDisplay
T007: template_providers.dart — añadir templateDetailNotifier
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Completar Phase 1: Setup
2. Completar Phase 2: Foundational (crítico — bloquea todo)
3. Completar Phase 3: US1 — lista compacta
4. **PARAR y VALIDAR**: la pestaña "Recurrentes" muestra la lista con datos reales
5. Continuar con US2 si el MVP es aceptable

### Incremental Delivery

1. Setup + Foundational → navegación funciona, pestaña visible (aunque vacía)
2. US1 → lista compacta operativa → **MVP validable**
3. US2 → modal de detalle operativo
4. US3 → edición de monto operativa
5. US4 → eliminación operativa
6. Polish → calidad lista para release

---

## Notes

- [P] = archivos distintos o bloques independientes, sin dependencias incompletas
- Tests marcados **[TEST-FIRST]** son obligatorios por Constitución Principio IV — NO saltar
- Tras T005 y T017 ejecutar los tests y confirmar verde antes de avanzar
- Commit recomendado: por tarea o por checkpoint de fase
- Archivos nuevos: `recurrentes_view.dart`, `template_detail_modal.dart`, `template_providers_test.dart`
- Archivos modificados: `template_dao.dart`, `template_providers.dart`, `app_router.dart`, `app_shell.dart`
