# create_files.ps1
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 شروع ایجاد فایل‌های پروژه..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# ایجاد پوشه‌ها
New-Item -ItemType Directory -Force -Path "lib\models" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\widgets" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\ui" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\database" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\utils" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\views" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\presenters" | Out-Null

Write-Host "✅ پوشه‌ها ایجاد شدند" -ForegroundColor Green

# ============================================================
# فایل‌های مدل
# ============================================================
Write-Host "📄 ایجاد فایل‌های مدل..." -ForegroundColor Yellow

$shipmentContent = @'
class Shipment {
  int? id;
  int invoiceId;
  String invoiceNumber;
  String truckName;
  String plateNumber;
  String driverName;
  String driverPhone;
  String loadDate;
  int transportCost;
  int clearanceStatus;

  Shipment({
    this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.truckName,
    required this.plateNumber,
    required this.driverName,
    required this.driverPhone,
    required this.loadDate,
    this.transportCost = 0,
    this.clearanceStatus = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'invoice_number': invoiceNumber,
      'truck_name': truckName,
      'plate_number': plateNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'load_date': loadDate,
      'transport_cost': transportCost,
      'clearance_status': clearanceStatus,
    };
  }

  factory Shipment.fromMap(Map<String, dynamic> map) {
    return Shipment(
      id: map['id'],
      invoiceId: map['invoice_id'] ?? 0,
      invoiceNumber: map['invoice_number'] ?? '',
      truckName: map['truck_name'] ?? '',
      plateNumber: map['plate_number'] ?? '',
      driverName: map['driver_name'] ?? '',
      driverPhone: map['driver_phone'] ?? '',
      loadDate: map['load_date'] ?? '',
      transportCost: map['transport_cost'] ?? 0,
      clearanceStatus: map['clearance_status'] ?? 0,
    );
  }
}
'@
$shipmentContent | Out-File -FilePath "lib\models\shipment.dart" -Encoding UTF8

$clearanceContent = @'
class Clearance {
  int? id;
  int shipmentId;
  String clearanceName;
  String clearancePhone;
  String borderName;
  String clearanceDate;
  String notes;
  int clearanceCost;

  Clearance({
    this.id,
    required this.shipmentId,
    required this.clearanceName,
    required this.clearancePhone,
    required this.borderName,
    required this.clearanceDate,
    this.notes = '',
    this.clearanceCost = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'clearance_name': clearanceName,
      'clearance_phone': clearancePhone,
      'border_name': borderName,
      'clearance_date': clearanceDate,
      'notes': notes,
      'clearance_cost': clearanceCost,
    };
  }

  factory Clearance.fromMap(Map<String, dynamic> map) {
    return Clearance(
      id: map['id'],
      shipmentId: map['shipment_id'] ?? 0,
      clearanceName: map['clearance_name'] ?? '',
      clearancePhone: map['clearance_phone'] ?? '',
      borderName: map['border_name'] ?? '',
      clearanceDate: map['clearance_date'] ?? '',
      notes: map['notes'] ?? '',
      clearanceCost: map['clearance_cost'] ?? 0,
    );
  }
}
'@
$clearanceContent | Out-File -FilePath "lib\models\clearance.dart" -Encoding UTF8

$iraqiContent = @'
class IraqiHandover {
  int? id;
  int shipmentId;
  String clearanceName;
  String clearancePhone;
  String borderName;
  String clearanceDate;
  String notes;
  int clearanceCost;

  IraqiHandover({
    this.id,
    required this.shipmentId,
    required this.clearanceName,
    required this.clearancePhone,
    required this.borderName,
    required this.clearanceDate,
    this.notes = '',
    this.clearanceCost = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'clearance_name': clearanceName,
      'clearance_phone': clearancePhone,
      'border_name': borderName,
      'clearance_date': clearanceDate,
      'notes': notes,
      'clearance_cost': clearanceCost,
    };
  }

  factory IraqiHandover.fromMap(Map<String, dynamic> map) {
    return IraqiHandover(
      id: map['id'],
      shipmentId: map['shipment_id'] ?? 0,
      clearanceName: map['clearance_name'] ?? '',
      clearancePhone: map['clearance_phone'] ?? '',
      borderName: map['border_name'] ?? '',
      clearanceDate: map['clearance_date'] ?? '',
      notes: map['notes'] ?? '',
      clearanceCost: map['clearance_cost'] ?? 0,
    );
  }
}
'@
$iraqiContent | Out-File -FilePath "lib\models\iraqi_handover.dart" -Encoding UTF8

