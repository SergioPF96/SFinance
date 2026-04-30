# Quickstart — Quick Expenses

This is the fastest path to building, running, and validating the Quick
Expenses feature locally. Treat it as a developer cheat sheet, not as
production documentation.

## 0. Prerequisites

- Flutter stable channel installed
- Melos installed at the canonical path
  (`/c/Users/Sergio/AppData/Local/Pub/Cache/bin/melos.bat`)
- On the `011-quick-expenses` branch
- Database file from a previous run can be removed before first launch to
  exercise the v3 → v4 migration cleanly:
  `del %APPDATA%\com.example.sfinance\sfinance.sqlite` (Windows)

## 1. Install the new dependency

```bash
cd my_apps/apps/sfinance
flutter pub add file_picker
```

This is the only new top-level dependency for the feature. After running it
verify `pubspec.yaml` shows `file_picker: ^8.x`.

## 2. Generate Drift code

After adding `quick_expenses.dart` and `quick_expense_dao.dart`:

```bash
cd my_apps/packages/shared_services
flutter pub run build_runner build --delete-conflicting-outputs
```

If the build fails with `errno 183` on Windows, see the workaround in
`CLAUDE.md` (delete `build/native_assets/windows/sqlite3.dll`).

## 3. Run the test suite

```bash
/c/Users/Sergio/AppData/Local/Pub/Cache/bin/melos.bat run test
```

Expected new failing tests **before** implementation (test-first per
Principle IV):

- `packages/shared_models/test/quick_expense_test.dart`
- `packages/shared_services/test/quick_expense_dao_test.dart`
- `packages/shared_services/test/image_storage_service_test.dart`
- `apps/sfinance/test/providers/quick_expense_form_notifier_test.dart`

After implementation all tests pass.

## 4. Manual smoke test (golden path)

1. Launch the app: `flutter run -d windows` from `my_apps/apps/sfinance`.
2. Open `+ Gasto` from the top-right.
3. Verify the card row at the top of the modal is **absent** (no quick
   expenses yet).
4. Type `Café`, `1,50`, select category `Producto`.
5. Click **Guardar como gasto común**. The creation dialog appears (image picker only — name/amount/category are not shown).
6. Skip the image (do not click the picker), click **Guardar**.
7. Close the modal. Re-open `+ Gasto`. Verify a single card now appears at
   the top with the generic icon.
8. Click the card. Verify name=`Café`, amount=`1,50`, category=`Producto`
   are populated.
9. Click **Guardar** to record the expense.
10. Navigate to **Entradas** → **Frecuentes** tab. Verify one row "Café —
    1,50 € — Producto" with edit and delete icons.
11. Click the row. The edit dialog appears with current values.
12. Click the image picker, select a JPG/PNG. Confirm.
13. Re-open `+ Gasto` and verify the card now shows the image instead of
    the generic icon.

## 5. Manual edge-case tests

| Case | Steps | Expected |
|------|-------|----------|
| Absent save button | Open `+ Gasto`, select category `Suscripción` (or any non-Producto/Servicio category) | The **Guardar como gasto común** button is entirely absent from the form |
| Inline validation errors | Open `+ Gasto`, select category `Producto`, leave name or amount empty, click **Guardar como gasto común** | Inline error text appears below the empty field(s); the creation dialog does not open |
| Image copy failure | Pick a file, then before clicking Confirm rename/delete it from the OS file explorer (or pick a file on a write-protected drive); click Confirm | Error banner appears in the dialog; **Reintentar** button re-attempts the copy. The DB is not written. |
| Remove image | Open the edit dialog for a quick expense that has an image; click **Eliminar imagen**; Confirm | Card on the +Gasto modal reverts to the generic icon. The internal file under `quick_expense_images/` is gone. |
| Delete confirmation | In Frecuentes tab, click delete on a row | Modal "¿Eliminar este gasto común?" appears with **Eliminar** / **Cancelar** buttons. Cancel keeps the row; Confirm removes it. |
| Empty Frecuentes tab | Delete all quick expenses | Tab shows an empty-state message. |
| Many cards (scroll) | Add 20+ quick expenses | Card row scrolls horizontally; performance stays smooth. |

## 6. Reset state between manual runs

```bash
del %APPDATA%\com.example.sfinance\sfinance.sqlite
rd /s /q %APPDATA%\com.example.sfinance\quick_expense_images
```

## 7. Migration sanity check (v3 → v4)

To verify migration without losing existing data:

1. Check out the previous branch (e.g. `010-entries-ux-fixes`), launch app,
   add a few transactions, close the app.
2. Check out `011-quick-expenses`, launch the app.
3. Verify all previous transactions still appear in Entradas → Transacciones.
4. Verify Frecuentes tab is empty (the new table starts empty per migration
   spec).

## 8. What "done" looks like

- `flutter analyze` passes with zero issues across the workspace.
- `melos run test` passes everywhere.
- All checklist items in `checklists/requirements.md` remain ticked.
- Manual smoke test (§4) and edge-case tests (§5) pass.
- Constitution Check re-evaluation in `plan.md` passes (re-run after Phase
  1 design — see plan §"Constitution Check").
