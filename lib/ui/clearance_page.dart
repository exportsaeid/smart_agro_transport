import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import '../database/database_helper.dart';
import '../models/shipment.dart';
import '../models/clearance.dart';
import '../models/iraqi_handover.dart';
import '../utils/persian_date_helper.dart';
import '../utils/number_formatter.dart';

class ClearancePage extends StatefulWidget {
  const ClearancePage({super.key});

  @override
  State<ClearancePage> createState() => _ClearancePageState();
}

class _ClearancePageState extends State<ClearancePage> {
  int _currentIndex = 0;
  final GlobalKey<_InTransitViewState> _inTransitKey = GlobalKey();
  final GlobalKey<_ClearedViewState> _clearedKey = GlobalKey();

  void _refreshData() {
    _inTransitKey.currentState?._loadData();
    _clearedKey.currentState?._loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text('🛂📋 مدیریت ترخیص مرز',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tahoma')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          InTransitView(key: _inTransitKey, onUpdate: _refreshData),
          ClearedView(key: _clearedKey, onUpdate: _refreshData),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF1976D2),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'در راه مرز'),
          BottomNavigationBarItem(icon: Icon(Icons.done_all), label: 'ترخیص شده'),
        ],
      ),
    );
  }
}

class InTransitView extends StatefulWidget {
  final VoidCallback onUpdate;
  const InTransitView({super.key, required this.onUpdate});

  @override
  State<InTransitView> createState() => _InTransitViewState();
}

class _InTransitViewState extends State<InTransitView> {
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
    final list = await DatabaseHelper.instance.getInTransitShipments();
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
              hintText: 'جستجو در بارهای در راه...',
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
                  ? const Center(child: Text('📭 بار منطبقی یافت نشد'))
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
                                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(6)),
                                      child: const Text('🟠 در راه مرز', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Text('👤 راننده: ${s.driverName}', style: const TextStyle(fontFamily: 'Tahoma')),
                                Text('📞 تلفن راننده: ${s.driverPhone}', style: const TextStyle(fontFamily: 'Tahoma', color: Colors.blueGrey)),
                                Text('🔢 پلاک: ${s.plateNumber}', style: const TextStyle(fontFamily: 'Tahoma')),
                                Text('🧾 فاکتور: #${s.invoiceNumber}', style: const TextStyle(color: Colors.blueGrey, fontFamily: 'Tahoma')),
                                const Divider(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showClearanceDialog(context, s),
                                    icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
                                    label: const Text('ثبت ترخیص مرز', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
    );
  }

  void _showClearanceDialog(BuildContext context, Shipment shipment) {
    _showClearanceDialogInternal(context: context, shipment: shipment, onComplete: widget.onUpdate);
  }
}

class ClearedView extends StatefulWidget {
  final VoidCallback onUpdate;
  const ClearedView({super.key, required this.onUpdate});

  @override
  State<ClearedView> createState() => _ClearedViewState();
}

class _ClearedViewState extends State<ClearedView> {
  List<Shipment> _allShipments = [];
  List<Shipment> _filteredShipments = [];
  Map<int, Clearance?> _clearances = {};
  Map<int, IraqiHandover?> _handovers = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await DatabaseHelper.instance.getClearedShipments();
    final Map<int, Clearance?> clearanceMap = {};
    final Map<int, IraqiHandover?> handoverMap = {};
    for (var s in list) {
      if (s.id != null) {
        clearanceMap[s.id!] = await DatabaseHelper.instance.getClearanceByShipmentId(s.id!);
        handoverMap[s.id!] = await DatabaseHelper.instance.getIraqiHandoverByShipmentId(s.id!);
      }
    }
    
