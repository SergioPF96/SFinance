// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'initial_capital_dao.dart';

// ignore_for_file: type=lint
mixin _$InitialCapitalDaoMixin on DatabaseAccessor<AppDatabase> {
  $InitialCapitalTableTable get initialCapitalTable =>
      attachedDatabase.initialCapitalTable;
  InitialCapitalDaoManager get managers => InitialCapitalDaoManager(this);
}

class InitialCapitalDaoManager {
  final _$InitialCapitalDaoMixin _db;
  InitialCapitalDaoManager(this._db);
  $$InitialCapitalTableTableTableManager get initialCapitalTable =>
      $$InitialCapitalTableTableTableManager(
          _db.attachedDatabase, _db.initialCapitalTable);
}
