import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../models/iraqi_handover.dart';
import '../utils/number_formatter.dart';
import '../widgets/iraqi_handover_dialog.dart';

class IraqiHandoverScreen extends StatefulWidget {
  const IraqiHandoverScreen({super.key});

  @override
  State<IraqiHandoverScreen> createState() => _IraqiHandoverScreenState();
}

class _IraqiHandoverScreenState extends State<IraqiHandoverScreen> {
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
      // فقط بارگیری‌هایی که ترخیص شده‌اند و تحویل عراقی ثبت نشده
      final allCleared = await _dbHelper.getClearedShipments();
      _shipments = [];
      for (var shipment in allCleared) {
        final handover = await _dbHelper.getIraqiHandoverByShipmentId(shipment.id!);
        if (handover == null) {
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

  void _showCreateDialog(Shipment shipment) {
    IraqiHandoverDialog.showCreate(
      context: context,
      shipment: shipment,
      onSuccess: _loadShipments,
    );
  }

  void refreshData() {
    _loadShipments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('🇮🇶 تحویل به ترخیص‌کار عراقی'),
        backgroundColor: Colors.indigo[700],
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '🔍 جستجو در بارگیری‌های ترخیص شده...',
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '🇮🇶 تمام بارگیری‌های ترخیص شده به عراقی تحویل داده شده‌اند',
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
                    color: Colors.indigo,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✅ ترخیص شده',
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
                onPressed: () => _showCreateDialog(shipment),
                icon: const Icon(Icons.people, size: 20),
                label: const Text('🇮🇶 ثبت تحویل به عراقی', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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