    if (mounted) {
      setState(() {
        _allShipments = list;
        _filteredShipments = list;
        _clearances = clearanceMap;
        _handovers = handoverMap;
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterData,
            decoration: InputDecoration(
              hintText: 'جستجو در ترخیص شده‌ها...',
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
                  ? const Center(child: Text('📭 بار منطبقی یافت نشد'))
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
                                      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                                      child: const Text('✅ ترخیص شده', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Text('👤 راننده: ${s.driverName}', style: const TextStyle(fontFamily: 'Tahoma')),
                                Text('📞 تلفن راننده: ${s.driverPhone}', style: const TextStyle(fontFamily: 'Tahoma', color: Colors.blueGrey, fontSize: 13)),
                                Text('🧾 فاکتور: #${s.invoiceNumber}', style: const TextStyle(color: Colors.blueGrey, fontFamily: 'Tahoma')),
                                
                                // اطلاعات ترخیص ایران
                                if (_clearances[s.id] != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green[100]!)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('🛂 اطلاعات ترخیصکار ایران', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green, fontFamily: 'Tahoma')),
                                        const SizedBox(height: 4),
                                        Text('👤 ترخیصکار: ${_clearances[s.id]!.clearanceName}', style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma')),
                                        Text('📞 تلفن: ${_clearances[s.id]!.clearancePhone}', style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma')),
                                        Text('📍 مرز: ${_clearances[s.id]!.borderName} | 📅 ${_clearances[s.id]!.clearanceDate}', style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma')),
                                        Text('💰 هزینه: ${intl.NumberFormat("#,###").format(_clearances[s.id]!.clearanceCost)} تومان', style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma', color: Colors.red)),
                                        if (_clearances[s.id]!.notes.isNotEmpty)
                                          Text('📝 ${_clearances[s.id]!.notes}', style: const TextStyle(fontSize: 11, color: Colors.black54, fontFamily: 'Tahoma')),
                                      ],
                                    ),
                                  ),
                                ],

                                // اطلاعات تحویل عراقی
                                if (_handovers[s.id] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[100]!)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('🇮🇶 اطلاعات ترخیصکار عراق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue, fontFamily: 'Tahoma')),
                                        const SizedBox(height: 4),
                                        Text('👤 ترخیصکار عراقی: ${_handovers[s.id]!.clearanceName}', style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma')),
                                        Text('📞 تلفن: ${_handovers[s.id]!.clearancePhone}', style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma')),
                                        Text('📍 مرز: ${_handovers[s.id]!.borderName} | 📅 ${_handovers[s.id]!.clearanceDate}', style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma')),
                                        if (_handovers[s.id]!.clearanceCost > 0)
                                          Text('💰 هزینه: ${intl.NumberFormat("#,###").format(_handovers[s.id]!.clearanceCost)} تومان', style: const TextStyle(fontSize: 12, fontFamily: 'Tahoma', color: Colors.red)),
                                        if (_handovers[s.id]!.notes.isNotEmpty)
                                          Text('📝 ${_handovers[s.id]!.notes}', style: const TextStyle(fontSize: 11, color: Colors.black54, fontFamily: 'Tahoma')),
                                      ],
                                    ),
                                  ),
                                ],
                                const Divider(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showEditClearance(s),
                                        icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                                        label: const Text('ویرایش اطلاعات ترخیصکار ایران', style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Tahoma'), textAlign: TextAlign.center),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: EdgeInsets.zero),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showIraqiHandover(s),
                                        icon: Icon(_handovers[s.id] == null ? Icons.add_circle_outline : Icons.edit, size: 16, color: Colors.white),
                                        label: Text(_handovers[s.id] == null ? 'ثبت اطلاعات ترخیصکار عراق' : 'ویرایش اطلاعات ترخیصکار عراق', style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Tahoma'), textAlign: TextAlign.center),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: EdgeInsets.zero),
                                      ),
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

  void _showEditClearance(Shipment shipment) async {
    final clearance = await DatabaseHelper.instance.getClearanceByShipmentId(shipment.id!);
    if (mounted) {
      _showClearanceDialogInternal(context: context, shipment: shipment, existingClearance: clearance, onComplete: widget.onUpdate);
    }
  }

  void _showIraqiHandover(Shipment shipment) async {
    final handover = await DatabaseHelper.instance.getIraqiHandoverByShipmentId(shipment.id!);
    if (mounted) {
      _showIraqiHandoverDialogInternal(context: context, shipment: shipment, existingHandover: handover, onComplete: widget.onUpdate);
    }
  }
}

void _showClearanceDialogInternal({required BuildContext context, required Shipment shipment, Clearance? existingClearance, required VoidCallback onComplete}) {
  final nameC = TextEditingController(text: existingClearance?.clearanceName);
  final phoneC = TextEditingController(text: existingClearance?.clearancePhone);
  final borderC = TextEditingController(text: existingClearance?.borderName);
  final costC = TextEditingController(text: existingClearance != null ? intl.NumberFormat("#,###").format(existingClearance.clearanceCost) : '');
  final notesC = TextEditingController(text: existingClearance?.notes);
  String clearanceDate = existingClearance?.clearanceDate ?? PersianDateHelper.getCurrentDate();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(existingClearance == null ? '📋 ثبت ترخیص مرز' : '✏️ ویرایش ترخیص مرز',
              style: const TextStyle(fontSize: 18, color: Colors.blue, fontFamily: 'Tahoma')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(nameC, '👤 نام ترخیصکار', Icons.person, textInputAction: TextInputAction.next),
                _buildDialogField(phoneC, '📞 تلفن ترخیصکار', Icons.phone, isNumber: true, textInputAction: TextInputAction.next),
                _buildDialogField(borderC, '🛂 نام مرز', Icons.location_on, textInputAction: TextInputAction.next),
                _buildDialogField(costC, '💰 هزینه ترخیص (تومان)', Icons.money, isNumber: true, formatters: [ThousandSeparatorFormatter()], textInputAction: TextInputAction.next),
                _buildDialogField(notesC, '📝 توضیحات', Icons.notes, textInputAction: TextInputAction.done),
                InkWell(
                  onTap: () async {
                    String? picked = await PersianDateHelper.pickDate(context);
                    if (picked != null) {
                      setDialogState(() => clearanceDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: '📅 تاریخ ترخیص', prefixIcon: Icon(Icons.calendar_today)),
                    child: Text(clearanceDate, style: const TextStyle(fontFamily: 'Tahoma')),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو', style: TextStyle(fontFamily: 'Tahoma'))),
            ElevatedButton(
              onPressed: () async {
                if (nameC.text.isEmpty || borderC.text.isEmpty) return;

                final cl = Clearance(
                  id: existingClearance?.id,
                  shipmentId: shipment.id!,
                  clearanceName: nameC.text,
                  clearancePhone: phoneC.text,
                  borderName: borderC.text,
                  clearanceDate: clearanceDate,
                  notes: notesC.text,
                  clearanceCost: double.tryParse(costC.text.replaceAll(',', '')) ?? 0,
                );

                if (existingClearance == null) {
                  await DatabaseHelper.instance.addClearance(cl);
                } else {
                  await DatabaseHelper.instance.updateClearance(cl);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  onComplete();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('ذخیره', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showIraqiHandoverDialogInternal({required BuildContext context, required Shipment shipment, IraqiHandover? existingHandover, required VoidCallback onComplete}) {
  final nameC = TextEditingController(text: existingHandover?.clearanceName);
  final phoneC = TextEditingController(text: existingHandover?.clearancePhone);
  final borderC = TextEditingController(text: existingHandover?.borderName);
  final costC = TextEditingController(text: existingHandover != null ? intl.NumberFormat("#,###").format(existingHandover.clearanceCost) : '');
  final notesC = TextEditingController(text: existingHandover?.notes);
  String handoverDate = existingHandover?.clearanceDate ?? PersianDateHelper.getCurrentDate();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(existingHandover == null ? '🇮🇶 ثبت تحویل عراقی' : '✏️ ویرایش تحویل عراقی',
              style: const TextStyle(fontSize: 18, color: Colors.blueGrey, fontFamily: 'Tahoma')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(nameC, '🇮🇶 نام ترخیصکار عراقی', Icons.person, textInputAction: TextInputAction.next),
                _buildDialogField(phoneC, '📞 تلفن عراقی', Icons.phone, isNumber: true, textInputAction: TextInputAction.next),
                _buildDialogField(borderC, '🛂 نام مرز', Icons.location_on, textInputAction: TextInputAction.next),
                _buildDialogField(costC, '💰 هزینه اضافی (تومان)', Icons.money, isNumber: true, formatters: [ThousandSeparatorFormatter()], textInputAction: TextInputAction.next),
                _buildDialogField(notesC, '📝 توضیحات و پلاک عراقی', Icons.notes, textInputAction: TextInputAction.done),
                InkWell(
                  onTap: () async {
                    String? picked = await PersianDateHelper.pickDate(context);
                    if (picked != null) {
                      setDialogState(() => handoverDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: '📅 تاریخ تحویل عراقی', prefixIcon: Icon(Icons.calendar_today)),
                    child: Text(handoverDate, style: const TextStyle(fontFamily: 'Tahoma')),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو', style: TextStyle(fontFamily: 'Tahoma'))),
            ElevatedButton(
              onPressed: () async {
                if (nameC.text.isEmpty) return;

                final ho = IraqiHandover(
                  id: existingHandover?.id,
                  shipmentId: shipment.id!,
                  clearanceName: nameC.text,
                  clearancePhone: phoneC.text,
                  borderName: borderC.text,
                  clearanceDate: handoverDate,
                  notes: notesC.text,
                  clearanceCost: double.tryParse(costC.text.replaceAll(',', '')) ?? 0,
                );

                if (existingHandover == null) {
                  await DatabaseHelper.instance.addIraqiHandover(ho);
                } else {
                  await DatabaseHelper.instance.updateIraqiHandover(ho);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  onComplete();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              child: const Text('ذخیره', style: TextStyle(color: Colors.white, fontFamily: 'Tahoma')),
            ),
          ],
        ),
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
          prefixIcon: Icon(icon, color: Colors.blue),
          border: const OutlineInputBorder(),
          labelStyle: const TextStyle(fontFamily: 'Tahoma', fontSize: 13)),
      style: const TextStyle(fontFamily: 'Tahoma', fontSize: 14),
    ),
  );
}
