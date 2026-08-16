import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../models/buyer_delivery.dart';
import '../models/clearance.dart';
import '../models/iraqi_handover.dart';
import '../utils/persian_date_helper.dart';
import '../utils/number_formatter.dart';

class BuyerDeliveryPage extends StatefulWidget {
  const BuyerDeliveryPage({super.key});

  @override
  State<BuyerDeliveryPage> createState() => _BuyerDeliveryPageState();
}

class _BuyerDeliveryPageState extends State<BuyerDeliveryPage> {
  List<Shipment> _allShipments = [];
  List<Shipment> _filteredShipments = [];
  Map<int, Clearance?> _clearances = {};
  Map<int, IraqiHandover?> _handovers = {};
  Map<int, BuyerDelivery?> _deliveries = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cleared = await DatabaseHelper.instance.getClearedShipments();
    final List<Shipment> iraqiDelivered = [];
    final Map<int, Clearance?> clearanceMap = {};
    final Map<int, IraqiHandover?> handoverMap = {};
    final Map<int, BuyerDelivery?> deliveryMap = {};

    for (var s in cleared) {
      final handover = await DatabaseHelper.instance.getIraqiHandoverByShipmentId(s.id!);
      if (handover != null) {
        iraqiDelivered.add(s);
        clearanceMap[s.id!] = await DatabaseHelper.instance.getClearanceByShipmentId(s.id!);
        handoverMap[s.id!] = handover;
        deliveryMap[s.id!] = await DatabaseHelper.instance.getBuyerDeliveryByShipmentId(s.id!);
      }
    }

