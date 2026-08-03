import 'package:intl/intl.dart';

class NumberFormatter {
  // ========== فرمت عدد با جداکننده هزارگان ==========
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  // ========== تبدیل متن فرمت شده به عدد ==========
  static int parseNumber(String text) {
    return int.tryParse(text.replaceAll(',', '').trim()) ?? 0;
  }

  // ========== فرمت کردن متن هنگام تایپ ==========
  static String formatInput(String text) {
    final clean = text.replaceAll(',', '');
    if (clean.isEmpty) return '';
    final parsed = int.tryParse(clean);
    if (parsed == null) return text;
    return formatNumber(parsed);
  }
}