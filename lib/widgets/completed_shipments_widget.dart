import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../models/invoice.dart';
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

  Widget _buildShipmentCard(Shipment shipment) {
    return FutureBuilder<Invoice?>(
      future: _dbHelper.getInvoiceById(shipment.invoiceId),
      builder: (context, snapshot) {
        final invoice = snapshot.data;
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
                // ====== شماره فاکتور و نام مشتری ======
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚛 #${shipment.invoiceNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '👤 مشتری: $customerName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
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
      },
    );
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
}