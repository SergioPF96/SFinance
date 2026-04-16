# Feature Specification: Diferir primera entrada recurrente mensual según día de pago

**Feature Branch**: `006-defer-recurring-first-entry`  
**Created**: 2026-04-16  
**Status**: Draft  
**Input**: Cambiar el comportamiento de generación de entradas recurrentes mensuales: la primera entrada se genera al guardar solo si el día de pago (paymentDay) coincide con el día actual o aún no ha llegado en el mes en curso. Si paymentDay ya pasó este mes, la primera entrada se difiere al mismo día del mes siguiente. Ejemplos: hoy es 16/04, paymentDay=16 → entrada hoy; paymentDay=20 → entrada el 20/04; paymentDay=10 → entrada el 10/05. Este comportamiento aplica a todos los recurrentes mensuales (Suscripción, Financiación, Salario). Este cambio invalida FR-013 y SC-004 de la spec actual, que deben actualizarse.

## Supersedes

Esta especificación reemplaza parcialmente la spec 001 (`specs/001-sfinance-core-app/spec.md`):

- **FR-013** (spec 001) queda reemplazado por **FR-001** de esta spec.
- **SC-004** (spec 001) queda reemplazado por **SC-001** de esta spec.

También complementa la spec 005 (`specs/005-recurring-payment-day/spec.md`), cuyo FR-003 describía la intención pero cuya implementación resultante no reflejaba correctamente el caso `paymentDay == hoy`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Primer pago en el mismo día de hoy (Priority: P1)

El usuario crea una entrada recurrente mensual (Suscripción, Financiación o Salario) y el día de pago configurado coincide exactamente con el día de hoy. Espera ver la primera entrada registrada de inmediato al guardar.

**Why this priority**: Es el caso más claro y directo: el usuario crea el recurrente justo el día en que toca pagar. La entrada debe aparecer ahora, no en un mes. Establecer este caso correctamente es el núcleo de la feature.

**Independent Test**: Crear un recurrente mensual con paymentDay igual al día actual y verificar que aparece una entrada en la lista de transacciones inmediatamente tras guardar, con fecha de hoy.

**Acceptance Scenarios**:

1. **Given** que hoy es el día 16 del mes, **When** el usuario guarda una Suscripción mensual con paymentDay=16, **Then** se genera exactamente una entrada con fecha 16 del mes actual y la entrada es visible en la lista de transacciones.
2. **Given** que hoy es el día 1 del mes, **When** el usuario guarda un Salario mensual con paymentDay=1, **Then** se genera exactamente una entrada con fecha 1 del mes actual.

---

### User Story 2 — Primer pago en un día futuro del mes en curso (Priority: P1)

El usuario crea una entrada recurrente mensual y el día de pago configurado aún no ha llegado en el mes actual. No debe generarse ninguna entrada al guardar; la primera entrada aparecerá cuando ese día llegue.

**Why this priority**: Igual de crítico que el caso anterior: generar una entrada antes de que llegue su fecha sería un dato incorrecto que distorsionaría los totales y el balance del mes.

**Independent Test**: Crear un recurrente mensual con paymentDay posterior al día actual del mes y verificar que no hay entrada nueva en la lista de transacciones al guardar, y que sí aparece cuando la app se abre en esa fecha futura.

**Acceptance Scenarios**:

1. **Given** que hoy es el día 16, **When** el usuario guarda una Financiación mensual con paymentDay=20, **Then** no se genera ninguna entrada al guardar; la primera entrada se programa para el día 20 del mes actual.
2. **Given** que la app se lanza el día 20 del mismo mes, **Then** la entrada para ese recurrente aparece en la lista con fecha 20 del mes actual.
3. **Given** que hoy es el día 28 de febrero, **When** el usuario guarda un recurrente mensual con paymentDay=31, **Then** la primera entrada se programa para el último día de febrero (28 o 29 según el año), respetando la regla de "aún no ha pasado".

---

### User Story 3 — Primer pago diferido al mes siguiente (Priority: P1)

El usuario crea una entrada recurrente mensual y el día de pago configurado ya pasó en el mes actual. La primera entrada debe diferirse al mismo día del mes siguiente.

**Why this priority**: Sin este diferimiento, el usuario ve una entrada "atrasada" con fecha pasada nada más guardar, lo cual es confuso y financieramente incorrecto para su registro personal.

**Independent Test**: Crear un recurrente mensual con paymentDay anterior al día actual del mes y verificar que no se genera ninguna entrada al guardar; la primera entrada aparece cuando la app se abre en ese día del mes siguiente.

**Acceptance Scenarios**:

