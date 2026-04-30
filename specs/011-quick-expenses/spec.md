# Feature Specification: Quick Expenses

**Feature Branch**: `011-quick-expenses`  
**Created**: 2026-04-29  
**Status**: Draft  
**Input**: User description: "Build a 'Quick Expenses' feature for SFinance. Allows the user to save frequently used expense entries as reusable visual shortcuts that auto-fill the '+Gasto' modal form."

## Clarifications

### Session 2026-04-29

- Q: What is the minimum condition to enable the "Guardar como gasto común" button — name only, both name and amount, or either? → A: Both name and amount are required, and the category must be Producto or Servicio. For all other categories the button is entirely absent. When the button is present but name or amount is empty, clicking it shows inline validation errors below the respective fields; the dialog does not open.
- Q: Where does the "Frecuentes" tab appear in the Entradas view tab bar? → A: Last — order is Transacciones → Recurrentes → Frecuentes.
- Q: If the image copy fails during save, should the quick expense be saved without the image, or should the save be aborted? → A: Abort the save, show an error message, and offer the user the option to retry.
- Q: Can the user remove a quick expense's image without replacing it? → A: Yes — the edit dialog shows an "Eliminar imagen" option when an image is set; confirming removes it and reverts the card to the generic icon.
- Q: What form does the delete confirmation take when removing a quick expense? → A: Modal confirmation dialog with "Eliminar" and "Cancelar" buttons before the delete is committed.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Apply a Quick Expense shortcut (Priority: P1)

The user opens the "+Gasto" modal to record an expense. At the top they see a row of compact cards — one per saved quick expense. They tap the card for their usual "Café" entry and the form instantly fills in with the name, amount, and category. They confirm without changing anything, and the expense is saved.

**Why this priority**: This is the core value proposition. Every subsequent feature (saving, managing) is worthless unless applying a shortcut saves time and reduces friction.

**Independent Test**: Can be fully tested by pre-seeding one quick expense in the data store, opening the expense form, tapping the card, and verifying the form fields match the stored values — delivering a complete, demonstrable speed-saving interaction.

**Acceptance Scenarios**:

1. **Given** at least one quick expense exists, **When** the user opens the "+Gasto" modal, **Then** a scrollable horizontal row of cards is visible at the top of the form, one per quick expense.
2. **Given** the card row is visible, **When** the user taps a card, **Then** the name, amount, and category fields are immediately filled with that quick expense's stored values.
3. **Given** the form has been pre-filled from a card, **When** the user edits any field, **Then** the edited value is used (not the stored shortcut value) when the expense is saved.
4. **Given** no quick expenses exist, **When** the user opens the "+Gasto" modal, **Then** no card row appears and the form looks identical to its current state.
5. **Given** a quick expense has no image set, **When** its card is displayed, **Then** a generic icon is shown in place of an image.

---

### User Story 2 - Save current expense form as a quick expense (Priority: P2)

After filling in the "+Gasto" form with a name and amount (e.g., "Café 1,50 € – Producto"), they tap the "Guardar como gasto común" button (visible only for Producto and Servicio categories). A creation dialog opens showing only an image picker — name, amount, and category are already taken from the form. The user optionally selects an image and confirms. The new quick expense is saved and will appear as a card the next time they open the expense form.

**Why this priority**: Without a way to create quick expenses, the shortcut row would always be empty. This is the creation path that populates P1.

**Independent Test**: Can be fully tested by entering a name and amount in the expense form, tapping "Guardar como gasto común", optionally selecting an image, confirming, then reopening the form and verifying the new card appears with correct data.

**Acceptance Scenarios**:

1. **Given** the "+Gasto" modal has category Producto or Servicio selected, **When** the user views the action buttons, **Then** the "Guardar como gasto común" button is visible; for all other categories it is entirely absent.
2. **Given** the button is visible but name or amount is empty, **When** the user clicks "Guardar como gasto común", **Then** inline validation errors appear below the empty field(s) and the dialog does not open.
3. **Given** the button is visible and both name and amount are filled, **When** the user clicks "Guardar como gasto común", **Then** a creation dialog opens showing only an optional image picker; name, amount, and category are not shown in the dialog because they come from the form state.
4. **Given** the creation dialog is open, **When** the user selects an image file and clicks "Guardar", **Then** the image is copied to the app's internal storage and the quick expense is saved with a reference to the internal copy.
5. **Given** the creation dialog is open, **When** the user clicks "Guardar" without selecting an image, **Then** the quick expense is saved with no image and its card will show a generic icon.
6. **Given** the creation dialog is open, **When** the user clicks "Cancelar" or dismisses it, **Then** no quick expense is created.
7. **Given** a quick expense has just been saved, **When** the user opens the "+Gasto" modal again, **Then** the new card appears in the shortcut row.

