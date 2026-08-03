class InvoiceItem {
  int? id;
  int invoiceId;
  String productName;
  int weight;
  int unitPrice;
  String name;
  String mobile;
  String address;
  String notes;

  InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productName,
    required this.weight,
    required this.unitPrice,
    this.name = '',
    this.mobile = '',
    this.address = '',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_name': productName,
      'weight': weight,
      'unit_price': unitPrice,
      'name': name,
      'mobile': mobile,
      'address': address,
      'notes': notes,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'] ?? 0,
      productName: map['product_name'] ?? '',
      weight: map['weight']?.toInt() ?? 0,
      unitPrice: map['unit_price']?.toInt() ?? 0,
      name: map['name'] ?? '',
      mobile: map['mobile'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  int get rowTotal => (weight * unitPrice).toInt();
}
