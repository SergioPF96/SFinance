# Feature Specification: Selección de día de cobro/pago en entradas recurrentes

**Feature Branch**: `005-recurring-payment-day`  
**Created**: 2026-04-13  
**Status**: Draft  
**Input**: Permitir al usuario seleccionar el día de cobro/pago al crear una entrada recurrente mensual o anual. Para recurrentes mensuales: el usuario elige un día del mes (1-31); si ese día ya pasó en el mes actual al guardar, la primera entrada se genera el mes siguiente. Para recurrentes anuales: el usuario elige un día dentro del mes definido por la Fecha de fin. El día seleccionado se muestra en el badge/detalle de la entrada recurrente en la lista de Entradas.

## Clarifications

### Session 2026-04-13

- Q: ¿Qué función cumple "Fecha de fin" en una entrada recurrente anual? → A: Doble rol — define el mes de cobro anual Y marca cuándo termina la recurrencia (la recurrencia no genera ocurrencias más allá de esa fecha).
- Q: ¿Puede el usuario modificar el día de cobro/pago de una entrada recurrente existente? → A: No; el día queda fijo en el momento de creación y no es editable posteriormente.
- Q: ¿Las entradas recurrentes mensuales también tienen Fecha de fin que limita cuándo dejan de generarse ocurrencias? → A: Sí; no se generan ocurrencias en fechas posteriores a la Fecha de fin mensual.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Seleccionar día de cobro en recurrente mensual (Priority: P1)

El usuario crea una entrada recurrente mensual (gasto o ingreso que se repite cada mes, como una suscripción o nómina) y quiere que el cobro/pago ocurra siempre el mismo día del mes. Al guardar, si ese día ya pasó en el mes actual, la primera entrada se genera en el mes siguiente.

**Why this priority**: Es el caso más frecuente de recurrente (mensual). Sin poder fijar el día exacto, las entradas generadas no reflejan la realidad del calendario de pagos del usuario.

**Independent Test**: Se puede probar creando una entrada mensual con un día específico y verificando que la primera entrada generada cae en la fecha correcta, entregando un registro de pago preciso.

**Acceptance Scenarios**:

1. **Given** que el usuario está creando una entrada recurrente de frecuencia mensual, **When** selecciona el día 15, **Then** el campo de día queda fijado a 15 y es visible en el formulario.
2. **Given** que hoy es 13 de abril y el usuario guarda una recurrente mensual con día 10 (ya pasó en abril), **When** se guarda la entrada, **Then** la primera ocurrencia se programa para el 10 de mayo.
3. **Given** que hoy es 13 de abril y el usuario guarda una recurrente mensual con día 20 (aún no ha llegado en abril), **When** se guarda la entrada, **Then** la primera ocurrencia se programa para el 20 de abril.
4. **Given** que el usuario selecciona el día 31 para una recurrente mensual, **When** se genera una ocurrencia en un mes con menos de 31 días (p.ej. febrero), **Then** la ocurrencia se genera el último día de ese mes.

---

### User Story 2 — Seleccionar día de cobro en recurrente anual (Priority: P2)

El usuario crea una entrada recurrente anual (p.ej. seguro, membresía anual) y quiere fijar el día exacto dentro del mes en que ocurre el pago. El mes ya está determinado por la Fecha de fin de la entrada.

**Why this priority**: Sin el día exacto, la entrada anual no se puede registrar con precisión. Depende del flujo mensual (P1) en diseño, pero es independiente en lógica de generación.

**Independent Test**: Se puede probar creando una entrada anual con una Fecha de fin en un mes concreto, seleccionando un día, y verificando que la ocurrencia cae en la fecha correcta de ese mes.

**Acceptance Scenarios**:

1. **Given** que el usuario está creando una entrada recurrente anual con Fecha de fin en junio, **When** selecciona el día 15, **Then** la ocurrencia anual se programa para el 15 de junio de cada año de recurrencia.
2. **Given** que el usuario selecciona el día 30 para una recurrente anual cuyo mes es febrero, **Then** la ocurrencia se genera el último día de febrero (28 o 29 según el año).
3. **Given** que el usuario no selecciona ningún día explícitamente, **When** guarda la entrada, **Then** el sistema usa el día 1 del mes como valor por defecto.

---

### User Story 3 — Visualizar el día en el badge/detalle de la lista de Entradas (Priority: P3)

El usuario ve la lista de Entradas y puede identificar rápidamente en qué día del mes/año se cobra o paga cada entrada recurrente, directamente desde el badge o el panel de detalle.

**Why this priority**: Es valor informativo complementario; no bloquea la creación ni la generación correcta de entradas. Se puede implementar de forma independiente sobre los datos ya almacenados.

**Independent Test**: Con entradas recurrentes ya creadas con día definido, se puede verificar que el badge/detalle muestra la información correcta sin necesitar modificar ni guardar nada.

**Acceptance Scenarios**:

1. **Given** una entrada recurrente mensual con día 15 en la lista de Entradas, **When** el usuario la visualiza, **Then** el badge o detalle muestra "Día 15 de cada mes".
2. **Given** una entrada recurrente anual con día 10 de junio en la lista de Entradas, **When** el usuario la visualiza, **Then** el badge o detalle muestra "10 de junio" (o equivalente legible).
3. **Given** una entrada recurrente sin día explícito (datos anteriores a esta feature), **When** se visualiza, **Then** el badge no muestra información de día o muestra "Día 1" como valor por defecto.

---

### Edge Cases

