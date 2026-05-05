# Feature Specification: Vista de Templates Recurrentes

**Feature Branch**: `009-recurring-templates-view`  
**Created**: 2026-04-18  
**Status**: Draft  
**Input**: User description: "Crear una nueva pestaña "Recurrentes" en la navegación principal (junto a Resumen, Análisis y Entradas). Esta vista lista todos los templates recurrentes activos (Suscripción, Financiación, Salario) en filas compactas que muestran nombre, monto actual, próximo día de pago y fecha fin. Al pulsar una fila se abre un modal de detalle con toda la información del template y dos acciones: editar el monto y eliminar el template. Editar el monto abre un campo inline o un segundo modal; el nuevo monto aplica solo a pagos futuros, las entradas ya generadas se conservan intactas. Eliminar requiere confirmación con texto explicativo. La edición del monto no afecta a ningún otro campo del template."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver todos los compromisos recurrentes activos (Priority: P1)

El usuario quiere tener una vista centralizada de todos sus templates recurrentes activos para saber de un vistazo qué pagos tiene comprometidos, cuánto importan y cuándo llega el siguiente.

**Why this priority**: Es el núcleo de la feature. Sin esta vista, el resto de interacciones no tienen sentido. Aporta valor inmediato sin necesitar las acciones de edición o eliminación.

**Independent Test**: Abrir la pestaña "Recurrentes" con al menos un template activo y verificar que aparece en la lista con nombre, monto, próximo día de pago y fecha de fin.

**Acceptance Scenarios**:

1. **Given** que existen templates recurrentes activos de distintos tipos (Suscripción, Financiación, Salario), **When** el usuario navega a la pestaña "Recurrentes", **Then** ve una fila compacta por cada template con nombre, monto actual, fecha completa del próximo pago (ej. "15 may. 2026") y fecha de fin (o indicador de sin fecha límite).
2. **Given** que no existe ningún template recurrente activo, **When** el usuario abre la pestaña "Recurrentes", **Then** ve un estado vacío con un mensaje explicativo.
3. **Given** que un template tiene fecha de fin pasada o fue eliminado, **When** el usuario abre la pestaña, **Then** ese template no aparece en la lista.

---

### User Story 2 - Consultar el detalle completo de un template (Priority: P2)

El usuario quiere ver toda la información de un template específico (tipo, día de pago, fecha de inicio, fecha de fin, monto) en un panel de detalle sin salir de la vista.

**Why this priority**: Complementa la lista compacta con la información completa. Es necesaria para las acciones de edición y eliminación, pero también útil de forma independiente.

**Independent Test**: Pulsar sobre una fila de la lista y verificar que el modal muestra todos los campos del template correctamente.

**Acceptance Scenarios**:

1. **Given** que la lista de recurrentes está visible, **When** el usuario pulsa sobre una fila, **Then** se abre un modal con el nombre, tipo, monto actual, día de pago, fecha de inicio y fecha de fin del template.
2. **Given** que el modal está abierto, **When** el usuario pulsa fuera del modal o en un botón de cerrar, **Then** el modal se cierra y la lista permanece sin cambios.

---

### User Story 3 - Actualizar el monto de un template sin alterar el historial (Priority: P3)

El usuario quiere cambiar el importe de un template recurrente (por ejemplo, una suscripción que subió de precio) sabiendo que las entradas ya contabilizadas no se verán afectadas.

**Why this priority**: Operación de mantenimiento habitual en compromisos a largo plazo. Debe preservar la integridad del historial financiero.

**Independent Test**: Editar el monto de un template que ya tiene entradas generadas, verificar que el nuevo monto se refleja en el template y que las entradas previas conservan su importe original.

**Acceptance Scenarios**:

1. **Given** que el modal de detalle está abierto, **When** el usuario activa la edición del monto e introduce un nuevo valor positivo válido y confirma, **Then** el template muestra el nuevo monto y los pagos futuros usarán ese valor.
2. **Given** que existen entradas ya generadas para ese template, **When** el monto se actualiza, **Then** esas entradas conservan intacto su importe original.
3. **Given** que el usuario está editando el monto, **When** introduce un valor inválido (vacío, cero, negativo o no numérico), **Then** el sistema rechaza el cambio y muestra un mensaje de error aclaratorio.
4. **Given** que el usuario inicia la edición del monto, **When** cancela antes de confirmar, **Then** el monto del template no cambia.

---

### User Story 4 - Eliminar un template recurrente con confirmación (Priority: P4)

El usuario quiere cancelar un compromiso recurrente (por ejemplo, una suscripción que ya no necesita) eliminando el template para que no se generen más entradas.

**Why this priority**: Operación destructiva e irreversible; la confirmación explícita es imprescindible. Tiene menor prioridad que las historias de consulta y edición.

**Independent Test**: Pulsar "Eliminar" en el modal de un template, confirmar la acción y verificar que el template desaparece de la lista.

**Acceptance Scenarios**:

1. **Given** que el modal de detalle está abierto, **When** el usuario pulsa "Eliminar", **Then** aparece un diálogo de confirmación con un texto que explica que no se generarán más entradas futuras pero las ya existentes se conservan.
2. **Given** que el diálogo de confirmación está visible, **When** el usuario confirma la eliminación, **Then** el template desaparece de la lista y el modal se cierra.
3. **Given** que el diálogo de confirmación está visible, **When** el usuario cancela, **Then** el template permanece sin cambios y el modal sigue abierto.

