import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../database/database_helper.dart';
import '../utils/backup_scheduler.dart';
import '../utils/battery_optimization_helper.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _autoBackup = true;
  String _selectedLanguage = 'فارسی';
  String _selectedCurrency = 'تومان';
  String _selectedWeightUnit = 'کیلوگرم';
  int _backupDays = 7;
  final String _appVersion = '1.0.0';
  bool _isLoading = true;
  bool _isSending = false;

  // ========== متغیرهای ایمیل ==========
  String _backupEmail = '';
  String _backupTime = '02:30';
  String _senderEmail = '';
  String _senderPassword = '';

  String _backupEmailStatus = 'بارگذاری...';
  Color _backupEmailColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    BackupScheduler.initialize(); // async, fire-and-forget
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('isDarkMode') ?? false;
        _autoBackup = prefs.getBool('autoBackup') ?? true;
        _selectedLanguage = prefs.getString('language') ?? 'فارسی';
        _selectedCurrency = prefs.getString('currency') ?? 'تومان';
        _selectedWeightUnit = prefs.getString('weightUnit') ?? 'کیلوگرم';
        _backupDays = prefs.getInt('backupDays') ?? 7;

        _backupEmail = prefs.getString('backup_email') ?? '';
        _backupTime = prefs.getString('backup_time') ?? '02:30';
        _senderEmail = prefs.getString('sender_email') ?? '';
        _senderPassword = prefs.getString('sender_password') ?? '';

        _isLoading = false;
      });
      await _refreshBackupEmailStatus();
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('خطا در بارگذاری تنظیمات');
    }
  }

  Future<void> _refreshBackupEmailStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('backup_email') ?? '';
    final enabled = prefs.getBool('backup_enabled') ?? false;

    setState(() {
      if (enabled && email.isNotEmpty && email.contains('@')) {
        _backupEmailStatus = '✅ فعال — ایمیل: $email';
        _backupEmailColor = const Color(0xFF2E7D32);
      } else if (email.isNotEmpty && email.contains('@')) {
        _backupEmailStatus = '⚠️ ایمیل تنظیم شده (بکاپ خاموش)';
        _backupEmailColor = const Color(0xFFF57C00);
      } else {
        _backupEmailStatus = '❌ ایمیل بکاپ تنظیم نشده';
        _backupEmailColor = const Color(0xFFC62828);
      }
    });
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setBool('autoBackup', _autoBackup);
      await prefs.setString('language', _selectedLanguage);
      await prefs.setString('currency', _selectedCurrency);
      await prefs.setString('weightUnit', _selectedWeightUnit);
      await prefs.setInt('backupDays', _backupDays);

      await prefs.setString('backup_email', _backupEmail);
      await prefs.setString('backup_time', _backupTime);
      await prefs.setString('sender_email', _senderEmail);
      await prefs.setString('sender_password', _senderPassword);

      if (_autoBackup && _backupEmail.isNotEmpty && _backupEmail.contains('@')) {
        await prefs.setBool('backup_enabled', true);
        await BackupScheduler.scheduleCustomBackup(
          email: _backupEmail,
          time: _backupTime,
          intervalDays: _backupDays,
        );
      } else {
        await prefs.setBool('backup_enabled', false);
        await BackupScheduler.cancelBackup();
      }

      _showToast('✅ تنظیمات با موفقیت ذخیره شد');
    } catch (e) {
      _showToast('❌ خطا در ذخیره تنظیمات: $e');
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Tahoma', fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        backgroundColor: message.contains('✅')
            ? const Color(0xFF2E7D32)
            : message.contains('❌')
                ? const Color(0xFFC62828)
                : null,
      ),
    );
  }

  // ============================================================
  // دیالوگ تنظیمات ایمیل بکاپ
  // ============================================================
  Future<void> _showBackupEmailDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final emailCtrl = TextEditingController(text: _backupEmail);
    final senderEmailCtrl = TextEditingController(text: _senderEmail);
    final senderPassCtrl = TextEditingController(text: _senderPassword);
    String selectedTime = _backupTime;
    bool isBusy = false;
    String? dialogMessage;
    bool isError = false;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void showDialogMsg(String msg, {bool error = true}) {
              setDialogState(() {
                dialogMessage = msg;
                isError = error;
              });
            }

            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text(
                  '📧 تنظیمات بکاپ خودکار',
                  style: TextStyle(fontFamily: 'Tahoma', fontSize: 18),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📤 ایمیل فرستنده (Gmail)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tahoma',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: senderEmailCtrl,
                        enabled: !isBusy,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'your-email@gmail.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.send, color: Colors.blue),
                          helperText: 'ایمیلی که بکاپ از آن ارسال شود',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '🔑 App Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tahoma',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: senderPassCtrl,
                        enabled: !isBusy,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'xxxx xxxx xxxx xxxx',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.vpn_key, color: Colors.orange),
                          helperText:
                              '۱۶ کاراکتری — فاصله‌ها خودکار حذف می‌شوند',
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: isBusy
                              ? null
                              : () async {
                                  final uri = Uri.parse(
                                      'https://myaccount.google.com/apppasswords');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    showDialogMsg(
                                      '❌ نتوانست لینک را باز کند\nCould not open the link',
                                    );
                                  }
                                },
                          icon: const Icon(Icons.open_in_new,
                              size: 16, color: Colors.blue),
                          label: const Text(
                            'ساخت App Password در گوگل',
                            style: TextStyle(
                              color: Colors.blue,
                              fontFamily: 'Tahoma',
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '📧 ایمیل گیرنده بکاپ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tahoma',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: emailCtrl,
                        enabled: !isBusy,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'receiver@gmail.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email, color: Colors.green),
                          helperText: 'ایمیلی که فایل بکاپ به آن ارسال شود',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '⏰ ساعت ارسال بکاپ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tahoma',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildTimePicker(
                        context,
                        selectedTime,
                        (time) =>
                            setDialogState(() => selectedTime = time),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📌 راهنما:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tahoma',
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• ایمیل فرستنده باید Gmail باشد\n'
                              '• تأیید دو مرحله‌ای گوگل را فعال کنید\n'
                              '• از لینک بالا App Password بسازید\n'
                              '• فاصله‌های App Password خودکار حذف می‌شوند\n'
                              '• اول «ارسال تست» را امتحان کنید',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontFamily: 'Tahoma',
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (dialogMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isError
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isError
                                  ? Colors.red.shade300
                                  : Colors.green.shade300,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isBusy)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                )
                              else
                                Icon(
                                  isError
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline,
                                  color: isError
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                  size: 20,
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dialogMessage!,
                                  style: TextStyle(
                                    fontFamily: 'Tahoma',
                                    fontSize: 12.5,
                                    height: 1.45,
                                    color: isError
                                        ? Colors.red.shade800
                                        : Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () async {
                            final email = emailCtrl.text.trim();
                            final senderEmail =
                                senderEmailCtrl.text.trim();
                            final senderPass = senderPassCtrl.text
                                .replaceAll(' ', '')
                                .replaceAll('\u00A0', '')
                                .trim();

                            if (senderEmail.isEmpty ||
                                !senderEmail.contains('@')) {
                              showDialogMsg(
                                  '❌ ایمیل فرستنده معتبر نیست\nInvalid sender email');
                              return;
                            }
                            if (senderPass.length < 10) {
                              showDialogMsg(
                                  '❌ App Password باید ۱۶ کاراکتر باشد\nApp Password must be 16 characters');
                              return;
                            }
                            if (email.isEmpty || !email.contains('@')) {
                              showDialogMsg(
                                  '❌ ایمیل گیرنده معتبر نیست\nInvalid receiver email');
                              return;
                            }

                            await prefs.setString(
                                'sender_email', senderEmail);
                            await prefs.setString(
                                'sender_password', senderPass);

                            setDialogState(() {
                              isBusy = true;
                              dialogMessage =
                                  '⏳ در حال ارسال ایمیل تست...\nSending test email...';
                              isError = false;
                            });

                            final result = await BackupScheduler
                                .sendTestEmail(email);

                            setDialogState(() {
                              isBusy = false;
                              dialogMessage = result.contains('✅')
                                  ? '$result\nTest email sent successfully'
                                  : result;
                              isError = !result.contains('✅');
                            });
                          },
                    child: const Text(
                      '📤 ارسال تست',
                      style:
                          TextStyle(color: Colors.blue, fontFamily: 'Tahoma'),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        isBusy ? null : () => Navigator.pop(ctx),
                    child: const Text('انصراف',
                        style: TextStyle(fontFamily: 'Tahoma')),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isBusy
                        ? null
                        : () async {
                            final email = emailCtrl.text.trim();
                            final senderEmail =
                                senderEmailCtrl.text.trim();
                            final senderPass = senderPassCtrl.text
                                .replaceAll(' ', '')
                                .replaceAll('\u00A0', '')
                                .trim();

                            if (email.isEmpty || !email.contains('@')) {
                              showDialogMsg(
                                  '❌ ایمیل گیرنده معتبر نیست\nInvalid receiver email');
                              return;
                            }
                            if (senderEmail.isEmpty ||
                                !senderEmail.contains('@')) {
                              showDialogMsg(
                                  '❌ ایمیل فرستنده معتبر نیست\nInvalid sender email');
                              return;
                            }
                            if (senderPass.length < 10) {
                              showDialogMsg(
                                  '❌ App Password باید ۱۶ کاراکتر باشد (بدون فاصله)\nApp Password must be 16 characters');
                              return;
                            }

                            setDialogState(() {
                              isBusy = true;
                              dialogMessage =
                                  '⏳ در حال ذخیره تنظیمات...\nSaving settings...';
                              isError = false;
                            });

                            try {
                              setState(() {
                                _backupEmail = email;
                                _backupTime = selectedTime;
                                _senderEmail = senderEmail;
                                _senderPassword = senderPass;
                              });

                              await prefs.setString(
                                  'backup_email', email);
                              await prefs.setString(
                                  'backup_time', selectedTime);
                              await prefs.setString(
                                  'sender_email', senderEmail);
                              await prefs.setString(
                                  'sender_password', senderPass);

                              if (_autoBackup) {
                                await prefs.setBool(
                                    'backup_enabled', true);
                                await BackupScheduler
                                    .scheduleCustomBackup(
                                  email: email,
                                  time: selectedTime,
                                  intervalDays: _backupDays,
                                );
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              _refreshBackupEmailStatus();
                              Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () {
                                if (mounted) {
                                  _showToast(
                                      '✅ تنظیمات ایمیل با موفقیت ذخیره شد');
                                }
                              });
                            } catch (e) {
                              setDialogState(() {
                                isBusy = false;
                                dialogMessage =
                                    '❌ خطا در ذخیره: $e\nSave error: $e';
                                isError = true;
                              });
                            }
                          },
                    child: isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'ذخیره',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Tahoma'),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ویجت انتخاب ساعت
  // ============================================================
  Widget _buildTimePicker(
      BuildContext context,
      String currentTime,
      Function(String) onChanged,
      ) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _parseTime(currentTime),
          builder: (context, child) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: child!,
            );
          },
        );
        if (picked != null) {
          final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onChanged(timeStr);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              currentTime,
              style: const TextStyle(fontSize: 16, fontFamily: 'Tahoma'),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 2;
    final minute = int.tryParse(parts[1]) ?? 30;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // ============================================================
  // ارسال بکاپ دستی
  // ============================================================
  Future<void> _sendManualBackup() async {
    if (_isSending) return;

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('backup_email') ?? '';

    if (email.isEmpty || !email.contains('@')) {
      _showToast('❌ ابتدا ایمیل گیرنده را در تنظیمات وارد کنید');
      return;
    }

    setState(() => _isSending = true);
    _showToast('⏳ در حال آماده‌سازی بکاپ...');

    final result = await BackupScheduler.performManualBackup(email: email);

    setState(() => _isSending = false);
    _showToast(result);
  }

  // ============================================================
  // تغییر رمز عبور
  // ============================================================
  Future<void> _showChangePasswordDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUser = prefs.getString('last_username') ?? 'admin';

    final userCtrl = TextEditingController(text: lastUser);
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            '🔑 تغییر رمز عبور',
            style: TextStyle(fontFamily: 'Tahoma'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'نام کاربری',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: oldCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'رمز فعلی',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'رمز جدید (حداقل ۶ کاراکتر)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'تکرار رمز جدید',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Tahoma')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
              onPressed: () async {
                final user = userCtrl.text.trim();
                final oldP = oldCtrl.text.trim();
                final newP = newCtrl.text.trim();
                final conf = confirmCtrl.text.trim();

                if (user.isEmpty) {
                  _showToast('نام کاربری را وارد کنید');
                  return;
                }
                if (newP.length < 6) {
                  _showToast('رمز جدید باید حداقل ۶ کاراکتر باشد');
                  return;
                }
                if (newP != conf) {
                  _showToast('رمز جدید و تکرار آن یکسان نیستند');
                  return;
                }
                if (newP == '123') {
                  _showToast('رمز ضعیف است. رمز قوی‌تری انتخاب کنید');
                  return;
                }

                try {
                  final db = await DatabaseHelper.instance.database;
                  final result = await db.query(
                    'users',
                    where: 'username = ? AND password = ?',
                    whereArgs: [user, oldP],
                  );

                  if (result.isEmpty) {
                    _showToast('رمز فعلی اشتباه است یا کاربر یافت نشد');
                    return;
                  }

                  await db.update(
                    'users',
                    {'password': newP},
                    where: 'username = ?',
                    whereArgs: [user],
                  );

                  await prefs.setString('last_username', user);
                  await prefs.setBool('force_password_change', false);

                  if (ctx.mounted) Navigator.pop(ctx);
                  _showToast('✅ رمز عبور با موفقیت تغییر کرد');
                } catch (e) {
                  _showToast('❌ خطا: $e');
                }
              },
              child: const Text(
                'ذخیره',
                style: TextStyle(color: Colors.white, fontFamily: 'Tahoma'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('⚠️ بازنشانی تنظیمات'),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید همه تنظیمات را به حالت پیش‌فرض برگردانید؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو', style: TextStyle(fontFamily: 'Tahoma')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isDarkMode = false;
                  _autoBackup = true;
                  _selectedLanguage = 'فارسی';
                  _selectedCurrency = 'تومان';
                  _selectedWeightUnit = 'کیلوگرم';
                  _backupDays = 7;
                  _backupEmail = '';
                  _backupTime = '02:30';
                  _senderEmail = '';
                  _senderPassword = '';
                });
                _saveSettings();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'بازنشانی',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ویجت‌های نمایشی
  // ============================================================
  Widget _buildSection(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green[700]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.green[700]),
        title: Text(title, style: const TextStyle(fontFamily: 'Tahoma')),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green[700],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[700]),
        title: Text(title, style: const TextStyle(fontFamily: 'Tahoma')),
        trailing: DropdownButton<String>(
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontFamily: 'Tahoma')),
            ),
          )
              .toList(),
          onChanged: onChanged,
          underline: const SizedBox(),
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green[700]),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontFamily: 'Tahoma')),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${value.toInt()} روز',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                      fontFamily: 'Tahoma',
                    ),
                  ),
                ),
              ],
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              activeColor: Colors.green[700],
              label: '${value.toInt()} روز',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[700]),
        title: Text(title, style: const TextStyle(fontFamily: 'Tahoma')),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: subtitleColor ?? Colors.grey,
            fontFamily: 'Tahoma',
          ),
        ),
        trailing: const Icon(Icons.chevron_left, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[700]),
        title: Text(title, style: const TextStyle(fontFamily: 'Tahoma')),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Tahoma')),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontFamily: 'Tahoma',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: value.contains('تنظیم نشده') ? Colors.red : Colors.green[700],
              fontFamily: 'Tahoma',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Build اصلی
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('⚙️ تنظیمات'),
          backgroundColor: Colors.green[800],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _isDarkMode ? Colors.grey[900] : const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            '⚙️ تنظیمات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green[800],
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'ذخیره تنظیمات',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ========== بخش امنیت ==========
              _buildSection('🔒 امنیت', Icons.security),
              _buildButtonTile(
                icon: Icons.lock,
                title: 'تغییر رمز عبور',
                subtitle: 'نام کاربری و رمز ورود به برنامه',
                onTap: _showChangePasswordDialog,
              ),

              const Divider(),

              // ========== بخش بکاپ ==========
              _buildSection('💾 پشتیبان‌گیری خودکار', Icons.backup),

              _buildButtonTile(
                icon: Icons.email,
                title: '📧 تنظیمات ایمیل بکاپ',
                subtitle: _backupEmailStatus,
                subtitleColor: _backupEmailColor,
                onTap: _showBackupEmailDialog,
              ),

              const SizedBox(height: 8),

              // ========== نمایش تنظیمات فعلی ==========
              Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildInfoRow('⏰ ساعت ارسال', _backupTime),
                      _buildInfoRow('📧 ایمیل گیرنده', _backupEmail.isNotEmpty ? _backupEmail : 'تنظیم نشده'),
                      _buildInfoRow('📤 ایمیل فرستنده', _senderEmail.isNotEmpty ? _senderEmail : 'تنظیم نشده'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ========== دکمه ارسال بکاپ دستی ==========
              _buildButtonTile(
                icon: Icons.send,
                title: '📤 ارسال بکاپ دستی',
                subtitle: _isSending
                    ? '⏳ در حال ارسال...'
                    : 'ارسال فایل پشتیبان به ایمیل تنظیم شده',
                subtitleColor: _isSending ? Colors.orange : null,
                onTap: _sendManualBackup,
              ),

              // ========== اسلایدر دوره بکاپ ==========
              _buildSliderTile(
                icon: Icons.calendar_today,
                title: 'دوره پشتیبان‌گیری',
                subtitle: 'بکاپ هر چند روز یک بار ارسال شود',
                value: _backupDays.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                onChanged: (value) => setState(() => _backupDays = value.toInt()),
              ),

              const Divider(),

              // ========== بخش تنظیمات باتری ==========
              _buildSection('🔋 بهینه‌سازی باتری', Icons.battery_alert),
              _buildButtonTile(
                icon: Icons.battery_alert,
                title: 'تنظیمات Battery Optimization',
                subtitle: 'برای عملکرد صحیح بکاپ خودکار',
                onTap: () async {
                  await BatteryOptimizationHelper.showBatteryOptimizationDialog(context);
                },
              ),

              const Divider(),

              // ========== تنظیمات برنامه ==========
              _buildSection('⚙️ تنظیمات برنامه', Icons.settings),
              _buildSwitchTile(
                icon: Icons.dark_mode,
                title: 'حالت تاریک',
                subtitle: 'استفاده از تم تیره در برنامه',
                value: _isDarkMode,
                onChanged: (value) async {
                  setState(() => _isDarkMode = value);
                  MyApp.of(context)?.changeTheme(value);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isDarkMode', value);
                },
              ),
              _buildDropdownTile(
                icon: Icons.language,
                title: 'زبان برنامه',
                value: _selectedLanguage,
                items: const ['فارسی', 'English', 'العربية'],
                onChanged: (value) => setState(() => _selectedLanguage = value!),
              ),
              _buildDropdownTile(
                icon: Icons.currency_exchange,
                title: 'واحد پول',
                value: _selectedCurrency,
                items: const ['تومان', 'ریال', 'دلار', 'یورو'],
                onChanged: (value) => setState(() => _selectedCurrency = value!),
              ),
              _buildDropdownTile(
                icon: Icons.scale,
                title: 'واحد وزن',
                value: _selectedWeightUnit,
                items: const ['کیلوگرم', 'گرم', 'تن'],
                onChanged: (value) => setState(() => _selectedWeightUnit = value!),
              ),

              const Divider(),

              // ========== اطلاعات برنامه ==========
              _buildSection('📱 اطلاعات برنامه', Icons.info),
              _buildInfoTile(
                icon: Icons.android,
                title: 'نسخه برنامه',
                subtitle: _appVersion,
              ),
              _buildInfoTile(
                icon: Icons.calendar_today,
                title: 'تاریخ ساخت',
                subtitle: '۱۴۰۴/۰۵/۲۳',
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _resetToDefault,
                icon: const Icon(Icons.restore),
                label: const Text('بازنشانی به تنظیمات پیش‌فرض'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[800],
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}