import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class EmailBackupService {
  static Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    final sender = prefs.getString('backup_sender_email') ?? '';
    final pass = prefs.getString('backup_app_password') ?? '';
    final receiver = prefs.getString('backup_receiver_email') ?? '';
    final enabled = prefs.getBool('backup_enabled') ?? false;

    return enabled &&
        sender.contains('@') &&
        pass.isNotEmpty &&
        receiver.contains('@');
  }

  /// ساخت سرور SMTP پایدارتر برای Gmail
  static SmtpServer _buildSmtpServer(String sender, String appPassword) {
    // روش ۱: پورت 587 با STARTTLS (معمولاً بهتر کار می‌کند)
    return SmtpServer(
      'smtp.gmail.com',
      port: 587,
      username: sender,
      password: appPassword,
      ssl: false,
      allowInsecure: false,
    );
  }

  /// ارسال فایل ZIP بکاپ به ایمیل گیرنده
  static Future<String> sendBackupFile(File zipFile) async {
    try {
      if (!await zipFile.exists()) {
        return '❌ فایل بکاپ پیدا نشد';
      }

      final prefs = await SharedPreferences.getInstance();
      final sender = (prefs.getString('backup_sender_email') ?? '').trim();
      final appPassword = (prefs.getString('backup_app_password') ?? '')
          .replaceAll(' ', '')
          .trim();
      final receiver =
      (prefs.getString('backup_receiver_email') ?? '').trim();
      final enabled = prefs.getBool('backup_enabled') ?? false;

      if (!enabled) {
        return '⚠️ بکاپ ایمیلی غیرفعال است (از تنظیمات فعال کنید)';
      }
      if (!sender.contains('@') ||
          appPassword.isEmpty ||
          !receiver.contains('@')) {
        return '❌ تنظیمات ایمیل ناقص است';
      }

      final smtpServer = _buildSmtpServer(sender, appPassword);

      final message = Message()
        ..from = Address(sender, 'Smart Agro Transport')
        ..recipients.add(receiver)
        ..subject =
            'بکاپ برنامه — ${DateTime.now().toString().substring(0, 19)}'
        ..text =
            'فایل پشتیبان دیتابیس و پیوست‌ها به صورت خودکار ارسال شده است.\n'
            'نام فایل: ${p.basename(zipFile.path)}'
        ..attachments = [
          FileAttachment(zipFile)
            ..location = Location.attachment
            ..fileName = p.basename(zipFile.path),
        ];

      // یک بار تلاش با پورت 587
      try {
        final sendReport = await send(message, smtpServer);
        print('📧 ایمیل ارسال شد: $sendReport');
        return '✅ بکاپ با ایمیل ارسال شد به:\n$receiver';
      } catch (e) {
        print('⚠️ تلاش اول ناموفق: $e — تلاش با پورت 465');

        // تلاش دوم با پورت 465 (SSL)
        final smtpSsl = SmtpServer(
          'smtp.gmail.com',
          port: 465,
          username: sender,
          password: appPassword,
          ssl: true,
        );

        final sendReport = await send(message, smtpSsl);
        print('📧 ایمیل ارسال شد (SSL): $sendReport');
        return '✅ بکاپ با ایمیل ارسال شد به:\n$receiver';
      }
    } on MailerException catch (e) {
      print('❌ MailerException: $e');
      for (final p in e.problems) {
        print('  - ${p.code}: ${p.msg}');
      }
      return '❌ خطا در ارسال ایمیل:\n${e.message}';
    } catch (e) {
      return '❌ خطا در ارسال ایمیل: $e';
    }
  }

  /// تست ساده ارسال ایمیل (بدون فایل)
  static Future<String> sendTestEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sender = (prefs.getString('backup_sender_email') ?? '').trim();
      final appPassword = (prefs.getString('backup_app_password') ?? '')
          .replaceAll(' ', '')
          .trim();
      final receiver =
      (prefs.getString('backup_receiver_email') ?? '').trim();

      if (!sender.contains('@') ||
          appPassword.isEmpty ||
          !receiver.contains('@')) {
        return '❌ تنظیمات ایمیل ناقص است';
      }

      final smtpServer = _buildSmtpServer(sender, appPassword);

      final message = Message()
        ..from = Address(sender, 'Smart Agro Transport')
        ..recipients.add(receiver)
        ..subject = 'تست ایمیل بکاپ — Smart Agro'
        ..text = 'این یک ایمیل تست است. اگر دریافت کردید، تنظیمات درست است.';

      try {
        await send(message, smtpServer);
        return '✅ ایمیل تست با موفقیت ارسال شد';
      } catch (e) {
        print('⚠️ تست با 587 ناموفق: $e');

        final smtpSsl = SmtpServer(
          'smtp.gmail.com',
          port: 465,
          username: sender,
          password: appPassword,
          ssl: true,
        );
        await send(message, smtpSsl);
        return '✅ ایمیل تست با موفقیت ارسال شد (SSL)';
      }
    } on MailerException catch (e) {
      return '❌ خطا در ارسال ایمیل تست:\n${e.message}';
    } catch (e) {
      return '❌ خطا در ارسال ایمیل تست: $e';
    }
  }
}