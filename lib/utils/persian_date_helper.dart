import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class PersianDateHelper {
  static String getCurrentPersianDate() {
    final now = Jalali.now();
    // return '//';
    return '${now.year}/${now.month}/${now.day}';
  }
}
