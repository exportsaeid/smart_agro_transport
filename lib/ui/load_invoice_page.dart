import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/shipment.dart';
import '../utils/persian_date_helper.dart';
import '../utils/number_formatter.dart';

class LoadInvoicePage extends StatefulWidget {
  const LoadInvoicePage({super.key});

  @override
  State<LoadInvoicePage> createState() => _LoadInvoicePageState();
}

class _LoadInvoicePageState extends State<LoadInvoicePage> {
  int _currentIndex = 0;
  final GlobalKey<_ReadyInvoicesViewState> _readyKey = GlobalKey();
  final GlobalKey<_LoadedShipmentsViewState> _loadedKey = GlobalKey();

  void _refreshData() {
    _readyKey.currentState?._loadData();
    _loadedKey.currentState?._loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text('🚛📋 مدیریت بارگیری',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tahoma')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ReadyInvoicesView(key: _readyKey, onUpdate: _refreshData),
          LoadedShipmentsView(key: _loadedKey, onUpdate: _refreshData),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF1976D2),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'آماده بارگیری'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'بارگیری شده'),
        ],
      ),
    );
  }
}

class ReadyInvoicesView extends StatefulWidget {
  final VoidCallback onUpdate;
  const ReadyInvoicesView({super.key, required this.onUpdate});

  @override
  State<ReadyInvoicesView> createState() => _ReadyInvoicesViewState();
}

