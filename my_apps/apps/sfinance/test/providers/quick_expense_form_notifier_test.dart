import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/providers/database_provider.dart';
import 'package:sfinance/providers/dao_providers.dart';
import 'package:sfinance/providers/quick_expenses_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

late Directory _imagesTmpDir;

ProviderContainer makeContainer() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  _imagesTmpDir = Directory.systemTemp.createTempSync('qe_notifier_test_');
  final imgService = ImageStorageService(rootDirectoryOverride: _imagesTmpDir);

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      imageStorageServiceProvider.overrideWithValue(imgService),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
    if (_imagesTmpDir.existsSync()) {
      _imagesTmpDir.deleteSync(recursive: true);
    }
  });
  return container;
}

File _makeImageFile(String name) {
  final f = File('${_imagesTmpDir.path}/$name');
  f.writeAsStringSync('fake image');
  return f;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuickExpenseEditFormNotifier', () {
    // --- canSave ---

    group('canSave', () {
      test('is false when all fields are empty', () {
        final c = makeContainer();
        final state = c.read(quickExpenseEditFormProvider(null));
        expect(state.canSave, isFalse);
      });

      test('is false when name is empty', () {
        final c = makeContainer();
        final n = c.read(quickExpenseEditFormProvider(null).notifier);
        n.setAmount('1,50');
        n.setCategory(ExpenseCategory.producto);
        expect(c.read(quickExpenseEditFormProvider(null)).canSave, isFalse);
      });

      test('is false when amount is zero', () {
        final c = makeContainer();
        final n = c.read(quickExpenseEditFormProvider(null).notifier);
        n.setName('Café');
        n.setAmount('0');
        n.setCategory(ExpenseCategory.producto);
        expect(c.read(quickExpenseEditFormProvider(null)).canSave, isFalse);
      });

      test('is false when category is null', () {
        final c = makeContainer();
        final n = c.read(quickExpenseEditFormProvider(null).notifier);
        n.setName('Café');
        n.setAmount('1,50');
        expect(c.read(quickExpenseEditFormProvider(null)).canSave, isFalse);
      });

      test('is true when all valid', () {
        final c = makeContainer();
        final n = c.read(quickExpenseEditFormProvider(null).notifier);
        n.setName('Café');
        n.setAmount('1,50');
        n.setCategory(ExpenseCategory.producto);
        expect(c.read(quickExpenseEditFormProvider(null)).canSave, isTrue);
      });
    });

    // --- setPickedImage ---

    test('setPickedImage updates state without touching filesystem', () {
      final c = makeContainer();
      final n = c.read(quickExpenseEditFormProvider(null).notifier);
      n.setPickedImage('/fake/path.jpg');
      final state = c.read(quickExpenseEditFormProvider(null));
      expect(state.pickedImagePath, '/fake/path.jpg');
      expect(state.removeExistingImage, isFalse);
    });

    // --- removeImage ---

    test('removeImage sets flag without touching filesystem', () {
      final c = makeContainer();
      final n = c.read(quickExpenseEditFormProvider(null).notifier);
      n.setPickedImage('/fake/path.jpg');
      n.removeImage();
      final state = c.read(quickExpenseEditFormProvider(null));
      expect(state.removeExistingImage, isTrue);
      expect(state.pickedImagePath, isNull);
    });

    // --- save() create mode happy path ---

    test('save() create-mode without image inserts row with imagePath=null',
        () async {
      final c = makeContainer();
      final n = c.read(quickExpenseEditFormProvider(null).notifier);
      n.setName('Café');
      n.setAmount('1,50');
      n.setCategory(ExpenseCategory.producto);

      final error = await n.save(null);

      expect(error, isNull);
      final dao = c.read(quickExpenseDaoProvider);
      final rows = await dao.watchAll().first;
      expect(rows.length, 1);
      expect(rows.first.name, 'Café');
      expect(rows.first.amountCents, 150);
      expect(rows.first.category, 'producto');
      expect(rows.first.imagePath, isNull);
    });

    test('save() create-mode with image inserts row with canonical imagePath',
        () async {
      final c = makeContainer();
      final n = c.read(quickExpenseEditFormProvider(null).notifier);
      n.setName('Spotify');
      n.setAmount('9,99');
      n.setCategory(ExpenseCategory.suscripcion);
      final src = _makeImageFile('photo.jpg');
      n.setPickedImage(src.path);

      final error = await n.save(null);

      expect(error, isNull);
      final dao = c.read(quickExpenseDaoProvider);
      final rows = await dao.watchAll().first;
      expect(rows.length, 1);
      expect(rows.first.imagePath, isNotNull);
      expect(File(rows.first.imagePath!).existsSync(), isTrue);
    });

    // --- save() image copy failure ---

    test('save() sets errorMessage and skips DAO when image copy fails',
        () async {
      final c = makeContainer();
      // Use listen() to keep the autoDispose provider alive for the whole test.
      final states = <QuickExpenseEditFormState>[];
      final sub = c.listen(
        quickExpenseEditFormProvider(null),
        (prev, next) => states.add(next),
        fireImmediately: true,
      );
      final n = c.read(quickExpenseEditFormProvider(null).notifier);
      n.setName('Café');
      n.setAmount('1,50');
      n.setCategory(ExpenseCategory.producto);
      n.setPickedImage('/nonexistent/path.jpg'); // does not exist

      final error = await n.save(null);
      sub.close();

      expect(error, isNotNull);
      final dao = c.read(quickExpenseDaoProvider);
      final rows = await dao.watchAll().first;
      expect(rows, isEmpty);
      final state = states.last;
      expect(state.errorMessage, isNotNull);
    });

    // --- save() edit mode ---

    test('save() edit-mode updates row', () async {
      final c = makeContainer();
      // Seed a quick expense
      final dao = c.read(quickExpenseDaoProvider);
      final id = await dao.insert(const QuickExpensesCompanion(
        name: Value('Old'),
        amountCents: Value(100),
        category: Value('producto'),
      ));

      final n = c.read(quickExpenseEditFormProvider(id).notifier);
      await Future<void>.delayed(
          const Duration(milliseconds: 50)); // wait for _loadExisting
      n.setName('New');
      n.setAmount('2,00');
      n.setCategory(ExpenseCategory.servicio);

      final error = await n.save(id);

      expect(error, isNull);
      final row = await dao.findById(id);
      expect(row!.name, 'New');
      expect(row.amountCents, 200);
      expect(row.category, 'servicio');
    });

    test('save() edit-mode removing image sets imagePath to null', () async {
      final c = makeContainer();
      final src = _makeImageFile('existing.jpg');
      final imgService = c.read(imageStorageServiceProvider);
      final dao = c.read(quickExpenseDaoProvider);

      // Insert with image
      final id = await dao.insert(const QuickExpensesCompanion(
        name: Value('Café'),
        amountCents: Value(150),
        category: Value('producto'),
      ));
      final copiedPath = await imgService.copyImageForQuickExpense(
        quickExpenseId: id,
        sourcePath: src.path,
      );
      await dao.updateById(
          id, QuickExpensesCompanion(imagePath: Value(copiedPath)));

      final n = c.read(quickExpenseEditFormProvider(id).notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      n.removeImage();

      final error = await n.save(id);

      expect(error, isNull);
      final row = await dao.findById(id);
      expect(row!.imagePath, isNull);
    });

    // --- deleteThis ---

    test('deleteThis removes row from DB', () async {
      final c = makeContainer();
      final dao = c.read(quickExpenseDaoProvider);
      final id = await dao.insert(const QuickExpensesCompanion(
        name: Value('Café'),
        amountCents: Value(150),
        category: Value('producto'),
      ));

      final n = c.read(quickExpenseEditFormProvider(id).notifier);
      await n.deleteThis(id);

      final row = await dao.findById(id);
      expect(row, isNull);
    });

    test('deleteThis also deletes image file when imagePath is set', () async {
      final c = makeContainer();
      final src = _makeImageFile('to_delete.jpg');
      final imgService = c.read(imageStorageServiceProvider);
      final dao = c.read(quickExpenseDaoProvider);

      final id = await dao.insert(const QuickExpensesCompanion(
        name: Value('Café'),
        amountCents: Value(150),
        category: Value('producto'),
      ));
      final copiedPath = await imgService.copyImageForQuickExpense(
        quickExpenseId: id,
        sourcePath: src.path,
      );
      await dao.updateById(
          id, QuickExpensesCompanion(imagePath: Value(copiedPath)));

      final n = c.read(quickExpenseEditFormProvider(id).notifier);
      await n.deleteThis(id);

      // Give best-effort delete a tick to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(File(copiedPath).existsSync(), isFalse);
    });
  });
}
