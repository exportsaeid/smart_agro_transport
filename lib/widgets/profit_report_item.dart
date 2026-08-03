import 'package:flutter/material.dart';
import '../models/profit_item.dart';
import '../utils/number_formatter.dart';

class ProfitReportItem extends StatelessWidget {
  final ProfitItem item;

  const ProfitReportItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isProfit = item.profit >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== شماره فاکتور و وضعیت ======
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🧾 #${item.invoiceNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isProfit ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isProfit ? '💰 سود' : '💸 ضرر',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '👤 خریدار: ${item.buyerName}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // ====== جزئیات ======
            _buildRow('📄 مبلغ فاکتور', NumberFormatter.formatNumber(item.invoiceAmount)),
            _buildRow('🚛 کرایه ایرانی', NumberFormatter.formatNumber(item.iranianTransport)),
            _buildRow('🛂 ترخیص ایرانی', NumberFormatter.formatNumber(item.iranianClearance)),
            _buildRow('🇮🇶 ترخیص عراقی', NumberFormatter.formatNumber(item.iraqiTotalCost)),
            _buildRow('💰 دریافتی از خریدار', NumberFormatter.formatNumber(item.receivedAmount)),

            const Divider(height: 20),

            // ====== سود/ضرر نهایی ======
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💰 سود/ضرر خالص:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${isProfit ? '+' : ''}${NumberFormatter.formatNumber(item.profit)} تومان',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isProfit ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}