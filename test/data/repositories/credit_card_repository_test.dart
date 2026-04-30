import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/credit_card_repository.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase database;
  late CreditCardRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = CreditCardRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and lists active credit cards', () async {
    await repository.createCreditCard(
      name: 'Nubank',
      limitCents: 500000,
      closingDay: 10,
      dueDay: 17,
    );

    final cards = await repository.listActiveCreditCards();

    expect(cards, hasLength(1));
    expect(cards.single.name, 'Nubank');
    expect(cards.single.limitCents, 500000);
    expect(cards.single.closingDay, 10);
    expect(cards.single.dueDay, 17);
    expect(cards.single.isActive, isTrue);
  });

  test('updates credit card settings', () async {
    final card = await repository.createCreditCard(
      name: 'Cartão antigo',
      limitCents: 300000,
      closingDay: 8,
      dueDay: 15,
    );

    await repository.updateCreditCard(
      card.copyWith(
        name: 'Cartão novo',
        limitCents: 700000,
        closingDay: 12,
        dueDay: 20,
      ),
    );

    final updatedCard = await repository.getById(card.id);

    expect(updatedCard.name, 'Cartão novo');
    expect(updatedCard.limitCents, 700000);
    expect(updatedCard.closingDay, 12);
    expect(updatedCard.dueDay, 20);
  });

  test(
    'calculates current invoice from expenses inside invoice period',
    () async {
      final account = await AccountRepository(
        database,
      ).createAccount(name: 'Carteira', type: 'wallet');
      final card = await repository.createCreditCard(
        name: 'Nubank',
        limitCents: 500000,
        closingDay: 10,
        dueDay: 17,
      );
      final transactionRepository = TransactionRepository(database);

      await transactionRepository.createTransaction(
        type: 'expense',
        amountCents: 2500,
        description: 'Mercado',
        date: DateTime(2024, 5, 5),
        sourceAccountId: account.id,
      );
      await transactionRepository.createTransaction(
        type: 'expense',
        amountCents: 9900,
        description: 'Fora da fatura',
        date: DateTime(2024, 4, 10),
        sourceAccountId: account.id,
      );

      final invoice = await repository.calculateCurrentInvoice(
        card,
        month: DateTime(2024, 5),
      );

      expect(invoice.startDate, DateTime(2024, 4, 11));
      expect(invoice.closingDate, DateTime(2024, 5, 10));
      expect(invoice.dueDate, DateTime(2024, 5, 17));
      expect(invoice.totalCents, 2500);
      expect(invoice.launches, hasLength(1));
      expect(invoice.launches.single.description, 'Mercado');
      expect(invoice.isPaid, isFalse);
    },
  );

  test('registers invoice payment', () async {
    final card = await repository.createCreditCard(
      name: 'Nubank',
      limitCents: 500000,
      closingDay: 20,
      dueDay: 10,
    );

    final invoice = await repository.registerInvoicePayment(
      card,
      month: DateTime(2024, 5),
    );
    final summary = await repository.calculateCurrentInvoice(
      card,
      month: DateTime(2024, 5),
    );

    expect(invoice.isPaid, isTrue);
    expect(invoice.paidAt, isNotNull);
    expect(invoice.dueDate, DateTime(2024, 6, 10));
    expect(summary.isPaid, isTrue);
  });
}
