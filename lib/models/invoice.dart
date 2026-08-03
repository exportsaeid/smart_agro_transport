import 'invoice_item.dart';

class Invoice {
  int? id;
  String invoiceNumber;
  String customerName;
  String customerPhone;
  String date;
  int totalAmount;
  int extraCost;
  String extraDescription;
  int loadStatus; // ← جدید
  List<InvoiceItem> items;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerPhone,
    required this.date,
    this.totalAmount = 0,
    this.extraCost = 0,
    this.extraDescription = '',
    this.loadStatus = 0, // ← مقدار پیش‌فرض
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'date': date,
      'total_amount': totalAmount,
      'extra_cost': extraCost,
      'extra_description': extraDescription,
      'load_status': loadStatus, // ← جدید
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoice_number'] ?? '',
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'] ?? '',
      date: map['date'] ?? '',
      totalAmount: map['total_amount'] ?? 0,
      extraCost: map['extra_cost'] ?? 0,
      extraDescription: map['extra_description'] ?? '',
      loadStatus: map['load_status'] ?? 0, // ← جدید
    );
  }

  int calculateGrandTotal() {
    int itemsTotal = 0;
    for (var item in items) {
      itemsTotal += item.rowTotal;
    }
    return itemsTotal + extraCost;
  }
}