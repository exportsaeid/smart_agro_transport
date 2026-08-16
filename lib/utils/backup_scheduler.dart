// lib/utils/backup_scheduler.dart
import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class BackupScheduler {
  static const String _taskName = 'backupTask';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      _initialized = true;
      print('✅ Workmanager initialized');
    } catch (e) {
      print('⚠️ Workmanager initialize failed: $e');
    }
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == _taskName) {
        await _performBackup();
      }
      return Future.value(true);
    });
  }

  static Future<void> scheduleCustomBackup({
    required String email,
    required String time,
    required int intervalDays,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('backup_enabled') ?? false;

    await prefs.setString('backup_email', email);
    await prefs.setInt('backup_interval_days', intervalDays);
    await prefs.setString('backup_time', time);

    if (!enabled || email.isEmpty || !email.contains('@')) {
      try {
        await Workmanager().cancelByUniqueName(_taskName);
      } catch (_) {}
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 2;
    final minute = int.tryParse(timeParts[1]) ?? 30;

    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: intervalDays));
    }

    final initialDelay = scheduledTime.difference(now).inSeconds;
    final frequency = Duration(days: intervalDays < 1 ? 1 : intervalDays);

    try {
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: frequency,
        initialDelay: Duration(seconds: initialDelay > 0 ? initialDelay : 60),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
        // ✅ اصلاح شده برای workmanager 0.10+
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
      print('📅 بکاپ زمان‌بندی شد: هر $intervalDays روز در ساعت $time');
    } catch (e) {
      print('⚠️ خطا در زمان‌بندی Workmanager: $e');
      try {
        await Workmanager().registerOneOffTask(
          '${_taskName}_once',
          _taskName,
          initialDelay: Duration(seconds: initialDelay > 0 ? initialDelay : 60),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
        print('📅 بکاپ یک‌باره زمان‌بندی شد (fallback)');
      } catch (e2) {
        print('⚠️ fallback هم ناموفق: $e2');
      }
    }
  }

  static Future<void> _performBackup() async {
    try {
      print('📦 شروع بکاپ خودکار...');
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('backup_email') ?? '';

      if (email.isEmpty || !email.contains('@')) {
        print('❌ ایمیل تنظیم نشده است');
        return;
      }

      final zipPath = await _createBackupZip();
      if (zipPath == null) {
        print('❌ ایجاد فایل بکاپ ناموفق');
        return;
      }

      final result = await _sendBackupEmail(File(zipPath), email);
      print('📧 نتیجه ارسال: $result');

      try {
        await File(zipPath).delete();
      } catch (_) {}
    } catch (e) {
      print('❌ خطا در بکاپ خودکار: $e');
    }
  }

  static Future<String?> _createBackupZip() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      final zipPath = p.join(tempDir.path, 'backup_$timeStamp.zip');

      final tempFolder = Directory(p.join(tempDir.path, 'temp_backup_$timeStamp'));
      if (await tempFolder.exists()) {
        await tempFolder.delete(recursive: true);
      }
      await tempFolder.create(recursive: true);

      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, 'invoice_db.db'));
      if (await dbFile.exists()) {
        await dbFile.copy(p.join(tempFolder.path, 'invoice_db.db'));
        print('✅ دیتابیس کپی شد');
      }

      for (var ext in ['-wal', '-shm', '-journal']) {
        final companion = File(dbFile.path + ext);
        if (await companion.exists()) {
          await companion.copy(p.join(tempFolder.path, 'invoice_db.db$ext'));
        }
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(appDocDir.path, 'invoice_attachments'));
      if (await attachmentsDir.exists()) {
        final attBackupDir = Directory(p.join(tempFolder.path, 'attachments'));
        await attBackupDir.create();
        await for (var entity in attachmentsDir.list(recursive: false)) {
          if (entity is File) {
            await entity.copy(p.join(attBackupDir.path, p.basename(entity.path)));
          }
        }
        print('✅ پیوست‌ها کپی شدند');
      }

      final infoFile = File(p.join(tempFolder.path, 'backup_info.txt'));
      final intervalDays = (await SharedPreferences.getInstance()).getInt('backup_interval_days') ?? 7;
      await infoFile.writeAsString(
        '📦 اطلاعات بکاپ\n'
            '═══════════════════════════════════\n'
            '📅 تاریخ: ${DateTime.now()}\n'
            '⏰ ساعت: ${DateTime.now().hour}:${DateTime.now().minute}\n'
            '📱 نسخه برنامه: 1.0.0\n'
            '🔄 دوره بکاپ: هر $intervalDays روز\n'
            '═══════════════════════════════════\n'
            'این بکاپ به صورت خودکار ارسال شده است.',
      );

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addDirectory(tempFolder);
      encoder.close();

      await tempFolder.delete(recursive: true);

      print('✅ فایل ZIP ایجاد شد: $zipPath');
      return zipPath;
    } catch (e) {
      print('❌ خطا در ایجاد ZIP: $e');
      return null;
    }
  }

  static Future<String> _sendBackupEmail(File zipFile, String receiver) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final senderEmail = (prefs.getString('sender_email') ?? '').trim();
      final senderPassword = (prefs.getString('sender_password') ?? '')
          .replaceAll(' ', '')
          .replaceAll('\u00A0', '')
          .trim();

      if (senderEmail.isEmpty || !senderEmail.contains('@')) {
        return '❌ ایمیل فرستنده تنظیم نشده است.\nلطفاً در تنظیمات ایمیل فرستنده را وارد کنید.';
      }

      if (senderPassword.isEmpty || senderPassword.length < 10) {
        return '❌ App Password تنظیم نشده یا ناقص است.\n'
            'باید ۱۶ کاراکتری باشد (بدون فاصله).\n'
            'از تنظیمات گوگل → Security → App passwords بگیرید.';
      }

      final fileName = p.basename(zipFile.path);
      final fileSize = await zipFile.length();
      final intervalDays = prefs.getInt('backup_interval_days') ?? 7;

      final message = Message()
        ..from = Address(senderEmail, 'Smart Agro Transport')
        ..recipients.add(receiver)
        ..subject = '📦 بکاپ خودکار - ${DateTime.now().toIso8601String().substring(0, 10)}'
        ..text = '''
سلام،

فایل پشتیبان کامل برنامه "حمل و نقل هوشمند کشاورزی" به صورت خودکار ارسال شده است.

📋 جزئیات بکاپ:
═══════════════════════════════════
📅 تاریخ: ${DateTime.now()}
⏰ ساعت: ${DateTime.now().hour}:${DateTime.now().minute}
📁 نام فایل: $fileName
📦 حجم فایل: ${(fileSize / 1024).toStringAsFixed(2)} KB
🔄 دوره بکاپ: هر $intervalDays روز
═══════════════════════════════════

✅ محتویات بکاپ:
• تمام فاکتورها و آیتم‌ها
• اطلاعات بارگیری‌ها
• اطلاعات ترخیص‌ها (ایران و عراق)
• اطلاعات تحویل به خریدار
• فایل‌های پیوست
• تمام داده‌های برنامه

📌 نکته: این فایل شامل تمام اطلاعات شماست.
برای بازیابی، از گزینه "بازگردانی اطلاعات" در برنامه استفاده کنید.

با تشکر
سیستم پشتیبان‌گیری خودکار
''';

      final attachment = FileAttachment(zipFile)
        ..location = Location.attachment
        ..fileName = fileName;
      message.attachments.add(attachment);

      try {
        await _sendWithFallback(message, senderEmail, senderPassword);
        print('✅ ایمیل ارسال شد به: $receiver');
        return '✅ بکاپ با موفقیت ارسال شد به:\n$receiver';
      } catch (e) {
        return _friendlySmtpError(e);
      }
    } on MailerException catch (e) {
      print('❌ MailerException: $e');
      return _friendlySmtpError(e);
    } catch (e) {
      return _friendlySmtpError(e);
    }
  }

  static Future<void> _sendWithFallback(Message message, String senderEmail, String senderPassword) async {
    final attempts = <Map<String, dynamic>>[
      {
        'name': 'gmail() helper',
        'server': () => gmail(senderEmail, senderPassword),
      },
      {
        'name': '587 STARTTLS',
        'server': () => SmtpServer(
          'smtp.gmail.com',
          port: 587,
          username: senderEmail,
          password: senderPassword,
          ssl: false,
          allowInsecure: false,
        ),
      },
      {
        'name': '465 SSL',
        'server': () => SmtpServer(
          'smtp.gmail.com',
          port: 465,
          username: senderEmail,
          password: senderPassword,
          ssl: true,
          allowInsecure: false,
        ),
      },
      {
        'name': '587 allowInsecure',
        'server': () => SmtpServer(
          'smtp.gmail.com',
          port: 587,
          username: senderEmail,
          password: senderPassword,
          ssl: false,
          allowInsecure: true,
        ),
      },
    ];

    Object? lastError;
    for (final attempt in attempts) {
      try {
        final server = (attempt['server'] as SmtpServer Function())();
        await send(message, server);
        print('✅ SMTP موفق با روش: ${attempt['name']}');
        return;
      } catch (e) {
        print('⚠️ SMTP ناموفق (${attempt['name']}): $e');
        lastError = e;
      }
    }
    throw lastError ?? Exception('تمام روش‌های SMTP ناموفق بودند');
  }

  static String _friendlySmtpError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('handshake') || s.contains('certificate') || s.contains('ssl') || s.contains('tls')) {
      return '❌ خطای اتصال امن (SSL/TLS)\n'
          'Connection terminated during handshake\n\n'
          'احتمال‌ها / Possible causes:\n'
          '۱. اینترنت یا فیلتر شبکه پورت SMTP را بسته\n'
          '   Network/firewall blocking Gmail SMTP\n'
          '۲. نیاز به VPN (مخصوصاً در بعضی کشورها)\n'
          '   Try enabling VPN\n'
          '۳. آنتی‌ویروس/فایروال گوشی\n'
          '   Check phone antivirus/firewall\n'
          '۴. دوباره با اینترنت دیگر امتحان کنید\n'
          '   Try another network (mobile data/WiFi)';
    }
    if (s.contains('timeout') || s.contains('timed out')) {
      return '❌ اتصال قطع شد (Timeout)\n'
          'Connection timed out\n\n'
          'اینترنت ضعیف است یا SMTP مسدود شده.\n'
          'Weak internet or SMTP blocked. Try VPN.';
    }
    if (s.contains('authentication') || s.contains('username') || s.contains('password') || s.contains('535')) {
      return '❌ احراز هویت ناموفق / Authentication failed\n\n'
          '۱. تأیید دو مرحله‌ای گوگل فعال باشد\n'
          '۲. App Password جدید ۱۶ کاراکتری بسازید\n'
          '۳. فاصله‌ها را حذف کنید\n'
          '۴. ایمیل فرستنده درست باشد';
    }
    if (s.contains('socket') || s.contains('connection refused') || s.contains('network')) {
      return '❌ مشکل شبکه / Network error\n'
          '$e\n\n'
          'اینترنت را چک کنید یا VPN بزنید.';
    }
    return '❌ خطا / Error:\n$e';
  }

  static Future<String> sendTestEmail(String receiver) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final senderEmail = (prefs.getString('sender_email') ?? '').trim();
      final senderPassword = (prefs.getString('sender_password') ?? '')
          .replaceAll(' ', '')
          .replaceAll('\u00A0', '')
          .trim();

      if (senderEmail.isEmpty || !senderEmail.contains('@')) {
        return '❌ ایمیل فرستنده تنظیم نشده است.\nلطفاً تنظیمات را کامل کنید.';
      }

      if (senderPassword.isEmpty || senderPassword.length < 10) {
        return '❌ App Password تنظیم نشده یا ناقص است.\n'
            'باید ۱۶ کاراکتری باشد (بدون فاصله).\n'
            'از تنظیمات گوگل → Security → App passwords بگیرید.';
      }

      final message = Message()
        ..from = Address(senderEmail, 'Smart Agro Transport')
        ..recipients.add(receiver)
        ..subject = '📧 ایمیل تست - سیستم بکاپ خودکار'
        ..text = '''
سلام،

این یک ایمیل تست از سیستم بکاپ خودکار برنامه "حمل و نقل هوشمند کشاورزی" است.

✅ تنظیمات ایمیل شما به درستی انجام شده است.

📅 زمان ارسال: ${DateTime.now()}

با تشکر
سیستم پشتیبان‌گیری خودکار
''';

      try {
        await _sendWithFallback(message, senderEmail, senderPassword);
        return '✅ ایمیل تست با موفقیت ارسال شد به:\n$receiver\nTest email sent successfully';
      } catch (e) {
        return _friendlySmtpError(e);
      }
    } on MailerException catch (e) {
      return _friendlySmtpError(e);
    } catch (e) {
      return _friendlySmtpError(e);
    }
  }

  static Future<void> cancelBackup() async {
    try {
      await Workmanager().cancelByUniqueName(_taskName);
      await Workmanager().cancelByUniqueName('${_taskName}_once');
      print('⏹️ زمان‌بندی بکاپ لغو شد');
    } catch (e) {
      print('⚠️ خطا در لغو زمان‌بندی: $e');
    }
  }

  static Future<String> performManualBackup({required String email}) async {
    try {
      if (email.isEmpty || !email.contains('@')) {
        return '❌ ایمیل معتبر نیست';
      }

      final zipPath = await _createBackupZip();
      if (zipPath == null) {
        return '❌ خطا در ایجاد فایل بکاپ';
      }

      final result = await _sendBackupEmail(File(zipPath), email);
      try {
        await File(zipPath).delete();
      } catch (_) {}
      return result;
    } catch (e) {
      return '❌ خطا / Error: $e';
    }
  }
}
