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
            // ====== شماره فاکتور و نام مشتری ======
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧾 #${invoice.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '👤 مشتری: ${invoice.customerName}',
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