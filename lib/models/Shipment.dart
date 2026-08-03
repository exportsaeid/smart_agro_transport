class Shipment {
  int? id;
  int invoiceId;
  String invoiceNumber;
  String truckName;
  String plateNumber;
  String driverName;
  String driverPhone;
  String loadDate;
  int transportCost;
  int clearanceStatus;

  Shipment({
    this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.truckName,
    required this.plateNumber,
    required this.driverName,
    required this.driverPhone,
    required this.loadDate,
    this.transportCost = 0,
    this.clearanceStatus = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'invoice_number': invoiceNumber,
      'truck_name': truckName,
      'plate_number': plateNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'load_date': loadDate,
      'transport_cost': transportCost,
      'clearance_status': clearanceStatus,
    };
  }

  factory Shipment.fromMap(Map<String, dynamic> map) {
    return Shipment(
      id: map['id'],
      invoiceId: map['invoice_id'] ?? 0,
      invoiceNumber: map['invoice_number'] ?? '',
      truckName: map['truck_name'] ?? '',
      plateNumber: map['plate_number'] ?? '',
      driverName: map['driver_name'] ?? '',
      driverPhone: map['driver_phone'] ?? '',
      loadDate: map['load_date'] ?? '',
      transportCost: map['transport_cost'] ?? 0,
      clearanceStatus: map['clearance_status'] ?? 0,
    );
  }
}