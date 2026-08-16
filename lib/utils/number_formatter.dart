import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandSeparatorFormatter extends TextInputFormatter {
  static final _formatter = NumberFormat("#,###");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove old separators
    String text = newValue.text.replaceAll(',', '');
    
    // Check if it's a valid number
    if (double.tryParse(text) == null) {
      return oldValue;
    }

    // Format the number
    final double value = double.parse(text);
    final String newText = _formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

extension StringExtension on String {
  String removeCommas() {
    return replaceAll(',', '');
  }
}