1. **Given** que hoy es el día 16, **When** el usuario guarda una Suscripción mensual con paymentDay=10, **Then** no se genera ninguna entrada al guardar; la primera entrada se programa para el día 10 del mes siguiente.
2. **Given** que la app se lanza el día 10 del mes siguiente, **Then** la entrada para ese recurrente aparece en la lista con fecha 10 del mes siguiente.
3. **Given** que hoy es el día 16, **When** el usuario guarda una Financiación mensual con paymentDay=15, **Then** la primera entrada se difiere al día 15 del mes siguiente (paymentDay=15 ya pasó en el mes actual).

---

### Edge Cases

- ¿Qué ocurre si paymentDay=1 y hoy es el día 1? → Se genera la entrada hoy (paymentDay == hoy).
- ¿Qué ocurre si paymentDay=31 y el mes siguiente solo tiene 28 días? → La primera entrada se genera el último día del mes siguiente (28 o 29), consistente con el comportamiento definido en spec 005 FR-004.
- ¿Qué ocurre si el usuario guarda el recurrente en el último día del mes (p.ej. día 31) con paymentDay=31? → Se genera la entrada hoy (paymentDay == hoy).
- ¿Afecta este cambio a entradas recurrentes anuales? → No. Solo aplica a recurrentes mensuales (Suscripción, Financiación, Salario). Las anuales mantienen el comportamiento de spec 005.
- ¿Qué ocurre con entradas recurrentes mensuales ya guardadas antes de esta feature? → No se regeneran ni se recalculan; el nuevo comportamiento solo aplica a entradas creadas a partir de esta feature.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Al guardar un recurrente mensual (Suscripción, Financiación o Salario), el sistema DEBE calcular la fecha de la primera ocurrencia comparando `paymentDay` con el día actual del mes: si `paymentDay` es mayor o igual al día actual, la primera ocurrencia se fija al `paymentDay` del mes en curso; si `paymentDay` es menor que el día actual, la primera ocurrencia se fija al `paymentDay` del mes siguiente. **Este requisito reemplaza FR-013 de la spec 001.**
- **FR-002**: El sistema DEBE generar la primera entrada de transacción en el momento del guardado únicamente si la primera ocurrencia calculada según FR-001 corresponde a la fecha de hoy. Si la primera ocurrencia cae en el futuro, la entrada se generará cuando la app se lance en esa fecha o posterior a ella, siguiendo el mecanismo de generación existente (FR-014 de spec 001).
- **FR-003**: En ningún caso el sistema DEBE generar una entrada con fecha anterior a la fecha de hoy al guardar un nuevo recurrente mensual.
- **FR-004**: Para el cálculo del mes siguiente según FR-001, si `paymentDay` excede el número de días del mes siguiente, el sistema DEBE usar el último día de ese mes (consistente con spec 005 FR-004).
- **FR-005**: Este comportamiento DEBE aplicarse por igual a los tres tipos de recurrentes mensuales: Suscripción, Financiación y Salario.

### Key Entities

- **Recurrente mensual**: Entrada de tipo Suscripción, Financiación o Salario con frecuencia mensual. Almacena `paymentDay` (1–31) definido en la creación. El cálculo de la primera ocurrencia usa `paymentDay` comparado con el día actual.
- **Primera ocurrencia**: La fecha en que se genera la primera transacción del recurrente. Se calcula en el momento del guardado según la regla `paymentDay` vs. día actual, y puede caer hoy, en el futuro del mes en curso, o en el mes siguiente.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100 % de los recurrentes mensuales nuevos generan su primera entrada exactamente en la fecha calculada según la regla (`paymentDay` ≥ hoy → mes actual; `paymentDay` < hoy → mes siguiente), sin entradas prematuras ni retrasadas. **Este criterio reemplaza SC-004 de la spec 001.**
- **SC-002**: El 100 % de los recurrentes mensuales guardados con `paymentDay` < día actual no muestran ninguna entrada nueva en la lista de transacciones en el momento del guardado.
- **SC-003**: El 100 % de los recurrentes mensuales guardados con `paymentDay` == día actual muestran exactamente una entrada nueva con fecha de hoy en la lista de transacciones en el momento del guardado.
- **SC-004**: El cambio no introduce regresiones: los recurrentes anuales y el comportamiento de ocurrencias subsiguientes de los recurrentes mensuales continúan funcionando sin alteraciones.

## Assumptions

- El "día actual" se determina usando la fecha local del dispositivo en el momento del guardado; no hay consideraciones de zona horaria.
- El cambio aplica únicamente a recurrentes mensuales nuevos creados a partir de esta feature; las entradas ya existentes no se ven afectadas.
- Las frecuencias no mensuales (semanal, quincenal, anual) quedan fuera del alcance de esta feature.
- El mecanismo de generación de ocurrencias subsiguientes (en cada lanzamiento de la app) no cambia; solo se modifica el cálculo de la fecha de la primera ocurrencia.
- No se requiere ningún cambio en la interfaz de usuario; el cambio es exclusivamente de lógica de negocio.
