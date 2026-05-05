# Data Model: Vista de Templates Recurrentes (009)

## Sin cambio de esquema de base de datos

La tabla `recurring_templates` ya tiene todos los campos necesarios:

| Columna | Tipo Dart | Notas |
|---------|-----------|-------|
| `id` | `int` | PK |
| `name` | `String` | Nombre del template |
| `amount_cents` | `int` | Monto en céntimos (ya existe) |
| `transaction_type` | `String` | "income" / "expense" |
| `category` | `String` | enum name |
| `periodicity` | `String` | "mensual" / "anual" |
| `start_date` | `DateTime` | Fecha inicio |
| `end_date` | `DateTime?` | Null si sin fecha fin (feature 007) |
| `payment_day` | `int?` | Día del mes (1–31); null = legacy → 1 |
| `last_generated_period` | `String?` | Clave del último período generado |
| `is_deleted` | `bool` | Soft-delete |

**Versión de esquema**: se mantiene en v3. No hay migración.

---

## TemplateDisplay (extendido)

Añadir tres campos nuevos a la clase existente en `template_providers.dart`:

```dart
class TemplateDisplay {
  const TemplateDisplay({
    required this.id,
    required this.name,
    required this.categoryLabel,
    required this.periodicity,
    required this.endDate,
    required this.transactionType,
    // NUEVOS:
    required this.amountCents,
    required this.paymentDay,
    required this.nextPaymentDate,
  });

  final int id;
  final String name;
  final String categoryLabel;
  final String periodicity;
  final DateTime? endDate;           // null = sin fecha de fin
  final TransactionType transactionType;

  // --- NUEVOS (feature 009) ---
  final int amountCents;             // monto actual en céntimos
  final int? paymentDay;             // día del mes del pago (null = legacy → 1)
  final DateTime nextPaymentDate;    // próxima ocurrencia del día de pago
}
```

`_toDisplay()` se actualiza para poblar los tres campos nuevos:

```dart
TemplateDisplay _toDisplay(RecurringTemplateRow row) {
  // ... código existente ...
  final effectiveDay = row.paymentDay ?? 1;
  return TemplateDisplay(
    // ... campos existentes ...
    amountCents: row.amountCents,
    paymentDay: row.paymentDay,
    nextPaymentDate: computeNextPaymentDate(effectiveDay, DateTime.now()),
  );
}
```

---

## Nueva función pura: computeNextPaymentDate

Ubicación: `my_apps/apps/sfinance/lib/providers/template_providers.dart` (top-level)

```
DateTime computeNextPaymentDate(int paymentDay, DateTime today)
```

**Reglas**:
- Si `today.day <= paymentDay` → devuelve `DateTime(today.year, today.month, paymentDay)`
- Si `today.day > paymentDay` → devuelve primer día del mes siguiente = `DateTime(today.year, today.month + 1, paymentDay)`
  - Manejo de overflow de mes: usar `DateTime(y, m+1, 1)` para calcular el último día del mes si `paymentDay` excede los días del mes destino

---

## Nuevo método DAO: updateAmount

Ubicación: `my_apps/packages/shared_services/lib/src/database/daos/template_dao.dart`

```dart
Future<void> updateAmount(int id, int newAmountCents) async {
  await (update(recurringTemplates)..where((t) => t.id.equals(id))).write(
    RecurringTemplatesCompanion(amountCents: Value(newAmountCents)),
  );
}
```

Solo toca `amountCents`. Ningún otro campo cambia.

---

## Estado del modal de detalle

Modelo de estado gestionado por `templateDetailNotifier`:

```dart
class TemplateDetailState {
  const TemplateDetailState({
    this.isEditingAmount = false,
    this.amountText = '',
    this.amountError,
    this.isSubmitting = false,
  });

  final bool isEditingAmount;
  final String amountText;
  final String? amountError;
  final bool isSubmitting;
}
```

**Transiciones de estado**:
- `startEditing(currentAmountCents)` → `isEditingAmount = true`, `amountText` = monto formateado, error = null
- `setAmountText(text)` → actualiza `amountText`, limpia error
- `confirmEdit()` → valida → si ok: llama `updateAmount`, `isEditingAmount = false`; si error: pone `amountError`
- `cancelEdit()` → `isEditingAmount = false`, limpia texto y error
- `reset()` → estado inicial (llamado al abrir nuevo template)

---

## Nuevas rutas y navegación

`app_router.dart` — añadir dentro del `ShellRoute`:
```dart
GoRoute(
  path: '/recurrentes',
  builder: (context, state) => const RecurrentesView(),
),
```

`app_shell.dart` — cambios en `_currentIndex()`:
```dart
if (location.startsWith('/recurrentes')) return 3;
```

Y un 4º `_NavTab` con label `'Recurrentes'` y `onTap: () => context.go('/recurrentes')`.

---

## Estructura de archivos nuevos

```
my_apps/apps/sfinance/
├── lib/
│   ├── providers/
│   │   └── template_providers.dart     # MODIFICAR: TemplateDisplay + computeNextPaymentDate + provider detail state
│   ├── routing/
│   │   └── app_router.dart             # MODIFICAR: añadir ruta /recurrentes
│   └── ui/
│       ├── shell/
│       │   └── app_shell.dart          # MODIFICAR: 4ª tab Recurrentes
│       └── recurrentes/               # NUEVO directorio
│           ├── recurrentes_view.dart   # NUEVO
│           └── template_detail_modal.dart  # NUEVO
└── test/
    └── providers/
        └── template_providers_test.dart  # NUEVO: tests de computeNextPaymentDate y validación

my_apps/packages/shared_services/
└── lib/src/database/daos/
    └── template_dao.dart               # MODIFICAR: añadir updateAmount()
```
