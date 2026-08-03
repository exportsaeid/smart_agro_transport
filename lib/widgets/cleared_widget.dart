import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../models/invoice.dart';
import '../models/clearance.dart';
import '../models/iraqi_handover.dart';
import '../utils/number_formatter.dart';
import 'clearance_dialog.dart';
import 'iraqi_handover_dialog.dart';

class ClearedWidget extends StatefulWidget {
  const ClearedWidget({super.key});

  @override
  State<ClearedWidget> createState() => _ClearedWidgetState();
}

class _ClearedWidgetState extends State<ClearedWidget> {
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
      _shipments = await _dbHelper.getClearedShipments();
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

  void _showEditClearanceDialog(Shipment shipment) async {
    final clearance = await _dbHelper.getClearanceByShipmentId(shipment.id!);
    if (clearance == null) {
      _showSnackBar('❌ اطلاعات ترخیص یافت نشد!', Colors.red);
      return;
    }
    ClearanceDialog.showEdit(
      context: context,
      shipment: shipment,
      clearance: clearance,
      onSuccess: _loadShipments,
    );
  }

  void _showIraqiHandoverDialog(Shipment shipment) async {
    final handover = await _dbHelper.getIraqiHandoverByShipmentId(shipment.id!);
    if (handover != null) {
      IraqiHandoverDialog.showEdit(
        context: context,
        shipment: shipment,
        handover: handover,
        onSuccess: _loadShipments,
      );
    } else {
      IraqiHandoverDialog.showCreate(
        context: context,
        shipment: shipment,
        onSuccess: _loadShipments,
      );
    }
  }

  void refreshData() {
    _loadShipments();
  }

  Widget _buildShipmentCard(Shipment shipment) {
    return FutureBuilder(
      future: Future.wait([
        _dbHelper.getInvoiceById(shipment.invoiceId),
        _dbHelper.getClearanceByShipmentId(shipment.id!),
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

        final invoice = snapshot.data![0] as Invoice?;
        final clearance = snapshot.data![1] as Clearance?;
        final iraqiHandover = snapshot.data![2] as IraqiHandover?;
        final hasIraqi = iraqiHandover != null;
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
                            color: Colors.purple,
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
                        color: Colors.purple,
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

                // ====== اطلاعات راننده و ماشین ======
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
                const SizedBox(height: 12),

                // ====== اطلاعات ترخیص و تحویل عراقی (کنار هم) ======
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ترخیص ایرانی
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🛂 اطلاعات ترخیص ایرانی',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (clearance != null) ...[
                              Text('👤 ترخیصکار: ${clearance.clearanceName}'),
                              Text('📞 ${clearance.clearancePhone}'),
                              Text('🛂 مرز: ${clearance.borderName}'),
                              Text('💰 هزینه: ${NumberFormatter.formatNumber(clearance.clearanceCost)} تومان'),
                              Text('📅 تاریخ: ${clearance.clearanceDate}'),
                              if (clearance.notes != null && clearance.notes!.isNotEmpty)
                                Text('📝 ${clearance.notes}'),
                            ] else
                              const Text('⚠️ اطلاعات ترخیص ثبت نشده'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // تحویل به عراقی
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🇮🇶 تحویل به ترخیص‌کار عراقی',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (hasIraqi) ...[
                              Text('👤 نام: ${iraqiHandover!.clearanceName}'),
                              Text('📞 تلفن: ${iraqiHandover.clearancePhone}'),
                              Text('🛂 مرز: ${iraqiHandover.borderName}'),
                              Text('💰 هزینه اضافی: ${NumberFormatter.formatNumber(iraqiHandover.clearanceCost)} تومان'),
                              Text('📅 تاریخ: ${iraqiHandover.clearanceDate}'),
                              if (iraqiHandover.notes != null && iraqiHandover.notes!.isNotEmpty)
                                Text('📝 ${iraqiHandover.notes}'),
                            ] else
                              const Text('⚠️ تحویل به عراقی ثبت نشده'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // ====== دکمه‌های عملیات ======
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showEditClearanceDialog(shipment),
                      icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
                      label: Text(
                        clearance == null ? 'ثبت ترخیص' : 'ویرایش ترخیص',
                        style: const TextStyle(color: Colors.orange),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showIraqiHandoverDialog(shipment),
                      icon: const Icon(Icons.people, size: 18, color: Colors.indigo),
                      label: Text(
                        hasIraqi ? 'ویرایش عراقی' : 'ثبت عراقی',
                        style: const TextStyle(color: Colors.indigo),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.indigo),
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
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '✅ هیچ بارگیری ترخیص شده‌ای وجود ندارد',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}