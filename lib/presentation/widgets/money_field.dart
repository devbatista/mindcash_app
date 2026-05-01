import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindcash_app/presentation/widgets/app_text_field.dart';

class MoneyField extends StatefulWidget {
  const MoneyField({required this.controller, this.label = 'Valor', super.key});

  final TextEditingController controller;
  final String label;

  @override
  State<MoneyField> createState() => _MoneyFieldState();

  static int parseCents(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return 0;
    }

    return int.parse(digits);
  }
}

class _MoneyFieldState extends State<MoneyField> {
  @override
  void initState() {
    super.initState();
    _formatInitialValue();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      keyboardType: TextInputType.number,
      inputFormatters: [DigitsOnlyMoneyInputFormatter()],
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Informe um valor.';
        }

        return null;
      },
    );
  }

  void _formatInitialValue() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      return;
    }

    final formatted = DigitsOnlyMoneyInputFormatter.formatText(text);
    widget.controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DigitsOnlyMoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = formatDigits(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String formatText(String value) {
    return formatDigits(value.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  static String formatDigits(String digits) {
    if (digits.isEmpty) {
      return '';
    }

    final cents = int.parse(digits);
    final reais = cents ~/ 100;
    final centsPart = (cents % 100).toString().padLeft(2, '0');
    final reaisPart = _formatThousands(reais);

    return '$reaisPart,$centsPart';
  }

  static String _formatThousands(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < raw.length; index += 1) {
      final remaining = raw.length - index;
      buffer.write(raw[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}
