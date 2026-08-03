import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../models/invoice.dart';
import '../utils/number_formatter.dart';
import 'clearance_dialog.dart';

class InTransitWidget extends StatefulWidget {
  final VoidCallback? onCleared;

  const InTransitWidget({super.key, this.onCleared});

  @override
  State<InTransitWidget> createState() => _InTransitWidgetState();
}

class _InTransitWidgetState extends State<InTransitWidget> {
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
      _shipments = await _dbHelper.getInTransitShipments();
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

  void _showClearanceDialog(Shipment shipment) {
    ClearanceDialog.showCreate(
      context: context,
      shipment: shipment,
      onSuccess: () {
        _loadShipments();
        if (widget.onCleared != null) {
          widget.onCleared!();
        }
      },
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
                            color: Colors.orange,
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
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '⏳ در راه مرز',
                        style: TextStyle(color: Colors.white, fontSize: 11),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showClearanceDialog(shipment),
                    icon: const Icon(Icons.location_on, size: 20),
                    label: const Text('🛂 ثبت ترخیص', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
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
              hintText: '🔍 جستجو در بارگیری‌های در راه مرز...',
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
          Icon(Icons.location_on, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '🚚 هیچ بارگیری در راه مرز وجود ندارد',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}