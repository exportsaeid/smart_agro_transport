/// توابع خالص تولید/پارس شماره فاکتور (قابل تست واحد)
class InvoiceNumberHelper {
  /// ساخت شماره از سال و ترتیب: مثلاً 1404 + 13 -> 14040013
  static String format(int year, int sequence) {
    if (sequence < 1) sequence = 1;
    return '$year${sequence.toString().padLeft(4, '0')}';
  }

  /// استخراج ترتیب ۴ رقم آخر
  static int? parseSequence(String? number) {
    if (number == null || number.isEmpty) return null;
    final m = RegExp(r'(\d{4})$').firstMatch(number);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  /// سال از پیشوند
  static int? parseYear(String? number) {
    if (number == null || number.length < 4) return null;
    return int.tryParse(number.substring(0, 4));
  }
}
