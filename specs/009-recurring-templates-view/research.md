# Research: Vista de Templates Recurrentes (009)

## Codebase findings

### Archivos clave del área de cambio

| Archivo | Ruta actual (rama 007) | Rol |
|---------|----------------------|-----|
| Router | `my_apps/apps/sfinance/lib/routing/app_router.dart` | Define rutas con go_router. ShellRoute wraps Resumen/Analisis/Entradas. |
| AppShell | `my_apps/apps/sfinance/lib/ui/shell/app_shell.dart` | `_currentIndex()` mapea path → índice de tab. 3 tabs hoy. |
| TemplateDisplay | `my_apps/apps/sfinance/lib/providers/template_providers.dart` | Modelo de display para templates; `activeTemplatesProvider` expone `Stream<List<TemplateDisplay>>`. |
| TemplateDao | `my_apps/packages/shared_services/lib/src/database/daos/template_dao.dart` | Tiene `watchActive()` y `softDelete()`. Falta `updateAmount()`. |
| RecurringTemplates | `my_apps/packages/shared_services/lib/src/database/tables/recurring_templates.dart` | Columna `amountCents` ya existe. `paymentDay` nullable. `lastGeneratedPeriod` nullable. `endDate` nullable (feature 007). |

### Estado de TemplateDisplay (post-007)

```dart
class TemplateDisplay {
  final int id;
  final String name;
  final String categoryLabel;  // e.g. "Suscripción"
  final String periodicity;    // e.g. "Mensual"
  final DateTime? endDate;     // null = sin fecha de fin
  final TransactionType transactionType;
  // ❌ amountCents no incluido
  // ❌ nextPaymentDate no incluido
  // ❌ paymentDay no incluido
}
```

### Patrón de gestión de estado

Las formas existentes (`ExpenseForm`, `IncomeForm`) son `ConsumerWidget` respaldadas por `StateNotifierProvider` globales (`expenseFormProvider`, `incomeFormProvider`). No usan `setState`. El mismo patrón se aplicará al modal de detalle.

---

## Decisiones

### D-001: Enriquecer TemplateDisplay en lugar de crear un provider paralelo

- **Decision**: Añadir `amountCents`, `paymentDay` y `nextPaymentDate` a `TemplateDisplay` y actualizar `_toDisplay()` para computarlos. `activeTemplatesProvider` ya hace lo correcto; no se crea un provider redundante.
- **Rationale**: Evita duplicar la query a `watchActive()`. Un único proveedor de verdad. El usuario puede usar `activeTemplatesProvider` también en otras vistas futuras.
- **Alternatives considered**: Crear `recurrentesProvider = StreamProvider` separado → rechazado (duplicaría la query y el mapping).

### D-002: Cálculo de nextPaymentDate como función pura testeable

- **Decision**: Extraer `DateTime computeNextPaymentDate(int paymentDay, DateTime today)` como función top-level en `template_providers.dart`. La función determina la próxima ocurrencia de `paymentDay` en el mes actual o siguiente.
- **Rationale**: Lógica de fecha es considerada "financial logic" por la constitución → test-first obligatorio. Función pura facilita tests sin fixtures de DB.
- **Alternatives considered**: Calcularlo inline en `_toDisplay()` sin extraer → rechazado (no testeable de forma aislada).

### D-003: Estado del modal con StateNotifierProvider autoDispose

- **Decision**: Crear `templateDetailNotifier` con `StateNotifierProvider.autoDispose` que gestiona: el ID del template seleccionado, si está en modo edición, el texto del monto editado, y el mensaje de error inline.
- **Rationale**: Los providers `autoDispose` se destruyen cuando ningún widget los observa (al cerrar el modal), evitando estado stale. Cumple principio II (no setState).
- **Alternatives considered**: `StateProvider<bool>` individual para cada pieza de estado → rechazado (difícil coordinar reset). `ConsumerStatefulWidget` con setState → rechazado (viola principio II).

### D-004: Eliminación vía softDelete existente

- **Decision**: La acción "Eliminar" llama a `TemplateDao.softDelete(id)` ya existente. No se añade nueva lógica de borrado en el DAO.
- **Rationale**: `softDelete` ya hace exactamente lo requerido (isDeleted=true, entradas previas intactas). No hay razón para añadir una variante.

### D-005: updateAmount solo toca amountCents

- **Decision**: `TemplateDao.updateAmount(int id, int newAmountCents)` escribe únicamente `amountCents` usando `RecurringTemplatesCompanion(amountCents: Value(newAmountCents))`.
- **Rationale**: La especificación dice explícitamente que la edición de monto no afecta a ningún otro campo. Drift permite actualizaciones parciales vía `Companion`.

### D-006: Ruta /recurrentes como ShellRoute child

- **Decision**: Añadir `GoRoute(path: '/recurrentes', ...)` dentro del `ShellRoute` existente. `AppShell._currentIndex()` añade caso `'/recurrentes' → 3`.
- **Rationale**: Consistente con el patrón de las tres rutas existentes. El `ShellRoute` ya provee el shell con tabs y action buttons.

### D-007: Estructura de archivos nuevos

```
apps/sfinance/lib/ui/recurrentes/
├── recurrentes_view.dart          # Lista principal
└── template_detail_modal.dart     # Modal de detalle + edición + eliminación
```

No se crean nuevos packages — todo es código específico de la app sfinance.

### D-008: Formato de paymentDay cuando es null

- **Decision**: Si `paymentDay` es null (templates anteriores a feature 005), `nextPaymentDate` se calcula asumiendo día 1 del mes, consistente con la lógica existente en `PeriodGenerator`.
- **Rationale**: Evita romper la experiencia para templates legacy.

---

## Test plan para financial logic

Las siguientes funciones requieren tests escritos y en rojo ANTES de la implementación (Principio IV):

1. `computeNextPaymentDate(paymentDay, today)`:
   - today.day < paymentDay → devuelve mismo mes, día=paymentDay
   - today.day == paymentDay → devuelve mismo mes (pago es hoy)
   - today.day > paymentDay → devuelve mes siguiente, día=paymentDay
   - paymentDay=31 en mes con 30 días → último día del mes o primer día del siguiente (decidir)
   - paymentDay=null → día 1

2. Validación de monto en notifier:
   - String vacío → error "El monto no puede estar vacío"
   - "0" o negativo → error "El monto debe ser mayor que cero"
   - No numérico → error "Introduce un número válido"
   - Valor válido → actualiza DAO, cierra modo edición
