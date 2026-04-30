import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/installment_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';

class CreditCardRepository {
  const CreditCardRepository(this._database);

  final AppDatabase _database;

  Future<CreditCard> createCreditCard({
    required String name,
    required int limitCents,
    required int closingDay,
    required int dueDay,
  }) async {
    _validateCreditCard(
      name: name,
      limitCents: limitCents,
      closingDay: closingDay,
      dueDay: dueDay,
    );

    final now = DateTime.now();
    final id = await _database
        .into(_database.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            uuid: _createUuid('credit-card', now),
            name: name.trim(),
            limitCents: Value(limitCents),
            closingDay: closingDay,
            dueDay: dueDay,
            createdAt: now,
            updatedAt: now,
          ),
        );

    return getById(id);
  }

  Future<CreditCard> getById(int id) {
    return (_database.select(
      _database.creditCards,
    )..where((card) => card.id.equals(id))).getSingle();
  }

  Future<List<CreditCard>> listActiveCreditCards() {
    return (_database.select(_database.creditCards)
          ..where(
            (card) => card.isActive.equals(true) & card.deletedAt.isNull(),
          )
          ..orderBy([(card) => OrderingTerm.asc(card.name)]))
        .get();
  }

  Future<void> updateCreditCard(CreditCard creditCard) {
    _validateCreditCard(
      name: creditCard.name,
      limitCents: creditCard.limitCents,
      closingDay: creditCard.closingDay,
      dueDay: creditCard.dueDay,
    );

    return (_database.update(
      _database.creditCards,
    )..where((card) => card.id.equals(creditCard.id))).write(
      creditCard
          .copyWith(name: creditCard.name.trim(), updatedAt: DateTime.now())
          .toCompanion(false),
    );
  }

  Future<void> deactivateCreditCard(int id) {
    final now = DateTime.now();

    return (_database.update(
      _database.creditCards,
    )..where((card) => card.id.equals(id))).write(
      CreditCardsCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );
  }

  Future<CreditCardInvoiceSummary> calculateCurrentInvoice(
    CreditCard creditCard, {
    DateTime? month,
  }) async {
    final period = _buildInvoicePeriod(creditCard, month ?? DateTime.now());
    final launches = await listInvoiceLaunches(creditCard, month: month);
    final installments = await InstallmentRepository(_database)
        .listActiveInstallments(
          creditCardId: creditCard.id,
          startDate: period.startDate,
          endDate: period.endDate,
        );
    final storedInvoice = await _findInvoice(
      creditCard.id,
      period.referenceMonth,
    );
    final transactionTotalCents = launches.fold<int>(
      0,
      (total, transaction) => total + transaction.amountCents,
    );
    final installmentTotalCents = installments.fold<int>(
      0,
      (total, installment) => total + installment.amountCents,
    );

    return CreditCardInvoiceSummary(
      creditCard: creditCard,
      referenceMonth: period.referenceMonth,
      startDate: period.startDate,
      closingDate: period.closingDate,
      dueDate: period.dueDate,
      totalCents: transactionTotalCents + installmentTotalCents,
      launches: launches,
      installments: installments,
      invoice: storedInvoice,
      isPaid: storedInvoice?.isPaid ?? false,
      paidAt: storedInvoice?.paidAt,
    );
  }

  Future<List<Transaction>> listInvoiceLaunches(
    CreditCard creditCard, {
    DateTime? month,
  }) {
    final period = _buildInvoicePeriod(creditCard, month ?? DateTime.now());

    return TransactionRepository(_database).listTransactions(
      startDate: period.startDate,
      endDate: period.endDate,
      type: 'expense',
    );
  }

  Future<Invoice> registerInvoicePayment(
    CreditCard creditCard, {
    DateTime? month,
  }) async {
    final summary = await calculateCurrentInvoice(creditCard, month: month);
    final now = DateTime.now();
    final storedInvoice = summary.invoice;

    if (storedInvoice == null) {
      final id = await _database
          .into(_database.invoices)
          .insert(
            InvoicesCompanion.insert(
              uuid: _createUuid('invoice', now),
              creditCardId: creditCard.id,
              referenceMonth: summary.referenceMonth,
              closingDate: summary.closingDate,
              dueDate: summary.dueDate,
              totalCents: Value(summary.totalCents),
              isPaid: const Value(true),
              paidAt: Value(now),
              createdAt: now,
              updatedAt: now,
            ),
          );

      return (_database.select(
        _database.invoices,
      )..where((invoice) => invoice.id.equals(id))).getSingle();
    }

    await (_database.update(
      _database.invoices,
    )..where((invoice) => invoice.id.equals(storedInvoice.id))).write(
      InvoicesCompanion(
        closingDate: Value(summary.closingDate),
        dueDate: Value(summary.dueDate),
        totalCents: Value(summary.totalCents),
        isPaid: const Value(true),
        paidAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    return (_database.select(
      _database.invoices,
    )..where((invoice) => invoice.id.equals(storedInvoice.id))).getSingle();
  }

  Future<Invoice?> _findInvoice(int creditCardId, DateTime referenceMonth) {
    return (_database.select(_database.invoices)
          ..where((invoice) => invoice.creditCardId.equals(creditCardId))
          ..where((invoice) => invoice.deletedAt.isNull())
          ..where((invoice) => invoice.referenceMonth.equals(referenceMonth)))
        .getSingleOrNull();
  }

  _InvoicePeriod _buildInvoicePeriod(CreditCard creditCard, DateTime month) {
    final referenceMonth = DateTime(month.year, month.month);
    final previousMonth = DateTime(month.year, month.month - 1);
    final previousClosingDate = _dateWithClampedDay(
      previousMonth,
      creditCard.closingDay,
    );
    final closingDate = _dateWithClampedDay(
      referenceMonth,
      creditCard.closingDay,
    );
    final dueMonth = creditCard.dueDay > creditCard.closingDay
        ? referenceMonth
        : DateTime(month.year, month.month + 1);
    final dueDate = _dateWithClampedDay(dueMonth, creditCard.dueDay);

    return _InvoicePeriod(
      referenceMonth: referenceMonth,
      startDate: previousClosingDate.add(const Duration(days: 1)),
      closingDate: closingDate,
      endDate: closingDate.add(const Duration(days: 1)),
      dueDate: dueDate,
    );
  }

  DateTime _dateWithClampedDay(DateTime month, int day) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;

    return DateTime(month.year, month.month, day.clamp(1, lastDay));
  }

  void _validateCreditCard({
    required String name,
    required int limitCents,
    required int closingDay,
    required int dueDay,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'O nome do cartão é obrigatório.',
      );
    }

    if (limitCents < 0) {
      throw ArgumentError.value(
        limitCents,
        'limitCents',
        'O limite não pode ser negativo.',
      );
    }

    if (closingDay < 1 || closingDay > 31) {
      throw ArgumentError.value(
        closingDay,
        'closingDay',
        'O dia de fechamento deve estar entre 1 e 31.',
      );
    }

    if (dueDay < 1 || dueDay > 31) {
      throw ArgumentError.value(
        dueDay,
        'dueDay',
        'O dia de vencimento deve estar entre 1 e 31.',
      );
    }
  }

  String _createUuid(String prefix, DateTime now) {
    return '$prefix-${now.microsecondsSinceEpoch}';
  }
}

class CreditCardInvoiceSummary {
  const CreditCardInvoiceSummary({
    required this.creditCard,
    required this.referenceMonth,
    required this.startDate,
    required this.closingDate,
    required this.dueDate,
    required this.totalCents,
    required this.launches,
    required this.installments,
    required this.isPaid,
    this.invoice,
    this.paidAt,
  });

  final CreditCard creditCard;
  final DateTime referenceMonth;
  final DateTime startDate;
  final DateTime closingDate;
  final DateTime dueDate;
  final int totalCents;
  final List<Transaction> launches;
  final List<Installment> installments;
  final Invoice? invoice;
  final bool isPaid;
  final DateTime? paidAt;
}

class _InvoicePeriod {
  const _InvoicePeriod({
    required this.referenceMonth,
    required this.startDate,
    required this.closingDate,
    required this.endDate,
    required this.dueDate,
  });

  final DateTime referenceMonth;
  final DateTime startDate;
  final DateTime closingDate;
  final DateTime endDate;
  final DateTime dueDate;
}
