// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RecurringTemplatesTable extends RecurringTemplates
    with TableInfo<$RecurringTemplatesTable, RecurringTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountCentsMeta =
      const VerificationMeta('amountCents');
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
      'amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _transactionTypeMeta =
      const VerificationMeta('transactionType');
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
      'transaction_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _periodicityMeta =
      const VerificationMeta('periodicity');
  @override
  late final GeneratedColumn<String> periodicity = GeneratedColumn<String>(
      'periodicity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _payFrequencyMeta =
      const VerificationMeta('payFrequency');
  @override
  late final GeneratedColumn<String> payFrequency = GeneratedColumn<String>(
      'pay_frequency', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _extraPayMonth1Meta =
      const VerificationMeta('extraPayMonth1');
  @override
  late final GeneratedColumn<int> extraPayMonth1 = GeneratedColumn<int>(
      'extra_pay_month1', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _extraPayMonth2Meta =
      const VerificationMeta('extraPayMonth2');
  @override
  late final GeneratedColumn<int> extraPayMonth2 = GeneratedColumn<int>(
      'extra_pay_month2', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _paymentDayMeta =
      const VerificationMeta('paymentDay');
  @override
  late final GeneratedColumn<int> paymentDay = GeneratedColumn<int>(
      'payment_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastGeneratedPeriodMeta =
      const VerificationMeta('lastGeneratedPeriod');
  @override
  late final GeneratedColumn<String> lastGeneratedPeriod =
      GeneratedColumn<String>('last_generated_period', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        amountCents,
        transactionType,
        category,
        periodicity,
        startDate,
        endDate,
        payFrequency,
        extraPayMonth1,
        extraPayMonth2,
        paymentDay,
        lastGeneratedPeriod,
        isDeleted,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_templates';
  @override
  VerificationContext validateIntegrity(
      Insertable<RecurringTemplateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
          _amountCentsMeta,
          amountCents.isAcceptableOrUnknown(
              data['amount_cents']!, _amountCentsMeta));
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
          _transactionTypeMeta,
          transactionType.isAcceptableOrUnknown(
              data['transaction_type']!, _transactionTypeMeta));
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('periodicity')) {
      context.handle(
          _periodicityMeta,
          periodicity.isAcceptableOrUnknown(
              data['periodicity']!, _periodicityMeta));
    } else if (isInserting) {
      context.missing(_periodicityMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('pay_frequency')) {
      context.handle(
          _payFrequencyMeta,
          payFrequency.isAcceptableOrUnknown(
              data['pay_frequency']!, _payFrequencyMeta));
    }
    if (data.containsKey('extra_pay_month1')) {
      context.handle(
          _extraPayMonth1Meta,
          extraPayMonth1.isAcceptableOrUnknown(
              data['extra_pay_month1']!, _extraPayMonth1Meta));
    }
    if (data.containsKey('extra_pay_month2')) {
      context.handle(
          _extraPayMonth2Meta,
          extraPayMonth2.isAcceptableOrUnknown(
              data['extra_pay_month2']!, _extraPayMonth2Meta));
    }
    if (data.containsKey('payment_day')) {
      context.handle(
          _paymentDayMeta,
          paymentDay.isAcceptableOrUnknown(
              data['payment_day']!, _paymentDayMeta));
    }
    if (data.containsKey('last_generated_period')) {
      context.handle(
          _lastGeneratedPeriodMeta,
          lastGeneratedPeriod.isAcceptableOrUnknown(
              data['last_generated_period']!, _lastGeneratedPeriodMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringTemplateRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amountCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_cents'])!,
      transactionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transaction_type'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      periodicity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}periodicity'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date'])!,
      payFrequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pay_frequency']),
      extraPayMonth1: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}extra_pay_month1']),
      extraPayMonth2: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}extra_pay_month2']),
      paymentDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payment_day']),
      lastGeneratedPeriod: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_generated_period']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RecurringTemplatesTable createAlias(String alias) {
    return $RecurringTemplatesTable(attachedDatabase, alias);
  }
}

class RecurringTemplateRow extends DataClass
    implements Insertable<RecurringTemplateRow> {
  final int id;
  final String name;
  final int amountCents;

  /// "income" or "expense".
  final String transactionType;

  /// "suscripcion", "financiacion" (expense) or "salario" (income).
  final String category;

  /// "mensual" or "anual".
  final String periodicity;
  final DateTime startDate;
  final DateTime endDate;

  /// "docepagas" or "catorcepagas". Null for non-salary templates.
  final String? payFrequency;

  /// 1–12. Null unless payFrequency = catorcepagas.
  final int? extraPayMonth1;

  /// 1–12. Must differ from extraPayMonth1.
  final int? extraPayMonth2;

  /// Day of month for payment/charge (1–31). Null for pre-feature templates
  /// (treated as 1 by application logic).
  final int? paymentDay;

  /// Period key of the last generated transaction. Null before first generation.
  final String? lastGeneratedPeriod;
  final bool isDeleted;
  final DateTime createdAt;
  const RecurringTemplateRow(
      {required this.id,
      required this.name,
      required this.amountCents,
      required this.transactionType,
      required this.category,
      required this.periodicity,
      required this.startDate,
      required this.endDate,
      this.payFrequency,
      this.extraPayMonth1,
      this.extraPayMonth2,
      this.paymentDay,
      this.lastGeneratedPeriod,
      required this.isDeleted,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount_cents'] = Variable<int>(amountCents);
    map['transaction_type'] = Variable<String>(transactionType);
    map['category'] = Variable<String>(category);
    map['periodicity'] = Variable<String>(periodicity);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    if (!nullToAbsent || payFrequency != null) {
      map['pay_frequency'] = Variable<String>(payFrequency);
    }
    if (!nullToAbsent || extraPayMonth1 != null) {
      map['extra_pay_month1'] = Variable<int>(extraPayMonth1);
    }
    if (!nullToAbsent || extraPayMonth2 != null) {
      map['extra_pay_month2'] = Variable<int>(extraPayMonth2);
    }
    if (!nullToAbsent || paymentDay != null) {
      map['payment_day'] = Variable<int>(paymentDay);
    }
    if (!nullToAbsent || lastGeneratedPeriod != null) {
      map['last_generated_period'] = Variable<String>(lastGeneratedPeriod);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RecurringTemplatesCompanion toCompanion(bool nullToAbsent) {
    return RecurringTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      amountCents: Value(amountCents),
      transactionType: Value(transactionType),
      category: Value(category),
      periodicity: Value(periodicity),
      startDate: Value(startDate),
      endDate: Value(endDate),
      payFrequency: payFrequency == null && nullToAbsent
          ? const Value.absent()
          : Value(payFrequency),
      extraPayMonth1: extraPayMonth1 == null && nullToAbsent
          ? const Value.absent()
          : Value(extraPayMonth1),
      extraPayMonth2: extraPayMonth2 == null && nullToAbsent
          ? const Value.absent()
          : Value(extraPayMonth2),
      paymentDay: paymentDay == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentDay),
      lastGeneratedPeriod: lastGeneratedPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(lastGeneratedPeriod),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
    );
  }

  factory RecurringTemplateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringTemplateRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      category: serializer.fromJson<String>(json['category']),
      periodicity: serializer.fromJson<String>(json['periodicity']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      payFrequency: serializer.fromJson<String?>(json['payFrequency']),
      extraPayMonth1: serializer.fromJson<int?>(json['extraPayMonth1']),
      extraPayMonth2: serializer.fromJson<int?>(json['extraPayMonth2']),
      paymentDay: serializer.fromJson<int?>(json['paymentDay']),
      lastGeneratedPeriod:
          serializer.fromJson<String?>(json['lastGeneratedPeriod']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amountCents': serializer.toJson<int>(amountCents),
      'transactionType': serializer.toJson<String>(transactionType),
      'category': serializer.toJson<String>(category),
      'periodicity': serializer.toJson<String>(periodicity),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'payFrequency': serializer.toJson<String?>(payFrequency),
      'extraPayMonth1': serializer.toJson<int?>(extraPayMonth1),
      'extraPayMonth2': serializer.toJson<int?>(extraPayMonth2),
      'paymentDay': serializer.toJson<int?>(paymentDay),
      'lastGeneratedPeriod': serializer.toJson<String?>(lastGeneratedPeriod),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RecurringTemplateRow copyWith(
          {int? id,
          String? name,
          int? amountCents,
          String? transactionType,
          String? category,
          String? periodicity,
          DateTime? startDate,
          DateTime? endDate,
          Value<String?> payFrequency = const Value.absent(),
          Value<int?> extraPayMonth1 = const Value.absent(),
          Value<int?> extraPayMonth2 = const Value.absent(),
          Value<int?> paymentDay = const Value.absent(),
          Value<String?> lastGeneratedPeriod = const Value.absent(),
          bool? isDeleted,
          DateTime? createdAt}) =>
      RecurringTemplateRow(
        id: id ?? this.id,
        name: name ?? this.name,
        amountCents: amountCents ?? this.amountCents,
        transactionType: transactionType ?? this.transactionType,
        category: category ?? this.category,
        periodicity: periodicity ?? this.periodicity,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        payFrequency:
            payFrequency.present ? payFrequency.value : this.payFrequency,
        extraPayMonth1:
            extraPayMonth1.present ? extraPayMonth1.value : this.extraPayMonth1,
        extraPayMonth2:
            extraPayMonth2.present ? extraPayMonth2.value : this.extraPayMonth2,
        paymentDay: paymentDay.present ? paymentDay.value : this.paymentDay,
        lastGeneratedPeriod: lastGeneratedPeriod.present
            ? lastGeneratedPeriod.value
            : this.lastGeneratedPeriod,
        isDeleted: isDeleted ?? this.isDeleted,
        createdAt: createdAt ?? this.createdAt,
      );
  RecurringTemplateRow copyWithCompanion(RecurringTemplatesCompanion data) {
    return RecurringTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amountCents:
          data.amountCents.present ? data.amountCents.value : this.amountCents,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      category: data.category.present ? data.category.value : this.category,
      periodicity:
          data.periodicity.present ? data.periodicity.value : this.periodicity,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      payFrequency: data.payFrequency.present
          ? data.payFrequency.value
          : this.payFrequency,
      extraPayMonth1: data.extraPayMonth1.present
          ? data.extraPayMonth1.value
          : this.extraPayMonth1,
      extraPayMonth2: data.extraPayMonth2.present
          ? data.extraPayMonth2.value
          : this.extraPayMonth2,
      paymentDay:
          data.paymentDay.present ? data.paymentDay.value : this.paymentDay,
      lastGeneratedPeriod: data.lastGeneratedPeriod.present
          ? data.lastGeneratedPeriod.value
          : this.lastGeneratedPeriod,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTemplateRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents, ')
          ..write('transactionType: $transactionType, ')
          ..write('category: $category, ')
          ..write('periodicity: $periodicity, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('payFrequency: $payFrequency, ')
          ..write('extraPayMonth1: $extraPayMonth1, ')
          ..write('extraPayMonth2: $extraPayMonth2, ')
          ..write('paymentDay: $paymentDay, ')
          ..write('lastGeneratedPeriod: $lastGeneratedPeriod, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      amountCents,
      transactionType,
      category,
      periodicity,
      startDate,
      endDate,
      payFrequency,
      extraPayMonth1,
      extraPayMonth2,
      paymentDay,
      lastGeneratedPeriod,
      isDeleted,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringTemplateRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.amountCents == this.amountCents &&
          other.transactionType == this.transactionType &&
          other.category == this.category &&
          other.periodicity == this.periodicity &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.payFrequency == this.payFrequency &&
          other.extraPayMonth1 == this.extraPayMonth1 &&
          other.extraPayMonth2 == this.extraPayMonth2 &&
          other.paymentDay == this.paymentDay &&
          other.lastGeneratedPeriod == this.lastGeneratedPeriod &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt);
}

class RecurringTemplatesCompanion
    extends UpdateCompanion<RecurringTemplateRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> amountCents;
  final Value<String> transactionType;
  final Value<String> category;
  final Value<String> periodicity;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<String?> payFrequency;
  final Value<int?> extraPayMonth1;
  final Value<int?> extraPayMonth2;
  final Value<int?> paymentDay;
  final Value<String?> lastGeneratedPeriod;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  const RecurringTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.category = const Value.absent(),
    this.periodicity = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.payFrequency = const Value.absent(),
    this.extraPayMonth1 = const Value.absent(),
    this.extraPayMonth2 = const Value.absent(),
    this.paymentDay = const Value.absent(),
    this.lastGeneratedPeriod = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RecurringTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int amountCents,
    required String transactionType,
    required String category,
    required String periodicity,
    required DateTime startDate,
    required DateTime endDate,
    this.payFrequency = const Value.absent(),
    this.extraPayMonth1 = const Value.absent(),
    this.extraPayMonth2 = const Value.absent(),
    this.paymentDay = const Value.absent(),
    this.lastGeneratedPeriod = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        amountCents = Value(amountCents),
        transactionType = Value(transactionType),
        category = Value(category),
        periodicity = Value(periodicity),
        startDate = Value(startDate),
        endDate = Value(endDate);
  static Insertable<RecurringTemplateRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? amountCents,
    Expression<String>? transactionType,
    Expression<String>? category,
    Expression<String>? periodicity,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? payFrequency,
    Expression<int>? extraPayMonth1,
    Expression<int>? extraPayMonth2,
    Expression<int>? paymentDay,
    Expression<String>? lastGeneratedPeriod,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amountCents != null) 'amount_cents': amountCents,
      if (transactionType != null) 'transaction_type': transactionType,
      if (category != null) 'category': category,
      if (periodicity != null) 'periodicity': periodicity,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (payFrequency != null) 'pay_frequency': payFrequency,
      if (extraPayMonth1 != null) 'extra_pay_month1': extraPayMonth1,
      if (extraPayMonth2 != null) 'extra_pay_month2': extraPayMonth2,
      if (paymentDay != null) 'payment_day': paymentDay,
      if (lastGeneratedPeriod != null)
        'last_generated_period': lastGeneratedPeriod,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RecurringTemplatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? amountCents,
      Value<String>? transactionType,
      Value<String>? category,
      Value<String>? periodicity,
      Value<DateTime>? startDate,
      Value<DateTime>? endDate,
      Value<String?>? payFrequency,
      Value<int?>? extraPayMonth1,
      Value<int?>? extraPayMonth2,
      Value<int?>? paymentDay,
      Value<String?>? lastGeneratedPeriod,
      Value<bool>? isDeleted,
      Value<DateTime>? createdAt}) {
    return RecurringTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amountCents: amountCents ?? this.amountCents,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      periodicity: periodicity ?? this.periodicity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      payFrequency: payFrequency ?? this.payFrequency,
      extraPayMonth1: extraPayMonth1 ?? this.extraPayMonth1,
      extraPayMonth2: extraPayMonth2 ?? this.extraPayMonth2,
      paymentDay: paymentDay ?? this.paymentDay,
      lastGeneratedPeriod: lastGeneratedPeriod ?? this.lastGeneratedPeriod,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (periodicity.present) {
      map['periodicity'] = Variable<String>(periodicity.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (payFrequency.present) {
      map['pay_frequency'] = Variable<String>(payFrequency.value);
    }
    if (extraPayMonth1.present) {
      map['extra_pay_month1'] = Variable<int>(extraPayMonth1.value);
    }
    if (extraPayMonth2.present) {
      map['extra_pay_month2'] = Variable<int>(extraPayMonth2.value);
    }
    if (paymentDay.present) {
      map['payment_day'] = Variable<int>(paymentDay.value);
    }
    if (lastGeneratedPeriod.present) {
      map['last_generated_period'] =
          Variable<String>(lastGeneratedPeriod.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents, ')
          ..write('transactionType: $transactionType, ')
          ..write('category: $category, ')
          ..write('periodicity: $periodicity, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('payFrequency: $payFrequency, ')
          ..write('extraPayMonth1: $extraPayMonth1, ')
          ..write('extraPayMonth2: $extraPayMonth2, ')
          ..write('paymentDay: $paymentDay, ')
          ..write('lastGeneratedPeriod: $lastGeneratedPeriod, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountCentsMeta =
      const VerificationMeta('amountCents');
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
      'amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transactionTypeMeta =
      const VerificationMeta('transactionType');
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
      'transaction_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
      'template_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recurring_templates (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        amountCents,
        description,
        transactionType,
        category,
        date,
        templateId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
          _amountCentsMeta,
          amountCents.isAcceptableOrUnknown(
              data['amount_cents']!, _amountCentsMeta));
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
          _transactionTypeMeta,
          transactionType.isAcceptableOrUnknown(
              data['transaction_type']!, _transactionTypeMeta));
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amountCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_cents'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      transactionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transaction_type'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}template_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final String name;
  final int amountCents;
  final String? description;

  /// "income" or "expense" — stored via EnumNameConverter.
  final String transactionType;

  /// ExpenseCategory or IncomeCategory enum name string.
  final String category;
  final DateTime date;

  /// Null for one-off transactions.
  final int? templateId;
  final DateTime createdAt;
  const TransactionRow(
      {required this.id,
      required this.name,
      required this.amountCents,
      this.description,
      required this.transactionType,
      required this.category,
      required this.date,
      this.templateId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount_cents'] = Variable<int>(amountCents);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['transaction_type'] = Variable<String>(transactionType);
    map['category'] = Variable<String>(category);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<int>(templateId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      name: Value(name),
      amountCents: Value(amountCents),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      transactionType: Value(transactionType),
      category: Value(category),
      date: Value(date),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      createdAt: Value(createdAt),
    );
  }

  factory TransactionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      description: serializer.fromJson<String?>(json['description']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      category: serializer.fromJson<String>(json['category']),
      date: serializer.fromJson<DateTime>(json['date']),
      templateId: serializer.fromJson<int?>(json['templateId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amountCents': serializer.toJson<int>(amountCents),
      'description': serializer.toJson<String?>(description),
      'transactionType': serializer.toJson<String>(transactionType),
      'category': serializer.toJson<String>(category),
      'date': serializer.toJson<DateTime>(date),
      'templateId': serializer.toJson<int?>(templateId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransactionRow copyWith(
          {int? id,
          String? name,
          int? amountCents,
          Value<String?> description = const Value.absent(),
          String? transactionType,
          String? category,
          DateTime? date,
          Value<int?> templateId = const Value.absent(),
          DateTime? createdAt}) =>
      TransactionRow(
        id: id ?? this.id,
        name: name ?? this.name,
        amountCents: amountCents ?? this.amountCents,
        description: description.present ? description.value : this.description,
        transactionType: transactionType ?? this.transactionType,
        category: category ?? this.category,
        date: date ?? this.date,
        templateId: templateId.present ? templateId.value : this.templateId,
        createdAt: createdAt ?? this.createdAt,
      );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amountCents:
          data.amountCents.present ? data.amountCents.value : this.amountCents,
      description:
          data.description.present ? data.description.value : this.description,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      category: data.category.present ? data.category.value : this.category,
      date: data.date.present ? data.date.value : this.date,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents, ')
          ..write('description: $description, ')
          ..write('transactionType: $transactionType, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('templateId: $templateId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, amountCents, description,
      transactionType, category, date, templateId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.amountCents == this.amountCents &&
          other.description == this.description &&
          other.transactionType == this.transactionType &&
          other.category == this.category &&
          other.date == this.date &&
          other.templateId == this.templateId &&
          other.createdAt == this.createdAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> amountCents;
  final Value<String?> description;
  final Value<String> transactionType;
  final Value<String> category;
  final Value<DateTime> date;
  final Value<int?> templateId;
  final Value<DateTime> createdAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.description = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.category = const Value.absent(),
    this.date = const Value.absent(),
    this.templateId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int amountCents,
    this.description = const Value.absent(),
    required String transactionType,
    required String category,
    required DateTime date,
    this.templateId = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        amountCents = Value(amountCents),
        transactionType = Value(transactionType),
        category = Value(category),
        date = Value(date);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? amountCents,
    Expression<String>? description,
    Expression<String>? transactionType,
    Expression<String>? category,
    Expression<DateTime>? date,
    Expression<int>? templateId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amountCents != null) 'amount_cents': amountCents,
      if (description != null) 'description': description,
      if (transactionType != null) 'transaction_type': transactionType,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
      if (templateId != null) 'template_id': templateId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TransactionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? amountCents,
      Value<String?>? description,
      Value<String>? transactionType,
      Value<String>? category,
      Value<DateTime>? date,
      Value<int?>? templateId,
      Value<DateTime>? createdAt}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amountCents: amountCents ?? this.amountCents,
      description: description ?? this.description,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      date: date ?? this.date,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents, ')
          ..write('description: $description, ')
          ..write('transactionType: $transactionType, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('templateId: $templateId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InitialCapitalTableTable extends InitialCapitalTable
    with TableInfo<$InitialCapitalTableTable, InitialCapitalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InitialCapitalTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _amountCentsMeta =
      const VerificationMeta('amountCents');
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
      'amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [id, amountCents, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'initial_capital';
  @override
  VerificationContext validateIntegrity(Insertable<InitialCapitalRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
          _amountCentsMeta,
          amountCents.isAcceptableOrUnknown(
              data['amount_cents']!, _amountCentsMeta));
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InitialCapitalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InitialCapitalRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      amountCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_cents'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $InitialCapitalTableTable createAlias(String alias) {
    return $InitialCapitalTableTable(attachedDatabase, alias);
  }
}

class InitialCapitalRow extends DataClass
    implements Insertable<InitialCapitalRow> {
  /// Fixed to 1 — enforces single-row constraint.
  final int id;
  final int amountCents;
  final bool isActive;
  const InitialCapitalRow(
      {required this.id, required this.amountCents, required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount_cents'] = Variable<int>(amountCents);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  InitialCapitalTableCompanion toCompanion(bool nullToAbsent) {
    return InitialCapitalTableCompanion(
      id: Value(id),
      amountCents: Value(amountCents),
      isActive: Value(isActive),
    );
  }

  factory InitialCapitalRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InitialCapitalRow(
      id: serializer.fromJson<int>(json['id']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountCents': serializer.toJson<int>(amountCents),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  InitialCapitalRow copyWith({int? id, int? amountCents, bool? isActive}) =>
      InitialCapitalRow(
        id: id ?? this.id,
        amountCents: amountCents ?? this.amountCents,
        isActive: isActive ?? this.isActive,
      );
  InitialCapitalRow copyWithCompanion(InitialCapitalTableCompanion data) {
    return InitialCapitalRow(
      id: data.id.present ? data.id.value : this.id,
      amountCents:
          data.amountCents.present ? data.amountCents.value : this.amountCents,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InitialCapitalRow(')
          ..write('id: $id, ')
          ..write('amountCents: $amountCents, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, amountCents, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InitialCapitalRow &&
          other.id == this.id &&
          other.amountCents == this.amountCents &&
          other.isActive == this.isActive);
}

class InitialCapitalTableCompanion extends UpdateCompanion<InitialCapitalRow> {
  final Value<int> id;
  final Value<int> amountCents;
  final Value<bool> isActive;
  const InitialCapitalTableCompanion({
    this.id = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  InitialCapitalTableCompanion.insert({
    this.id = const Value.absent(),
    required int amountCents,
    this.isActive = const Value.absent(),
  }) : amountCents = Value(amountCents);
  static Insertable<InitialCapitalRow> custom({
    Expression<int>? id,
    Expression<int>? amountCents,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountCents != null) 'amount_cents': amountCents,
      if (isActive != null) 'is_active': isActive,
    });
  }

  InitialCapitalTableCompanion copyWith(
      {Value<int>? id, Value<int>? amountCents, Value<bool>? isActive}) {
    return InitialCapitalTableCompanion(
      id: id ?? this.id,
      amountCents: amountCents ?? this.amountCents,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InitialCapitalTableCompanion(')
          ..write('id: $id, ')
          ..write('amountCents: $amountCents, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecurringTemplatesTable recurringTemplates =
      $RecurringTemplatesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $InitialCapitalTableTable initialCapitalTable =
      $InitialCapitalTableTable(this);
  late final TransactionDao transactionDao =
      TransactionDao(this as AppDatabase);
  late final TemplateDao templateDao = TemplateDao(this as AppDatabase);
  late final InitialCapitalDao initialCapitalDao =
      InitialCapitalDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [recurringTemplates, transactions, initialCapitalTable];
}

typedef $$RecurringTemplatesTableCreateCompanionBuilder
    = RecurringTemplatesCompanion Function({
  Value<int> id,
  required String name,
  required int amountCents,
  required String transactionType,
  required String category,
  required String periodicity,
  required DateTime startDate,
  required DateTime endDate,
  Value<String?> payFrequency,
  Value<int?> extraPayMonth1,
  Value<int?> extraPayMonth2,
  Value<int?> paymentDay,
  Value<String?> lastGeneratedPeriod,
  Value<bool> isDeleted,
  Value<DateTime> createdAt,
});
typedef $$RecurringTemplatesTableUpdateCompanionBuilder
    = RecurringTemplatesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> amountCents,
  Value<String> transactionType,
  Value<String> category,
  Value<String> periodicity,
  Value<DateTime> startDate,
  Value<DateTime> endDate,
  Value<String?> payFrequency,
  Value<int?> extraPayMonth1,
  Value<int?> extraPayMonth2,
  Value<int?> paymentDay,
  Value<String?> lastGeneratedPeriod,
  Value<bool> isDeleted,
  Value<DateTime> createdAt,
});

final class $$RecurringTemplatesTableReferences extends BaseReferences<
    _$AppDatabase, $RecurringTemplatesTable, RecurringTemplateRow> {
  $$RecurringTemplatesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.recurringTemplates.id, db.transactions.templateId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RecurringTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get periodicity => $composableBuilder(
      column: $table.periodicity, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payFrequency => $composableBuilder(
      column: $table.payFrequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get extraPayMonth1 => $composableBuilder(
      column: $table.extraPayMonth1,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get extraPayMonth2 => $composableBuilder(
      column: $table.extraPayMonth2,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get paymentDay => $composableBuilder(
      column: $table.paymentDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastGeneratedPeriod => $composableBuilder(
      column: $table.lastGeneratedPeriod,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.templateId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecurringTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get periodicity => $composableBuilder(
      column: $table.periodicity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payFrequency => $composableBuilder(
      column: $table.payFrequency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get extraPayMonth1 => $composableBuilder(
      column: $table.extraPayMonth1,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get extraPayMonth2 => $composableBuilder(
      column: $table.extraPayMonth2,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paymentDay => $composableBuilder(
      column: $table.paymentDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastGeneratedPeriod => $composableBuilder(
      column: $table.lastGeneratedPeriod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RecurringTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
      column: $table.transactionType, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get periodicity => $composableBuilder(
      column: $table.periodicity, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get payFrequency => $composableBuilder(
      column: $table.payFrequency, builder: (column) => column);

  GeneratedColumn<int> get extraPayMonth1 => $composableBuilder(
      column: $table.extraPayMonth1, builder: (column) => column);

  GeneratedColumn<int> get extraPayMonth2 => $composableBuilder(
      column: $table.extraPayMonth2, builder: (column) => column);

  GeneratedColumn<int> get paymentDay => $composableBuilder(
      column: $table.paymentDay, builder: (column) => column);

  GeneratedColumn<String> get lastGeneratedPeriod => $composableBuilder(
      column: $table.lastGeneratedPeriod, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.templateId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecurringTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurringTemplatesTable,
    RecurringTemplateRow,
    $$RecurringTemplatesTableFilterComposer,
    $$RecurringTemplatesTableOrderingComposer,
    $$RecurringTemplatesTableAnnotationComposer,
    $$RecurringTemplatesTableCreateCompanionBuilder,
    $$RecurringTemplatesTableUpdateCompanionBuilder,
    (RecurringTemplateRow, $$RecurringTemplatesTableReferences),
    RecurringTemplateRow,
    PrefetchHooks Function({bool transactionsRefs})> {
  $$RecurringTemplatesTableTableManager(
      _$AppDatabase db, $RecurringTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringTemplatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> amountCents = const Value.absent(),
            Value<String> transactionType = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> periodicity = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime> endDate = const Value.absent(),
            Value<String?> payFrequency = const Value.absent(),
            Value<int?> extraPayMonth1 = const Value.absent(),
            Value<int?> extraPayMonth2 = const Value.absent(),
            Value<int?> paymentDay = const Value.absent(),
            Value<String?> lastGeneratedPeriod = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RecurringTemplatesCompanion(
            id: id,
            name: name,
            amountCents: amountCents,
            transactionType: transactionType,
            category: category,
            periodicity: periodicity,
            startDate: startDate,
            endDate: endDate,
            payFrequency: payFrequency,
            extraPayMonth1: extraPayMonth1,
            extraPayMonth2: extraPayMonth2,
            paymentDay: paymentDay,
            lastGeneratedPeriod: lastGeneratedPeriod,
            isDeleted: isDeleted,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int amountCents,
            required String transactionType,
            required String category,
            required String periodicity,
            required DateTime startDate,
            required DateTime endDate,
            Value<String?> payFrequency = const Value.absent(),
            Value<int?> extraPayMonth1 = const Value.absent(),
            Value<int?> extraPayMonth2 = const Value.absent(),
            Value<int?> paymentDay = const Value.absent(),
            Value<String?> lastGeneratedPeriod = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RecurringTemplatesCompanion.insert(
            id: id,
            name: name,
            amountCents: amountCents,
            transactionType: transactionType,
            category: category,
            periodicity: periodicity,
            startDate: startDate,
            endDate: endDate,
            payFrequency: payFrequency,
            extraPayMonth1: extraPayMonth1,
            extraPayMonth2: extraPayMonth2,
            paymentDay: paymentDay,
            lastGeneratedPeriod: lastGeneratedPeriod,
            isDeleted: isDeleted,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RecurringTemplatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<RecurringTemplateRow,
                            $RecurringTemplatesTable, TransactionRow>(
                        currentTable: table,
                        referencedTable: $$RecurringTemplatesTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecurringTemplatesTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.templateId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RecurringTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecurringTemplatesTable,
    RecurringTemplateRow,
    $$RecurringTemplatesTableFilterComposer,
    $$RecurringTemplatesTableOrderingComposer,
    $$RecurringTemplatesTableAnnotationComposer,
    $$RecurringTemplatesTableCreateCompanionBuilder,
    $$RecurringTemplatesTableUpdateCompanionBuilder,
    (RecurringTemplateRow, $$RecurringTemplatesTableReferences),
    RecurringTemplateRow,
    PrefetchHooks Function({bool transactionsRefs})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  required String name,
  required int amountCents,
  Value<String?> description,
  required String transactionType,
  required String category,
  required DateTime date,
  Value<int?> templateId,
  Value<DateTime> createdAt,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int> amountCents,
  Value<String?> description,
  Value<String> transactionType,
  Value<String> category,
  Value<DateTime> date,
  Value<int?> templateId,
  Value<DateTime> createdAt,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecurringTemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.recurringTemplates.createAlias($_aliasNameGenerator(
          db.transactions.templateId, db.recurringTemplates.id));

  $$RecurringTemplatesTableProcessedTableManager? get templateId {
    final $_column = $_itemColumn<int>('template_id');
    if ($_column == null) return null;
    final manager =
        $$RecurringTemplatesTableTableManager($_db, $_db.recurringTemplates)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$RecurringTemplatesTableFilterComposer get templateId {
    final $$RecurringTemplatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.templateId,
        referencedTable: $db.recurringTemplates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTemplatesTableFilterComposer(
              $db: $db,
              $table: $db.recurringTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$RecurringTemplatesTableOrderingComposer get templateId {
    final $$RecurringTemplatesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.templateId,
        referencedTable: $db.recurringTemplates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTemplatesTableOrderingComposer(
              $db: $db,
              $table: $db.recurringTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
      column: $table.transactionType, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$RecurringTemplatesTableAnnotationComposer get templateId {
    final $$RecurringTemplatesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.templateId,
            referencedTable: $db.recurringTemplates,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecurringTemplatesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recurringTemplates,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    TransactionRow,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (TransactionRow, $$TransactionsTableReferences),
    TransactionRow,
    PrefetchHooks Function({bool templateId})> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> amountCents = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> transactionType = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int?> templateId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            name: name,
            amountCents: amountCents,
            description: description,
            transactionType: transactionType,
            category: category,
            date: date,
            templateId: templateId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int amountCents,
            Value<String?> description = const Value.absent(),
            required String transactionType,
            required String category,
            required DateTime date,
            Value<int?> templateId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            name: name,
            amountCents: amountCents,
            description: description,
            transactionType: transactionType,
            category: category,
            date: date,
            templateId: templateId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({templateId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (templateId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.templateId,
                    referencedTable:
                        $$TransactionsTableReferences._templateIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._templateIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    TransactionRow,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (TransactionRow, $$TransactionsTableReferences),
    TransactionRow,
    PrefetchHooks Function({bool templateId})>;
typedef $$InitialCapitalTableTableCreateCompanionBuilder
    = InitialCapitalTableCompanion Function({
  Value<int> id,
  required int amountCents,
  Value<bool> isActive,
});
typedef $$InitialCapitalTableTableUpdateCompanionBuilder
    = InitialCapitalTableCompanion Function({
  Value<int> id,
  Value<int> amountCents,
  Value<bool> isActive,
});

class $$InitialCapitalTableTableFilterComposer
    extends Composer<_$AppDatabase, $InitialCapitalTableTable> {
  $$InitialCapitalTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$InitialCapitalTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InitialCapitalTableTable> {
  $$InitialCapitalTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$InitialCapitalTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InitialCapitalTableTable> {
  $$InitialCapitalTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
      column: $table.amountCents, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$InitialCapitalTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InitialCapitalTableTable,
    InitialCapitalRow,
    $$InitialCapitalTableTableFilterComposer,
    $$InitialCapitalTableTableOrderingComposer,
    $$InitialCapitalTableTableAnnotationComposer,
    $$InitialCapitalTableTableCreateCompanionBuilder,
    $$InitialCapitalTableTableUpdateCompanionBuilder,
    (
      InitialCapitalRow,
      BaseReferences<_$AppDatabase, $InitialCapitalTableTable,
          InitialCapitalRow>
    ),
    InitialCapitalRow,
    PrefetchHooks Function()> {
  $$InitialCapitalTableTableTableManager(
      _$AppDatabase db, $InitialCapitalTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InitialCapitalTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InitialCapitalTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InitialCapitalTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> amountCents = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
          }) =>
              InitialCapitalTableCompanion(
            id: id,
            amountCents: amountCents,
            isActive: isActive,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int amountCents,
            Value<bool> isActive = const Value.absent(),
          }) =>
              InitialCapitalTableCompanion.insert(
            id: id,
            amountCents: amountCents,
            isActive: isActive,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InitialCapitalTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InitialCapitalTableTable,
    InitialCapitalRow,
    $$InitialCapitalTableTableFilterComposer,
    $$InitialCapitalTableTableOrderingComposer,
    $$InitialCapitalTableTableAnnotationComposer,
    $$InitialCapitalTableTableCreateCompanionBuilder,
    $$InitialCapitalTableTableUpdateCompanionBuilder,
    (
      InitialCapitalRow,
      BaseReferences<_$AppDatabase, $InitialCapitalTableTable,
          InitialCapitalRow>
    ),
    InitialCapitalRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecurringTemplatesTableTableManager get recurringTemplates =>
      $$RecurringTemplatesTableTableManager(_db, _db.recurringTemplates);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$InitialCapitalTableTableTableManager get initialCapitalTable =>
      $$InitialCapitalTableTableTableManager(_db, _db.initialCapitalTable);
}
