import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../models/iraqi_handover.dart';
import '../utils/number_formatter.dart';
import '../utils/persian_date_picker.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

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

class IraqiHandoverDialog {
  static Future<void> showCreate({
    required BuildContext context,
    required Shipment shipment,
    required VoidCallback onSuccess,
  }) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController borderController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    final now = Jalali.now();
    String clearanceDate = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

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
            const Icon(Icons.people, color: Colors.indigo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🇮🇶 تحویل به ترخیص‌کار عراقی - فاکتور #${shipment.invoiceNumber}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, '🇮🇶 نام ترخیص‌کار عراقی', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(phoneController, '📞 تلفن ترخیص‌کار عراقی (+964)', Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(borderController, '🛂 نام مرز', Icons.place),
              const SizedBox(height: 12),
              _buildTextField(costController, '💰 هزینه اضافی (تومان)', Icons.money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(notesController, '📝 توضیحات و شماره پلاک عراقی', Icons.description,
                  maxLines: 2),
              const SizedBox(height: 12),
              _buildDatePicker(context, clearanceDate, (date) {
                clearanceDate = date;
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
              if (nameController.text.trim().isEmpty) {
                _showToast(context, '🇮🇶 نام ترخیص‌کار عراقی الزامی است', Colors.orange);
                return;
              }
              if (phoneController.text.trim().isEmpty) {
                _showToast(context, '📞 تلفن ترخیص‌کار عراقی الزامی است', Colors.orange);
                return;
              }
              if (borderController.text.trim().isEmpty) {
                _showToast(context, '🛂 نام مرز الزامی است', Colors.orange);
                return;
              }
              if (clearanceDate.isEmpty) {
                _showToast(context, '📅 تاریخ تحویل الزامی است', Colors.orange);
                return;
              }

              final cost = NumberFormatter.parseNumber(costController.text);

              final handover = IraqiHandover(
                shipmentId: shipment.id!,
                clearanceName: nameController.text.trim(),
                clearancePhone: phoneController.text.trim(),
                borderName: borderController.text.trim(),
                clearanceDate: clearanceDate,
                notes: notesController.text.trim(),
                clearanceCost: cost,
              );

              try {
                final id = await dbHelper.addIraqiHandover(handover);
                if (id > 0) {
                  _showToast(context, '✅ تحویل به ترخیص‌کار عراقی با موفقیت ثبت شد!', Colors.green);
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
              backgroundColor: Colors.indigo,
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
    required IraqiHandover handover,
    required VoidCallback onSuccess,
  }) async {
    final TextEditingController nameController = TextEditingController(text: handover.clearanceName);
    final TextEditingController phoneController = TextEditingController(text: handover.clearancePhone);
    final TextEditingController borderController = TextEditingController(text: handover.borderName);
    final TextEditingController costController = TextEditingController(
      text: handover.clearanceCost > 0 ? NumberFormatter.formatNumber(handover.clearanceCost) : '',
    );
    final TextEditingController notesController = TextEditingController(text: handover.notes ?? '');
    String clearanceDate = handover.clearanceDate;

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
                '✏️ ویرایش تحویل به عراقی - فاکتور #${shipment.invoiceNumber}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, '🇮🇶 نام ترخیص‌کار عراقی', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(phoneController, '📞 تلفن ترخیص‌کار عراقی (+964)', Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(borderController, '🛂 نام مرز', Icons.place),
              const SizedBox(height: 12),
              _buildTextField(costController, '💰 هزینه اضافی (تومان)', Icons.money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(notesController, '📝 توضیحات و شماره پلاک عراقی', Icons.description,
                  maxLines: 2),
              const SizedBox(height: 12),
              _buildDatePicker(context, clearanceDate, (date) {
                clearanceDate = date;
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
              if (nameController.text.trim().isEmpty) {
                _showToast(context, '🇮🇶 نام ترخیص‌کار عراقی الزامی است', Colors.orange);
                return;
              }
              if (phoneController.text.trim().isEmpty) {
                _showToast(context, '📞 تلفن ترخیص‌کار عراقی الزامی است', Colors.orange);
                return;
              }
              if (borderController.text.trim().isEmpty) {
                _showToast(context, '🛂 نام مرز الزامی است', Colors.orange);
                return;
              }
              if (clearanceDate.isEmpty) {
                _showToast(context, '📅 تاریخ تحویل الزامی است', Colors.orange);
                return;
              }

              final cost = NumberFormatter.parseNumber(costController.text);

              final updatedHandover = IraqiHandover(
                id: handover.id,
                shipmentId: shipment.id!,
                clearanceName: nameController.text.trim(),
                clearancePhone: phoneController.text.trim(),
                borderName: borderController.text.trim(),
                clearanceDate: clearanceDate,
                notes: notesController.text.trim(),
                clearanceCost: cost,
              );

              try {
                final success = await dbHelper.updateIraqiHandover(updatedHandover);
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