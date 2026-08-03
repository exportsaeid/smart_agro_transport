import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../models/buyer_delivery.dart';
import '../models/invoice.dart';
import '../models/iraqi_handover.dart';
import '../utils/number_formatter.dart';
import '../dialogs/buyer_delivery_dialog.dart';

class BuyerDeliveryScreen extends StatefulWidget {
  const BuyerDeliveryScreen({super.key});

  @override
  State<BuyerDeliveryScreen> createState() => _BuyerDeliveryScreenState();
}

class _BuyerDeliveryScreenState extends State<BuyerDeliveryScreen> {
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
      final allCleared = await _dbHelper.getClearedShipments();
      _shipments = [];

      for (var shipment in allCleared) {
        final handover = await _dbHelper.getIraqiHandoverByShipmentId(shipment.id!);
        // فقط بارهایی که ترخیص عراقی دارند (حتی اگر تحویل هم ثبت شده باشد)
        if (handover != null) {
          _shipments.add(shipment);
        }
      }

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
      _filteredShipments = _shipments.where((shipment) {
        return shipment.invoiceNumber.toLowerCase().contains(query) ||
            shipment.truckName.toLowerCase().contains(query) ||
            shipment.driverName.toLowerCase().contains(query) ||
            shipment.plateNumber.toLowerCase().contains(query);
      }).toList();
    }
    setState(() {});
  }

  void _showSnackBar(String message, Color color) {
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

  void _showCreateDialog(Shipment shipment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BuyerDeliveryDialog(
        shipment: shipment,
        isEdit: false,
        onSuccess: _loadShipments,
      ),
    );
  }

  void _showEditDialog(Shipment shipment, BuyerDelivery delivery) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BuyerDeliveryDialog(
        shipment: shipment,
        delivery: delivery,
        isEdit: true,
        onSuccess: _loadShipments,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('📦 تحویل نهایی به خریدار'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadShipments();
              _showSnackBar('🔄 اطلاعات بروزرسانی شد', Colors.blue);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // جستجو
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '🔍 جستجو بر اساس شماره فاکتور، ماشین، پلاک یا راننده...',
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

          // لیست
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
                return FutureBuilder(
                  future: Future.wait([
                    _dbHelper.getBuyerDeliveryByShipmentId(shipment.id!),
                    _dbHelper.getInvoiceById(shipment.invoiceId),
                    _dbHelper.getIraqiHandoverByShipmentId(shipment.id!),
                  ]),
                  builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                    if (!snapshot.hasData) {
                      return const Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    final delivery = snapshot.data![0] as BuyerDelivery?;
                    final invoice = snapshot.data![1] as Invoice?;
                    final iraqiHandover = snapshot.data![2] as IraqiHandover?;
                    final isDelivered = delivery != null;

                    return BuyerDeliveryItem(
                      shipment: shipment,
                      delivery: delivery,
                      invoice: invoice,
                      iraqiHandover: iraqiHandover,
                      isDelivered: isDelivered,
                      onEdit: () => _showEditDialog(shipment, delivery!),
                      onCreate: () => _showCreateDialog(shipment),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '📦 هیچ باری برای تحویل به خریدار وجود ندارد',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'ابتدا باید ترخیص عراقی ثبت شده باشد',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// کارت هر بار (مثل item_buyer_delivery در اندروید)
// ============================================================
class BuyerDeliveryItem extends StatelessWidget {
  final Shipment shipment;
  final BuyerDelivery? delivery;
  final Invoice? invoice;
  final IraqiHandover? iraqiHandover;
  final bool isDelivered;
  final VoidCallback onEdit;
  final VoidCallback onCreate;

  const BuyerDeliveryItem({
    super.key,
    required this.shipment,
    this.delivery,
    this.invoice,
    this.iraqiHandover,
    required this.isDelivered,
    required this.onEdit,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final customerName = invoice?.customerName ?? 'مشتری نامشخص';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شماره فاکتور + وضعیت
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧾 #${shipment.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      '👤 مشتری: $customerName',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivered ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDelivered ? '✅ تحویل شده' : '⏳ در انتظار تحویل',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // اطلاعات راننده و ماشین
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

            // هزینه حمل + تاریخ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💰 هزینه حمل: ${NumberFormatter.formatNumber(shipment.transportCost)} تومان',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                ),
                Text('📅 ${shipment.loadDate}'),
              ],
            ),

            // اطلاعات تحویل به خریدار (اگر ثبت شده)
            if (isDelivered && delivery != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📦 اطلاعات تحویل به خریدار',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          onPressed: onEdit,
                          tooltip: 'ویرایش تحویل',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('👤 خریدار: ${delivery!.buyerName}'),
                    Text('📞 ${delivery!.buyerPhone}'),
                    if (delivery!.hajraNumber.isNotEmpty)
                      Text('🏪 حجره: ${delivery!.hajraNumber}'),
                    Text('💰 مبلغ دریافتی: ${NumberFormatter.formatNumber(delivery!.receivedAmount)} تومان'),
                    Text('📅 تاریخ: ${delivery!.deliveryDate}'),
                    if (delivery!.notes.isNotEmpty)
                      Text('📝 توضیحات: ${delivery!.notes}'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // دکمه ثبت (فقط وقتی هنوز ثبت نشده)
            if (!isDelivered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.payment, size: 20),
                  label: const Text('📦 ثبت تحویل به خریدار', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}