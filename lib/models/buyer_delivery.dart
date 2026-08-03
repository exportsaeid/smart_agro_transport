class BuyerDelivery {
  int? id;
  int shipmentId;
  String buyerName;
  String buyerPhone;
  String hajraNumber;
  String deliveryDate;
  int receivedAmount;
  String notes;

  BuyerDelivery({
    this.id,
    required this.shipmentId,
    required this.buyerName,
    required this.buyerPhone,
    required this.hajraNumber,
    required this.deliveryDate,
    required this.receivedAmount,
    this.notes = '',
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
      shipmentId: map['shipment_id'] ?? 0,
      buyerName: map['buyer_name'] ?? '',
      buyerPhone: map['buyer_phone'] ?? '',
      hajraNumber: map['hajra_number'] ?? '',
      deliveryDate: map['delivery_date'] ?? '',
      receivedAmount: map['received_amount'] ?? 0,
      notes: map['notes'] ?? '',
    );
  }
}