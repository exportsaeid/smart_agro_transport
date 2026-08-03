import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // ← این خط را از حالت کامنت خارج کنید
import 'package:path_provider/path_provider.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/shipment.dart';
import '../models/clearance.dart';
import '../models/iraqi_handover.dart';
import '../models/buyer_delivery.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // ================================================
    // ⚠️ این بخش را از حالت کامنت خارج کنید
    // ================================================
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('✅ دیتابیس برای دسکتاپ مقداردهی شد');
    }
    // ================================================

    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    // ایجاد پوشه مخصوص برنامه
    String appDir = join(documentsDirectory.path, 'smart_agro_transport');
    Directory directory = Directory(appDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('📁 پوشه برنامه ایجاد شد: $appDir');
    }

    String path = join(appDir, 'smart_agro.db');
    print('📁 مسیر دیتابیس: $path');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ========== ایجاد جداول ==========
  Future<void> _onCreate(Database db, int version) async {
    print('🔄 ایجاد جداول دیتابیس...');

    // جدول فاکتورها
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE,
        customer_name TEXT,
        customer_phone TEXT,
        date TEXT,
        total_amount INTEGER,
        extra_cost INTEGER,
        extra_description TEXT,
        load_status INTEGER DEFAULT 0
      )
    ''');

    // جدول آیتم‌های فاکتور
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        product_name TEXT,
        weight INTEGER,
        unit_price INTEGER,
        name TEXT,
        mobile TEXT,
        address TEXT,
        notes TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // جدول بارگیری (Shipment)
    await db.execute('''
      CREATE TABLE shipments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        invoice_number TEXT,
        truck_name TEXT,
        plate_number TEXT,
        driver_name TEXT,
        driver_phone TEXT,
        load_date TEXT,
        transport_cost INTEGER DEFAULT 0,
        clearance_status INTEGER DEFAULT 0
      )
    ''');

    // جدول ترخیص ایرانی (Clearance)
    await db.execute('''
      CREATE TABLE clearances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shipment_id INTEGER,
        clearance_name TEXT,
        clearance_phone TEXT,
        border_name TEXT,
        clearance_date TEXT,
        notes TEXT,
        clearance_cost INTEGER DEFAULT 0,
        FOREIGN KEY (shipment_id) REFERENCES shipments (id) ON DELETE CASCADE
      )
    ''');

    // جدول تحویل به ترخیص‌کار عراقی (IraqiHandover)
    await db.execute('''
      CREATE TABLE iraqi_handovers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shipment_id INTEGER,
        clearance_name TEXT,
        clearance_phone TEXT,
        border_name TEXT,
        clearance_date TEXT,
        notes TEXT,
        clearance_cost INTEGER DEFAULT 0,
        FOREIGN KEY (shipment_id) REFERENCES shipments (id) ON DELETE CASCADE
      )
    ''');

    // جدول تحویل به خریدار (BuyerDelivery)
    await db.execute('''
      CREATE TABLE buyer_deliveries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shipment_id INTEGER,
        buyer_name TEXT,
        buyer_phone TEXT,
        hajra_number TEXT,
        delivery_date TEXT,
        received_amount INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (shipment_id) REFERENCES shipments (id) ON DELETE CASCADE
      )
    ''');

    // جدول پیوست‌ها (Attachment)
    await db.execute('''
      CREATE TABLE attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        file_name TEXT,
        file_path TEXT,
        file_type TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    print('✅ تمام جداول دیتابیس ساخته شدند.');
  }

  // ========== ارتقا دیتابیس ==========
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 ارتقا دیتابیس از نسخه $oldVersion به $newVersion');

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE shipments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          invoice_id INTEGER,
          invoice_number TEXT,
          truck_name TEXT,
          plate_number TEXT,
          driver_name TEXT,
          driver_phone TEXT,
          load_date TEXT,
          transport_cost INTEGER DEFAULT 0,
          clearance_status INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE clearances (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shipment_id INTEGER,
          clearance_name TEXT,
          clearance_phone TEXT,
          border_name TEXT,
          clearance_date TEXT,
          notes TEXT,
          clearance_cost INTEGER DEFAULT 0,
          FOREIGN KEY (shipment_id) REFERENCES shipments (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE iraqi_handovers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shipment_id INTEGER,
          clearance_name TEXT,
          clearance_phone TEXT,
          border_name TEXT,
          clearance_date TEXT,
          notes TEXT,
          clearance_cost INTEGER DEFAULT 0,
          FOREIGN KEY (shipment_id) REFERENCES shipments (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE buyer_deliveries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shipment_id INTEGER,
          buyer_name TEXT,
          buyer_phone TEXT,
          hajra_number TEXT,
          delivery_date TEXT,
          received_amount INTEGER DEFAULT 0,
          notes TEXT,
          FOREIGN KEY (shipment_id) REFERENCES shipments (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // ============================================================
  // ========== تولید شماره فاکتور خودکار ==========
  // ============================================================
  Future<String> generateInvoiceNumber() async {
    Database db = await database;

    final now = Jalali.now();
    final year = now.year.toString();

    final List<Map<String, dynamic>> result = await db.query(
      'invoices',
      columns: ['invoice_number'],
      where: 'invoice_number LIKE ?',
      whereArgs: ['$year%'],
      orderBy: 'id DESC',
      limit: 1,
    );

    int nextSeq = 1;
    if (result.isNotEmpty) {
      final lastNumber = result.first['invoice_number'] as String;
      final lastSeqStr = lastNumber.substring(year.length);
      nextSeq = int.parse(lastSeqStr) + 1;
    }

    return '$year${nextSeq.toString().padLeft(4, '0')}';
  }

  // ============================================================
  // ========== متدهای Invoice ==========
  // ============================================================

  // 1. ثبت فاکتور جدید
  Future<int> insertInvoice(Invoice invoice) async {
    Database db = await database;
    int invoiceId = 0;

    // ====== تولید شماره فاکتور خودکار ======
    final invoiceNumber = await generateInvoiceNumber();
    invoice.invoiceNumber = invoiceNumber;
    // ========================================

    await db.transaction((txn) async {
      invoiceId = await txn.insert('invoices', {
        'invoice_number': invoice.invoiceNumber,
        'customer_name': invoice.customerName,
        'customer_phone': invoice.customerPhone,
        'date': invoice.date,
        'total_amount': invoice.totalAmount,
        'extra_cost': invoice.extraCost,
        'extra_description': invoice.extraDescription,
        'load_status': 0,
      });

      for (var item in invoice.items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_name': item.productName,
          'weight': item.weight,
          'unit_price': item.unitPrice,
          'name': item.name,
          'mobile': item.mobile,
          'address': item.address,
          'notes': item.notes,
        });
      }
    });

    print('✅ فاکتور جدید با شماره ${invoice.invoiceNumber} ذخیره شد');
    return invoiceId;
  }

  // 2. دریافت همه فاکتورها
  Future<List<Invoice>> getAllInvoices() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('invoices', orderBy: 'date DESC');
    List<Invoice> invoices = [];

    for (var map in maps) {
      Invoice invoice = Invoice(
        id: map['id'],
        invoiceNumber: map['invoice_number'] ?? '',
        customerName: map['customer_name'] ?? '',
        customerPhone: map['customer_phone'] ?? '',
        date: map['date'] ?? '',
        totalAmount: map['total_amount'] ?? 0,
        extraCost: map['extra_cost'] ?? 0,
        extraDescription: map['extra_description'] ?? '',
        items: await getItemsByInvoiceId(map['id']),
      );
      invoices.add(invoice);
    }
    return invoices;
  }

  // 3. دریافت فاکتور با شناسه
  Future<Invoice?> getInvoiceById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    var map = maps.first;
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoice_number'] ?? '',
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'] ?? '',
      date: map['date'] ?? '',
      totalAmount: map['total_amount'] ?? 0,
      extraCost: map['extra_cost'] ?? 0,
      extraDescription: map['extra_description'] ?? '',
      items: await getItemsByInvoiceId(map['id']),
    );
  }

  // 4. بروزرسانی فاکتور
  Future<int> updateInvoice(Invoice invoice) async {
    Database db = await database;
    await db.transaction((txn) async {
      await txn.update('invoices', {
        'customer_name': invoice.customerName,
        'customer_phone': invoice.customerPhone,
        'date': invoice.date,
        'total_amount': invoice.totalAmount,
        'extra_cost': invoice.extraCost,
        'extra_description': invoice.extraDescription,
      }, where: 'id = ?', whereArgs: [invoice.id]);

      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoice.id]);
      for (var item in invoice.items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoice.id,
          'product_name': item.productName,
          'weight': item.weight,
          'unit_price': item.unitPrice,
          'name': item.name,
          'mobile': item.mobile,
          'address': item.address,
          'notes': item.notes,
        });
      }
    });
    print('✅ فاکتور با ID ${invoice.id} بروزرسانی شد');
    return 0;
  }

  // 5. حذف فاکتور
  Future<int> deleteInvoice(int id) async {
    Database db = await database;
    int result = await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
    print('✅ فاکتور با ID $id حذف شد');
    return result;
  }

  // 6. دریافت آیتم‌های یک فاکتور
  Future<List<InvoiceItem>> getItemsByInvoiceId(int invoiceId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);

    return maps.map((map) => InvoiceItem(
      invoiceId: invoiceId,
      productName: map['product_name'] ?? '',
      weight: map['weight'] ?? 0,
      unitPrice: map['unit_price'] ?? 0,
      name: map['name'] ?? '',
      mobile: map['mobile'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
    )).toList();
  }

  // 7. دریافت فاکتورهای آماده بارگیری
  Future<List<Invoice>> getReadyInvoices() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'load_status = 0 OR load_status IS NULL',
      orderBy: 'date DESC',
    );
    List<Invoice> invoices = [];
    for (var map in maps) {
      invoices.add(Invoice(
        id: map['id'],
        invoiceNumber: map['invoice_number'] ?? '',
        customerName: map['customer_name'] ?? '',
        customerPhone: map['customer_phone'] ?? '',
        date: map['date'] ?? '',
        totalAmount: map['total_amount'] ?? 0,
        extraCost: map['extra_cost'] ?? 0,
        extraDescription: map['extra_description'] ?? '',
        items: await getItemsByInvoiceId(map['id']),
      ));
    }
    return invoices;
  }

  // 8. بروزرسانی وضعیت بارگیری فاکتور
  Future<void> updateInvoiceLoadStatus(int invoiceId, int status) async {
    Database db = await database;
    await db.update(
      'invoices',
      {'load_status': status},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
    print('✅ وضعیت بارگیری فاکتور $invoiceId به $status تغییر کرد');
  }

  // 9. بررسی وجود بارگیری برای فاکتور
  Future<bool> hasShipment(int invoiceId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'shipments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return result.isNotEmpty;
  }

  // ============================================================
  // ========== متدهای Shipment ==========
  // ============================================================

  Future<int> addShipment(Shipment shipment) async {
    Database db = await database;
    int id = await db.insert('shipments', shipment.toMap());
    // بروزرسانی وضعیت بارگیری فاکتور
    await updateInvoiceLoadStatus(shipment.invoiceId, 1);
    print('✅ بارگیری جدید با ID $id ذخیره شد');
    return id;
  }

  Future<bool> updateShipment(Shipment shipment) async {
    Database db = await database;
    int result = await db.update(
      'shipments',
      shipment.toMap(),
      where: 'id = ?',
      whereArgs: [shipment.id],
    );
    return result > 0;
  }

  Future<List<Shipment>> getAllShipments() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'shipments',
      orderBy: 'load_date DESC',
    );
    return maps.map((map) => Shipment.fromMap(map)).toList();
  }

  Future<List<Shipment>> getInTransitShipments() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'shipments',
      where: 'clearance_status = 0',
      orderBy: 'load_date DESC',
    );
    return maps.map((map) => Shipment.fromMap(map)).toList();
  }

  Future<List<Shipment>> getClearedShipments() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'shipments',
      where: 'clearance_status = 1',
      orderBy: 'load_date DESC',
    );
    return maps.map((map) => Shipment.fromMap(map)).toList();
  }

  Future<void> updateShipmentClearanceStatus(int shipmentId, int status) async {
    Database db = await database;
    await db.update(
      'shipments',
      {'clearance_status': status},
      where: 'id = ?',
      whereArgs: [shipmentId],
    );
    print('✅ وضعیت ترخیص بارگیری $shipmentId به $status تغییر کرد');
  }

  // ============================================================
  // ========== متدهای Clearance ==========
  // ============================================================

  Future<int> addClearance(Clearance clearance) async {
    Database db = await database;
    int id = await db.insert('clearances', clearance.toMap());
    await updateShipmentClearanceStatus(clearance.shipmentId, 1);
    print('✅ ترخیص جدید با ID $id ذخیره شد');
    return id;
  }

  Future<bool> updateClearance(Clearance clearance) async {
    Database db = await database;
    int result = await db.update(
      'clearances',
      clearance.toMap(),
      where: 'id = ?',
      whereArgs: [clearance.id],
    );
    return result > 0;
  }

  Future<Clearance?> getClearanceByShipmentId(int shipmentId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'clearances',
      where: 'shipment_id = ?',
      whereArgs: [shipmentId],
    );
    if (maps.isEmpty) return null;
    return Clearance.fromMap(maps.first);
  }

  // ============================================================
  // ========== متدهای IraqiHandover ==========
  // ============================================================

  Future<int> addIraqiHandover(IraqiHandover handover) async {
    Database db = await database;
    int id = await db.insert('iraqi_handovers', handover.toMap());
    print('✅ تحویل به عراقی با ID $id ذخیره شد');
    return id;
  }

  Future<bool> updateIraqiHandover(IraqiHandover handover) async {
    Database db = await database;
    int result = await db.update(
      'iraqi_handovers',
      handover.toMap(),
      where: 'id = ?',
      whereArgs: [handover.id],
    );
    return result > 0;
  }

  Future<IraqiHandover?> getIraqiHandoverByShipmentId(int shipmentId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'iraqi_handovers',
      where: 'shipment_id = ?',
      whereArgs: [shipmentId],
    );
    if (maps.isEmpty) return null;
    return IraqiHandover.fromMap(maps.first);
  }

  // ============================================================
  // ========== متدهای BuyerDelivery ==========
  // ============================================================

  Future<int> addBuyerDelivery(BuyerDelivery delivery) async {
    Database db = await database;
    int id = await db.insert('buyer_deliveries', delivery.toMap());
    print('✅ تحویل به خریدار با ID $id ذخیره شد');
    return id;
  }

  Future<bool> updateBuyerDelivery(BuyerDelivery delivery) async {
    Database db = await database;
    int result = await db.update(
      'buyer_deliveries',
      delivery.toMap(),
      where: 'id = ?',
      whereArgs: [delivery.id],
    );
    return result > 0;
  }

  Future<BuyerDelivery?> getBuyerDeliveryByShipmentId(int shipmentId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'buyer_deliveries',
      where: 'shipment_id = ?',
      whereArgs: [shipmentId],
    );
    if (maps.isEmpty) return null;
    return BuyerDelivery.fromMap(maps.first);
  }

  // ============================================================
  // ========== متدهای Attachment ==========
  // ============================================================

  Future<int> insertAttachment(int invoiceId, String fileName, String filePath, String fileType) async {
    Database db = await database;
    int id = await db.insert('attachments', {
      'invoice_id': invoiceId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
    });
    print('✅ پیوست $fileName با ID $id ذخیره شد');
    return id;
  }

  Future<List<Map<String, dynamic>>> getAttachmentsByInvoiceId(int invoiceId) async {
    Database db = await database;
    return await db.query('attachments', where: 'invoice_id = ?', whereArgs: [invoiceId]);
  }

  Future<int> deleteAttachment(int id) async {
    Database db = await database;
    int result = await db.delete('attachments', where: 'id = ?', whereArgs: [id]);
    print('✅ پیوست با ID $id حذف شد');
    return result;
  }

  Future<int> deleteAllAttachmentsByInvoiceId(int invoiceId) async {
    Database db = await database;
    int result = await db.delete('attachments', where: 'invoice_id = ?', whereArgs: [invoiceId]);
    print('✅ تمام پیوست‌های فاکتور $invoiceId حذف شدند');
    return result;
  }

  // ========== بستن دیتابیس ==========
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('✅ دیتابیس بسته شد');
    }
  }

  // ========== باز کردن دیتابیس ==========
  Future<void> open() async {
    if (_database == null) {
      await database; // این کار دیتابیس را باز می‌کند
      print('✅ دیتابیس باز شد');
    }
  }
}