import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';

class InstallmentRepository {
  const InstallmentRepository(this._database);

  final AppDatabase _database;

  Future<List<Installment>> createInstallmentPurchase({
    required String description,
    required int totalCents,
    required int installmentCount,
    required DateTime purchaseDate,
    int? accountId,
    int? creditCardId,
    int? categoryId,
  }) async {
    _validatePurchase(
      description: description,
      totalCents: totalCents,
      installmentCount: installmentCount,
      accountId: accountId,
      creditCardId: creditCardId,
    );

    final now = DateTime.now();
    final purchaseUuid = 'purchase-${now.microsecondsSinceEpoch}';
    final amounts = _splitAmount(totalCents, installmentCount);
    final created = <Installment>[];

    for (var index = 0; index < installmentCount; index++) {
      final installmentNumber = index + 1;
      final dueDate = DateTime(
        purchaseDate.year,
        purchaseDate.month + index,
        purchaseDate.day,
      );
      final amountCents = amounts[index];
      int? transactionId;

      if (accountId != null) {
        final transaction = await TransactionRepository(_database)
            .createTransaction(
              type: 'expense',
              amountCents: amountCents,
              description:
                  '$description ($installmentNumber/$installmentCount)',
              date: dueDate,
              sourceAccountId: accountId,
              categoryId: categoryId,
            );
        transactionId = transaction.id;
      }

      final id = await _database
          .into(_database.installments)
          .insert(
            InstallmentsCompanion.insert(
              uuid: 'installment-${now.microsecondsSinceEpoch}-$index',
              purchaseUuid: purchaseUuid,
              description: description.trim(),
              totalCents: totalCents,
              amountCents: amountCents,
              installmentNumber: installmentNumber,
              installmentCount: installmentCount,
              purchaseDate: purchaseDate,
              dueDate: dueDate,
              accountId: Value.absentIfNull(accountId),
              creditCardId: Value.absentIfNull(creditCardId),
              categoryId: Value.absentIfNull(categoryId),
              transactionId: Value.absentIfNull(transactionId),
              createdAt: now,
              updatedAt: now,
            ),
          );

      created.add(await getById(id));
    }

    return created;
  }

  Future<Installment> getById(int id) {
    return (_database.select(
      _database.installments,
    )..where((installment) => installment.id.equals(id))).getSingle();
  }

  Future<List<Installment>> listActiveInstallments({
    int? accountId,
    int? creditCardId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return (_database.select(_database.installments)
          ..where(
            (installment) =>
                installment.deletedAt.isNull() &
                installment.isCanceled.equals(false),
          )
          ..where((installment) {
            if (accountId == null) {
              return const Constant(true);
            }

            return installment.accountId.equals(accountId);
          })
          ..where((installment) {
            if (creditCardId == null) {
              return const Constant(true);
            }

            return installment.creditCardId.equals(creditCardId);
          })
          ..where((installment) {
            if (startDate == null) {
              return const Constant(true);
            }

            return installment.dueDate.isBiggerOrEqualValue(startDate);
          })
          ..where((installment) {
            if (endDate == null) {
              return const Constant(true);
            }

            return installment.dueDate.isSmallerThanValue(endDate);
          })
          ..orderBy([
            (installment) => OrderingTerm.asc(installment.dueDate),
            (installment) => OrderingTerm.asc(installment.installmentNumber),
          ]))
        .get();
  }

  Future<Installment?> getCurrentInstallment(
    String purchaseUuid, {
    DateTime? date,
  }) {
    final reference = date ?? DateTime.now();
    final monthStart = DateTime(reference.year, reference.month);
    final monthEnd = DateTime(reference.year, reference.month + 1);

    return (_database.select(_database.installments)
          ..where(
            (installment) => installment.purchaseUuid.equals(purchaseUuid),
          )
          ..where((installment) => installment.deletedAt.isNull())
          ..where((installment) => installment.isCanceled.equals(false))
          ..where(
            (installment) =>
                installment.dueDate.isBiggerOrEqualValue(monthStart),
          )
          ..where(
            (installment) => installment.dueDate.isSmallerThanValue(monthEnd),
          )
          ..orderBy([
            (installment) => OrderingTerm.asc(installment.installmentNumber),
          ]))
        .getSingleOrNull();
  }

  Future<void> cancelFutureInstallments(
    String purchaseUuid, {
    DateTime? fromDate,
  }) async {
    final now = DateTime.now();
    final startDate = fromDate ?? DateTime(now.year, now.month + 1);
    final installments =
        await (_database.select(_database.installments)
              ..where(
                (installment) => installment.purchaseUuid.equals(purchaseUuid),
              )
              ..where((installment) => installment.deletedAt.isNull())
              ..where((installment) => installment.isCanceled.equals(false))
              ..where(
                (installment) =>
                    installment.dueDate.isBiggerOrEqualValue(startDate),
              ))
            .get();

    for (final installment in installments) {
      await (_database.update(
        _database.installments,
      )..where((row) => row.id.equals(installment.id))).write(
        InstallmentsCompanion(
          isCanceled: const Value(true),
          canceledAt: Value(now),
          updatedAt: Value(now),
          deletedAt: Value(now),
        ),
      );

      final transactionId = installment.transactionId;
      if (transactionId != null) {
        await TransactionRepository(
          _database,
        ).deactivateTransaction(transactionId);
      }
    }
  }

  List<int> _splitAmount(int totalCents, int count) {
    final base = totalCents ~/ count;
    final remainder = totalCents % count;

    return List<int>.generate(
      count,
      (index) => index == count - 1 ? base + remainder : base,
    );
  }

  void _validatePurchase({
    required String description,
    required int totalCents,
    required int installmentCount,
    required int? accountId,
    required int? creditCardId,
  }) {
    if (description.trim().isEmpty) {
      throw ArgumentError.value(
        description,
        'description',
        'A descrição é obrigatória.',
      );
    }

    if (totalCents <= 0) {
      throw ArgumentError.value(
        totalCents,
        'totalCents',
        'O valor deve ser maior que zero.',
      );
    }

    if (installmentCount < 2) {
      throw ArgumentError.value(
        installmentCount,
        'installmentCount',
        'A compra parcelada precisa ter pelo menos duas parcelas.',
      );
    }

    if ((accountId == null && creditCardId == null) ||
        (accountId != null && creditCardId != null)) {
      throw ArgumentError(
        'Informe uma conta ou um cartão para a compra parcelada.',
      );
    }
  }
}