$buyerContent = @'
class BuyerDelivery {
  int? id;
  int shipmentId;
  String buyerName;
  String buyerPhone;
  String hajraNumber;
  String deliveryDate;
  int receivedAmount;
  String notes;

  BuyerDelivery({
    this.id,
    required this.shipmentId,
    required this.buyerName,
    required this.buyerPhone,
    required this.hajraNumber,
    required this.deliveryDate,
    required this.receivedAmount,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'hajra_number': hajraNumber,
      'delivery_date': deliveryDate,
      'received_amount': receivedAmount,
      'notes': notes,
    };
  }

  factory BuyerDelivery.fromMap(Map<String, dynamic> map) {
    return BuyerDelivery(
      id: map['id'],
      shipmentId: map['shipment_id'] ?? 0,
      buyerName: map['buyer_name'] ?? '',
      buyerPhone: map['buyer_phone'] ?? '',
      hajraNumber: map['hajra_number'] ?? '',
      deliveryDate: map['delivery_date'] ?? '',
      receivedAmount: map['received_amount'] ?? 0,
      notes: map['notes'] ?? '',
    );
  }
}
'@
$buyerContent | Out-File -FilePath "lib\models\buyer_delivery.dart" -Encoding UTF8

Write-Host "✅ فایل‌های مدل ایجاد شدند" -ForegroundColor Green

# ============================================================
# فایل UI
# ============================================================
Write-Host "📄 ایجاد فایل UI..." -ForegroundColor Yellow

$uiContent = @'
import 'package:flutter/material.dart';
import '../widgets/ready_invoices_widget.dart';
import '../widgets/completed_shipments_widget.dart';

class ShipmentScreen extends StatefulWidget {
  const ShipmentScreen({super.key});

