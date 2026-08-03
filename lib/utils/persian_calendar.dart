import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class PersianCalendar {
  static String toJalali(DateTime date) {
    final j = Jalali.fromDateTime(date);
    return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
  }
}