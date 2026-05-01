import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/app_database.dart';

class LocalBackupService {
  const LocalBackupService(this._database);

  final AppDatabase _database;

  Future<String> exportJson() async {
    final data = {
      'backupVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'accounts': (await _database.select(_database.accounts).get())
            .map(_accountToJson)
            .toList(),
        'categories': (await _database.select(_database.categories).get())
            .map(_categoryToJson)
            .toList(),
        'transactions': (await _database.select(_database.transactions).get())
            .map(_transactionToJson)
            .toList(),
        'creditCards': (await _database.select(_database.creditCards).get())
            .map(_creditCardToJson)
            .toList(),
        'invoices': (await _database.select(_database.invoices).get())
            .map(_invoiceToJson)
            .toList(),
        'installments': (await _database.select(_database.installments).get())
            .map(_installmentToJson)
            .toList(),
        'recurrences': (await _database.select(_database.recurrences).get())
            .map(_recurrenceToJson)
            .toList(),
        'appSettings': (await _database.select(_database.appSettings).get())
            .map(_appSettingToJson)
            .toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String> exportCsv() async {
    final transactions = await _database.select(_database.transactions).get();
    final accounts = {
      for (final account in await _database.select(_database.accounts).get())
        account.id: account.name,
    };
    final categories = {
      for (final category in await _database.select(_database.categories).get())
        category.id: category.name,
    };
    final rows = <List<String>>[
      [
        'id',
        'tipo',
        'valor_centavos',
        'descricao',
        'data',
        'conta_origem',
        'conta_destino',
        'categoria',
        'observacao',
      ],
      for (final transaction in transactions)
        [
          transaction.id.toString(),
          transaction.type,
          transaction.amountCents.toString(),
          transaction.description,
          transaction.date.toIso8601String(),
          accounts[transaction.sourceAccountId] ?? '',
          accounts[transaction.destinationAccountId] ?? '',
          categories[transaction.categoryId] ?? '',
          transaction.note ?? '',
        ],
    ];

    return rows.map(_csvRow).join('\n');
  }

  BackupValidationResult validateJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, Object?>) {
        return const BackupValidationResult.invalid(
          'O arquivo precisa conter um objeto JSON.',
        );
      }

      if (decoded['backupVersion'] != 1) {
        return const BackupValidationResult.invalid(
          'Versão de backup não suportada.',
        );
      }

      final data = decoded['data'];
      if (data is! Map<String, Object?>) {
        return const BackupValidationResult.invalid(
          'O backup não possui a seção de dados.',
        );
      }

      for (final key in _requiredLists) {
        if (data[key] is! List<Object?>) {
          return BackupValidationResult.invalid(
            'A lista "$key" está ausente ou inválida.',
          );
        }
      }

      return const BackupValidationResult.valid();
    } catch (_) {
      return const BackupValidationResult.invalid(
        'O conteúdo informado não é um JSON válido.',
      );
    }
  }

  Future<BackupImportResult> importJson(String rawJson) async {
    final validation = validateJson(rawJson);
    if (!validation.isValid) {
      throw ArgumentError(validation.message);
    }

    final safetyBackupJson = await exportJson();
    final decoded = jsonDecode(rawJson) as Map<String, Object?>;
    final data = decoded['data']! as Map<String, Object?>;

    await _database.transaction(() async {
      await _clearDatabase();
      await _restoreAccounts(_list(data, 'accounts'));
      await _restoreCategories(_list(data, 'categories'));
      await _restoreCreditCards(_list(data, 'creditCards'));
      await _restoreTransactions(_list(data, 'transactions'));
      await _restoreInvoices(_list(data, 'invoices'));
      await _restoreInstallments(_list(data, 'installments'));
      await _restoreRecurrences(_list(data, 'recurrences'));
      await _restoreAppSettings(_optionalList(data, 'appSettings'));
    });

    return BackupImportResult(safetyBackupJson: safetyBackupJson);
  }

  Future<void> resetAllData() async {
    await _database.transaction(_clearDatabase);
  }

  Future<void> _clearDatabase() async {
    await _database.delete(_database.appSettings).go();
    await _database.delete(_database.recurrences).go();
    await _database.delete(_database.installments).go();
    await _database.delete(_database.invoices).go();
    await _database.delete(_database.transactions).go();
    await _database.delete(_database.creditCards).go();
    await _database.delete(_database.categories).go();
    await _database.delete(_database.accounts).go();
  }

  Future<void> _restoreAccounts(List<Object?> rows) async {
    for (final row in rows) {
      final map = _map(row);
      await _database
          .into(_database.accounts)
          .insert(
            AccountsCompanion.insert(
              id: Value(_int(map, 'id')),
              uuid: _string(map, 'uuid'),
              name: _string(map, 'name'),
              type: _string(map, 'type'),
              initialBalanceCents: Value(_int(map, 'initialBalanceCents')),
              isActive: Value(_bool(map, 'isActive')),
              syncStatus: Value(_string(map, 'syncStatus')),
              createdAt: _date(map, 'createdAt'),
              updatedAt: _date(map, 'updatedAt'),
              deletedAt: Value(_nullableDate(map, 'deletedAt')),
            ),
          );
    }
  }

  Future<void> _restoreCategories(List<Object?> rows) async {
    for (final row in rows) {
      final map = _map(row);
      await _database
          .into(_database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: Value(_int(map, 'id')),
              uuid: _string(map, 'uuid'),
              name: _string(map, 'name'),
              type: _string(map, 'type'),
              colorValue: Value(_nullableInt(map, 'colorValue')),
              iconName: Value(_nullableString(map, 'iconName')),
              isSystem: Value(_bool(map, 'isSystem')),
              isActive: Value(_bool(map, 'isActive')),
              syncStatus: Value(_string(map, 'syncStatus')),
              createdAt: _date(map, 'createdAt'),
              updatedAt: _date(map, 'updatedAt'),
              deletedAt: Value(_nullableDate(map, 'deletedAt')),
            ),
          );
    }
  }

  Future<void> _restoreTransactions(List<Object?> rows) async {
    for (final row in rows) {
      final map = _map(row);
      await _database
          .into(_database.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: Value(_int(map, 'id')),
              uuid: _string(map, 'uuid'),
              type: _string(map, 'type'),
              amountCents: _int(map, 'amountCents'),
              description: _string(map, 'description'),
              date: _date(map, 'date'),
              sourceAccountId: _int(map, 'sourceAccountId'),
              destinationAccountId: Value(
                _nullableInt(map, 'destinationAccountId'),
              ),
              categoryId: Value(_nullableInt(map, 'categoryId')),
              note: Value(_nullableString(map, 'note')),
              syncStatus: Value(_string(map, 'syncStatus')),
              createdAt: _date(map, 'createdAt'),
              updatedAt: _date(map, 'updatedAt'),
              deletedAt: Value(_nullableDate(map, 'deletedAt')),
            ),
          );
    }
  }

  Future<void> _restoreCreditCards(List<Object?> rows) async {
    for (final row in rows) {
      final map = _map(row);
      await _database
          .into(_database.creditCards)
          .insert(
            CreditCardsCompanion.insert(
              id: Value(_int(map, 'id')),
              uuid: _string(map, 'uuid'),
              name: _string(map, 'name'),
              limitCents: Value(_int(map, 'limitCents')),
              closingDay: _int(map, 'closingDay'),
              dueDay: _int(map, 'dueDay'),
              isActive: Value(_bool(map, 'isActive')),
              syncStatus: Value(_string(map, 'syncStatus')),
              createdAt: _date(map, 'createdAt'),
              updatedAt: _date(map, 'updatedAt'),
              deletedAt: Value(_nullableDate(map, 'deletedAt')),
            ),
          );
    }
  }

  Future<void> _restoreInvoices(List<Object?> rows) async {
    for (final row in rows) {
      final map = _map(row);
      await _database
          .into(_database.invoices)
          .insert(
            InvoicesCompanion.insert(
              id: Value(_int(map, 'id')),
              uuid: _string(map, 'uuid'),
              creditCardId: _int(map, 'creditCardId'),
              referenceMonth: _date(map, 'referenceMonth'),
              closingDate: _date(map, 'closingDate'),
              dueDate: _date(map, 'dueDate'),
              totalCents: Value(_int(map, 'totalCents')),
              isPaid: Value(_bool(map, 'isPaid')),
              paidAt: Value(_nullableDate(map, 'paidAt')),
              syncStatus: Value(_string(map, 'syncStatus')),
              createdAt: _date(map, 'createdAt'),
              updatedAt: _date(map, 'updatedAt'),
              deletedAt: Value(_nullableDate(map, 'deletedAt')),
            ),
          );
    }
  }

  Future<void> _restoreInstallments(List<Object?> rows) async {
    for (final row in rows) {
      final map = _map(row);
      await _database
          .into(_database.installments)
          .insert(
            InstallmentsCompanion.insert(
              id: Value(_int(map, 'id')),
              uuid: _string(map, 'uuid'),
              purchaseUuid: _string(map, 'purchaseUuid'),
              description: _string(map, 'description'),
              totalCents: _int(map, 'totalCents'),
              amountCents: _int(map, 'amountCents'),
              installmentNumber: _int(map, 'installmentNumber'),
              installmentCount: _int(map, 'installmentCount'),
              purchaseDate: _date(map, 'purchaseDate'),
              dueDate: _date(map, 'dueDate'),
              accountId: Value(_nullableInt(map, 'accountId')),
              creditCardId: Value(_nullableInt(map, 'creditCardId')),
              categoryId: Value(_nullableInt(map, 'categoryId')),
              transactionId: Value(_nullableInt(map, 'transactionId')),
              isCanceled: Value(_bool(map, 'isCanceled')),
              canceledAt: Value(_nullableDate(map, 'canceledAt')),
              syncStatus: Value(_string(map, 'syncStatus')),
              createdAt: _date(map, 'createdAt'),
              updatedAt: _date(map, 'updatedAt'),
              deletedAt: Value(_nullableDate(map, 'deletedAt')),
            ),
          );
    }
  }

  Future<void> _restoreRecurrences(List<Object?> rows) async {
    for (final row in rows) {
      final map = _map(row);
      await _database
          .into(_database.recurrences)
          .insert(
            RecurrencesCompanion.insert(
              id: Value(_int(map, 'id')),
              uuid: _string(map, 'uuid'),
              type: _string(map, 'type'),
              amountCents: _int(map, 'amountCents'),
              description: _string(map, 'description'),
              dayOfMonth: _int(map, 'dayOfMonth'),
              nextDueDate: _date(map, 'nextDueDate'),
              accountId: _int(map, 'accountId'),
              categoryId: Value(_nullableInt(map, 'categoryId')),
              note: Value(_nullableString(map, 'note')),
              isActive: Value(_bool(map, 'isActive')),
              syncStatus: Value(_string(map, 'syncStatus')),
              createdAt: _date(map, 'createdAt'),
              updatedAt: _date(map, 'updatedAt'),
              deletedAt: Value(_nullableDate(map, 'deletedAt')),
            ),
          );
    }
  }

  Future<void> _restoreAppSettings(List<Object?> rows) async {
    for (final row in rows) {
      final map = _map(row);
      await _database
          .into(_database.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              id: Value(_int(map, 'id')),
              userName: _string(map, 'userName'),
              currencyCode: Value(_string(map, 'currencyCode')),
              createdAt: _date(map, 'createdAt'),
              updatedAt: _date(map, 'updatedAt'),
            ),
          );
    }
  }

  Map<String, Object?> _accountToJson(Account account) => {
    'id': account.id,
    'uuid': account.uuid,
    'name': account.name,
    'type': account.type,
    'initialBalanceCents': account.initialBalanceCents,
    'isActive': account.isActive,
    'syncStatus': account.syncStatus,
    'createdAt': account.createdAt.toIso8601String(),
    'updatedAt': account.updatedAt.toIso8601String(),
    'deletedAt': account.deletedAt?.toIso8601String(),
  };

  Map<String, Object?> _categoryToJson(Category category) => {
    'id': category.id,
    'uuid': category.uuid,
    'name': category.name,
    'type': category.type,
    'colorValue': category.colorValue,
    'iconName': category.iconName,
    'isSystem': category.isSystem,
    'isActive': category.isActive,
    'syncStatus': category.syncStatus,
    'createdAt': category.createdAt.toIso8601String(),
    'updatedAt': category.updatedAt.toIso8601String(),
    'deletedAt': category.deletedAt?.toIso8601String(),
  };

  Map<String, Object?> _transactionToJson(Transaction transaction) => {
    'id': transaction.id,
    'uuid': transaction.uuid,
    'type': transaction.type,
    'amountCents': transaction.amountCents,
    'description': transaction.description,
    'date': transaction.date.toIso8601String(),
    'sourceAccountId': transaction.sourceAccountId,
    'destinationAccountId': transaction.destinationAccountId,
    'categoryId': transaction.categoryId,
    'note': transaction.note,
    'syncStatus': transaction.syncStatus,
    'createdAt': transaction.createdAt.toIso8601String(),
    'updatedAt': transaction.updatedAt.toIso8601String(),
    'deletedAt': transaction.deletedAt?.toIso8601String(),
  };

  Map<String, Object?> _creditCardToJson(CreditCard card) => {
    'id': card.id,
    'uuid': card.uuid,
    'name': card.name,
    'limitCents': card.limitCents,
    'closingDay': card.closingDay,
    'dueDay': card.dueDay,
    'isActive': card.isActive,
    'syncStatus': card.syncStatus,
    'createdAt': card.createdAt.toIso8601String(),
    'updatedAt': card.updatedAt.toIso8601String(),
    'deletedAt': card.deletedAt?.toIso8601String(),
  };

  Map<String, Object?> _invoiceToJson(Invoice invoice) => {
    'id': invoice.id,
    'uuid': invoice.uuid,
    'creditCardId': invoice.creditCardId,
    'referenceMonth': invoice.referenceMonth.toIso8601String(),
    'closingDate': invoice.closingDate.toIso8601String(),
    'dueDate': invoice.dueDate.toIso8601String(),
    'totalCents': invoice.totalCents,
    'isPaid': invoice.isPaid,
    'paidAt': invoice.paidAt?.toIso8601String(),
    'syncStatus': invoice.syncStatus,
    'createdAt': invoice.createdAt.toIso8601String(),
    'updatedAt': invoice.updatedAt.toIso8601String(),
    'deletedAt': invoice.deletedAt?.toIso8601String(),
  };

  Map<String, Object?> _installmentToJson(Installment installment) => {
    'id': installment.id,
    'uuid': installment.uuid,
    'purchaseUuid': installment.purchaseUuid,
    'description': installment.description,
    'totalCents': installment.totalCents,
    'amountCents': installment.amountCents,
    'installmentNumber': installment.installmentNumber,
    'installmentCount': installment.installmentCount,
    'purchaseDate': installment.purchaseDate.toIso8601String(),
    'dueDate': installment.dueDate.toIso8601String(),
    'accountId': installment.accountId,
    'creditCardId': installment.creditCardId,
    'categoryId': installment.categoryId,
    'transactionId': installment.transactionId,
    'isCanceled': installment.isCanceled,
    'canceledAt': installment.canceledAt?.toIso8601String(),
    'syncStatus': installment.syncStatus,
    'createdAt': installment.createdAt.toIso8601String(),
    'updatedAt': installment.updatedAt.toIso8601String(),
    'deletedAt': installment.deletedAt?.toIso8601String(),
  };

  Map<String, Object?> _recurrenceToJson(Recurrence recurrence) => {
    'id': recurrence.id,
    'uuid': recurrence.uuid,
    'type': recurrence.type,
    'amountCents': recurrence.amountCents,
    'description': recurrence.description,
    'dayOfMonth': recurrence.dayOfMonth,
    'nextDueDate': recurrence.nextDueDate.toIso8601String(),
    'accountId': recurrence.accountId,
    'categoryId': recurrence.categoryId,
    'note': recurrence.note,
    'isActive': recurrence.isActive,
    'syncStatus': recurrence.syncStatus,
    'createdAt': recurrence.createdAt.toIso8601String(),
    'updatedAt': recurrence.updatedAt.toIso8601String(),
    'deletedAt': recurrence.deletedAt?.toIso8601String(),
  };

  Map<String, Object?> _appSettingToJson(AppSetting settings) => {
    'id': settings.id,
    'userName': settings.userName,
    'currencyCode': settings.currencyCode,
    'createdAt': settings.createdAt.toIso8601String(),
    'updatedAt': settings.updatedAt.toIso8601String(),
  };

  List<Object?> _list(Map<String, Object?> data, String key) {
    return data[key]! as List<Object?>;
  }

  List<Object?> _optionalList(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value == null) {
      return const [];
    }
    if (value is List<Object?>) {
      return value;
    }

    throw ArgumentError('A lista "$key" é inválida.');
  }

  Map<String, Object?> _map(Object? row) {
    if (row is Map<String, Object?>) {
      return row;
    }

    throw ArgumentError('Linha de backup inválida.');
  }

  String _string(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String) {
      return value;
    }

    throw ArgumentError('Campo "$key" inválido.');
  }

  String? _nullableString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null || value is String) {
      return value as String?;
    }

    throw ArgumentError('Campo "$key" inválido.');
  }

  int _int(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }

    throw ArgumentError('Campo "$key" inválido.');
  }

  int? _nullableInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null || value is int) {
      return value as int?;
    }

    throw ArgumentError('Campo "$key" inválido.');
  }

  bool _bool(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is bool) {
      return value;
    }

    throw ArgumentError('Campo "$key" inválido.');
  }

  DateTime _date(Map<String, Object?> map, String key) {
    return DateTime.parse(_string(map, key));
  }

  DateTime? _nullableDate(Map<String, Object?> map, String key) {
    final value = _nullableString(map, key);

    return value == null ? null : DateTime.parse(value);
  }

  String _csvRow(List<String> values) {
    return values.map(_csvValue).join(',');
  }

  String _csvValue(String value) {
    final escaped = value.replaceAll('"', '""');

    return '"$escaped"';
  }
}

class BackupImportResult {
  const BackupImportResult({required this.safetyBackupJson});

  final String safetyBackupJson;
}

class BackupValidationResult {
  const BackupValidationResult._({
    required this.isValid,
    required this.message,
  });

  const BackupValidationResult.valid()
    : this._(isValid: true, message: 'Backup válido.');

  const BackupValidationResult.invalid(String message)
    : this._(isValid: false, message: message);

  final bool isValid;
  final String message;
}

const _requiredLists = [
  'accounts',
  'categories',
  'transactions',
  'creditCards',
  'invoices',
  'installments',
  'recurrences',
];
