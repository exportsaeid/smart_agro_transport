import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../models/buyer_delivery.dart';
import '../utils/number_formatter.dart';
import '../utils/persian_date_picker.dart';

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final onlyDigits = newValue.text.replaceAll(',', '');
    if (onlyDigits.isEmpty) return newValue.copyWith(text: '');
    final parsed = int.tryParse(onlyDigits);
    if (parsed == null) return oldValue;
    final formatter = NumberFormat('#,###');
    final newText = formatter.format(parsed);
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

class BuyerDeliveryDialog {
  static Future<void> showCreate({
    required BuildContext context,
    required Shipment shipment,
    required VoidCallback onSuccess,
  }) async {
    final TextEditingController buyerNameController = TextEditingController();
    final TextEditingController buyerPhoneController = TextEditingController();
    final TextEditingController hajraController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    final now = Jalali.now();
    String deliveryDate = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    amountController.addListener(() {
      final text = amountController.text;
      if (text.isNotEmpty) {
        final onlyDigits = text.replaceAll(',', '');
        if (onlyDigits.isNotEmpty) {
          final parsed = int.tryParse(onlyDigits);
          if (parsed != null) {
            final formatted = NumberFormatter.formatNumber(parsed);
            if (formatted != text) {
              amountController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          }
        }
      }
    });

    final dbHelper = DatabaseHelper();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.payment, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '📦 تحویل نهایی به خریدار - فاکتور #${shipment.invoiceNumber}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(buyerNameController, '👤 نام خریدار', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(buyerPhoneController, '📞 تلفن خریدار', Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(hajraController, '🏪 شماره حجره خریدار', Icons.store),
              const SizedBox(height: 12),
              _buildTextField(amountController, '💰 مبلغ دریافت شده (تومان)', Icons.money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(notesController, '📝 توضیحات (روش پرداخت، امضا و ...)', Icons.description,
                  maxLines: 2),
              const SizedBox(height: 12),
              _buildDatePicker(context, deliveryDate, (date) {
                deliveryDate = date;
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (buyerNameController.text.trim().isEmpty) {
                _showToast(context, '👤 نام خریدار الزامی است', Colors.orange);
                return;
              }
              if (deliveryDate.isEmpty) {
                _showToast(context, '📅 تاریخ تحویل الزامی است', Colors.orange);
                return;
              }

              final amount = NumberFormatter.parseNumber(amountController.text);

              final delivery = BuyerDelivery(
                shipmentId: shipment.id!,
                buyerName: buyerNameController.text.trim(),
                buyerPhone: buyerPhoneController.text.trim(),
                hajraNumber: hajraController.text.trim(),
                deliveryDate: deliveryDate,
                receivedAmount: amount,
                notes: notesController.text.trim(),
              );

              try {
                final id = await dbHelper.addBuyerDelivery(delivery);
                if (id > 0) {
                  _showToast(context, '✅ تحویل به خریدار با موفقیت ثبت شد!', Colors.green);
                  Navigator.pop(context);
                  onSuccess();
                } else {
                  _showToast(context, '❌ خطا در ثبت تحویل!', Colors.red);
                }
              } catch (e) {
                _showToast(context, '❌ خطا: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('✅ ثبت تحویل'),
          ),
        ],
      ),
    );
  }

  static Future<void> showEdit({
    required BuildContext context,
    required Shipment shipment,
    required BuyerDelivery delivery,
    required VoidCallback onSuccess,
  }) async {
    final TextEditingController buyerNameController = TextEditingController(text: delivery.buyerName);
    final TextEditingController buyerPhoneController = TextEditingController(text: delivery.buyerPhone);
    final TextEditingController hajraController = TextEditingController(text: delivery.hajraNumber);
    final TextEditingController amountController = TextEditingController(
      text: delivery.receivedAmount > 0 ? NumberFormatter.formatNumber(delivery.receivedAmount) : '',
    );
    final TextEditingController notesController = TextEditingController(text: delivery.notes ?? '');
    String deliveryDate = delivery.deliveryDate;

    amountController.addListener(() {
      final text = amountController.text;
      if (text.isNotEmpty) {
        final onlyDigits = text.replaceAll(',', '');
        if (onlyDigits.isNotEmpty) {
          final parsed = int.tryParse(onlyDigits);
          if (parsed != null) {
            final formatted = NumberFormatter.formatNumber(parsed);
            if (formatted != text) {
              amountController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          }
        }
      }
    });

    final dbHelper = DatabaseHelper();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '✏️ ویرایش تحویل به خریدار - فاکتور #${shipment.invoiceNumber}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(buyerNameController, '👤 نام خریدار', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(buyerPhoneController, '📞 تلفن خریدار', Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(hajraController, '🏪 شماره حجره خریدار', Icons.store),
              const SizedBox(height: 12),
              _buildTextField(amountController, '💰 مبلغ دریافت شده (تومان)', Icons.money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(notesController, '📝 توضیحات (روش پرداخت، امضا و ...)', Icons.description,
                  maxLines: 2),
              const SizedBox(height: 12),
              _buildDatePicker(context, deliveryDate, (date) {
                deliveryDate = date;
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (buyerNameController.text.trim().isEmpty) {
                _showToast(context, '👤 نام خریدار الزامی است', Colors.orange);
                return;
              }
              if (deliveryDate.isEmpty) {
                _showToast(context, '📅 تاریخ تحویل الزامی است', Colors.orange);
                return;
              }

              final amount = NumberFormatter.parseNumber(amountController.text);

              final updatedDelivery = BuyerDelivery(
                id: delivery.id,
                shipmentId: shipment.id!,
                buyerName: buyerNameController.text.trim(),
                buyerPhone: buyerPhoneController.text.trim(),
                hajraNumber: hajraController.text.trim(),
                deliveryDate: deliveryDate,
                receivedAmount: amount,
                notes: notesController.text.trim(),
              );

              try {
                final success = await dbHelper.updateBuyerDelivery(updatedDelivery);
                if (success) {
                  _showToast(context, '✅ تحویل با موفقیت ویرایش شد!', Colors.green);
                  Navigator.pop(context);
                  onSuccess();
                } else {
                  _showToast(context, '❌ خطا در ویرایش تحویل!', Colors.red);
                }
              } catch (e) {
                _showToast(context, '❌ خطا: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('✏️ ویرایش تحویل'),
          ),
        ],
      ),
    );
  }

  static Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  static Widget _buildDatePicker(
      BuildContext context,
      String currentDate,
      Function(String) onDateSelected,
      ) {
    return InkWell(
      onTap: () async {
        final selected = await CustomPersianDatePicker.show(context);
        if (selected != null) {
          onDateSelected(selected);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '📅 تاریخ تحویل',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          currentDate.isEmpty ? 'انتخاب تاریخ' : currentDate,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  static void _showToast(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}