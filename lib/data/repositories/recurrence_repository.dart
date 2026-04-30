import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/transaction_repository.dart';

class RecurrenceRepository {
  const RecurrenceRepository(this._database);

  final AppDatabase _database;

  Future<Recurrence> createMonthlyRecurrence({
    required String type,
    required int amountCents,
    required String description,
    required int dayOfMonth,
    required DateTime nextDueDate,
    required int accountId,
    int? categoryId,
    String? note,
  }) async {
    _validateRecurrence(
      type: type,
      amountCents: amountCents,
      description: description,
      dayOfMonth: dayOfMonth,
    );

    final now = DateTime.now();
    final id = await _database
        .into(_database.recurrences)
        .insert(
          RecurrencesCompanion.insert(
            uuid: _createUuid(now),
            type: type,
            amountCents: amountCents,
            description: description.trim(),
            dayOfMonth: dayOfMonth,
            nextDueDate: _dateWithClampedDay(nextDueDate, dayOfMonth),
            accountId: accountId,
            categoryId: Value.absentIfNull(categoryId),
            note: Value.absentIfNull(_nullIfBlank(note)),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return getById(id);
  }

  Future<Recurrence> getById(int id) {
    return (_database.select(
      _database.recurrences,
    )..where((recurrence) => recurrence.id.equals(id))).getSingle();
  }

  Future<List<Recurrence>> listActiveRecurrences() {
    return (_database.select(_database.recurrences)
          ..where(
            (recurrence) =>
                recurrence.isActive.equals(true) &
                recurrence.deletedAt.isNull(),
          )
          ..orderBy([
            (recurrence) => OrderingTerm.asc(recurrence.nextDueDate),
            (recurrence) => OrderingTerm.asc(recurrence.description),
          ]))
        .get();
  }

  Future<void> updateRecurrence(Recurrence recurrence) {
    _validateRecurrence(
      type: recurrence.type,
      amountCents: recurrence.amountCents,
      description: recurrence.description,
      dayOfMonth: recurrence.dayOfMonth,
    );

    return (_database.update(
      _database.recurrences,
    )..where((row) => row.id.equals(recurrence.id))).write(
      recurrence
          .copyWith(
            description: recurrence.description.trim(),
            nextDueDate: _dateWithClampedDay(
              recurrence.nextDueDate,
              recurrence.dayOfMonth,
            ),
            note: Value(_nullIfBlank(recurrence.note)),
            updatedAt: DateTime.now(),
          )
          .toCompanion(false),
    );
  }

  Future<void> deactivateRecurrence(int id) {
    final now = DateTime.now();

    return (_database.update(
      _database.recurrences,
    )..where((recurrence) => recurrence.id.equals(id))).write(
      RecurrencesCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );
  }

  Future<void> reactivateRecurrence(int id) {
    final now = DateTime.now();

    return (_database.update(
      _database.recurrences,
    )..where((recurrence) => recurrence.id.equals(id))).write(
      RecurrencesCompanion(
        isActive: const Value(true),
        updatedAt: Value(now),
        deletedAt: const Value(null),
      ),
    );
  }

  Future<List<Transaction>> executePendingRecurrences({DateTime? today}) async {
    final reference = today ?? DateTime.now();
    final endOfDay = DateTime(
      reference.year,
      reference.month,
      reference.day + 1,
    );
    final generated = <Transaction>[];
    final dueRecurrences =
        await (_database.select(_database.recurrences)
              ..where(
                (recurrence) =>
                    recurrence.isActive.equals(true) &
                    recurrence.deletedAt.isNull(),
              )
              ..where(
                (recurrence) =>
                    recurrence.nextDueDate.isSmallerThanValue(endOfDay),
              )
              ..orderBy([
                (recurrence) => OrderingTerm.asc(recurrence.nextDueDate),
              ]))
            .get();

    for (final recurrence in dueRecurrences) {
      var current = recurrence;

      while (current.nextDueDate.isBefore(endOfDay)) {
        await _database.transaction(() async {
          final transaction = await TransactionRepository(_database)
              .createTransaction(
                type: current.type,
                amountCents: current.amountCents,
                description: current.description,
                date: current.nextDueDate,
                sourceAccountId: current.accountId,
                categoryId: current.categoryId,
                note: current.note,
              );
          generated.add(transaction);

          final nextDueDate = _nextMonthlyDueDate(
            current.nextDueDate,
            current.dayOfMonth,
          );
          await (_database.update(
            _database.recurrences,
          )..where((row) => row.id.equals(current.id))).write(
            RecurrencesCompanion(
              nextDueDate: Value(nextDueDate),
              updatedAt: Value(DateTime.now()),
            ),
          );
          current = current.copyWith(nextDueDate: nextDueDate);
        });
      }
    }

    return generated;
  }

  DateTime _nextMonthlyDueDate(DateTime date, int dayOfMonth) {
    return _dateWithClampedDay(DateTime(date.year, date.month + 1), dayOfMonth);
  }

  DateTime _dateWithClampedDay(DateTime month, int day) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;

    return DateTime(month.year, month.month, day.clamp(1, lastDay));
  }

  void _validateRecurrence({
    required String type,
    required int amountCents,
    required String description,
    required int dayOfMonth,
  }) {
    if (type != 'income' && type != 'expense') {
      throw ArgumentError.value(
        type,
        'type',
        'A recorrência deve ser de receita ou despesa.',
      );
    }

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

    if (dayOfMonth < 1 || dayOfMonth > 31) {
      throw ArgumentError.value(
        dayOfMonth,
        'dayOfMonth',
        'O dia da recorrência deve estar entre 1 e 31.',
      );
    }
  }

  String _createUuid(DateTime now) {
    return 'recurrence-${now.microsecondsSinceEpoch}';
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