  @override
  State<ShipmentScreen> createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends State<ShipmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey<ReadyInvoicesWidgetState> _readyKey = GlobalKey();
  final GlobalKey<CompletedShipmentsWidgetState> _completedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showToast(String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('🚛📋 مدیریت بارگیری'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '📋 فاکتورهای آماده'),
            Tab(text: '🚛 بارگیری‌ها'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _readyKey.currentState?.refreshData();
              _completedKey.currentState?.refreshData();
              _showToast('🔄 اطلاعات بروزرسانی شد', color: Colors.blue);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ReadyInvoicesWidget(
            key: _readyKey,
            onShipmentCreated: (_) {
              _completedKey.currentState?.refreshData();
            },
          ),
          CompletedShipmentsWidget(key: _completedKey),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
'@
$uiContent | Out-File -FilePath "lib\ui\shipment_screen.dart" -Encoding UTF8

Write-Host "✅ فایل UI ایجاد شد" -ForegroundColor Green

# ============================================================
# فایل‌های ویجت
# ============================================================
Write-Host "📄 ایجاد فایل‌های ویجت..." -ForegroundColor Yellow

$readyWidgetContent = @'
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/shipment.dart';
import '../utils/number_formatter.dart';
import 'shipment_dialog.dart';

class ReadyInvoicesWidget extends StatefulWidget {
  final Function(Shipment)? onShipmentCreated;

  const ReadyInvoicesWidget({super.key, this.onShipmentCreated});

  @override
  State<ReadyInvoicesWidget> createState() => _ReadyInvoicesWidgetState();
}

class _ReadyInvoicesWidgetState extends State<ReadyInvoicesWidget> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      _invoices = await _dbHelper.getReadyInvoices();
      _filteredInvoices = List.from(_invoices);
      _applyFilter();
    } catch (e) {
      _showSnackBar('❌ خطا در بارگذاری: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredInvoices = List.from(_invoices);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredInvoices = _invoices.where((invoice) =>
          invoice.customerName.toLowerCase().contains(query) ||
          invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.date.contains(query)).toList();
    }
    setState(() {});
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showLoadDialog(Invoice invoice) {
    ShipmentDialog.showCreate(
      context: context,
      invoice: invoice,
      onSuccess: (shipment) {
        _loadInvoices();
        if (widget.onShipmentCreated != null) {
          widget.onShipmentCreated!(shipment);
        }
      },
    );
  }

  void refreshData() {
    _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '🔍 جستجو در فاکتورهای آماده...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFilter();
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredInvoices.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = _filteredInvoices[index];
                    return _buildInvoiceCard(invoice);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '📭 هیچ فاکتور آماده‌ای برای بارگیری وجود ندارد',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    int total = 0;
    for (var item in invoice.items) {
      total += item.rowTotal;
    }
    total += invoice.extraCost;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🧾 #${invoice.invoiceNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✅ آماده بارگیری',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('👤 مشتری: ${invoice.customerName}'),
            Text('📅 تاریخ: ${invoice.date}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💰 جمع کل: ${NumberFormatter.formatNumber(total)} تومان',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text('📦 ${invoice.items.length} آیتم'),
              ],
            ),
            if (invoice.extraCost > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '📌 هزینه متفرقه: ${NumberFormatter.formatNumber(invoice.extraCost)} تومان',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLoadDialog(invoice),
                icon: const Icon(Icons.local_shipping, size: 20),
                label: const Text('🚛 ثبت بارگیری', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
'@
$readyWidgetContent | Out-File -FilePath "lib\widgets\ready_invoices_widget.dart" -Encoding UTF8

$completedWidgetContent = @'
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../utils/number_formatter.dart';
import 'shipment_dialog.dart';

class CompletedShipmentsWidget extends StatefulWidget {
  const CompletedShipmentsWidget({super.key});

  @override
  State<CompletedShipmentsWidget> createState() =>
      _CompletedShipmentsWidgetState();
}

class _CompletedShipmentsWidgetState extends State<CompletedShipmentsWidget> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Shipment> _shipments = [];
  List<Shipment> _filteredShipments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    setState(() => _isLoading = true);
    try {
      _shipments = await _dbHelper.getAllShipments();
      _filteredShipments = List.from(_shipments);
      _applyFilter();
    } catch (e) {
      _showSnackBar('❌ خطا در بارگذاری: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredShipments = List.from(_shipments);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredShipments = _shipments.where((shipment) =>
          shipment.invoiceNumber.toLowerCase().contains(query) ||
          shipment.truckName.toLowerCase().contains(query) ||
          shipment.driverName.toLowerCase().contains(query) ||
          shipment.plateNumber.toLowerCase().contains(query)).toList();
    }
    setState(() {});
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showEditDialog(Shipment shipment) {
    ShipmentDialog.showEdit(
      context: context,
      shipment: shipment,
      onSuccess: _loadShipments,
    );
  }

  void _showDeleteDialog(Shipment shipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🗑️ حذف بارگیری'),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید بارگیری فاکتور #${shipment.invoiceNumber} را حذف کنید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                _showSnackBar('🗑️ بارگیری با موفقیت حذف شد', Colors.orange);
                Navigator.pop(context);
                _loadShipments();
              } catch (e) {
                _showSnackBar('❌ خطا در حذف: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('🗑️ حذف'),
          ),
        ],
      ),
    );
  }

