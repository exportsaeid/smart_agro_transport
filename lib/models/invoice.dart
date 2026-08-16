import 'invoice_item.dart';
import 'attachment.dart';

class Invoice {
  int? id;
  String? invoiceNumber;
  String customerName;
  String customerPhone;
  String date;
  double totalAmount;
  int loadStatus; // 0: not loaded, 1: loaded
  int itemCount;
  double miscCost; // فیلد جدید: هزینه متفرقه
  String miscNotes; // فیلد جدید: توضیحات متفرقه
  List<InvoiceItem> items;
  List<Attachment> attachments;

  Invoice({
    this.id,
    this.invoiceNumber,
    required this.customerName,
    required this.customerPhone,
    required this.date,
    required this.totalAmount,
    this.loadStatus = 0,
    this.itemCount = 0,
    this.miscCost = 0.0,
    this.miscNotes = '',
    this.items = const [],
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'date': date,
      'total_amount': totalAmount,
      'load_status': loadStatus,
      'misc_cost': miscCost,
      'misc_notes': miscNotes,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'] ?? '',
      date: map['date'] ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      loadStatus: map['load_status'] ?? 0,
      itemCount: map['item_count'] ?? 0,
      miscCost: (map['misc_cost'] as num?)?.toDouble() ?? 0.0,
      miscNotes: map['misc_notes'] ?? '',
    );
  }
}