    if (mounted) {
      setState(() {
        _allShipments = iraqiDelivered;
        _filteredShipments = iraqiDelivered;
        _clearances = clearanceMap;
        _handovers = handoverMap;
        _deliveries = deliveryMap;
        _isLoading = false;
        _filterData(_searchController.text);
      });
    }
  }

  void _filterData(String query) {
    setState(() {
      _filteredShipments = _allShipments.where((s) {
        final delivery = _deliveries[s.id];
        return s.truckName.contains(query) ||
            s.driverName.contains(query) ||
            s.invoiceNumber.contains(query) ||
            (delivery?.buyerName.contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = intl.NumberFormat("#,###");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text('📦 تحویل نهایی به خریدار',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tahoma')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterData,
              decoration: InputDecoration(
                hintText: 'جستجو (ماشین، راننده، خریدار)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredShipments.isEmpty
                    ? const Center(child: Text('📭 موردی یافت نشد'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredShipments.length,
                        itemBuilder: (context, index) {
                          final s = _filteredShipments[index];
                          final delivery = _deliveries[s.id];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('🚛 ${s.truckName}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Tahoma')),
                                      if (delivery != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                                          child: const Text('✅ تحویل شد', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(6)),
                                          child: const Text('🕒 در انتظار تحویل', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Text('👤 راننده: ${s.driverName} (${s.driverPhone})', style: const TextStyle(fontFamily: 'Tahoma')),
                                  Text('🧾 فاکتور: #${s.invoiceNumber}', style: const TextStyle(color: Colors.blueGrey, fontFamily: 'Tahoma')),
                                  
                                  // اطلاعات ترخیصکار ایران
                                  if (_clearances[s.id] != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green[100]!)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('🛂 ترخیصکار ایران:',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green, fontFamily: 'Tahoma')),
                                          const SizedBox(height: 4),
                                          Text('👤 ${_clearances[s.id]!.clearanceName} | 📞 ${_clearances[s.id]!.clearancePhone}',
                                              style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma')),
                                          Text('📍 مرز: ${_clearances[s.id]!.borderName} | 📅 ${_clearances[s.id]!.clearanceDate}',
                                              style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma')),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // اطلاعات ترخیصکار عراق
                                  if (_handovers[s.id] != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue[100]!)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('🇮🇶 ترخیصکار عراق:',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue, fontFamily: 'Tahoma')),
                                          const SizedBox(height: 4),
                                          Text('👤 ${_handovers[s.id]!.clearanceName} | 📞 ${_handovers[s.id]!.clearancePhone}',
                                              style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma')),
                                          Text('📍 مرز: ${_handovers[s.id]!.borderName} | 📅 ${_handovers[s.id]!.clearanceDate}',
                                              style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma')),
                                        ],
                                      ),
                                    ),
                                  ],

                                  if (delivery != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green[100]!)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('👤 مشخصات خریدار:',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green, fontFamily: 'Tahoma')),
                                          const SizedBox(height: 4),
                                          Text('نام: ${delivery.buyerName}', style: const TextStyle(fontSize: 13, fontFamily: 'Tahoma')),
                                          Text('تلفن: ${delivery.buyerPhone}', style: const TextStyle(fontSize: 13, fontFamily: 'Tahoma')),
                                          Text('شماره حجره: ${delivery.hajraNumber}', style: const TextStyle(fontSize: 13, fontFamily: 'Tahoma')),
                                          Text('📅 تاریخ تحویل: ${delivery.deliveryDate}', style: const TextStyle(fontSize: 13, fontFamily: 'Tahoma')),
                                          Text('💰 مبلغ دریافتی: ${currencyFormat.format(delivery.receivedAmount)} تومان',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13, fontFamily: 'Tahoma')),
                                          if (delivery.notes.isNotEmpty)
                                            Text('📝 ${delivery.notes}', style: const TextStyle(fontSize: 11, color: Colors.black54, fontFamily: 'Tahoma')),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  const Divider(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showDeliveryDialog(s, delivery),
                                      icon: Icon(delivery == null ? Icons.add_task : Icons.edit, color: Colors.white),
                                      label: Text(delivery == null ? 'ثبت تحویل به خریدار' : 'ویرایش اطلاعات تحویل',
                                          style: const TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: delivery == null ? Colors.blue[700] : Colors.green[700],
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDeliveryDialog(Shipment shipment, BuyerDelivery? existing) {
    final buyerNameC = TextEditingController(text: existing?.buyerName);
    final buyerPhoneC = TextEditingController(text: existing?.buyerPhone);
    final hajraC = TextEditingController(text: existing?.hajraNumber);
    final amountC = TextEditingController(text: existing != null ? intl.NumberFormat("#,###").format(existing.receivedAmount) : '');
    final notesC = TextEditingController(text: existing?.notes);
    String deliveryDate = existing?.deliveryDate ?? PersianDateHelper.getCurrentDate();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(existing == null ? '📦 ثبت تحویل به خریدار' : '✏️ ویرایش تحویل به خریدار',
                style: const TextStyle(fontSize: 18, color: Colors.blue, fontFamily: 'Tahoma')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField(buyerNameC, '👤 نام خریدار', Icons.person, textInputAction: TextInputAction.next),
                  _buildField(buyerPhoneC, '📞 تلفن خریدار', Icons.phone, isNumber: true, textInputAction: TextInputAction.next),
                  _buildField(hajraC, '🏪 شماره حجره', Icons.store, textInputAction: TextInputAction.next),
                  _buildField(amountC, '💰 مبلغ دریافتی (تومان)', Icons.money, isNumber: true, formatters: [ThousandSeparatorFormatter()], textInputAction: TextInputAction.next),
                  _buildField(notesC, '📝 توضیحات', Icons.notes, textInputAction: TextInputAction.done),
                  InkWell(
                    onTap: () async {
                      String? picked = await PersianDateHelper.pickDate(context);
                      if (picked != null) {
                        setDialogState(() => deliveryDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '📅 تاریخ تحویل', prefixIcon: Icon(Icons.calendar_today)),
                      child: Text(deliveryDate, style: const TextStyle(fontFamily: 'Tahoma')),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو', style: TextStyle(fontFamily: 'Tahoma'))),
              ElevatedButton(
                onPressed: () async {
                  if (buyerNameC.text.isEmpty) return;

                  final bd = BuyerDelivery(
                    id: existing?.id,
                    shipmentId: shipment.id!,
                    buyerName: buyerNameC.text,
                    buyerPhone: buyerPhoneC.text,
                    hajraNumber: hajraC.text,
                    deliveryDate: deliveryDate,
                    receivedAmount: double.tryParse(amountC.text.replaceAll(',', '')) ?? 0,
                    notes: notesC.text,
                  );

                  if (existing == null) {
                    await DatabaseHelper.instance.addBuyerDelivery(bd);
                  } else {
                    await DatabaseHelper.instance.updateBuyerDelivery(bd);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ اطلاعات با موفقیت ثبت شد')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('ذخیره نهایی', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, List<TextInputFormatter>? formatters, TextInputAction? textInputAction}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        textInputAction: textInputAction,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: formatters,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.blue),
            border: const OutlineInputBorder(),
            labelStyle: const TextStyle(fontFamily: 'Tahoma', fontSize: 13)),
        style: const TextStyle(fontFamily: 'Tahoma', fontSize: 14),
      ),
    );
  }
}
