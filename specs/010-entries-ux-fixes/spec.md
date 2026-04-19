# Feature Specification: Entries UX Fixes and Analysis Chart Axes

**Feature Branch**: `010-entries-ux-fixes`  
**Created**: 2026-04-19  
**Status**: Draft  
**Input**: User description: "Se tienen que hacer los siguientes cambios: 1. Las entradas no deberían poder eliminarse. 2. En los iconos de cada entrada aparece un texto de overflow que no debe aparecer. 3. En la vista de Analisis las graficas no tienen medidas, se quieren referencias en eje x e y. 4. Añadir filtro de categoría en la vista de entradas."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Entries Cannot Be Deleted (Priority: P1)

Un usuario que navega a la vista de Entradas ya no puede borrar entradas individuales. El icono de eliminar ha desaparecido de cada fila. Solo en la vista de Recurrentes sigue siendo posible eliminar plantillas.

**Why this priority**: Evita borrados accidentales de datos financieros históricos; es la corrección con mayor impacto en integridad de datos.

**Independent Test**: Navegar a la vista Entradas y verificar que no existe ningún control de borrado en ninguna fila; navegar a Recurrentes y verificar que el control de borrado sigue presente.

**Acceptance Scenarios**:

1. **Given** el usuario está en la vista Entradas, **When** observa cualquier fila de entrada, **Then** no aparece ningún botón ni icono de eliminar.
2. **Given** el usuario está en la vista Recurrentes, **When** observa cualquier plantilla recurrente, **Then** el icono/botón de eliminar sigue visible y funcional.
3. **Given** una entrada existente, **When** el usuario intenta eliminarla por cualquier vía (teclado, clic, menú contextual), **Then** no ocurre ningún borrado.

---

### User Story 2 - Eliminar Overflow en Iconos de Entrada (Priority: P1)

El texto de depuración "Bottom overflowed by 9.0 pixels" que aparecía solapado sobre el icono de categoría/tipo en cada fila de la vista Entradas deja de verse.

**Why this priority**: Es un defecto visual crítico que degrada la legibilidad de la pantalla principal de datos.

**Independent Test**: Abrir la vista Entradas con al menos una entrada visible y verificar que ningún icono muestra texto de overflow.

**Acceptance Scenarios**:

1. **Given** la vista Entradas con entradas visibles, **When** el usuario la abre, **Then** ninguna fila muestra texto de desbordamiento ni errores de layout visibles.
2. **Given** entradas con nombres largos o importes grandes, **When** se renderizan, **Then** los iconos siguen mostrándose correctamente sin overflow.

---

### User Story 3 - Ejes con Referencias en Gráficas de Análisis (Priority: P2)

Las gráficas de la vista Análisis muestran marcas y etiquetas en el eje X (tiempo) y en el eje Y (importe), de modo que el usuario puede leer valores concretos sin tener que estimar.

**Why this priority**: Sin referencias numéricas las gráficas son decorativas; añadir ejes convierte la vista en una herramienta de análisis real.

**Independent Test**: Navegar a la vista Análisis con datos de al menos dos periodos y verificar que ambos ejes tienen etiquetas legibles.

**Acceptance Scenarios**:

1. **Given** la vista Análisis con datos, **When** el usuario la abre, **Then** el eje Y muestra etiquetas de importe (con símbolo de divisa y separador de miles según locale) a intervalos regulares.
2. **Given** la vista Análisis con datos, **When** el usuario la abre, **Then** el eje X muestra etiquetas de fecha/periodo a intervalos regulares y sin solapamiento.
3. **Given** un conjunto de datos muy pequeño (una sola entrada), **When** se renderiza la gráfica, **Then** los ejes siguen mostrando al menos una etiqueta en cada eje.
4. **Given** importes muy grandes o muy pequeños, **When** se renderizan, **Then** la escala del eje Y se adapta y las etiquetas siguen siendo legibles.

---

### User Story 4 - Filtro de Categoría en Vista de Entradas (Priority: P2)

Junto al filtro de temporalidad existente, aparece un filtro de categoría que permite al usuario ver solo las entradas de tipo "Financiación", "Suscripción" o "Producto" (o todas a la vez).

**Why this priority**: Permite segmentar gastos por tipo sin necesidad de ir a la vista de Análisis, aumentando la utilidad de la vista principal de entradas.

