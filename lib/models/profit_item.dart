class ProfitItem {
  final String invoiceNumber;
  final String buyerName;
  final int invoiceAmount;
  final int iranianTransport;
  final int iranianClearance;
  final int iraqiTotalCost;
  final int receivedAmount;
  final int profit;

  ProfitItem({
    required this.invoiceNumber,
    required this.buyerName,
    required this.invoiceAmount,
    required this.iranianTransport,
    required this.iranianClearance,
    required this.iraqiTotalCost,
    required this.receivedAmount,
    required this.profit,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoice_number': invoiceNumber,
      'buyer_name': buyerName,
      'invoice_amount': invoiceAmount,
      'iranian_transport': iranianTransport,
      'iranian_clearance': iranianClearance,
      'iraqi_total_cost': iraqiTotalCost,
      'received_amount': receivedAmount,
      'profit': profit,
    };
  }

  factory ProfitItem.fromMap(Map<String, dynamic> map) {
    return ProfitItem(
      invoiceNumber: map['invoice_number'] ?? '',
      buyerName: map['buyer_name'] ?? '',
      invoiceAmount: map['invoice_amount'] ?? 0,
      iranianTransport: map['iranian_transport'] ?? 0,
      iranianClearance: map['iranian_clearance'] ?? 0,
      iraqiTotalCost: map['iraqi_total_cost'] ?? 0,
      receivedAmount: map['received_amount'] ?? 0,
      profit: map['profit'] ?? 0,
    );
  }
}