---

### User Story 3 - Manage quick expenses from the Frecuentes tab (Priority: P3)

The user navigates to the "Frecuentes" tab in the Entradas view. They see a list of all their saved quick expenses. They tap one to open the edit dialog, update the name and amount, and save. They then delete another quick expense they no longer need. Changes are reflected immediately in the list and in the card row of the expense form.

**Why this priority**: Management is essential for long-term usability but not required for the initial value. Users can still use existing shortcuts; editing and deleting refine them over time.

**Independent Test**: Can be fully tested independently of the "+Gasto" modal by navigating to the Frecuentes tab, editing a pre-seeded quick expense, verifying the change persists, then deleting it and verifying it disappears.

**Acceptance Scenarios**:

1. **Given** the user is in the Entradas view, **When** they tap the "Frecuentes" tab, **Then** a list of all saved quick expenses is displayed, each showing name, amount, category, and image (or generic icon).
2. **Given** the Frecuentes list is visible, **When** the user taps a row, **Then** an edit dialog opens with the quick expense's current values.
3. **Given** the edit dialog is open, **When** the user changes any field (name, amount, category, or image) and confirms, **Then** the quick expense is updated and the change is reflected in the list and in the "+Gasto" card row.
4. **Given** the edit dialog is open, **When** the user taps the delete action, **Then** a modal confirmation dialog appears with "Eliminar" and "Cancelar" buttons; if the user confirms, the quick expense is permanently removed; if they cancel, the edit dialog remains open.
5. **Given** no quick expenses have been saved, **When** the user views the Frecuentes tab, **Then** an empty-state message is shown.

---

### User Story 4 - Add or replace an image on an existing quick expense (Priority: P4)

The user created a quick expense without an image. They later decide to add one. They open the edit dialog from the Frecuentes tab, tap the image field, select a photo from their filesystem, and save. The card in the "+Gasto" modal now shows the chosen image instead of the generic icon.

**Why this priority**: Images make cards more scannable and recognizable, but are optional. This story extends the management flow (P3) and is lower priority because the feature is fully usable without it.

**Independent Test**: Can be fully tested by opening the edit dialog for an image-less quick expense, selecting an image, saving, and verifying the card now shows the image in the "+Gasto" modal.

**Acceptance Scenarios**:

1. **Given** an existing quick expense has no image, **When** the user opens its edit dialog and selects an image file, **Then** the image is copied to internal storage and associated with the quick expense on save.
2. **Given** an existing quick expense already has an image, **When** the user opens its edit dialog and selects a different image file, **Then** the new image replaces the old one in internal storage after saving.
3. **Given** an existing quick expense has an image, **When** the user opens its edit dialog and taps "Eliminar imagen" and confirms, **Then** the image is removed from internal storage and the card reverts to the generic icon.
4. **Given** an image has been set, **When** the card is displayed in the "+Gasto" modal, **Then** the image is shown instead of the generic icon.

---

### Edge Cases

