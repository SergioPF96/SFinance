# Contract: `ImageStorageService`

**Location**: `packages/shared_services/lib/src/storage/image_storage_service.dart`

A thin, testable wrapper around `dart:io` `File` operations and
`path_provider`, scoped to the QuickExpense image lifecycle.

## Public API (target signatures)

```dart
class ImageStorageService {
  /// Constructor allows test injection of a custom root directory.
  /// In production `rootDirectory` is `getApplicationDocumentsDirectory()`.
  ImageStorageService({Directory? rootDirectoryOverride});

  /// Copies the file at [sourcePath] into the internal images directory
  /// using the canonical naming scheme `<id>_<timestampMs>.<ext>`.
  ///
  /// Throws [ImageCopyException] if the copy fails (disk full, permission,
  /// missing source file, unsupported extension). The destination file is
  /// not left half-written: implementation copies to a `.tmp` sibling and
  /// renames after success.
  ///
  /// Returns the absolute path of the copied file.
  Future<String> copyImageForQuickExpense({
    required int quickExpenseId,
    required String sourcePath,
  });

  /// For inserts where the id isn't known yet: copy under a temp filename,
  /// then rename to canonical once the row is inserted.
  Future<String> copyImageForNewQuickExpense({required String sourcePath});

  /// Renames a temp file to its canonical name once the row id is known.
  Future<String> assignTempFileToId(int id, String tempPath);

  /// Best-effort delete. Logs (debug-only) on failure but never throws.
  Future<void> deleteImageFile(String path);
}

class ImageCopyException implements Exception {
  ImageCopyException(this.cause);
  final Object cause;
}
```

## Behavioral contract

- **Atomicity**: `copyImageForQuickExpense` writes to `<dest>.tmp` and renames
  on success. A partial copy is never visible at the canonical path.
- **No silent fallbacks**: A copy failure throws. Spec FR-006 explicitly
  requires the save to be aborted on copy failure; the provider observes the
  exception and propagates a `SaveError.imageCopyFailed` to the UI.
- **Best-effort delete**: `deleteImageFile` swallows exceptions because a
  failed delete is a leaked file (R-7), not a user-visible bug.
- **Extension preservation**: The output extension matches the source path's
  extension (lowercased). If the source has no recognizable extension the
  service rejects it with `ImageCopyException`.
- **Directory creation**: The target directory is created on first call if
  it doesn't exist (`Directory.create(recursive: true)`).
- **Path injection in tests**: `rootDirectoryOverride` lets `image_storage_service_test.dart` use a `Directory.systemTemp.createTempSync()` directory and clean up after each test.

## Test contract (`image_storage_service_test.dart`)

Each test creates its own temp directory via
`Directory.systemTemp.createTempSync('img_test_')` and passes it as
`rootDirectoryOverride`. `tearDown` deletes the temp directory recursively.

- Happy path: copy a fixture file → returns canonical path → file exists at
  that path → original file untouched
- Source missing: throws `ImageCopyException`
- Source extension unsupported: throws `ImageCopyException`
- Copy then atomic rename: simulating a `.tmp` left from a previous crash
  does not break a subsequent successful copy (the new copy uses a different
  timestamp suffix)
- `deleteImageFile` on a missing path: completes normally, no throw
- `assignTempFileToId`: temp file is renamed to the canonical id-prefixed
  name; the old temp path no longer exists
