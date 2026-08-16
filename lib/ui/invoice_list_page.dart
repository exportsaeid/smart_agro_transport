// lib/ui/invoice_list_page.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../models/invoice.dart';
import '../database/database_helper.dart';
import '../utils/pdf_generator.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final list = await DatabaseHelper.instance.getAllInvoices();
    setState(() {
      _allInvoices = list;
      _filteredInvoices = list;
      _isLoading = false;
    });
  }

  void _filterInvoices(String query) {
    setState(() {
      _filteredInvoices = _allInvoices.where((invoice) {
        final customerName = invoice.customerName.toLowerCase();
        final date = invoice.date.toLowerCase();
        final invoiceNumber = (invoice.invoiceNumber ?? '').toLowerCase();
        final searchLower = query.toLowerCase();

        return customerName.contains(searchLower) ||
            date.contains(searchLower) ||
            invoiceNumber.contains(searchLower);
      }).toList();
    });
  }

  void _deleteInvoice(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ حذف فاکتور', textAlign: TextAlign.right),
        content: const Text('آیا از حذف این فاکتور مطمئن هستید؟ این عمل غیرقابل بازگشت است.', textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف شود', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteInvoice(id);
      _loadInvoices();
      if (mounted) {
        _showToast('✅ فاکتور با موفقیت حذف شد');
      }
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tahoma')),
      ),
    );
  }

  Future<void> _printInvoice(Invoice invoice) async {
    setState(() => _processingIds.add(invoice.id!));

    try {
      final fullInvoice = await DatabaseHelper.instance.getInvoice(invoice.id!);
      if (fullInvoice == null) {
        _showToast('❌ فاکتور یافت نشد');
        return;
      }
      await PdfGenerator.printPdf(fullInvoice);
      _showToast('🖨️ فاکتور برای چاپ ارسال شد');
    } catch (e) {
      _showToast('❌ خطا در چاپ: $e');
    } finally {
      if (mounted) setState(() => _processingIds.remove(invoice.id));
    }
  }

  Future<void> _sharePdf(Invoice invoice) async {
    setState(() => _processingIds.add(invoice.id!));

    try {
      final fullInvoice = await DatabaseHelper.instance.getInvoice(invoice.id!);
      if (fullInvoice == null) {
        _showToast('❌ فاکتور یافت نشد');
        return;
      }
      await PdfGenerator.sharePdf(fullInvoice);
      _showToast('📤 فاکتور برای اشتراک‌گذاری ارسال شد');
    } catch (e) {
      _showToast('❌ خطا در اشتراک‌گذاری: $e');
    } finally {
      if (mounted) setState(() => _processingIds.remove(invoice.id));
    }
  }

  Future<void> _savePdf(Invoice invoice) async {
    setState(() => _processingIds.add(invoice.id!));

    try {
      final fullInvoice = await DatabaseHelper.instance.getInvoice(invoice.id!);
      if (fullInvoice == null) {
        _showToast('❌ فاکتور یافت نشد');
        return;
      }
      final path = await PdfGenerator.savePdf(fullInvoice);
      if (path != null) {
        _showToast('✅ PDF ذخیره شد: $path');
        await OpenFilex.open(path);
      } else {
        _showToast('❌ ذخیره PDF لغو شد');
      }
    } catch (e) {
      _showToast('❌ خطا در ذخیره PDF: $e');
    } finally {
      if (mounted) setState(() => _processingIds.remove(invoice.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###");

    return Directionality(
      textDirection: ui.TextDirection.rtl, // ✅ اصلاح شده
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(top: 40, bottom: 20, right: 16, left: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '📋 لیست فاکتورهای ذخیره شده',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tahoma'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterInvoices,
                decoration: InputDecoration(
                  hintText: 'جستجو بر اساس نام مشتری یا تاریخ...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredInvoices.isEmpty
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('📭', style: TextStyle(fontSize: 60)),
                  SizedBox(height: 16),
                  Text('هیچ فاکتوری یافت نشد', style: TextStyle(color: Colors.grey, fontSize: 18, fontFamily: 'Tahoma')),
                ],
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _filteredInvoices.length,
                itemBuilder: (context, index) {
                  final invoice = _filteredInvoices[index];
                  final isProcessing = _processingIds.contains(invoice.id);

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status and Customer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '👤 مشتری: ${invoice.customerName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Tahoma'),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: invoice.loadStatus == 1 ? Colors.green[100] : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  invoice.loadStatus == 1 ? '✅ بارگیری شده' : '⏳ آماده بارگیری',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: invoice.loadStatus == 1 ? Colors.green[800] : Colors.orange[800],
                                    fontFamily: 'Tahoma',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('🧾 شماره فاکتور: ${invoice.invoiceNumber ?? '---'}', style: const TextStyle(color: Colors.blueGrey)),
                          const SizedBox(height: 4),
                          Text('📅 تاریخ: ${invoice.date}', style: const TextStyle(color: Colors.blueGrey)),
                          const SizedBox(height: 4),
                          Text('📦 تعداد آیتم: ${invoice.itemCount}', style: const TextStyle(color: Colors.blueGrey)),
                          const SizedBox(height: 12),
                          Text(
                            '💰 جمع کل: ${currencyFormat.format(invoice.totalAmount)} تومان',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Tahoma'),
                          ),
                          const Divider(height: 24),

                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // چاپ
                              IconButton(
                                icon: isProcessing
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                )
                                    : const Icon(Icons.print, color: Colors.blue),
                                onPressed: isProcessing ? null : () => _printInvoice(invoice),
                                tooltip: 'چاپ فاکتور',
                              ),
                              // اشتراک‌گذاری
                              IconButton(
                                icon: isProcessing
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.green,
                                  ),
                                )
                                    : const Icon(Icons.share, color: Colors.green),
                                onPressed: isProcessing ? null : () => _sharePdf(invoice),
                                tooltip: 'اشتراک‌گذاری PDF',
                              ),
                              // ذخیره PDF
                              IconButton(
                                icon: isProcessing
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange,
                                  ),
                                )
                                    : const Icon(Icons.save_alt, color: Colors.orange),
                                onPressed: isProcessing ? null : () => _savePdf(invoice),
                                tooltip: 'ذخیره PDF',
                              ),
                              const SizedBox(width: 8),
                              // ویرایش
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context, invoice.id),
                                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                label: const Text('ویرایش', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // حذف
                              ElevatedButton.icon(
                                onPressed: () => _deleteInvoice(invoice.id!),
                                icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                                label: const Text('حذف', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF44336),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}