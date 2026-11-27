import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:ui' as ui;

class PersianDateHelper {
  static String getCurrentDate() {
    return Jalali.now().formatFullDate();
  }

  /// تبدیل رشته تاریخ فارسی به Jalali
  /// پشتیبانی از فرمت‌های رایج مثل: ۱۴۰۳/۰۵/۱۲ یا 1403/5/12
  static Jalali? parsePersianDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty || dateStr == 'انتخاب تاریخ') {
      return null;
    }

    try {
      // تبدیل اعداد فارسی به انگلیسی
      String normalized = dateStr
          .replaceAll('۰', '0')
          .replaceAll('۱', '1')
          .replaceAll('۲', '2')
          .replaceAll('۳', '3')
          .replaceAll('۴', '4')
          .replaceAll('۵', '5')
          .replaceAll('۶', '6')
          .replaceAll('۷', '7')
          .replaceAll('۸', '8')
          .replaceAll('۹', '9')
          .trim();

      // جدا کردن با / یا -
      final parts = normalized.split(RegExp(r'[/\-.]'));
      if (parts.length < 3) return null;

      final year = int.tryParse(parts[0].trim());
      final month = int.tryParse(parts[1].trim());
      final day = int.tryParse(parts[2].trim());

      if (year == null || month == null || day == null) return null;
      if (year < 1300 || year > 1450 || month < 1 || month > 12 || day < 1 || day > 31) {
        return null;
      }

      return Jalali(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> pickDate(
      BuildContext context, {
        String? initialDateStr, // تاریخ فعلی فاکتور
      }) async {
    // اگر تاریخ معتبر از قبل وجود دارد، همان را به‌عنوان initialDate استفاده کن
    final Jalali initial =
        parsePersianDate(initialDateStr) ?? Jalali.now();

    Jalali? picked = await showPersianDatePicker(
      context: context,
      initialDate: initial,
      firstDate: Jalali(1300, 1),
      lastDate: Jalali(1450, 12),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green[800]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: Colors.green[800],
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              dayStyle: const TextStyle(fontFamily: 'Tahoma'),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[800],
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tahoma',
                ),
              ),
            ),
          ),
          child: Directionality(
            textDirection: ui.TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      return picked.formatFullDate();
    }
    return null;
  }

  /// کلید عددی برای سورت تاریخ (YYYYMMDD). در صورت نامعتبر بودن null.
  static int? toSortableKey(String? dateStr) {
    final j = parsePersianDate(dateStr);
    if (j != null) {
      return j.year * 10000 + j.month * 100 + j.day;
    }
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    // پشتیبانی از formatFullDate مثل: «پنجشنبه 12 مهر 1403»
    String normalized = dateStr
        .replaceAll('۰', '0').replaceAll('۱', '1').replaceAll('۲', '2')
        .replaceAll('۳', '3').replaceAll('۴', '4').replaceAll('۵', '5')
        .replaceAll('۶', '6').replaceAll('۷', '7').replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .trim();

    final months = <String, int>{
      'فروردین': 1, 'اردیبهشت': 2, 'خرداد': 3, 'تیر': 4,
      'مرداد': 5, 'شهریور': 6, 'مهر': 7, 'آبان': 8,
      'آذر': 9, 'دی': 10, 'بهمن': 11, 'اسفند': 12,
    };

    int? year;
    int? month;
    int? day;

    final yearMatch = RegExp(r'(13|14)\d{2}').firstMatch(normalized);
    if (yearMatch != null) year = int.tryParse(yearMatch.group(0)!);

    for (final e in months.entries) {
      if (normalized.contains(e.key)) {
        month = e.value;
        break;
      }
    }

    final dayMatch = RegExp(r'\b([1-9]|[12]\d|3[01])\b').firstMatch(normalized);
    if (dayMatch != null) day = int.tryParse(dayMatch.group(1)!);

    if (year != null && month != null && day != null) {
      return year * 10000 + month * 100 + day;
    }
    return null;
  }
}