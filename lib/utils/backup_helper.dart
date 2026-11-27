import 'dart:io';
import 'package:intl/intl.dart';
import 'email_backup_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';

class BackupHelper {
  // ============================================================
  // پشتیبان‌گیری
  // ============================================================
  static Future<String?> createBackup() async {
    try {
      if (Platform.isAndroid) {
        bool hasPermission = false;
        if (await Permission.manageExternalStorage.request().isGranted) {
          hasPermission = true;
        } else if (await Permission.storage.request().isGranted) {
          hasPermission = true;
        }
        if (!hasPermission) {
          return "❌ مجوز دسترسی به حافظه داده نشد.";
        }
      }

      final String timeStamp =
      DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final String backupFileName = "smart_agro_backup_$timeStamp.zip";

      final Directory cacheDir = await getTemporaryDirectory();
      final Directory tempDir =
      Directory(p.join(cacheDir.path, "temp_backup_$timeStamp"));
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
      await tempDir.create(recursive: true);

      final Directory dbFolder = Directory(p.join(tempDir.path, "database"));
      final Directory attFolder =
      Directory(p.join(tempDir.path, "attachments"));
      await dbFolder.create();
      await attFolder.create();

      // دیتابیس
      final String dbPath = await getDatabasesPath();
      final File dbFile = File(p.join(dbPath, 'invoice_db.db'));
      if (await dbFile.exists()) {
        await dbFile.copy(p.join(dbFolder.path, 'invoice_db.db'));
      }

      // پیوست‌ها
      final appDocDir = await getApplicationDocumentsDirectory();
      final attachmentsDir =
      Directory(p.join(appDocDir.path, 'invoice_attachments'));
      if (await attachmentsDir.exists()) {
        await for (var entity in attachmentsDir.list(recursive: false)) {
          if (entity is File) {
            await entity.copy(p.join(attFolder.path, p.basename(entity.path)));
          }
        }
      }

      final File infoFile = File(p.join(tempDir.path, 'backup_info.txt'));
      await infoFile.writeAsString("تاریخ: ${DateTime.now()}");

      final zipEncoder = ZipFileEncoder();
      final String zipPath = p.join(cacheDir.path, backupFileName);
      zipEncoder.create(zipPath);
      await zipEncoder.addDirectory(tempDir);
      zipEncoder.close();

      String? outputFile;
      if (Platform.isAndroid) {
        String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory != null) {
          outputFile = p.join(selectedDirectory, backupFileName);
        }
      }

      if (outputFile != null) {
        await File(zipPath).copy(outputFile);
        return "✅ پشتیبان ذخیره شد:\n$outputFile";
      }
      return "⚠️ لغو شد";
    } catch (e) {
      return "❌ خطا: $e";
    }
  }

  // ============================================================
  // بازگردانی (پشتیبانی از بکاپ اندروید + فلاتر)
  // ============================================================
  static Future<String?> restoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.single.path == null) {
        return "⚠️ فایلی انتخاب نشد";
      }

      final File zipFile = File(result.files.single.path!);
      final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());

      final appDocDir = await getApplicationDocumentsDirectory();
      final attachmentsDir =
      Directory(p.join(appDocDir.path, 'invoice_attachments'));
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      // پوشه موقت
      final tempDir = Directory(p.join(
        (await getTemporaryDirectory()).path,
        "restore_${DateTime.now().millisecondsSinceEpoch}",
      ));
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
      await tempDir.create(recursive: true);

      File? extractedDbFile;

      // استخراج فایل‌ها از ZIP
      for (final file in archive) {
        if (!file.isFile) continue;
        final data = file.content as List<int>;
        final name = file.name.replaceAll('\\', '/');
        final lower = name.toLowerCase();

        // پیدا کردن دیتابیس (اندروید: invoice_db | فلاتر: invoice_db.db)
        if ((lower.endsWith('invoice_db') || lower.endsWith('invoice_db.db')) &&
            !lower.contains('-wal') &&
            !lower.contains('-shm') &&
            !lower.contains('-journal')) {
          extractedDbFile = File(p.join(tempDir.path, 'restored_db.db'));
          await extractedDbFile.writeAsBytes(data);
          print("📦 دیتابیس استخراج شد: $name");
        }
        // پیوست‌ها
        else if (name.contains('attachments/') && !name.endsWith('/')) {
          final dest = File(p.join(attachmentsDir.path, p.basename(name)));
          await dest.writeAsBytes(data);
        }
      }

      if (extractedDbFile == null || !await extractedDbFile.exists()) {
        await tempDir.delete(recursive: true);
        return "❌ فایل دیتابیس داخل ZIP پیدا نشد.\n"
            "(باید invoice_db یا invoice_db.db باشد)";
      }

      // باز کردن دیتابیس بکاپ (فقط خواندنی)
      final oldDb = await openDatabase(extractedDbFile.path, readOnly: true);
      final newDb = await DatabaseHelper.instance.database;

      // اطمینان از وجود ستون‌های فلاتر
      await _ensureFlutterColumns(newDb);

      // پاک کردن داده‌های فعلی (به جز users)
      final tablesToClear = [
        'buyer_delivery',
        'iraqi_handovers',
        'clearances',
        'shipments',
        'attachments',
        'invoice_items',
        'invoices',
      ];
      for (final t in tablesToClear) {
        try {
          await newDb.delete(t);
        } catch (_) {}
      }

      int totalRows = 0;

      // ---------- invoices ----------
      try {
        final rows = await oldDb.query('invoices');
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row);
          map['total_amount'] =
              (map['total_amount'] as num?)?.toDouble() ?? 0.0;
          map['misc_cost'] = (map['misc_cost'] as num?)?.toDouble() ?? 0.0;
          map['misc_notes'] = map['misc_notes'] ?? '';
          map['load_status'] = map['load_status'] ?? 0;
          await newDb.insert('invoices', map,
              conflictAlgorithm: ConflictAlgorithm.replace);
          totalRows++;
        }
        print("✅ invoices: ${rows.length}");
      } catch (e) {
        print("❌ invoices: $e");
      }

      // ---------- invoice_items ----------
      try {
        final rows = await oldDb.query('invoice_items');
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row);
          map['weight'] = (map['weight'] as num?)?.toDouble() ?? 0.0;
          map['unit_price'] = (map['unit_price'] as num?)?.toDouble() ?? 0.0;
          map['notes'] = map['notes'] ?? '';
          await newDb.insert('invoice_items', map,
              conflictAlgorithm: ConflictAlgorithm.replace);
          totalRows++;
        }
        print("✅ invoice_items: ${rows.length}");
      } catch (e) {
        print("❌ invoice_items: $e");
      }

      // ---------- shipments ----------
      try {
        final rows = await oldDb.query('shipments');
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row);
          map['transport_cost'] =
              (map['transport_cost'] as num?)?.toDouble() ?? 0.0;
          map['clearance_status'] = map['clearance_status'] ?? 0;
          await newDb.insert('shipments', map,
              conflictAlgorithm: ConflictAlgorithm.replace);
          totalRows++;
        }
        print("✅ shipments: ${rows.length}");
      } catch (e) {
        print("❌ shipments: $e");
      }

      // ---------- clearances ----------
      try {
        final rows = await oldDb.query('clearances');
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row);
          map['clearance_cost'] =
              (map['clearance_cost'] as num?)?.toDouble() ?? 0.0;
          map['notes'] = map['notes'] ?? '';
          await newDb.insert('clearances', map,
              conflictAlgorithm: ConflictAlgorithm.replace);
          totalRows++;
        }
        print("✅ clearances: ${rows.length}");
      } catch (e) {
        print("❌ clearances: $e");
      }

      // ---------- iraqi_handovers ----------
      try {
        final rows = await oldDb.query('iraqi_handovers');
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row);
          map['clearance_cost'] =
              (map['clearance_cost'] as num?)?.toDouble() ?? 0.0;
          map['notes'] = map['notes'] ?? '';
          await newDb.insert('iraqi_handovers', map,
              conflictAlgorithm: ConflictAlgorithm.replace);
          totalRows++;
        }
        print("✅ iraqi_handovers: ${rows.length}");
      } catch (e) {
        print("❌ iraqi_handovers: $e");
      }

      // ---------- buyer_delivery ----------
      try {
        final rows = await oldDb.query('buyer_delivery');
        for (final row in rows) {
          final map = Map<String, dynamic>.from(row);
          map['received_amount'] =
              (map['received_amount'] as num?)?.toDouble() ?? 0.0;
          map['notes'] = map['notes'] ?? '';
          await newDb.insert('buyer_delivery', map,
              conflictAlgorithm: ConflictAlgorithm.replace);
          totalRows++;
        }
        print("✅ buyer_delivery: ${rows.length}");
      } catch (e) {
        print("❌ buyer_delivery: $e");
      }

      // ---------- attachments (مسیر هنوز اندرویدی است) ----------
      try {
        final rows = await oldDb.query('attachments');
        for (final row in rows) {
          await newDb.insert('attachments', row,
              conflictAlgorithm: ConflictAlgorithm.replace);
          totalRows++;
        }
        print("✅ attachments: ${rows.length}");
      } catch (e) {
        print("❌ attachments: $e");
      }

      // ---------- users ----------
      try {
        await newDb.delete('users');
        await newDb.insert('users', {
          'username': 'admin',
          'password': '123',
          'role': 'مدیر سیستم',
        });
      } catch (e) {
        print("❌ users: $e");
      }

      await oldDb.close();
      await tempDir.delete(recursive: true);

      // اصلاح مسیرهای پیوست از اندروید به فلاتر
      final fixedCount = await _fixAttachmentPaths();
      print('🔧 تعداد پیوست‌های اصلاح‌شده: $fixedCount');

      return "✅ مهاجرت موفق — $totalRows ردیف منتقل شد.\n"
          "🔧 $fixedCount پیوست اصلاح شد\n"
          "رمز ورود: admin / 123";
    } catch (e) {
      return "❌ خطا: $e";
    }
  }

  // ============================================================
  // اصلاح مسیر پیوست‌ها (اندروید → فلاتر)
  // ============================================================
  static Future<int> _fixAttachmentPaths() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final attachmentsDir =
    Directory(p.join(appDocDir.path, 'invoice_attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('attachments');
    int fixed = 0;

    // فایل‌های واقعی روی دیسک (نام‌شان UUID است)
    final filesOnDisk = <String, String>{}; // basename -> fullPath
    for (final f in attachmentsDir.listSync().whereType<File>()) {
      filesOnDisk[p.basename(f.path)] = f.path;
    }

    print('📂 تعداد فایل روی دیسک: ${filesOnDisk.length}');
    print('📋 تعداد رکورد attachments: ${rows.length}');
    for (final name in filesOnDisk.keys) {
      print('   📄 $name');
    }

    for (final row in rows) {
      final id = row['id'] as int;
      final oldPath = ((row['file_path'] as String?) ?? '').replaceAll('\\', '/');
      final displayName = (row['file_name'] as String?) ?? '';

      // نام واقعی فایل = آخرین بخش مسیر قدیمی (UUID + پسوند)
      final diskFileName = p.basename(oldPath);

      print('🔎 id=$id | نمایش="$displayName" | دیسک="$diskFileName"');

      if (diskFileName.isEmpty) {
        print('⚠️ مسیر خالی برای id=$id');
        continue;
      }

      // تطبیق دقیق با نام UUID
      if (filesOnDisk.containsKey(diskFileName)) {
        final newPath = filesOnDisk[diskFileName]!;
        await db.update(
          'attachments',
          {'file_path': newPath},
          where: 'id = ?',
          whereArgs: [id],
        );
        fixed++;
        print('✅ اصلاح شد → $newPath');
        continue;
      }

      // تطبیق بدون حساسیت به حروف بزرگ/کوچک
      final lower = diskFileName.toLowerCase();
      String? foundKey;
      for (final key in filesOnDisk.keys) {
        if (key.toLowerCase() == lower) {
          foundKey = key;
          break;
        }
      }

      if (foundKey != null) {
        final newPath = filesOnDisk[foundKey]!;
        await db.update(
          'attachments',
          {'file_path': newPath},
          where: 'id = ?',
          whereArgs: [id],
        );
        fixed++;
        print('✅ اصلاح شد (case-insensitive) → $newPath');
      } else {
        print('❌ پیدا نشد: $diskFileName برای id=$id');
      }
    }

    print('🔧 جمع اصلاح‌شده: $fixed از ${rows.length}');
    return fixed;
  }

  // ============================================================
  // اطمینان از وجود ستون‌های فلاتر
  // ============================================================
  static Future<void> _ensureFlutterColumns(Database db) async {
    Future<void> addCol(String table, String col, String type) async {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN $col $type');
      } catch (_) {
        // ستون از قبل وجود دارد
      }
    }

    await addCol('invoices', 'misc_cost', 'REAL DEFAULT 0');
    await addCol('invoices', 'misc_notes', "TEXT DEFAULT ''");
  }
}