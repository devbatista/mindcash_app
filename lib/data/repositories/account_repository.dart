import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/app_database.dart';

class AccountRepository {
  const AccountRepository(this._database);

  final AppDatabase _database;

  Future<Account> createAccount({
    required String name,
    required String type,
    int initialBalanceCents = 0,
  }) async {
    final now = DateTime.now();
    final id = await _database
        .into(_database.accounts)
        .insert(
          AccountsCompanion.insert(
            uuid: _createUuid(now),
            name: name.trim(),
            type: type,
            initialBalanceCents: Value(initialBalanceCents),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return getById(id);
  }

  Future<Account> getById(int id) {
    return (_database.select(
      _database.accounts,
    )..where((account) => account.id.equals(id))).getSingle();
  }

  Future<List<Account>> listActiveAccounts() {
    return (_database.select(_database.accounts)
          ..where(
            (account) =>
                account.isActive.equals(true) & account.deletedAt.isNull(),
          )
          ..orderBy([(account) => OrderingTerm.asc(account.name)]))
        .get();
  }

  Future<void> updateAccount(Account account) {
    return (_database.update(
      _database.accounts,
    )..where((row) => row.id.equals(account.id))).write(
      account
          .copyWith(name: account.name.trim(), updatedAt: DateTime.now())
          .toCompanion(false),
    );
  }

  Future<void> deactivateAccount(int id) {
    final now = DateTime.now();

    return (_database.update(
      _database.accounts,
    )..where((account) => account.id.equals(id))).write(
      AccountsCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );
  }

  Future<bool> hasTransactions(int id) async {
    final sourceTransactions =
        await (_database.select(_database.transactions)
              ..where(
                (transaction) =>
                    transaction.sourceAccountId.equals(id) &
                    transaction.deletedAt.isNull(),
              )
              ..limit(1))
            .get();

    if (sourceTransactions.isNotEmpty) {
      return true;
    }

    final destinationTransactions =
        await (_database.select(_database.transactions)
              ..where(
                (transaction) =>
                    transaction.destinationAccountId.equals(id) &
                    transaction.deletedAt.isNull(),
              )
              ..limit(1))
            .get();

    return destinationTransactions.isNotEmpty;
  }

  String _createUuid(DateTime now) {
    return 'account-${now.microsecondsSinceEpoch}';
  }
}
