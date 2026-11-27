class ProfitItem {
  String invoiceNumber;
  String buyerName;
  double invoiceAmount; // Base amount (items total)
  double miscCost;
  double iranianTransport;
  double iranianClearance;
  double iraqiTotalCost;
  double receivedAmount;
  double profit;
  String loadDate; // تاریخ بارگیری
  String deliveryDate; // تاریخ تحویل به خریدار

  ProfitItem({
    required this.invoiceNumber,
    required this.buyerName,
    required this.invoiceAmount,
    required this.miscCost,
    required this.iranianTransport,
    required this.iranianClearance,
    required this.iraqiTotalCost,
    required this.receivedAmount,
    required this.profit,
    this.loadDate = '',
    this.deliveryDate = '',
  });
}