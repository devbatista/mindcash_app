import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindcash_app/presentation/widgets/app_text_field.dart';

class MoneyField extends StatelessWidget {
  const MoneyField({required this.controller, this.label = 'Valor', super.key});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Informe um valor.';
        }

        return null;
      },
    );
  }

  static int parseCents(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return 0;
    }

    return int.parse(digits);
  }
}

class DigitsOnlyMoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
