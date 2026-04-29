final class MoneyFormatter {
  const MoneyFormatter._();

  static String brl(int cents) {
    final isNegative = cents < 0;
    final absolute = cents.abs();
    final reais = absolute ~/ 100;
    final centavos = absolute % 100;
    final formattedReais = _withThousands(reais);
    final prefix = isNegative ? '-R\$ ' : 'R\$ ';

    return '$prefix$formattedReais,${centavos.toString().padLeft(2, '0')}';
  }

  static String _withThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final positionFromEnd = digits.length - index;
      buffer.write(digits[index]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}