**Independent Test**: Seleccionar la categoría "Suscripción" y verificar que solo aparecen entradas de ese tipo; volver a "Todas" y verificar que vuelven todas las entradas.

**Acceptance Scenarios**:

1. **Given** la vista Entradas, **When** el usuario la abre, **Then** aparece un control de filtro de categoría con las opciones: Todas, Financiación, Suscripción, Producto.
2. **Given** el filtro de categoría en "Todas", **When** el usuario selecciona "Suscripción", **Then** la lista se actualiza mostrando solo entradas de categoría Suscripción.
3. **Given** un filtro de categoría activo, **When** el usuario cambia también el filtro de temporalidad, **Then** ambos filtros se aplican combinados (AND).
4. **Given** ninguna entrada coincide con la combinación de filtros, **When** se aplican, **Then** la lista muestra un estado vacío descriptivo (sin errores).
5. **Given** el filtro de categoría en cualquier valor, **When** el usuario navega a otra vista y vuelve, **Then** el filtro se restablece a "Todas" (estado por defecto).

---

### Edge Cases

- ¿Qué ocurre si el filtro de categoría y el de temporalidad juntos no devuelven ninguna entrada? → Se muestra estado vacío, sin errores.
- ¿Qué pasa si una entrada no tiene categoría asignada? → Se trata como "Sin categoría" y solo aparece con el filtro "Todas".
- ¿Qué pasa si la gráfica de Análisis no tiene datos en el periodo seleccionado? → Los ejes se muestran igualmente con escala base (0).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE eliminar cualquier control de borrado (botón, icono, gesto) de la vista Entradas.
- **FR-002**: El sistema DEBE conservar intacto el control de borrado de plantillas en la vista Recurrentes.
- **FR-003**: Los iconos de tipo/categoría en cada fila de la vista Entradas DEBEN renderizarse dentro de sus límites de layout sin desbordamiento visual.
- **FR-004**: La vista Análisis DEBE mostrar etiquetas numéricas de importe en el eje Y a intervalos regulares, formateadas con símbolo de divisa y separador de miles según el locale del usuario.
- **FR-005**: La vista Análisis DEBE mostrar etiquetas de fecha o periodo en el eje X a intervalos regulares, sin solapamiento entre etiquetas.
- **FR-006**: La vista Entradas DEBE incluir un control de filtro de categoría con las opciones: Todas, Financiación, Suscripción, Producto.
- **FR-007**: Los filtros de temporalidad y de categoría en la vista Entradas DEBEN aplicarse de forma combinada (intersección).
- **FR-008**: El filtro de categoría DEBE restablecerse a "Todas" al abandonar la vista Entradas.

### Key Entities

- **Entrada**: Registro financiero individual con atributos de importe, fecha y categoría.
- **Categoría**: Clasificación de la entrada — Financiación, Suscripción o Producto.
- **Filtro de categoría**: Estado de UI que determina qué categorías son visibles en la lista de entradas.
- **Eje de gráfica**: Componente visual que muestra escala de valores (Y: importe, X: tiempo) con etiquetas legibles.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: En la vista Entradas, ninguna fila muestra botón o icono de eliminar.
- **SC-002**: En la vista Entradas, ninguna fila muestra texto de desbordamiento de layout.
- **SC-003**: En la vista Análisis, el 100 % de las gráficas con datos muestran etiquetas en ambos ejes.
- **SC-004**: Al aplicar el filtro de categoría "Suscripción", la lista muestra exclusivamente entradas de esa categoría.
- **SC-005**: La combinación de filtro de categoría + filtro de temporalidad produce resultados correctos en el 100 % de las combinaciones posibles.

## Assumptions

- Las categorías posibles son exactamente tres: Financiación, Suscripción y Producto (las mismas que ya existen en el modelo de datos).
- El filtro de categoría no persiste entre sesiones ni entre navegaciones; se restablece a "Todas" al salir de la vista.
- Los ejes de las gráficas se añaden a todas las gráficas presentes en la vista Análisis.
- El diseño visual del filtro de categoría sigue el mismo patrón de chips/botones del filtro de temporalidad existente.
- No se añaden nuevas categorías en este feature; solo se implementa el filtro sobre las existentes.
