class InvoiceItem {
  int? id;
  int? invoiceId;
  String productName;
  double weight;
  double unitPrice;
  String name;
  String mobile;
  String address;
  String notes;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productName,
    required this.weight,
    required this.unitPrice,
    this.name = '',
    this.mobile = '',
    this.address = '',
    this.notes = '',
  });

  double get rowTotal => weight * unitPrice;

  Map<String, dynamic> toMap(int invoiceId) {
    final Map<String, dynamic> map = {
      'invoice_id': invoiceId,
      'product_name': productName,
      'weight': weight,
      'unit_price': unitPrice,
      'name': name,
      'mobile': mobile,
      'address': address,
      'notes': notes,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      productName: map['product_name'] ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      name: map['name'] ?? '',
      mobile: map['mobile'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
