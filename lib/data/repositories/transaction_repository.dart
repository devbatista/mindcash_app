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
            note: Value.absentIfNull(note?.trim()),
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
    return (_database.select(_database.transactions)
          ..where(
            (transaction) =>
                transaction.deletedAt.isNull() &
                transaction.sourceAccountId.isNotNull(),
          )
          ..orderBy([
            (transaction) => OrderingTerm.desc(transaction.date),
            (transaction) => OrderingTerm.desc(transaction.id),
          ]))
        .get();
  }

  Future<void> updateTransaction(Transaction transaction) {
    return (_database.update(
      _database.transactions,
    )..where((row) => row.id.equals(transaction.id))).write(
      transaction
          .copyWith(
            description: transaction.description.trim(),
            note: Value(transaction.note?.trim()),
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

  String _createUuid(DateTime now) {
    return 'transaction-${now.microsecondsSinceEpoch}';
  }
}