  void refreshData() {
    _loadShipments();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '🔍 جستجو در بارگیری‌ها...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFilter();
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredShipments.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredShipments.length,
                  itemBuilder: (context, index) {
                    final shipment = _filteredShipments[index];
                    return _buildShipmentCard(shipment);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '📭 هنوز بارگیری ثبت نشده',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentCard(Shipment shipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🚛 #${shipment.invoiceNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: shipment.clearanceStatus == 1 ? Colors.purple : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    shipment.clearanceStatus == 1 ? '✅ ترخیص شده' : '⏳ در راه مرز',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('👤 راننده: ${shipment.driverName}'),
                      Text('📞 ${shipment.driverPhone}'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🚛 ماشین: ${shipment.truckName}'),
                      Text('🔢 پلاک: ${shipment.plateNumber}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💰 هزینه حمل: ${NumberFormatter.formatNumber(shipment.transportCost)} تومان',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text('📅 ${shipment.loadDate}'),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(shipment),
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  label: const Text('ویرایش', style: TextStyle(color: Colors.blue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteDialog(shipment),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('حذف', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
'@
$completedWidgetContent | Out-File -FilePath "lib\widgets\completed_shipments_widget.dart" -Encoding UTF8

# ============================================================
# فایل shipment_dialog.dart
# ============================================================
$dialogContent = @'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/shipment.dart';
import '../utils/number_formatter.dart';
import '../utils/persian_date_helper.dart';

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final onlyDigits = newValue.text.replaceAll(',', '');
    if (onlyDigits.isEmpty) return newValue.copyWith(text: '');
    final parsed = int.tryParse(onlyDigits);
    if (parsed == null) return oldValue;
    final formatter = NumberFormat('#,###');
    final newText = formatter.format(parsed);
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

class ShipmentDialog {
  static Future<void> showCreate({
    required BuildContext context,
    required Invoice invoice,
    required Function(Shipment) onSuccess,
  }) async {
    final TextEditingController truckController = TextEditingController();
    final TextEditingController plateController = TextEditingController();
    final TextEditingController driverController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    String loadDate = PersianDateHelper.getCurrentPersianDate();

    costController.addListener(() {
      final text = costController.text;
      if (text.isNotEmpty) {
        final onlyDigits = text.replaceAll(',', '');
        if (onlyDigits.isNotEmpty) {
          final parsed = int.tryParse(onlyDigits);
          if (parsed != null) {
            final formatted = NumberFormatter.formatNumber(parsed);
            if (formatted != text) {
              costController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          }
        }
      }
    });

    final dbHelper = DatabaseHelper();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🚛 ثبت بارگیری فاکتور #${invoice.invoiceNumber}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(truckController, '🚛 نام ماشین', Icons.directions_truck),
              const SizedBox(height: 12),
              _buildTextField(plateController, '🔢 پلاک ماشین', Icons.confirmation_number),
              const SizedBox(height: 12),
              _buildTextField(driverController, '👤 نام راننده', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(phoneController, '📞 تلفن راننده', Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(costController, '💰 هزینه حمل (تومان)', Icons.money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildDatePicker(context, loadDate, (date) {
                loadDate = date;
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (truckController.text.trim().isEmpty) {
                _showToast(context, '🚛 نام ماشین الزامی است', Colors.orange);
                return;
              }
              if (plateController.text.trim().isEmpty) {
                _showToast(context, '🔢 پلاک ماشین الزامی است', Colors.orange);
                return;
              }
              if (driverController.text.trim().isEmpty) {
                _showToast(context, '👤 نام راننده الزامی است', Colors.orange);
                return;
              }
              if (phoneController.text.trim().length < 10) {
                _showToast(context, '📞 شماره تلفن معتبر نیست (حداقل ۱۰ رقم)', Colors.orange);
                return;
              }
              if (loadDate.isEmpty) {
                _showToast(context, '📅 تاریخ بارگیری الزامی است', Colors.orange);
                return;
              }

              final cost = NumberFormatter.parseNumber(costController.text);

              final shipment = Shipment(
                invoiceId: invoice.id!,
                invoiceNumber: invoice.invoiceNumber,
                truckName: truckController.text.trim(),
                plateNumber: plateController.text.trim(),
                driverName: driverController.text.trim(),
                driverPhone: phoneController.text.trim(),
                loadDate: loadDate,
                transportCost: cost,
              );

              try {
                final id = await dbHelper.addShipment(shipment);
                if (id > 0) {
                  await dbHelper.updateInvoiceLoadStatus(invoice.id!, 1);
                  _showToast(context, '✅ بارگیری با موفقیت ثبت شد!', Colors.green);
                  Navigator.pop(context);
                  onSuccess(shipment);
                } else {
                  _showToast(context, '❌ خطا در ثبت بارگیری!', Colors.red);
                }
              } catch (e) {
                _showToast(context, '❌ خطا: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('✅ ثبت بارگیری'),
          ),
        ],
      ),
    );
  }

  static Future<void> showEdit({
    required BuildContext context,
    required Shipment shipment,
    required VoidCallback onSuccess,
  }) async {
    final TextEditingController truckController = TextEditingController(text: shipment.truckName);
    final TextEditingController plateController = TextEditingController(text: shipment.plateNumber);
    final TextEditingController driverController = TextEditingController(text: shipment.driverName);
    final TextEditingController phoneController = TextEditingController(text: shipment.driverPhone);
    final TextEditingController costController = TextEditingController(
      text: shipment.transportCost > 0 ? NumberFormatter.formatNumber(shipment.transportCost) : '',
    );
    String loadDate = shipment.loadDate;

    costController.addListener(() {
      final text = costController.text;
      if (text.isNotEmpty) {
        final onlyDigits = text.replaceAll(',', '');
        if (onlyDigits.isNotEmpty) {
          final parsed = int.tryParse(onlyDigits);
          if (parsed != null) {
            final formatted = NumberFormatter.formatNumber(parsed);
            if (formatted != text) {
              costController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          }
        }
      }
    });

    final dbHelper = DatabaseHelper();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '✏️ ویرایش بارگیری فاکتور #${shipment.invoiceNumber}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(truckController, '🚛 نام ماشین', Icons.directions_truck),
              const SizedBox(height: 12),
              _buildTextField(plateController, '🔢 پلاک ماشین', Icons.confirmation_number),
              const SizedBox(height: 12),
              _buildTextField(driverController, '👤 نام راننده', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(phoneController, '📞 تلفن راننده', Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(costController, '💰 هزینه حمل (تومان)', Icons.money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildDatePicker(context, loadDate, (date) {
                loadDate = date;
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (truckController.text.trim().isEmpty) {
                _showToast(context, '🚛 نام ماشین الزامی است', Colors.orange);
                return;
              }
              if (plateController.text.trim().isEmpty) {
                _showToast(context, '🔢 پلاک ماشین الزامی است', Colors.orange);
                return;
              }
              if (driverController.text.trim().isEmpty) {
                _showToast(context, '👤 نام راننده الزامی است', Colors.orange);
                return;
              }
              if (phoneController.text.trim().length < 10) {
                _showToast(context, '📞 شماره تلفن معتبر نیست (حداقل ۱۰ رقم)', Colors.orange);
                return;
              }
              if (loadDate.isEmpty) {
                _showToast(context, '📅 تاریخ بارگیری الزامی است', Colors.orange);
                return;
              }

              final cost = NumberFormatter.parseNumber(costController.text);

              final updatedShipment = Shipment(
                id: shipment.id,
                invoiceId: shipment.invoiceId,
                invoiceNumber: shipment.invoiceNumber,
                truckName: truckController.text.trim(),
                plateNumber: plateController.text.trim(),
                driverName: driverController.text.trim(),
                driverPhone: phoneController.text.trim(),
                loadDate: loadDate,
                transportCost: cost,
              );

              try {
                final success = await dbHelper.updateShipment(updatedShipment);
                if (success) {
                  _showToast(context, '✅ بارگیری با موفقیت ویرایش شد!', Colors.green);
                  Navigator.pop(context);
                  onSuccess();
                } else {
                  _showToast(context, '❌ خطا در ویرایش!', Colors.red);
                }
              } catch (e) {
                _showToast(context, '❌ خطا: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('✏️ ویرایش بارگیری'),
          ),
        ],
      ),
    );
  }

  static Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
    );
  }

  static Widget _buildDatePicker(
    BuildContext context,
    String currentDate,
    Function(String) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final selected = await showPersianDatePicker(
          context: context,
          initialDate: Jalali.now(),
          firstDate: Jalali(1400, 1, 1),
          lastDate: Jalali(1410, 12, 29),
          locale: const Locale('fa'),
        );
        if (selected != null) {
          final date = '${selected.year}/${selected.month.toString().padLeft(2, '0')}/${selected.day.toString().padLeft(2, '0')}';
          onDateSelected(date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '📅 تاریخ بارگیری',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          currentDate,
          style: const TextStyle(fontSize: 16),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  static void _showToast(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
'@
$dialogContent | Out-File -FilePath "lib\widgets\shipment_dialog.dart" -Encoding UTF8

Write-Host "✅ فایل‌های ویجت ایجاد شدند" -ForegroundColor Green

# ============================================================
# پیام نهایی
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ همه فایل‌ها با موفقیت ایجاد شدند!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 فایل‌های ایجاد شده:" -ForegroundColor Yellow
Write-Host "  📄 lib/models/shipment.dart" -ForegroundColor White
Write-Host "  📄 lib/models/clearance.dart" -ForegroundColor White
Write-Host "  📄 lib/models/iraqi_handover.dart" -ForegroundColor White
Write-Host "  📄 lib/models/buyer_delivery.dart" -ForegroundColor White
Write-Host "  📄 lib/widgets/shipment_dialog.dart" -ForegroundColor White
Write-Host "  📄 lib/widgets/ready_invoices_widget.dart" -ForegroundColor White
Write-Host "  📄 lib/widgets/completed_shipments_widget.dart" -ForegroundColor White
Write-Host "  📄 lib/ui/shipment_screen.dart" -ForegroundColor White
Write-Host ""
Write-Host "🚀 حالا اجرا کنید:" -ForegroundColor Yellow
Write-Host "  flutter pub get" -ForegroundColor Cyan
Write-Host "  flutter run" -ForegroundColor Cyan