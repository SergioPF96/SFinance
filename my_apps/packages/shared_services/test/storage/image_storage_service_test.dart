import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';

void main() {
  group('ImageStorageService', () {
    late Directory tmpDir;
    late ImageStorageService service;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('img_test_');
      service = ImageStorageService(rootDirectoryOverride: tmpDir);
    });

    tearDown(() {
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    // --- Helper: create a fixture source file ---
    File _makeSource(String name, {String content = 'fake image data'}) {
      final f = File('${tmpDir.path}/$name');
      f.writeAsStringSync(content);
      return f;
    }

    group('copyImageForQuickExpense', () {
      test('happy path: returns canonical path and file exists there', () async {
        final src = _makeSource('photo.jpg');
        final result = await service.copyImageForQuickExpense(
          quickExpenseId: 1,
          sourcePath: src.path,
        );

        expect(result, contains('quick_expense_images'));
        expect(result, contains('1_'));
        expect(result, endsWith('.jpg'));
        expect(File(result).existsSync(), isTrue);
      });

      test('original file is untouched after copy', () async {
        final src = _makeSource('photo.jpg', content: 'original');
        await service.copyImageForQuickExpense(
          quickExpenseId: 1,
          sourcePath: src.path,
        );

        expect(src.existsSync(), isTrue);
        expect(src.readAsStringSync(), 'original');
      });

      test('throws ImageCopyException when source is missing', () async {
        expect(
          () => service.copyImageForQuickExpense(
            quickExpenseId: 1,
            sourcePath: '${tmpDir.path}/nonexistent.jpg',
          ),
          throwsA(isA<ImageCopyException>()),
        );
      });

      test('throws ImageCopyException for unsupported extension', () async {
        final src = _makeSource('video.mp4');
        expect(
          () => service.copyImageForQuickExpense(
            quickExpenseId: 1,
            sourcePath: src.path,
          ),
          throwsA(isA<ImageCopyException>()),
        );
      });

      test('no partial .tmp file left on failure', () async {
        try {
        await service.copyImageForQuickExpense(
          quickExpenseId: 1,
          sourcePath: '${tmpDir.path}/nonexistent.jpg',
        );
      } on ImageCopyException {
        // expected
      }

        final imagesDir = Directory('${tmpDir.path}/quick_expense_images');
        final tmpFiles = imagesDir.existsSync()
            ? imagesDir
                .listSync()
                .where((f) => f.path.endsWith('.tmp'))
                .toList()
            : <FileSystemEntity>[];
        expect(tmpFiles, isEmpty);
      });
    });

    group('copyImageForNewQuickExpense', () {
      test('returns a temp path inside images directory', () async {
        final src = _makeSource('photo.png');
        final result =
            await service.copyImageForNewQuickExpense(sourcePath: src.path);

        expect(result, contains('quick_expense_images'));
        expect(result, endsWith('.png'));
        expect(File(result).existsSync(), isTrue);
      });
    });

    group('assignTempFileToId', () {
      test('renames temp file to canonical id-prefixed name', () async {
        final src = _makeSource('photo.jpg');
        final tempPath =
            await service.copyImageForNewQuickExpense(sourcePath: src.path);

        final canonical = await service.assignTempFileToId(5, tempPath);

        expect(canonical, contains('5_'));
        expect(canonical, endsWith('.jpg'));
        expect(File(canonical).existsSync(), isTrue);
        expect(File(tempPath).existsSync(), isFalse);
      });
    });

    group('deleteImageFile', () {
      test('deletes an existing file', () async {
        final src = _makeSource('photo.jpg');
        final dest = await service.copyImageForQuickExpense(
          quickExpenseId: 1,
          sourcePath: src.path,
        );

        await service.deleteImageFile(dest);

        expect(File(dest).existsSync(), isFalse);
      });

      test('completes normally on missing path (no throw)', () async {
        await expectLater(
          service.deleteImageFile('${tmpDir.path}/nonexistent.jpg'),
          completes,
        );
      });
    });
  });
}
