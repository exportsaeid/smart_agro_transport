import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../database/database_helper.dart';
import '../utils/number_formatter.dart';
import '../views/main_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  // ========== بارگذاری فاکتورها ==========
  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _allInvoices = await _dbHelper.getAllInvoices();
      _filteredInvoices = List.from(_allInvoices);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطا در بارگذاری فاکتورها: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ========== جستجو ==========
  void _filterInvoices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInvoices = List.from(_allInvoices);
      } else {
        final searchLower = query.toLowerCase();
        _filteredInvoices = _allInvoices.where((invoice) {
          return invoice.customerName.toLowerCase().contains(searchLower) ||
              invoice.invoiceNumber.toLowerCase().contains(searchLower) ||
              invoice.date.contains(searchLower);
        }).toList();
      }
    });
  }

  // ========== ویرایش فاکتور ==========
  void _editInvoice(Invoice invoice) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          editInvoiceId: invoice.id,
        ),
      ),
    );

    if (result == true) {
      _loadInvoices();
    }
  }

  // ========== حذف فاکتور ==========
  void _deleteInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ حذف فاکتور'),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید فاکتور #${invoice.invoiceNumber} را حذف کنید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dbHelper.deleteInvoice(invoice.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ فاکتور #${invoice.invoiceNumber} حذف شد'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadInvoices();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ خطا در حذف فاکتور: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
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
        title: const Text('📋 لیست فاکتورهای ذخیره شده'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ========== جستجو ==========
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '🔍 جستجو بر اساس شماره فاکتور، نام مشتری یا تاریخ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _filterInvoices,
            ),
          ),

          // ========== لیست فاکتورها ==========
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '📭 هیچ فاکتوری یافت نشد',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredInvoices.length,
              itemBuilder: (context, index) {
                final invoice = _filteredInvoices[index];
                return _buildInvoiceCard(invoice);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ========== کارت فاکتور ==========
  Widget _buildInvoiceCard(Invoice invoice) {
    final grandTotal = invoice.totalAmount;
    final itemCount = invoice.items.length;
    final hasShipment = invoice.loadStatus == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasShipment ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasShipment ? '✅ بارگیری شده' : '⏳ آماده بارگیری',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ====== تاریخ ======
            Text(
              '📅 تاریخ: ${invoice.date}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),

            // ====== جمع کل و تعداد آیتم ======
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💰 جمع کل: ${NumberFormatter.formatNumber(grandTotal)} تومان',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  '📦 ${itemCount} آیتم',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            // ====== هزینه متفرقه (در صورت وجود) ======
            if (invoice.extraCost > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '📌 هزینه متفرقه: ${NumberFormatter.formatNumber(invoice.extraCost)} تومان',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ====== دکمه‌های عملیات ======
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // دکمه ویرایش
                OutlinedButton.icon(
                  onPressed: () => _editInvoice(invoice),
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  label: const Text(
                    'ویرایش',
                    style: TextStyle(color: Colors.blue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),

                // دکمه حذف
                OutlinedButton.icon(
                  onPressed: () => _deleteInvoice(invoice),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text(
                    'حذف',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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