class _ReadyInvoicesViewState extends State<ReadyInvoicesView> {
  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await DatabaseHelper.instance.getReadyInvoices();
    if (mounted) {
      setState(() {
        _allInvoices = list;
        _filteredInvoices = list;
        _isLoading = false;
        _filterData(_searchController.text);
      });
    }
  }

  void _filterData(String query) {
    setState(() {
      _filteredInvoices = _allInvoices.where((inv) {
        return inv.customerName.contains(query) || (inv.invoiceNumber ?? '').contains(query);
      }).toList();
    });
  }

  void _showLoadDialog({required Invoice invoice, Shipment? existingShipment}) {
    showDialog(
      context: context,
      builder: (context) => _buildLoadDialog(
          context: context,
          invoice: invoice,
          existingShipment: existingShipment,
          onComplete: widget.onUpdate),
    );
  }


  @override
  Widget build(BuildContext context) {
    final currencyFormat = intl.NumberFormat("#,###");
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterData,
            decoration: InputDecoration(
              hintText: 'جستجو در فاکتورهای آماده...',
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
              : _filteredInvoices.isEmpty
                  ? const Center(child: Text('📭 فاکتور منطبقی یافت نشد'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final inv = _filteredInvoices[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('👤 ${inv.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '🧾 #${inv.invoiceNumber} | 📅 ${inv.date}\n💰 ${currencyFormat.format(inv.totalAmount)} تومان'),
                            trailing: ElevatedButton(
                              onPressed: () => _showLoadDialog(invoice: inv),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              child: const Text('ثبت بارگیری', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class LoadedShipmentsView extends StatefulWidget {
  final VoidCallback onUpdate;
  const LoadedShipmentsView({super.key, required this.onUpdate});

  @override
  State<LoadedShipmentsView> createState() => _LoadedShipmentsViewState();
}

class _LoadedShipmentsViewState extends State<LoadedShipmentsView> {
  List<Shipment> _allShipments = [];
  List<Shipment> _filteredShipments = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await DatabaseHelper.instance.getAllShipments();
    if (mounted) {
      setState(() {
        _allShipments = list;
        _filteredShipments = list;
        _isLoading = false;
        _filterData(_searchController.text);
      });
    }
  }

  void _filterData(String query) {
    setState(() {
      _filteredShipments = _allShipments.where((s) {
        return s.truckName.contains(query) ||
            s.driverName.contains(query) ||
            s.plateNumber.contains(query) ||
            s.invoiceNumber.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = intl.NumberFormat("#,###");
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterData,
            decoration: InputDecoration(
              hintText: 'جستجو در بارگیری‌ها (ماشین، راننده، فاکتور)...',
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
                  ? const Center(child: Text('📭 بارگیری منطبقی یافت نشد'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredShipments.length,
                      itemBuilder: (context, index) {
                        final s = _filteredShipments[index];
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(6)),
                                      child: Text('🔢 ${s.plateNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Text('👤 راننده: ${s.driverName} (${s.driverPhone})', style: const TextStyle(fontFamily: 'Tahoma')),
                                const SizedBox(height: 4),
                                Text('🧾 فاکتور مربوطه: #${s.invoiceNumber}', style: const TextStyle(color: Colors.blueGrey, fontFamily: 'Tahoma')),
                                const SizedBox(height: 4),
                                Text('📅 تاریخ بارگیری: ${s.loadDate}', style: const TextStyle(color: Colors.blueGrey, fontFamily: 'Tahoma')),
                                const SizedBox(height: 12),
                                Text('💰 هزینه حمل: ${currencyFormat.format(s.transportCost)} تومان',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Tahoma')),
                                const Divider(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _showEditDialog(s),
                                      icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                      label: const Text('ویرایش', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => Directionality(
                                                  textDirection: TextDirection.rtl,
                                                  child: AlertDialog(
                                                    title: const Text('🗑️ حذف بارگیری', style: TextStyle(fontFamily: 'Tahoma')),
                                                    content: const Text('آیا این بارگیری حذف شود؟ (فاکتور به لیست آماده برمی‌گردد)', style: TextStyle(fontFamily: 'Tahoma')),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('خیر', style: TextStyle(fontFamily: 'Tahoma'))),
                                                      ElevatedButton(
                                                        onPressed: () => Navigator.pop(ctx, true),
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                        child: const Text('بله، حذف شود', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
                                                      ),
                                                    ],
                                                  ),
                                                ));
                                        if (ok == true) {
                                          await DatabaseHelper.instance.deleteShipment(s.id!, s.invoiceId);
                                          widget.onUpdate();
                                        }
                                      },
                                      icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                                      label: const Text('حذف', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showEditDialog(Shipment shipment) {
    final dummyInvoice = Invoice(
        id: shipment.invoiceId,
        invoiceNumber: shipment.invoiceNumber,
        customerName: '',
        customerPhone: '',
        date: '',
        totalAmount: 0);

    showDialog(
      context: context,
      builder: (context) => _buildLoadDialog(
          context: context,
          invoice: dummyInvoice,
          existingShipment: shipment,
          onComplete: widget.onUpdate),
    );
  }
}

Widget _buildLoadDialog(
    {required BuildContext context, required Invoice invoice, Shipment? existingShipment, required VoidCallback onComplete}) {
  final truckC = TextEditingController(text: existingShipment?.truckName);
  final plateC = TextEditingController(text: existingShipment?.plateNumber);
  final driverC = TextEditingController(text: existingShipment?.driverName);
  final phoneC = TextEditingController(text: existingShipment?.driverPhone);
  final currencyFormat = intl.NumberFormat("#,###");
  final costC = TextEditingController(
      text: existingShipment != null ? currencyFormat.format(existingShipment.transportCost) : '');
  String loadDate = existingShipment?.loadDate ?? PersianDateHelper.getCurrentDate();

  return StatefulBuilder(
    builder: (context, setDialogState) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(existingShipment == null ? '🧾 ثبت بارگیری' : '✏️ ویرایش بارگیری',
            style: const TextStyle(fontSize: 18, color: Colors.green, fontFamily: 'Tahoma')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(truckC, '🚛 نام ماشین', Icons.local_shipping, textInputAction: TextInputAction.next),
              _buildDialogField(plateC, '🔢 پلاک ماشین', Icons.numbers, textInputAction: TextInputAction.next),
              _buildDialogField(driverC, '👤 نام راننده', Icons.person, textInputAction: TextInputAction.next),
              _buildDialogField(phoneC, '📞 شماره تلفن راننده', Icons.phone, isNumber: true, textInputAction: TextInputAction.next),
              _buildDialogField(costC, '💰 هزینه حمل (تومان)', Icons.money, isNumber: true, formatters: [ThousandSeparatorFormatter()], textInputAction: TextInputAction.done),
              InkWell(
                onTap: () async {
                  String? picked = await PersianDateHelper.pickDate(context);
                  if (picked != null) {
                    setDialogState(() => loadDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: '📅 تاریخ بارگیری', prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(loadDate, style: const TextStyle(fontFamily: 'Tahoma')),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو', style: TextStyle(fontFamily: 'Tahoma'))),
          ElevatedButton(
            onPressed: () async {
              if (truckC.text.isEmpty || plateC.text.isEmpty || driverC.text.isEmpty) return;

              final shipment = Shipment(
                id: existingShipment?.id,
                invoiceId: invoice.id!,
                invoiceNumber: invoice.invoiceNumber!,
                truckName: truckC.text,
                plateNumber: plateC.text,
                driverName: driverC.text,
                driverPhone: phoneC.text,
                loadDate: loadDate,
                transportCost: double.tryParse(costC.text.replaceAll(',', '')) ?? 0,
              );

              if (existingShipment == null) {
                await DatabaseHelper.instance.addShipment(shipment);
                await DatabaseHelper.instance.updateInvoiceLoadStatus(invoice.id!, 1);
              } else {
                await DatabaseHelper.instance.updateShipment(shipment);
              }

              if (context.mounted) {
                Navigator.pop(context);
                onComplete();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ثبت نهایی', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDialogField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, List<TextInputFormatter>? formatters, TextInputAction? textInputAction}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: formatters,
      decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: const OutlineInputBorder(),
          labelStyle: const TextStyle(fontFamily: 'Tahoma')),
      style: const TextStyle(fontFamily: 'Tahoma'),
    ),
  );
}
