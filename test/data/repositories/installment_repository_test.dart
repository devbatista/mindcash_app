import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/credit_card_repository.dart';
import 'package:mindcash_app/data/repositories/installment_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase database;
  late InstallmentRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = InstallmentRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates installments associated with credit card', () async {
    final card = await CreditCardRepository(database).createCreditCard(
      name: 'Nubank',
      limitCents: 500000,
      closingDay: 10,
      dueDay: 17,
    );

    final installments = await repository.createInstallmentPurchase(
      description: 'Notebook',
      totalCents: 100001,
      installmentCount: 3,
      purchaseDate: DateTime(2024, 5, 10),
      creditCardId: card.id,
    );

    expect(installments, hasLength(3));
    expect(installments.first.creditCardId, card.id);
    expect(installments.first.amountCents, 33333);
    expect(installments.last.amountCents, 33335);
    expect(installments.last.installmentNumber, 3);
  });

  test(
    'creates account installments and future expense transactions',
    () async {
      final account = await AccountRepository(
        database,
      ).createAccount(name: 'Carteira', type: 'wallet');

      final installments = await repository.createInstallmentPurchase(
        description: 'Curso',
        totalCents: 90000,
        installmentCount: 3,
        purchaseDate: DateTime(2024, 5, 5),
        accountId: account.id,
      );
      final transactions = await TransactionRepository(
        database,
      ).listActiveTransactions();

      expect(installments, hasLength(3));
      expect(transactions, hasLength(3));
      expect(transactions.first.description, 'Curso (3/3)');
    },
  );

  test('gets current installment by purchase month', () async {
    final card = await CreditCardRepository(database).createCreditCard(
      name: 'Nubank',
      limitCents: 500000,
      closingDay: 10,
      dueDay: 17,
    );
    final installments = await repository.createInstallmentPurchase(
      description: 'Geladeira',
      totalCents: 60000,
      installmentCount: 3,
      purchaseDate: DateTime(2024, 5, 8),
      creditCardId: card.id,
    );

    final current = await repository.getCurrentInstallment(
      installments.first.purchaseUuid,
      date: DateTime(2024, 6, 1),
    );

    expect(current, isNotNull);
    expect(current!.installmentNumber, 2);
  });

  test('cancels future installments and linked transactions', () async {
    final account = await AccountRepository(
      database,
    ).createAccount(name: 'Carteira', type: 'wallet');
    final installments = await repository.createInstallmentPurchase(
      description: 'Sofá',
      totalCents: 120000,
      installmentCount: 4,
      purchaseDate: DateTime(2024, 5, 2),
      accountId: account.id,
    );

    await repository.cancelFutureInstallments(
      installments.first.purchaseUuid,
      fromDate: DateTime(2024, 7),
    );

    final activeInstallments = await repository.listActiveInstallments(
      accountId: account.id,
    );
    final transactions = await TransactionRepository(
      database,
    ).listActiveTransactions();

    expect(activeInstallments, hasLength(2));
    expect(transactions, hasLength(2));
  });
}
