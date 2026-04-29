import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/app_database.dart';

class TransactionRepository {
  const TransactionRepository(this._database);

  final AppDatabase _database;

  Future<Transaction> createTransaction({
    required String type,
    required int amountCents,
    required String description,
    required DateTime date,
    required int sourceAccountId,
    int? destinationAccountId,
    int? categoryId,
    String? note,
  }) async {
    _validateTransaction(
      type: type,
      amountCents: amountCents,
      description: description,
      destinationAccountId: destinationAccountId,
    );

    final now = DateTime.now();
    final id = await _database
        .into(_database.transactions)
        .insert(
          TransactionsCompanion.insert(
            uuid: _createUuid(now),
            type: type,
            amountCents: amountCents,
            description: description.trim(),
            date: date,
            sourceAccountId: sourceAccountId,
            destinationAccountId: Value.absentIfNull(destinationAccountId),
            categoryId: Value.absentIfNull(categoryId),
            note: Value.absentIfNull(_nullIfBlank(note)),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return getById(id);
  }

  Future<Transaction> getById(int id) {
    return (_database.select(
      _database.transactions,
    )..where((transaction) => transaction.id.equals(id))).getSingle();
  }

  Future<List<Transaction>> listActiveTransactions() {
    return listTransactions();
  }

  Future<List<Transaction>> listTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? search,
  }) {
    final normalizedSearch = search?.trim().toLowerCase();

    return (_database.select(_database.transactions)
          ..where((transaction) => transaction.deletedAt.isNull())
          ..where((transaction) {
            if (startDate == null) {
              return const Constant(true);
            }

            return transaction.date.isBiggerOrEqualValue(startDate);
          })
          ..where((transaction) {
            if (endDate == null) {
              return const Constant(true);
            }

            return transaction.date.isSmallerThanValue(endDate);
          })
          ..where((transaction) {
            if (type == null) {
              return const Constant(true);
            }

            return transaction.type.equals(type);
          })
          ..where((transaction) {
            if (normalizedSearch == null || normalizedSearch.isEmpty) {
              return const Constant(true);
            }

            return transaction.description.lower().contains(normalizedSearch);
          })
          ..orderBy([
            (transaction) => OrderingTerm.desc(transaction.date),
            (transaction) => OrderingTerm.desc(transaction.id),
          ]))
        .get();
  }

  Future<List<Transaction>> listTransactionsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return listTransactions(startDate: start, endDate: end);
  }

  Future<void> updateTransaction(Transaction transaction) {
    return (_database.update(
      _database.transactions,
    )..where((row) => row.id.equals(transaction.id))).write(
      transaction
          .copyWith(
            description: transaction.description.trim(),
            note: Value(_nullIfBlank(transaction.note)),
            updatedAt: DateTime.now(),
          )
          .toCompanion(false),
    );
  }

  Future<void> deactivateTransaction(int id) {
    final now = DateTime.now();

    return (_database.update(
      _database.transactions,
    )..where((transaction) => transaction.id.equals(id))).write(
      TransactionsCompanion(updatedAt: Value(now), deletedAt: Value(now)),
    );
  }

  Future<void> deleteTransaction(int id) {
    return deactivateTransaction(id);
  }

  Future<Transaction> createTransfer({
    required int amountCents,
    required String description,
    required DateTime date,
    required int sourceAccountId,
    required int destinationAccountId,
    String? note,
  }) {
    return createTransaction(
      type: 'transfer',
      amountCents: amountCents,
      description: description,
      date: date,
      sourceAccountId: sourceAccountId,
      destinationAccountId: destinationAccountId,
      note: note,
    );
  }

  Future<int> calculateAccountBalance(int accountId) async {
    final account = await (_database.select(
      _database.accounts,
    )..where((account) => account.id.equals(accountId))).getSingle();

    final transactions = await listTransactions();
    var balance = account.initialBalanceCents;

    for (final transaction in transactions) {
      if (transaction.type == 'income' &&
          transaction.sourceAccountId == accountId) {
        balance += transaction.amountCents;
      }

      if (transaction.type == 'expense' &&
          transaction.sourceAccountId == accountId) {
        balance -= transaction.amountCents;
      }

      if (transaction.type == 'transfer' &&
          transaction.sourceAccountId == accountId) {
        balance -= transaction.amountCents;
      }

      if (transaction.type == 'transfer' &&
          transaction.destinationAccountId == accountId) {
        balance += transaction.amountCents;
      }
    }

    return balance;
  }

  Future<int> calculateTotalBalance() async {
    final accounts =
        await (_database.select(_database.accounts)..where(
              (account) =>
                  account.isActive.equals(true) & account.deletedAt.isNull(),
            ))
            .get();

    var total = 0;

    for (final account in accounts) {
      total += await calculateAccountBalance(account.id);
    }

    return total;
  }

  Future<int> calculateMonthlyIncome(DateTime month) async {
    final transactions = await _listMonthTransactions(month, type: 'income');

    return transactions.fold<int>(
      0,
      (total, transaction) => total + transaction.amountCents,
    );
  }

  Future<int> calculateMonthlyExpense(DateTime month) async {
    final transactions = await _listMonthTransactions(month, type: 'expense');

    return transactions.fold<int>(
      0,
      (total, transaction) => total + transaction.amountCents,
    );
  }

  Future<int> calculateMonthlyResult(DateTime month) async {
    final income = await calculateMonthlyIncome(month);
    final expense = await calculateMonthlyExpense(month);

    return income - expense;
  }

  Future<List<Transaction>> _listMonthTransactions(
    DateTime month, {
    String? type,
  }) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    return listTransactions(startDate: start, endDate: end, type: type);
  }

  void _validateTransaction({
    required String type,
    required int amountCents,
    required String description,
    required int? destinationAccountId,
  }) {
    if (amountCents <= 0) {
      throw ArgumentError.value(
        amountCents,
        'amountCents',
        'O valor deve ser maior que zero.',
      );
    }

    if (description.trim().isEmpty) {
      throw ArgumentError.value(
        description,
        'description',
        'A descrição é obrigatória.',
      );
    }

    if (type == 'transfer' && destinationAccountId == null) {
      throw ArgumentError('Transferência precisa de uma conta de destino.');
    }
  }

  String _createUuid(DateTime now) {
    return 'transaction-${now.microsecondsSinceEpoch}';
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
