import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../models/buyer_delivery.dart';
import '../models/iraqi_handover.dart';
import '../models/invoice.dart';
import '../utils/number_formatter.dart';

class BuyerDeliveryItem extends StatelessWidget {
  final Shipment shipment;
  final BuyerDelivery? delivery;
  final Invoice? invoice;
  final IraqiHandover? iraqiHandover;
  final bool isDelivered;
  final VoidCallback onEdit;
  final VoidCallback onCreate;

  const BuyerDeliveryItem({
    super.key,
    required this.shipment,
    this.delivery,
    this.invoice,
    this.iraqiHandover,
    required this.isDelivered,
    required this.onEdit,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final customerName = invoice?.customerName ?? 'مشتری نامشخص';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== شماره فاکتور + نام مشتری =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧾 #${shipment.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      '👤 مشتری: $customerName',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivered ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDelivered ? '✅ تحویل شده' : '⏳ در انتظار تحویل',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ===== اطلاعات راننده و ماشین =====
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('👤 راننده: ${shipment.driverName}'),
                      Text('📞 ${shipment.driverPhone}'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🚛 ماشین: ${shipment.truckName}'),
                      Text('🔢 پلاک: ${shipment.plateNumber}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ===== هزینه حمل و تاریخ =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💰 هزینه حمل: ${NumberFormatter.formatNumber(shipment.transportCost)} تومان',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text('📅 ${shipment.loadDate}'),
              ],
            ),

            // ===== اطلاعات تحویل عراقی =====
            if (iraqiHandover != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🇮🇶 تحویل به ترخیص‌کار عراقی',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('👤 نام: ${iraqiHandover!.clearanceName}'),
                    Text('📞 تلفن: ${iraqiHandover!.clearancePhone}'),
                    Text('🛂 مرز: ${iraqiHandover!.borderName}'),
                    Text('📅 تاریخ: ${iraqiHandover!.clearanceDate}'),
                  ],
                ),
              ),
            ],

            // ===== اطلاعات تحویل به خریدار (اگر ثبت شده) =====
            if (isDelivered && delivery != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📦 اطلاعات تحویل به خریدار',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                        // دکمه ویرایش تحویل
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          onPressed: onEdit,
                          tooltip: 'ویرایش تحویل',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('👤 خریدار: ${delivery!.buyerName}'),
                    Text('📞 ${delivery!.buyerPhone}'),
                    if (delivery!.hajraNumber.isNotEmpty)
                      Text('🏪 حجره: ${delivery!.hajraNumber}'),
                    Text('💰 مبلغ دریافتی: ${NumberFormatter.formatNumber(delivery!.receivedAmount)} تومان'),
                    Text('📅 تاریخ: ${delivery!.deliveryDate}'),
                    if (delivery!.notes.isNotEmpty)
                      Text('📝 توضیحات: ${delivery!.notes}'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // ===== دکمه ثبت تحویل (اگر ثبت نشده) =====
            if (!isDelivered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.payment, size: 20),
                  label: const Text(
                    '📦 ثبت تحویل به خریدار',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}