- ¿Qué ocurre si el usuario selecciona el día 29, 30 o 31 para una recurrente mensual y algunos meses no tienen ese día? → La ocurrencia se genera el último día de ese mes.
- ¿Qué ocurre si el día seleccionado es el mismo día de hoy al guardar? → El día aún no ha "pasado"; la primera ocurrencia se genera en el mes actual.
- ¿Qué ocurre con entradas recurrentes ya existentes antes de esta feature (sin día definido)? → Se les asigna el día 1 como valor por defecto; sus ocurrencias ya generadas no se modifican.
- ¿Qué ocurre si la Fecha de fin de una recurrente mensual cae antes del día seleccionado en el mes de fin? → No se genera ninguna ocurrencia en ese mes; la última ocurrencia es la del mes anterior.
- ¿Qué ocurre si el usuario cambia la Fecha de fin de una recurrente anual a un mes diferente tras haber seleccionado un día (durante la creación)? → El selector de día se actualiza dinámicamente para reflejar el nuevo mes; el valor se ajusta al último día válido si excede la longitud del mes (FR-009).
- ¿Puede el usuario cambiar el día de cobro tras guardar la entrada? → No; el día es inmutable una vez creada la entrada (FR-006). Para cambiar el día sería necesario eliminar y recrear la entrada recurrente.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Al crear una entrada recurrente mensual, el formulario DEBE mostrar un selector de día del mes con rango 1–31.
- **FR-002**: Al crear una entrada recurrente anual, el formulario DEBE mostrar un selector de día del mes limitado al mes definido por la Fecha de fin.
- **FR-003**: El sistema DEBE determinar la primera ocurrencia de una recurrente mensual comparando el día seleccionado con la fecha actual: si el día ya pasó en el mes actual, la primera ocurrencia se programa en el mismo día del mes siguiente; si no ha pasado, se programa en el mes actual.
- **FR-004**: El sistema DEBE generar ocurrencias de recurrentes mensuales usando el último día del mes en meses que no alcancen el día seleccionado (p.ej. día 31 en un mes de 30 días).
- **FR-005**: El sistema DEBE generar la ocurrencia anual en el día seleccionado dentro del mes de la Fecha de fin; si el día excede los días del mes (p.ej. día 30 en febrero), usa el último día del mes. La Fecha de fin también actúa como límite de recurrencia: no se generan ocurrencias en años posteriores al año de la Fecha de fin.
- **FR-006**: El sistema DEBE persistir el día de cobro/pago como parte de los datos de la entrada recurrente. Este valor es inmutable: una vez guardada la entrada, el día de cobro no puede modificarse.
- **FR-010**: El formulario de edición de una entrada recurrente existente NO DEBE exponer el selector de día de cobro/pago; el campo debe mostrarse como solo lectura o no mostrarse.
- **FR-007**: Si no se selecciona un día explícito, el sistema DEBE usar el día 1 como valor por defecto.
- **FR-011**: Para recurrentes mensuales, el sistema NO DEBE generar ocurrencias en fechas posteriores a la Fecha de fin de la entrada.
- **FR-008**: La lista de Entradas DEBE mostrar el día de cobro/pago seleccionado en el badge o panel de detalle de cada entrada recurrente mensual o anual.
- **FR-009**: El selector de día para recurrentes anuales DEBE actualizarse dinámicamente si el usuario cambia la Fecha de fin a un mes con diferente número de días, ajustando el valor seleccionado al último día válido si es necesario.

### Key Entities

- **Entrada recurrente**: Registro de gasto o ingreso que se repite con una frecuencia definida (mensual o anual). Ahora incluye un atributo de día de cobro/pago (1–31 para mensual; 1–N donde N es el número de días del mes de fin para anual). Para entradas anuales, la Fecha de fin cumple doble rol: determina el mes de cobro de cada ocurrencia y marca el límite temporal de la recurrencia.
- **Ocurrencia**: Instancia concreta de una entrada recurrente en una fecha específica. Su fecha de generación se calcula a partir del día de cobro/pago almacenado en la entrada recurrente.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El usuario puede fijar el día exacto de cobro/pago de una recurrente mensual o anual en menos de 10 segundos adicionales respecto al flujo actual de creación.
- **SC-002**: El 100 % de las ocurrencias generadas para una recurrente mensual caen en el día del mes seleccionado (o el último día del mes cuando el seleccionado excede la longitud del mes).
- **SC-003**: El 100 % de las ocurrencias generadas para una recurrente anual caen en el día y mes correctos según la configuración.
- **SC-004**: La primera ocurrencia de cualquier recurrente mensual nueva respeta la regla de "día ya pasado → mes siguiente" sin intervención manual del usuario.
- **SC-005**: El día de cobro/pago es visible en la lista de Entradas para todas las entradas recurrentes mensuales y anuales sin necesidad de abrir un detalle adicional.

## Assumptions

- Solo las frecuencias mensual y anual tienen selector de día. Las frecuencias semanal, quincenal u otras (si existen) quedan fuera del alcance de esta feature.
- Las entradas recurrentes mensuales también tienen Fecha de fin; no se generan ocurrencias tras esa fecha.
- Las entradas recurrentes ya existentes sin día definido reciben el día 1 como valor retroactivo por defecto; sus ocurrencias pasadas ya generadas no se recalculan.
- La "Fecha de fin" de una recurrente anual cumple doble rol: es la referencia del mes de cobro/pago anual Y es el límite temporal de la recurrencia. No se generan ocurrencias en años posteriores al año de la Fecha de fin.
- El usuario trabaja en un único huso horario (local del dispositivo); no hay consideraciones de zona horaria.
- La app no envía recordatorios ni notificaciones; mostrar el día en la UI es suficiente para informar al usuario.
