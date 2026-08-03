import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/shipment.dart';
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

class ShipmentDialog {
  static Future<void> showCreate({
    required BuildContext context,
    required Invoice invoice,
    required Function(Shipment) onSuccess,
  }) async {
    final TextEditingController truckController = TextEditingController();
    final TextEditingController plateController = TextEditingController();
    final TextEditingController driverController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    String loadDate = '';

    // تنظیم تاریخ پیش‌فرض
    final now = Jalali.now();
    loadDate = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    costController.addListener(() {
      final text = costController.text;
      if (text.isNotEmpty) {
        final onlyDigits = text.replaceAll(',', '');
        if (onlyDigits.isNotEmpty) {
          final parsed = int.tryParse(onlyDigits);
          if (parsed != null) {
            final formatted = NumberFormatter.formatNumber(parsed);
            if (formatted != text) {
              costController.value = TextEditingValue(
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
            const Icon(Icons.local_shipping, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🚛 ثبت بارگیری فاکتور #${invoice.invoiceNumber}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(truckController, '🚛 نام ماشین', Icons.local_shipping),
              const SizedBox(height: 12),
              _buildTextField(plateController, '🔢 پلاک ماشین', Icons.confirmation_number),
              const SizedBox(height: 12),
              _buildTextField(driverController, '👤 نام راننده', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(phoneController, '📞 تلفن راننده', Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(costController, '💰 هزینه حمل (تومان)', Icons.money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildDatePicker(context, loadDate, (date) {
                loadDate = date;
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
              if (truckController.text.trim().isEmpty) {
                _showToast(context, '🚛 نام ماشین الزامی است', Colors.orange);
                return;
              }
              if (plateController.text.trim().isEmpty) {
                _showToast(context, '🔢 پلاک ماشین الزامی است', Colors.orange);
                return;
              }
              if (driverController.text.trim().isEmpty) {
                _showToast(context, '👤 نام راننده الزامی است', Colors.orange);
                return;
              }
              if (phoneController.text.trim().length < 10) {
                _showToast(context, '📞 شماره تلفن معتبر نیست (حداقل ۱۰ رقم)', Colors.orange);
                return;
              }
              if (loadDate.isEmpty) {
                _showToast(context, '📅 تاریخ بارگیری الزامی است', Colors.orange);
                return;
              }

              final cost = NumberFormatter.parseNumber(costController.text);

              final shipment = Shipment(
                invoiceId: invoice.id!,
                invoiceNumber: invoice.invoiceNumber,
                truckName: truckController.text.trim(),
                plateNumber: plateController.text.trim(),
                driverName: driverController.text.trim(),
                driverPhone: phoneController.text.trim(),
                loadDate: loadDate,
                transportCost: cost,
              );

              try {
                final id = await dbHelper.addShipment(shipment);
                if (id > 0) {
                  await dbHelper.updateInvoiceLoadStatus(invoice.id!, 1);
                  _showToast(context, '✅ بارگیری با موفقیت ثبت شد!', Colors.green);
                  Navigator.pop(context);
                  onSuccess(shipment);
                } else {
                  _showToast(context, '❌ خطا در ثبت بارگیری!', Colors.red);
                }
              } catch (e) {
                _showToast(context, '❌ خطا: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('✅ ثبت بارگیری'),
          ),
        ],
      ),
    );
  }

  static Future<void> showEdit({
    required BuildContext context,
    required Shipment shipment,
    required VoidCallback onSuccess,
  }) async {
    final TextEditingController truckController = TextEditingController(text: shipment.truckName);
    final TextEditingController plateController = TextEditingController(text: shipment.plateNumber);
    final TextEditingController driverController = TextEditingController(text: shipment.driverName);
    final TextEditingController phoneController = TextEditingController(text: shipment.driverPhone);
    final TextEditingController costController = TextEditingController(
      text: shipment.transportCost > 0 ? NumberFormatter.formatNumber(shipment.transportCost) : '',
    );
    String loadDate = shipment.loadDate;

    costController.addListener(() {
      final text = costController.text;
      if (text.isNotEmpty) {
        final onlyDigits = text.replaceAll(',', '');
        if (onlyDigits.isNotEmpty) {
          final parsed = int.tryParse(onlyDigits);
          if (parsed != null) {
            final formatted = NumberFormatter.formatNumber(parsed);
            if (formatted != text) {
              costController.value = TextEditingValue(
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
                '✏️ ویرایش بارگیری فاکتور #${shipment.invoiceNumber}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(truckController, '🚛 نام ماشین', Icons.local_shipping),
              const SizedBox(height: 12),
              _buildTextField(plateController, '🔢 پلاک ماشین', Icons.confirmation_number),
              const SizedBox(height: 12),
              _buildTextField(driverController, '👤 نام راننده', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(phoneController, '📞 تلفن راننده', Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(costController, '💰 هزینه حمل (تومان)', Icons.money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildDatePicker(context, loadDate, (date) {
                loadDate = date;
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
              if (truckController.text.trim().isEmpty) {
                _showToast(context, '🚛 نام ماشین الزامی است', Colors.orange);
                return;
              }
              if (plateController.text.trim().isEmpty) {
                _showToast(context, '🔢 پلاک ماشین الزامی است', Colors.orange);
                return;
              }
              if (driverController.text.trim().isEmpty) {
                _showToast(context, '👤 نام راننده الزامی است', Colors.orange);
                return;
              }
              if (phoneController.text.trim().length < 10) {
                _showToast(context, '📞 شماره تلفن معتبر نیست (حداقل ۱۰ رقم)', Colors.orange);
                return;
              }
              if (loadDate.isEmpty) {
                _showToast(context, '📅 تاریخ بارگیری الزامی است', Colors.orange);
                return;
              }

              final cost = NumberFormatter.parseNumber(costController.text);

              final updatedShipment = Shipment(
                id: shipment.id,
                invoiceId: shipment.invoiceId,
                invoiceNumber: shipment.invoiceNumber,
                truckName: truckController.text.trim(),
                plateNumber: plateController.text.trim(),
                driverName: driverController.text.trim(),
                driverPhone: phoneController.text.trim(),
                loadDate: loadDate,
                transportCost: cost,
              );

              try {
                final success = await dbHelper.updateShipment(updatedShipment);
                if (success) {
                  _showToast(context, '✅ بارگیری با موفقیت ویرایش شد!', Colors.green);
                  Navigator.pop(context);
                  onSuccess();
                } else {
                  _showToast(context, '❌ خطا در ویرایش!', Colors.red);
                }
              } catch (e) {
                _showToast(context, '❌ خطا: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('✏️ ویرایش بارگیری'),
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
      }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
    );
  }

  // ========== تاریخ با CustomPersianDatePicker ==========
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
          labelText: '📅 تاریخ بارگیری',
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