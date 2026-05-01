import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/presentation/widgets/money_field.dart';

void main() {
  test('formats digits as cents while typing', () {
    final formatter = DigitsOnlyMoneyInputFormatter();

    final value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '4500'),
    );

    expect(value.text, '45,00');
    expect(value.selection.baseOffset, 5);
  });

  test('formats large amounts with thousands separator', () {
    expect(DigitsOnlyMoneyInputFormatter.formatText('123456'), '1.234,56');
  });

  test('parses formatted money back to cents', () {
    expect(MoneyField.parseCents('45,00'), 4500);
    expect(MoneyField.parseCents('1.234,56'), 123456);
  });
}