- What happens when the quick expense card row contains many entries? The row scrolls horizontally; cards outside the visible area are accessible by scrolling.
- What happens if the user selects an image file that is subsequently deleted or moved from its original location? The original path is irrelevant — the app uses only its internal copy.
- What happens if the user attempts to save a quick expense with name or amount missing? Clicking the "Guardar como gasto común" button shows inline validation errors below the empty field(s); the creation dialog does not open.
- What happens if the selected category is not Producto or Servicio? The "Guardar como gasto común" button is entirely absent from the widget tree.
- What happens to the stored image when a quick expense is deleted? The app removes the internal image copy to avoid orphaned files.
- What happens when the user removes an image via "Eliminar imagen"? The internal image file is deleted immediately on save and the card reverts to the generic icon.
- What happens if the image copy fails during save? The save is aborted, an error message is shown, and the user is offered a retry option.
- What happens if two quick expenses have the same name and amount? Both are saved and shown as separate cards; there is no uniqueness constraint.
- What if a quick expense name is very long? The card truncates the display — name is not shown on the card (only the image or icon), so this is irrelevant for card display.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The expense form MUST display a scrollable horizontal row of quick expense cards at the top when one or more quick expenses are saved; the row MUST be absent when none exist.
- **FR-002**: Each card in the row MUST display the quick expense's image if one has been set, or a generic icon otherwise; cards MUST NOT display edit or delete affordances. Each card MUST show the quick expense name in a tooltip on hover (desktop) and on long-press (touch).
- **FR-003**: Tapping a card MUST pre-fill the expense form's name, amount, and category fields with the quick expense's stored values without preventing the user from editing those fields before saving.
- **FR-004**: The expense form MUST include a "Guardar como gasto común" button ONLY when the selected category is Producto or Servicio; for all other categories the button MUST be entirely absent from the widget tree (not disabled, not hidden — removed). When the button is present and the user clicks it with either the name or the amount field empty, inline validation errors MUST appear below the respective fields and the creation dialog MUST NOT open.
- **FR-005**: When "Guardar como gasto común" is clicked (button present, both name and amount non-empty), it MUST open a creation dialog that shows only an optional image picker; name, amount, and category are taken from the current form state and are not shown or editable in the creation dialog. Clicking "Guardar" in the creation dialog MUST save the quick expense; clicking "Cancelar" or dismissing MUST discard it.
- **FR-006**: When the user selects an image, the system MUST copy it to the app's internal data directory and store only the internal path; the original file path MUST NOT be retained or referenced after the copy. If the copy operation fails, the save MUST be aborted, an error message MUST be shown to the user, and a retry option MUST be offered.
- **FR-007**: The Entradas view MUST include a "Frecuentes" tab as the last tab, after the existing "Transacciones" and "Recurrentes" tabs (order: Transacciones → Recurrentes → Frecuentes).
- **FR-008**: The Frecuentes tab MUST list all saved quick expenses, each showing its name, amount, category, and image (or generic icon), with visible edit and delete affordances.
- **FR-009**: Tapping a quick expense row in the Frecuentes tab MUST open an edit dialog allowing modification of all fields (name, amount, category), replacing or removing the image via "Eliminar imagen" (when an image is set), or deletion of the entire entry via a delete action that requires confirmation through a modal dialog with "Eliminar" and "Cancelar" buttons. This edit dialog is distinct from the creation dialog (which shows only the image picker): the edit dialog always shows all fields.
- **FR-010**: Deleting a quick expense that has an associated image MUST also remove the internal image copy to avoid orphaned files.
- **FR-011**: Quick expenses MUST be scoped to expense entries only; income entries are out of scope.
- **FR-012**: All quick expense data MUST be stored on-device only; no network calls of any kind are permitted.
- **FR-013**: Quick expenses MUST NOT generate expense entries automatically; they are passive shortcuts only.

### Key Entities

- **QuickExpense**: A reusable shortcut for the expense form. Attributes: unique identifier, name (required), amount (required), expense category, optional internal image path. Has no relationship to actual expense entries beyond pre-filling the form.
- **QuickExpenseImage** (logical concept, not separate entity): The image file stored in the app's internal data directory. Lifecycle is tied to the parent QuickExpense — removed when the QuickExpense is deleted or its image is replaced.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user with saved quick expenses can start a new expense entry using a shortcut in under 5 seconds from opening the expense form to tapping confirm (compared to 30+ seconds of manual entry for a known recurring expense).
- **SC-002**: Saving a new quick expense from the expense form, including optionally selecting an image, completes in under 30 seconds.
- **SC-003**: All quick expenses created, edited, and deleted during a session are accurately reflected the next time the app is launched (data persists across restarts).
- **SC-004**: The Frecuentes tab loads and displays all saved quick expenses without noticeable delay for any realistic number of shortcuts a single user would create (assumed: up to a few dozen).
- **SC-005**: The image selected for a quick expense is visually recognizable on the card — neither too small to distinguish nor cropped in a way that obscures the subject.

## Assumptions

- A quick expense requires both a name and an amount, and the expense category must be Producto or Servicio. The "Guardar como gasto común" button is absent for other categories; when present and clicked with empty name or amount, inline validation errors are shown.
- Quick expenses are displayed in the order they were created (oldest first, newest last) in both the Frecuentes tab and the horizontal card row. There is no user-controlled reordering.
- There is no upper limit on the number of quick expenses. The horizontal card row scrolls to accommodate any number.
- Image selection is limited to common image formats (JPEG, PNG, and similar raster formats typically supported by a file picker). Video and other file types are not supported.
- The app's internal data directory is a private, app-managed location not accessible to other apps. It persists as long as the app is installed.
- This feature targets the desktop (Windows) context of the app. Touch interactions mentioned in the spec ("tapping") are equivalent to mouse clicks on desktop.
- The "Frecuentes" tab's empty state shows a simple explanatory message (e.g., "No hay gastos comunes guardados"). No tutorial or onboarding flow is required.
- The edit dialog (`QuickExpenseEditDialog`) is a single component operating in two modes: create mode (id == null, invoked from the expense form — shows only the image picker) and edit mode (id != null, invoked from the Frecuentes tab — shows all fields: name, amount, category, and image).
