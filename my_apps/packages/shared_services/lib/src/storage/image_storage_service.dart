import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCopyException implements Exception {
  ImageCopyException(this.cause);
  final Object cause;

  @override
  String toString() => 'ImageCopyException: $cause';
}

/// Manages image files associated with QuickExpense records.
///
/// All images live in `quick_expense_images/` under the app's documents
/// directory. Filenames follow `<id>_<timestampMs>.<ext>` for canonical copies
/// and `tmp_<timestampMs>.<ext>` for pre-insert copies.
///
/// Pass [rootDirectoryOverride] in tests to use an isolated temp directory.
class ImageStorageService {
  ImageStorageService({Directory? rootDirectoryOverride})
      : _rootOverride = rootDirectoryOverride;

  final Directory? _rootOverride;

  static const _imagesSubdir = 'quick_expense_images';
  static const _supportedExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'gif',
  };

  Future<Directory> _imagesDir() async {
    final root = _rootOverride ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, _imagesSubdir));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  String _ext(String sourcePath) {
    final ext = p.extension(sourcePath).replaceFirst('.', '').toLowerCase();
    if (ext.isEmpty || !_supportedExtensions.contains(ext)) {
      throw ImageCopyException('Unsupported or missing extension: "$ext"');
    }
    return ext;
  }

  /// Copies [sourcePath] to a canonical `<id>_<timestampMs>.<ext>` filename.
  ///
  /// Uses an atomic copy-to-.tmp-then-rename to avoid partial files.
  /// Throws [ImageCopyException] on any I/O failure.
  Future<String> copyImageForQuickExpense({
    required int quickExpenseId,
    required String sourcePath,
  }) async {
    final ext = _ext(sourcePath);
    final dir = await _imagesDir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final destName = '${quickExpenseId}_$ts.$ext';
    final tmpPath = p.join(dir.path, '${quickExpenseId}_$ts.tmp');
    final destPath = p.join(dir.path, destName);

    try {
      await File(sourcePath).copy(tmpPath);
      await File(tmpPath).rename(destPath);
      return destPath;
    } catch (e) {
      // Best-effort cleanup of the .tmp file
      try {
        final tmp = File(tmpPath);
        if (tmp.existsSync()) tmp.deleteSync();
      } catch (_) {}
      throw ImageCopyException(e);
    }
  }

  /// Copies [sourcePath] to a temp filename for use before the row id is known.
  /// Call [assignTempFileToId] after insert to get the canonical path.
  Future<String> copyImageForNewQuickExpense({
    required String sourcePath,
  }) async {
    final ext = _ext(sourcePath);
    final dir = await _imagesDir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final tmpName = 'tmp_$ts.$ext';
    final tmpPath = p.join(dir.path, tmpName);
    final stagingPath = p.join(dir.path, 'staging_$ts.tmp');

    try {
      await File(sourcePath).copy(stagingPath);
      await File(stagingPath).rename(tmpPath);
      return tmpPath;
    } catch (e) {
      try {
        final staging = File(stagingPath);
        if (staging.existsSync()) staging.deleteSync();
      } catch (_) {}
      throw ImageCopyException(e);
    }
  }

  /// Renames [tempPath] to the canonical `<id>_<timestampMs>.<ext>` name.
  Future<String> assignTempFileToId(int id, String tempPath) async {
    final ext = p.extension(tempPath).replaceFirst('.', '').toLowerCase();
    final dir = await _imagesDir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final destPath = p.join(dir.path, '${id}_$ts.$ext');
    await File(tempPath).rename(destPath);
    return destPath;
  }

  /// Best-effort delete — logs nothing, never throws.
  Future<void> deleteImageFile(String path) async {
    try {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }
}
