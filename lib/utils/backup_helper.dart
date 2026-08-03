import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class BackupHelper {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ========== ایجاد بکاپ ==========
  Future<String?> createBackup() async {
    try {
      // دریافت مسیر دیتابیس
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/smart_agro.db');

      if (!dbFile.existsSync()) {
        return null;
      }

      // ایجاد پوشه بکاپ
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      if (!backupDir.existsSync()) {
        await backupDir.create(recursive: true);
      }

      // نام فایل بکاپ با تاریخ
      final now = DateTime.now();
      final fileName = 'backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.db';
      final backupFile = File('${backupDir.path}/$fileName');

      // کپی فایل دیتابیس
      await dbFile.copy(backupFile.path);

      return backupFile.path;
    } catch (e) {
      print('❌ خطا در ایجاد بکاپ: $e');
      return null;
    }
  }

  // ========== گرفتن لیست بکاپ‌ها ==========
  Future<List<FileSystemEntity>> getBackupList() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');

      if (!backupDir.existsSync()) {
        return [];
      }

      return backupDir.listSync()
          .where((file) => file.path.endsWith('.db'))
          .toList()
        ..sort((a, b) {
          // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
          return b.statSync().modified.compareTo(a.statSync().modified);
        });
    } catch (e) {
      print('❌ خطا در دریافت لیست بکاپ‌ها: $e');
      return [];
    }
  }

  // ========== بازگردانی از فایل بکاپ ==========
  Future<bool> restoreBackup(String backupPath) async {
    try {
      // بستن دیتابیس فعلی
      await _dbHelper.close();

      // دریافت مسیر دیتابیس
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/smart_agro.db');

      // حذف دیتابیس فعلی
      if (dbFile.existsSync()) {
        await dbFile.delete();
      }

      // کپی فایل بکاپ به مسیر دیتابیس
      final backupFile = File(backupPath);
      await backupFile.copy(dbFile.path);

      // باز کردن مجدد دیتابیس
      await _dbHelper.open();

      return true;
    } catch (e) {
      print('❌ خطا در بازگردانی: $e');
      return false;
    }
  }

  // ========== حذف فایل بکاپ ==========
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ خطا در حذف بکاپ: $e');
      return false;
    }
  }

  // ========== دریافت اطلاعات فایل بکاپ ==========
  static String getBackupInfo(FileSystemEntity file) {
    final stat = file.statSync();
    final size = stat.size;
    final modified = stat.modified;

    final sizeStr = size > 1024 * 1024
        ? '${(size / (1024 * 1024)).toStringAsFixed(1)} MB'
        : size > 1024
        ? '${(size / 1024).toStringAsFixed(1)} KB'
        : '$size B';

    return '📅 ${modified.year}/${modified.month.toString().padLeft(2, '0')}/${modified.day.toString().padLeft(2, '0')} ${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')} - $sizeStr';
  }
}