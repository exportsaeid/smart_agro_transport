import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/attachment.dart';
import '../models/shipment.dart';
import '../models/clearance.dart';
import '../models/iraqi_handover.dart';
import '../models/buyer_delivery.dart';
import '../models/profit_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invoice_db.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // در صورت نیاز به مهاجرت نسخه‌های بعدی اینجا اضافه شود
        if (oldVersion < 7) {
          try {
            await db.execute('ALTER TABLE invoices ADD COLUMN misc_cost REAL DEFAULT 0');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE invoices ADD COLUMN misc_notes TEXT DEFAULT \'\'');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        date TEXT,
        total_amount REAL,
        load_status INTEGER DEFAULT 0,
        misc_cost REAL DEFAULT 0,
        misc_notes TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        product_name TEXT,
        weight REAL,
        unit_price REAL,
        name TEXT,
        mobile TEXT,
        address TEXT,
        notes TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shipments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        invoice_number TEXT,
        truck_name TEXT,
        plate_number TEXT,
        driver_name TEXT,
        driver_phone TEXT,
        load_date TEXT,
        transport_cost REAL,
        clearance_status INTEGER DEFAULT 0,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clearances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shipment_id INTEGER,
        clearance_name TEXT,
        clearance_phone TEXT,
        border_name TEXT,
        clearance_date TEXT,
        notes TEXT,
        clearance_cost REAL,
        FOREIGN KEY (shipment_id) REFERENCES shipments (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS iraqi_handovers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shipment_id INTEGER,
        clearance_name TEXT,
        clearance_phone TEXT,
        border_name TEXT,
        clearance_date TEXT,
        notes TEXT,
        clearance_cost REAL,
        FOREIGN KEY (shipment_id) REFERENCES shipments (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS buyer_delivery (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shipment_id INTEGER,
        buyer_name TEXT,
        buyer_phone TEXT,
        hajra_number TEXT,
        delivery_date TEXT,
        received_amount REAL,
        notes TEXT,
        FOREIGN KEY (shipment_id) REFERENCES shipments (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        file_name TEXT,
        file_path TEXT,
        file_type TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // درج کاربر مدیر پیش‌فرض
    await db.insert('users', {
      'username': 'admin',
      'password': '123',
      'role': 'مدیر سیستم',
    });
  }

  Future<String> generateInvoiceNumber([DatabaseExecutor? executor]) async {
    final db = executor ?? await instance.database;
    final now = Jalali.now();
    final prefix = now.year.toString();
    final result = await db.rawQuery(
      'SELECT invoice_number FROM invoices WHERE invoice_number LIKE ? ORDER BY id DESC LIMIT 1',
      ['$prefix%'],
    );
    int nextSeq = 1;
    if (result.isNotEmpty) {
      final lastNumber = result.first['invoice_number'] as String;
      if (lastNumber.length > prefix.length) {
        final lastSeqStr = lastNumber.substring(prefix.length);
        nextSeq = (int.tryParse(lastSeqStr) ?? 0) + 1;
      }
    }
    return prefix + nextSeq.toString().padLeft(4, '0');
  }

  // Save Invoice (Insert or Update)
  Future<int> saveInvoice(Invoice invoice) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      int invoiceId;
      if (invoice.id == null) {
        invoice.invoiceNumber = await generateInvoiceNumber(txn);
        invoiceId = await txn.insert('invoices', invoice.toMap());
      } else {
        invoiceId = invoice.id!;
        await txn.update('invoices', invoice.toMap(),
            where: 'id = ?', whereArgs: [invoiceId]);
        await txn.delete('invoice_items',
            where: 'invoice_id = ?', whereArgs: [invoiceId]);
      }

      for (var item in invoice.items) {
        final itemMap = item.toMap(invoiceId);
        if (invoice.id != null) itemMap.remove('id');
        await txn.insert('invoice_items', itemMap);
      }

      for (var attachment in invoice.attachments) {
        if (attachment.id == null) {
          attachment.invoiceId = invoiceId;
          await txn.insert('attachments', attachment.toMap());
        }
      }
      return invoiceId;
    });
  }

  Future<Invoice?> getInvoice(int id) async {
    final db = await instance.database;
    final invResult =
    await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (invResult.isEmpty) return null;

    final invoice = Invoice.fromMap(invResult.first);

    final itemsResult = await db
        .query('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    invoice.items = itemsResult.map((e) => InvoiceItem.fromMap(e)).toList();

    final attachResult =
    await db.query('attachments', where: 'invoice_id = ?', whereArgs: [id]);
    invoice.attachments =
        attachResult.map((e) => Attachment.fromMap(e)).toList();

    return invoice;
  }

  Future<List<Attachment>> getAttachments(int invoiceId) async {
    final db = await instance.database;
    final result = await db
        .query('attachments', where: 'invoice_id = ?', whereArgs: [invoiceId]);
    return result.map((e) => Attachment.fromMap(e)).toList();
  }

  Future<int> deleteAttachment(int id) async {
    final db = await instance.database;
    return await db.delete('attachments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAttachmentFileName(int id, String newName) async {
    final db = await instance.database;
    return await db.update(
      'attachments',
      {'file_name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> checkData() async {
    final dbPath = await getDatabasesPath();
    final file = File(join(dbPath, 'invoice_db.db'));
    print("📌 مسیر دیتابیس: ${file.path}");
    print(
        "📌 حجم فایل دیتابیس در فلاتر: ${await file.exists() ? await file.length() : 0} بایت");

    final db = await instance.database;
    final tables =
    await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print("📋 جداول پیدا شده: $tables");

    for (var table in tables) {
      String tableName = table['name'] as String;
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableName'));
      print("🔥 جدول $tableName دارای $count رکورد است.");
    }
  }

  Future<void> deleteInvoice(int id) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final shipments = await txn.query('shipments',
          columns: ['id'], where: 'invoice_id = ?', whereArgs: [id]);

      for (var s in shipments) {
        final shipmentId = s['id'] as int;
        await txn.delete('clearances',
            where: 'shipment_id = ?', whereArgs: [shipmentId]);
        await txn.delete('iraqi_handovers',
            where: 'shipment_id = ?', whereArgs: [shipmentId]);
        await txn.delete('buyer_delivery',
            where: 'shipment_id = ?', whereArgs: [shipmentId]);
      }

      await txn.delete('shipments', where: 'invoice_id = ?', whereArgs: [id]);
      await txn
          .delete('attachments', where: 'invoice_id = ?', whereArgs: [id]);
      await txn
          .delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
      await txn.delete('invoices', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT i.*, COUNT(it.id) as item_count
      FROM invoices i
      LEFT JOIN invoice_items it ON i.id = it.invoice_id
      GROUP BY i.id
      ORDER BY i.date DESC
    ''');
    return result.map((e) => Invoice.fromMap(e)).toList();
  }

  // --- Shipment Methods ---
  Future<int> addShipment(Shipment shipment) async {
    final db = await instance.database;
    return await db.insert('shipments', shipment.toMap());
  }

  Future<int> updateShipment(Shipment shipment) async {
    final db = await instance.database;
    return await db.update('shipments', shipment.toMap(),
        where: 'id = ?', whereArgs: [shipment.id]);
  }

  Future<void> updateInvoiceLoadStatus(int invoiceId, int status) async {
    final db = await instance.database;
    await db.update('invoices', {'load_status': status},
        where: 'id = ?', whereArgs: [invoiceId]);
  }

  Future<List<Invoice>> getReadyInvoices() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT i.*, COUNT(it.id) as item_count
      FROM invoices i
      LEFT JOIN invoice_items it ON i.id = it.invoice_id
      WHERE i.load_status = 0
      GROUP BY i.id
      ORDER BY i.date DESC
    ''');
    return result.map((e) => Invoice.fromMap(e)).toList();
  }

  Future<List<Shipment>> getAllShipments() async {
    final db = await instance.database;
    final result = await db.query('shipments', orderBy: 'load_date DESC');
    return result.map((e) => Shipment.fromMap(e)).toList();
  }

  Future<List<Shipment>> getInTransitShipments() async {
    final db = await instance.database;
    final result = await db.query('shipments',
        where: 'clearance_status = 0', orderBy: 'load_date DESC');
    return result.map((e) => Shipment.fromMap(e)).toList();
  }

  Future<List<Shipment>> getClearedShipments() async {
    final db = await instance.database;
    final result = await db.query('shipments',
        where: 'clearance_status = 1', orderBy: 'load_date DESC');
    return result.map((e) => Shipment.fromMap(e)).toList();
  }

  Future<int> deleteShipment(int id, int invoiceId) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await txn
          .delete('clearances', where: 'shipment_id = ?', whereArgs: [id]);
      await txn.delete('iraqi_handovers',
          where: 'shipment_id = ?', whereArgs: [id]);
      await txn
          .delete('buyer_delivery', where: 'shipment_id = ?', whereArgs: [id]);
      final count =
      await txn.delete('shipments', where: 'id = ?', whereArgs: [id]);
      await txn.update('invoices', {'load_status': 0},
          where: 'id = ?', whereArgs: [invoiceId]);
      return count;
    });
  }

  // --- Clearance Methods ---
  Future<int> addClearance(Clearance clearance) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final id = await txn.insert('clearances', clearance.toMap());
      await txn.update('shipments', {'clearance_status': 1},
          where: 'id = ?', whereArgs: [clearance.shipmentId]);
      return id;
    });
  }

  Future<int> updateClearance(Clearance clearance) async {
    final db = await instance.database;
    return await db.update('clearances', clearance.toMap(),
        where: 'id = ?', whereArgs: [clearance.id]);
  }

  Future<Clearance?> getClearanceByShipmentId(int shipmentId) async {
    final db = await instance.database;
    final result = await db
        .query('clearances', where: 'shipment_id = ?', whereArgs: [shipmentId]);
    if (result.isEmpty) return null;
    return Clearance.fromMap(result.first);
  }

  // --- Iraqi Handover Methods ---
  Future<int> addIraqiHandover(IraqiHandover handover) async {
    final db = await instance.database;
    return await db.insert('iraqi_handovers', handover.toMap());
  }

  Future<int> updateIraqiHandover(IraqiHandover handover) async {
    final db = await instance.database;
    return await db.update('iraqi_handovers', handover.toMap(),
        where: 'id = ?', whereArgs: [handover.id]);
  }

  Future<IraqiHandover?> getIraqiHandoverByShipmentId(int shipmentId) async {
    final db = await instance.database;
    final result = await db.query('iraqi_handovers',
        where: 'shipment_id = ?', whereArgs: [shipmentId]);
    if (result.isEmpty) return null;
    return IraqiHandover.fromMap(result.first);
  }

  // --- Buyer Delivery Methods ---
  Future<BuyerDelivery?> getBuyerDeliveryByShipmentId(int shipmentId) async {
    final db = await instance.database;
    final result = await db.query('buyer_delivery',
        where: 'shipment_id = ?', whereArgs: [shipmentId]);
    if (result.isEmpty) return null;
    return BuyerDelivery.fromMap(result.first);
  }

  Future<int> addBuyerDelivery(BuyerDelivery delivery) async {
    final db = await instance.database;
    return await db.insert('buyer_delivery', delivery.toMap());
  }

  Future<int> updateBuyerDelivery(BuyerDelivery delivery) async {
    final db = await instance.database;
    return await db.update('buyer_delivery', delivery.toMap(),
        where: 'id = ?', whereArgs: [delivery.id]);
  }

  Future<List<ProfitItem>> getProfitReportData() async {
    final db = await instance.database;
    final List<ProfitItem> report = [];

    final List<Map<String, dynamic>> shipmentsWithDelivery =
    await db.rawQuery('''
      SELECT s.*, bd.buyer_name, bd.received_amount, bd.delivery_date,
             i.misc_cost, i.total_amount, i.invoice_number as inv_num
      FROM shipments s
      JOIN buyer_delivery bd ON s.id = bd.shipment_id
      JOIN invoices i ON s.invoice_id = i.id
      ORDER BY s.load_date DESC
    ''');

    for (var sMap in shipmentsWithDelivery) {
      final int shipmentId = sMap['id'];

      final cl = await getClearanceByShipmentId(shipmentId);
      final double iranianClearance = cl?.clearanceCost ?? 0.0;

      final ho = await getIraqiHandoverByShipmentId(shipmentId);
      final double iraqiCost = ho?.clearanceCost ?? 0.0;

      final double iranianTransport =
          (sMap['transport_cost'] as num?)?.toDouble() ?? 0.0;
      final double receivedAmount =
          (sMap['received_amount'] as num?)?.toDouble() ?? 0.0;
      final double miscCost = (sMap['misc_cost'] as num?)?.toDouble() ?? 0.0;
      final double totalAmount =
          (sMap['total_amount'] as num?)?.toDouble() ?? 0.0;

      final double invoiceBaseAmount = totalAmount - miscCost;
      final double totalCosts = invoiceBaseAmount +
          miscCost +
          iranianTransport +
          iranianClearance +
          iraqiCost;
      final double profit = receivedAmount - totalCosts;

      report.add(ProfitItem(
        invoiceNumber: sMap['inv_num'] ?? '---',
        buyerName: sMap['buyer_name'] ?? '---',
        invoiceAmount: invoiceBaseAmount,
        miscCost: miscCost,
        iranianTransport: iranianTransport,
        iranianClearance: iranianClearance,
        iraqiTotalCost: iraqiCost,
        receivedAmount: receivedAmount,
        profit: profit,
        loadDate: (sMap['load_date'] as String?) ?? '',
        deliveryDate: (sMap['delivery_date'] as String?) ?? '',
      ));
    }
    return report;
  }
}