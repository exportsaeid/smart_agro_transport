class Clearance {
  int? id;
  int shipmentId;
  String clearanceName;
  String clearancePhone;
  String borderName;
  String clearanceDate;
  String? notes;
  int clearanceCost;

  Clearance({
    this.id,
    required this.shipmentId,
    required this.clearanceName,
    required this.clearancePhone,
    required this.borderName,
    required this.clearanceDate,
    this.notes,
    this.clearanceCost = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'clearance_name': clearanceName,
      'clearance_phone': clearancePhone,
      'border_name': borderName,
      'clearance_date': clearanceDate,
      'notes': notes,
      'clearance_cost': clearanceCost,
    };
  }

  factory Clearance.fromMap(Map<String, dynamic> map) {
    return Clearance(
      id: map['id'],
      shipmentId: map['shipment_id'] ?? 0,
      clearanceName: map['clearance_name'] ?? '',
      clearancePhone: map['clearance_phone'] ?? '',
      borderName: map['border_name'] ?? '',
      clearanceDate: map['clearance_date'] ?? '',
      notes: map['notes'],
      clearanceCost: map['clearance_cost'] ?? 0,
    );
  }
}