---

### Edge Cases

- ¿Qué ocurre si no hay ningún template recurrente activo? → Se muestra estado vacío con mensaje explicativo.
- ¿Qué muestra la columna "Fecha fin" para templates sin fecha de fin (suscripciones abiertas)? → Se muestra un indicador neutro como "Sin fecha límite".
- ¿Qué ocurre si el usuario intenta eliminar un template mientras otra operación lo modifica? → La acción más reciente prevalece; no se muestra un error técnico al usuario.
- ¿Qué pasa si el usuario edita el monto y el nuevo valor es idéntico al actual? → Se permite confirmar sin error; no se genera ningún cambio efectivo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La aplicación DEBE mostrar una nueva pestaña llamada "Recurrentes" en la barra de navegación principal, al mismo nivel que Resumen, Análisis y Entradas.
- **FR-002**: La vista "Recurrentes" DEBE listar todos los templates recurrentes activos (cuya fecha de fin es futura o no tienen fecha de fin), ordenados por fecha de creación ascendente (el template más antiguo primero).
- **FR-003**: Cada fila de la lista DEBE mostrar de forma compacta: nombre del template, monto actual, fecha completa de la próxima ocurrencia del pago (ej. "15 may. 2026") y fecha de fin (o indicador de sin fecha límite).
- **FR-004**: La vista DEBE mostrar un estado vacío con mensaje explicativo cuando no haya templates activos.
- **FR-005**: Al pulsar una fila, DEBE abrirse un modal con toda la información del template: nombre, tipo, monto actual, día de pago, fecha de inicio y fecha de fin.
- **FR-006**: El modal DEBE incluir una acción para editar el monto del template. Al activar la edición, el monto actual se reemplaza in-place por un campo de texto con botones "Confirmar" y "Cancelar" dentro del mismo modal — sin abrir un segundo modal.
- **FR-007**: Al confirmar una edición de monto, el nuevo valor DEBE aplicarse únicamente a entradas futuras; las entradas ya generadas DEBEN conservar su importe original.
- **FR-008**: La edición de monto NO DEBE modificar ningún otro campo del template (nombre, tipo, día de pago, fechas).
- **FR-009**: El sistema DEBE rechazar montos inválidos (vacío, cero, negativo o no numérico) con un mensaje de error claro.
- **FR-010**: El modal DEBE incluir una acción para eliminar el template.
- **FR-011**: Antes de eliminar, DEBE mostrarse un diálogo de confirmación que explique que no se generarán más entradas pero las existentes se conservan.
- **FR-012**: La eliminación de un template DEBE ser permanente; el template no DEBE volver a aparecer en la lista.

### Key Entities

- **Template recurrente**: Representa un compromiso financiero periódico. Atributos clave: nombre, tipo (Suscripción / Financiación / Salario), monto vigente, día del mes en que se genera el pago, fecha de inicio, fecha de fin (opcional).
- **Entrada generada**: Registro histórico de un pago ya contabilizado asociado a un template. Es inmutable respecto a cambios de monto en el template; refleja el importe que tenía el template en el momento en que fue generada.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El usuario puede ver la lista completa de templates recurrentes activos en menos de 2 segundos desde que pulsa la pestaña "Recurrentes".
- **SC-002**: El usuario puede identificar la fecha exacta del próximo pago y el monto de cualquier template leyendo únicamente la fila de la lista, sin necesidad de abrir el detalle.
- **SC-003**: El usuario puede actualizar el monto de un template recurrente en menos de 60 segundos, desde que abre la pestaña hasta que confirma el cambio.
- **SC-004**: El usuario puede eliminar un template en menos de 30 segundos, incluyendo el paso de confirmación.
- **SC-005**: Tras editar el monto, ninguna entrada previamente generada cambia su importe — verificable comparando el historial antes y después de la edición.

## Clarifications

### Session 2026-04-18

- Q: ¿La edición de monto usa un campo inline dentro del modal de detalle o abre un segundo modal? → A: Campo inline dentro del mismo modal de detalle (Opción A).
- Q: ¿Qué muestra la columna "próximo día de pago" en la fila de la lista? → A: Fecha completa de la próxima ocurrencia (ej. "15 may. 2026").
- Q: ¿En qué orden se muestran las filas de la lista? → A: Por fecha de creación ascendente (el template más antiguo primero).

## Assumptions

- Los templates recurrentes ya existen en el sistema; esta feature no incluye la creación de nuevos templates (out of scope).
- La edición de campos distintos al monto (nombre, tipo, día de pago, fechas) está fuera del alcance de esta feature y se gestiona desde el flujo de creación/edición existente.
- "Próximo día de pago" se calcula como la próxima ocurrencia del día configurado en el template a partir de la fecha actual.
- Los templates sin fecha de fin (suscripciones abiertas, feature 007) son válidos y se incluyen en la lista con un indicador visual que lo indique.
- Un template cuya fecha de fin ya ha pasado se considera inactivo y no se muestra en la lista.
- La eliminación es permanente e inmediata; no existe papelera ni opción de deshacer.
- La app es de uso local y monousuario; no hay conflictos de concurrencia reales entre usuarios.
