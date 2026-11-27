class BuyerDelivery {
  int? id;
  int shipmentId;
  String buyerName;
  String buyerPhone;
  String hajraNumber;
  String deliveryDate;
  double receivedAmount;
  String notes;

  BuyerDelivery({
    this.id,
    required this.shipmentId,
    required this.buyerName,
    required this.buyerPhone,
    required this.hajraNumber,
    required this.deliveryDate,
    this.receivedAmount = 0.0,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'hajra_number': hajraNumber,
      'delivery_date': deliveryDate,
      'received_amount': receivedAmount,
      'notes': notes,
    };
  }

  factory BuyerDelivery.fromMap(Map<String, dynamic> map) {
    return BuyerDelivery(
      id: map['id'],
      shipmentId: map['shipment_id'],
      buyerName: map['buyer_name'] ?? '',
      buyerPhone: map['buyer_phone'] ?? '',
      hajraNumber: map['hajra_number'] ?? '',
      deliveryDate: map['delivery_date'] ?? '',
      receivedAmount: (map['received_amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
    );
  }
}
