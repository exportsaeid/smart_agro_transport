import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;

class BatteryOptimizationHelper {

  // ============================================================
  // بررسی وضعیت Battery Optimization
  // ============================================================
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (Platform.isIOS) return true; // iOS نیازی ندارد

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      print('❌ خطا در بررسی Battery Optimization: $e');
      return false;
    }
  }

  // ============================================================
  // درخواست خروج از Battery Optimization
  // ============================================================
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (Platform.isIOS) return true;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;

      if (status.isDenied) {
        final result = await Permission.ignoreBatteryOptimizations.request();
        return result.isGranted;
      }

      return status.isGranted;
    } catch (e) {
      print('❌ خطا در درخواست Battery Optimization: $e');
      return false;
    }
  }

  // ============================================================
  // باز کردن تنظیمات Battery Optimization
  // ============================================================
  static Future<void> openBatterySettings() async {
    if (Platform.isIOS) return;

    // روش ۱: درخواست مستقیم سیستم (دیالوگ رسمی اندروید)
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        final result = await Permission.ignoreBatteryOptimizations.request();
        if (result.isGranted) {
          print('✅ Battery optimization disabled via system dialog');
          return;
        }
      } else {
        print('✅ Already ignoring battery optimizations');
        return;
      }
    } catch (e) {
      print('⚠️ درخواست مستقیم باتری ناموفق: $e');
    }

    // روش ۲: باز کردن تنظیمات خود اپ (قابل اطمینان‌ترین راه)
    try {
      final opened = await openAppSettings();
      if (opened) {
        print('✅ App settings opened');
        return;
      }
    } catch (e) {
      print('⚠️ openAppSettings ناموفق: $e');
    }

    // روش ۳: fallback با url_launcher (package settings)
    try {
      final uri = Uri.parse('package:com.example.smart_agro_transport');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('⚠️ fallback url_launcher ناموفق: $e');
    }
  }

  // ============================================================
  // نمایش دیالوگ کامل آموزش خروج از Battery Optimization
  // ============================================================
  static Future<void> showBatteryOptimizationDialog(BuildContext context) async {
    final bool isIgnored = await isIgnoringBatteryOptimizations();

    if (isIgnored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ برنامه از Battery Optimization خارج شده است',
            style: TextStyle(fontFamily: 'Tahoma'),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.battery_alert, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ تنظیمات Battery Optimization',
                  style: TextStyle(fontFamily: 'Tahoma', fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'برای اینکه بکاپ خودکار به درستی کار کند، باید برنامه را از Battery Optimization خارج کنید.',
                  style: TextStyle(
                    fontFamily: 'Tahoma',
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📌 راهنمای گام‌به‌گام:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tahoma',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '۱. روی دکمه "رفتن به تنظیمات" کلیک کنید\n'
                            '۲. در صفحه تنظیمات، روی گزینه "باتری" بزنید\n'
                            '۳. گزینه "بهینه‌سازی مصرف باتری" را انتخاب کنید\n'
                            '۴. از لیست برنامه‌ها، "smart_agro_transport" را پیدا کنید\n'
                            '۵. گزینه "عدم بهینه‌سازی" را انتخاب کنید\n'
                            '۶. روی "تأیید" کلیک کنید\n\n'
                            '✅ پس از انجام، به برنامه برگردید و "تأیید" را بزنید',
                        style: TextStyle(
                          fontFamily: 'Tahoma',
                          fontSize: 13,
                          height: 1.8,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '💡 اگر گزینه "عدم بهینه‌سازی" را پیدا نکردید، از گزینه "همه برنامه‌ها" استفاده کنید.',
                          style: TextStyle(
                            fontFamily: 'Tahoma',
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // باز کردن تنظیمات باتری
                BatteryOptimizationHelper.openBatterySettings();
              },
              child: const Text(
                '⚙️ رفتن به تنظیمات',
                style: TextStyle(
                  fontFamily: 'Tahoma',
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'لغو',
                style: TextStyle(fontFamily: 'Tahoma', color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // درخواست مستقیم
                final bool result = await BatteryOptimizationHelper.requestIgnoreBatteryOptimizations();
                Navigator.pop(context);

                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '✅ برنامه از Battery Optimization خارج شد',
                        style: TextStyle(fontFamily: 'Tahoma'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // بررسی مجدد وضعیت
                  final bool isIgnoredNow = await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
                  if (isIgnoredNow) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ برنامه با موفقیت از Battery Optimization خارج شد',
                          style: TextStyle(fontFamily: 'Tahoma'),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '⚠️ لطفاً برنامه را به صورت دستی از Battery Optimization خارج کنید',
                          style: TextStyle(fontFamily: 'Tahoma'),
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              child: const Text(
                '✅ تأیید خروج',
                style: TextStyle(color: Colors.white, fontFamily: 'Tahoma'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // دیالوگ ساده برای درخواست خروج
  // ============================================================
  static Future<bool> showSimpleBatteryDialog(BuildContext context) async {
    final bool isIgnored = await isIgnoringBatteryOptimizations();
    if (isIgnored) return true;

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            '⚠️ تنظیمات باتری',
            style: TextStyle(fontFamily: 'Tahoma', fontSize: 18),
          ),
          content: const Text(
            'برای عملکرد صحیح بکاپ خودکار، برنامه باید از Battery Optimization خارج شود.\n\nآیا می‌خواهید به تنظیمات بروید؟',
            style: TextStyle(fontFamily: 'Tahoma', height: 1.6, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'نه، بعداً',
                style: TextStyle(fontFamily: 'Tahoma', color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                '✅ بله، برو به تنظیمات',
                style: TextStyle(color: Colors.white, fontFamily: 'Tahoma'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // اول درخواست مستقیم سیستم، بعد در صورت نیاز تنظیمات
      final granted = await requestIgnoreBatteryOptimizations();
      if (granted) return true;

      await openBatterySettings();
      // بعد از بازگشت از تنظیمات، وضعیت را بررسی کن
      final bool isIgnoredNow = await isIgnoringBatteryOptimizations();
      return isIgnoredNow;
    }

    return false;
  }

  // ============================================================
  // دیالوگ هشدار در زمان فعال‌سازی بکاپ
  // ============================================================
  static Future<void> showBackupWarningDialog(BuildContext context) async {
    final bool isIgnored = await isIgnoringBatteryOptimizations();

    if (isIgnored) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            '⚠️ هشدار بکاپ خودکار',
            style: TextStyle(fontFamily: 'Tahoma', fontSize: 18),
          ),
          content: const Text(
            'بکاپ خودکار ممکن است در پس‌زمینه به درستی کار نکند.\n\n'
                'برای اطمینان از عملکرد صحیح، برنامه را از Battery Optimization خارج کنید.',
            style: TextStyle(fontFamily: 'Tahoma', height: 1.6, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'بعداً',
                style: TextStyle(fontFamily: 'Tahoma', color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await showBatteryOptimizationDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                '🛠 تنظیمات',
                style: TextStyle(color: Colors.white, fontFamily: 'Tahoma'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}