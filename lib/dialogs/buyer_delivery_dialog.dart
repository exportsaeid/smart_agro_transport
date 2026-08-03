import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../models/buyer_delivery.dart';
import '../utils/number_formatter.dart';
import '../utils/persian_date_picker.dart';   // ← از این استفاده می‌کنیم

class BuyerDeliveryDialog extends StatefulWidget {
  final Shipment shipment;
  final BuyerDelivery? delivery;
  final bool isEdit;
  final VoidCallback onSuccess;

  const BuyerDeliveryDialog({
    super.key,
    required this.shipment,
    this.delivery,
    this.isEdit = false,
    required this.onSuccess,
  });

  @override
  State<BuyerDeliveryDialog> createState() => _BuyerDeliveryDialogState();
}

class _BuyerDeliveryDialogState extends State<BuyerDeliveryDialog> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _buyerNameController = TextEditingController();
  final TextEditingController _buyerPhoneController = TextEditingController();
  final TextEditingController _hajraController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _deliveryDate = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    _deliveryDate =
    '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    if (widget.isEdit && widget.delivery != null) {
      final delivery = widget.delivery!;
      _buyerNameController.text = delivery.buyerName;
      _buyerPhoneController.text = delivery.buyerPhone;
      _hajraController.text = delivery.hajraNumber;
      _amountController.text = delivery.receivedAmount > 0
          ? NumberFormatter.formatNumber(delivery.receivedAmount)
          : '';
      _notesController.text = delivery.notes;
      _deliveryDate = delivery.deliveryDate;
    }
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _hajraController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final String? pickedDate = await CustomPersianDatePicker.show(context);
    if (pickedDate != null) {
      setState(() {
        _deliveryDate = pickedDate;
      });
    }
  }

  Future<void> _save() async {
    if (_buyerNameController.text.trim().isEmpty) {
      _showToast('👤 نام خریدار الزامی است', Colors.orange);
      return;
    }
    if (_deliveryDate.isEmpty) {
      _showToast('📅 تاریخ تحویل الزامی است', Colors.orange);
      return;
    }

    final amount = NumberFormatter.parseNumber(_amountController.text);

    final delivery = BuyerDelivery(
      id: widget.isEdit ? widget.delivery!.id : null,
      shipmentId: widget.shipment.id!,
      buyerName: _buyerNameController.text.trim(),
      buyerPhone: _buyerPhoneController.text.trim(),
      hajraNumber: _hajraController.text.trim(),
      deliveryDate: _deliveryDate,
      receivedAmount: amount,
      notes: _notesController.text.trim(),
    );

    setState(() => _isLoading = true);

    try {
      if (widget.isEdit) {
        final success = await _dbHelper.updateBuyerDelivery(delivery);
        if (success) {
          _showToast('✅ تحویل با موفقیت ویرایش شد!', Colors.green);
          widget.onSuccess();
          if (mounted) Navigator.pop(context);
        } else {
          _showToast('❌ خطا در ویرایش تحویل!', Colors.red);
        }
      } else {
        final result = await _dbHelper.addBuyerDelivery(delivery);
        if (result > 0) {
          _showToast('✅ تحویل به خریدار با موفقیت ثبت شد!', Colors.green);
          widget.onSuccess();
          if (mounted) Navigator.pop(context);
        } else {
          _showToast('❌ خطا در ثبت تحویل!', Colors.red);
        }
      }
    } catch (e) {
      _showToast('❌ خطا: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, Color color) {
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(widget.isEdit ? Icons.edit : Icons.payment, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isEdit
                  ? '✏️ ویرایش تحویل به خریدار - فاکتور #${widget.shipment.invoiceNumber}'
                  : '📦 ثبت تحویل به خریدار - فاکتور #${widget.shipment.invoiceNumber}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(_buyerNameController, '👤 نام خریدار', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(_buyerPhoneController, '📞 تلفن خریدار', Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(_hajraController, '🏪 شماره حجره خریدار', Icons.store),
            const SizedBox(height: 12),
            _buildTextField(_amountController, '💰 مبلغ دریافت شده (تومان)', Icons.money,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField(_notesController, '📝 توضیحات (روش پرداخت، امضا و ...)',
                Icons.description,
                maxLines: 2),
            const SizedBox(height: 12),
            _buildDatePicker(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : Text(widget.isEdit ? '✏️ ویرایش تحویل' : '✅ ثبت تحویل'),
        ),
      ],
    );
  }

  Widget _buildTextField(
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
      onChanged: (value) {
        if (keyboardType == TextInputType.number) {
          final formatted = NumberFormatter.formatInput(value);
          if (formatted != value) {
            controller.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        }
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '📅 تاریخ تحویل',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _deliveryDate.isEmpty ? 'انتخاب تاریخ' : _deliveryDate,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}