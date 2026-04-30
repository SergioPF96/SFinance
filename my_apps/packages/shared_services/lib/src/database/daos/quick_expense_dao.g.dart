// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_expense_dao.dart';

// ignore_for_file: type=lint
mixin _$QuickExpenseDaoMixin on DatabaseAccessor<AppDatabase> {
  $QuickExpensesTable get quickExpenses => attachedDatabase.quickExpenses;
  QuickExpenseDaoManager get managers => QuickExpenseDaoManager(this);
}

class QuickExpenseDaoManager {
  final _$QuickExpenseDaoMixin _db;
  QuickExpenseDaoManager(this._db);
  $$QuickExpensesTableTableManager get quickExpenses =>
      $$QuickExpensesTableTableManager(_db.attachedDatabase, _db.quickExpenses);
}
