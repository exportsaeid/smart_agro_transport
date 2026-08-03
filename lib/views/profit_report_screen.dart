import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/shipment.dart';
import '../models/profit_item.dart';
import '../utils/number_formatter.dart';
import '../widgets/profit_report_item.dart';

class ProfitReportScreen extends StatefulWidget {
  const ProfitReportScreen({super.key});

  @override
  State<ProfitReportScreen> createState() => _ProfitReportScreenState();
}

class _ProfitReportScreenState extends State<ProfitReportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<ProfitItem> _items = [];
  List<ProfitItem> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _totalProfit = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ========== بارگذاری داده‌ها ==========
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _items = await _calculateProfit();
      _filteredItems = List.from(_items);
      _applyFilter();
      _calcTotal();
    } catch (e) {
      _showSnackBar('❌ خطا: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ========== محاسبه سود ==========
  Future<List<ProfitItem>> _calculateProfit() async {
    final List<ProfitItem> result = [];
    final shipments = await _dbHelper.getAllShipments();

    for (var shipment in shipments) {
      // دریافت فاکتور
      final invoice = await _dbHelper.getInvoiceById(shipment.invoiceId);
      if (invoice == null) continue;

      // دریافت ترخیص ایرانی
      final clearance = await _dbHelper.getClearanceByShipmentId(shipment.id!);

      // دریافت تحویل عراقی
      final iraqi = await _dbHelper.getIraqiHandoverByShipmentId(shipment.id!);

      // دریافت تحویل به خریدار
      final buyerDelivery = await _dbHelper.getBuyerDeliveryByShipmentId(shipment.id!);
      if (buyerDelivery == null) continue;

      // محاسبه مبلغ فاکتور
      final items = await _dbHelper.getItemsByInvoiceId(invoice.id!);
      int itemsTotal = 0;
      for (var item in items) {
        itemsTotal += (item.weight * item.unitPrice);
      }
      final invoiceAmount = itemsTotal + invoice.extraCost;

      // هزینه‌ها
      final iranianTransport = shipment.transportCost;
      final iranianClearance = clearance?.clearanceCost ?? 0;
      final iraqiTotalCost = iraqi?.clearanceCost ?? 0;
      final receivedAmount = buyerDelivery.receivedAmount;

      // محاسبه سود
      final totalCosts = invoiceAmount + iranianTransport + iranianClearance + iraqiTotalCost;
      final profit = receivedAmount - totalCosts;

      result.add(ProfitItem(
        invoiceNumber: invoice.invoiceNumber,
        buyerName: buyerDelivery.buyerName,
        invoiceAmount: invoiceAmount,
        iranianTransport: iranianTransport,
        iranianClearance: iranianClearance,
        iraqiTotalCost: iraqiTotalCost,
        receivedAmount: receivedAmount,
        profit: profit,
      ));
    }

    // مرتب‌سازی بر اساس سود (بیشترین اول)
    result.sort((a, b) => b.profit.compareTo(a.profit));
    return result;
  }

  // ========== فیلتر ==========
  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredItems = List.from(_items);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredItems = _items.where((item) =>
      item.invoiceNumber.toLowerCase().contains(query) ||
          item.buyerName.toLowerCase().contains(query)).toList();
    }
    setState(() {});
  }

  // ========== محاسبه جمع کل ==========
  void _calcTotal() {
    _totalProfit = 0;
    for (var item in _filteredItems) {
      _totalProfit += item.profit;
    }
    setState(() {});
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ========== وضعیت خالی ==========
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '📊 هیچ فاکتور تکمیل شده‌ای وجود ندارد',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'پس از ثبت تحویل به خریدار، گزارش نمایش داده می‌شود',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('📊 گزارش سود و زیان'),
        backgroundColor: Colors.blue[700],
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
              _loadData();
              _showSnackBar('🔄 بروزرسانی شد', Colors.blue);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ====== جمع کل ======
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _totalProfit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _totalProfit >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💰 جمع کل سود/ضرر:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_totalProfit >= 0 ? '+' : ''}${NumberFormatter.formatNumber(_totalProfit)} تومان',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _totalProfit >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // ====== جستجو ======
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: '🔍 جستجو بر اساس شماره فاکتور یا نام خریدار...',
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
                _calcTotal();
              },
            ),
          ),

          const SizedBox(height: 8),

          // ====== تعداد ======
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${_filteredItems.length} فاکتور تکمیل شده',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),

          const SizedBox(height: 8),

          // ====== لیست ======
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return ProfitReportItem(item: _filteredItems[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}