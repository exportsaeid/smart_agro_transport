// lib/ui/main_invoice_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:ui' as ui;

import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/attachment.dart';
import '../database/database_helper.dart';
import '../widgets/table_widgets.dart';
import '../utils/number_formatter.dart';
import '../utils/persian_date_helper.dart';
import '../utils/pdf_generator.dart';
import 'invoice_list_page.dart';
import 'load_invoice_page.dart';
import 'clearance_page.dart';
import 'buyer_delivery_page.dart';
import 'map_page.dart';
import 'profit_report_page.dart';
import '../utils/backup_helper.dart';
import 'about_page.dart';
import 'contact_page.dart';
import 'settings_page.dart';

class MainInvoicePage extends StatefulWidget {
  const MainInvoicePage({super.key});

  @override
  State<MainInvoicePage> createState() => _MainInvoicePageState();
}

class _MainInvoicePageState extends State<MainInvoicePage> {
  final List<InvoiceItem> _items = [];
  final List<PlatformFile> _pickedFiles = [];
  final List<Attachment> _savedAttachments = [];

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _miscCostController = TextEditingController();
  final TextEditingController _miscNotesController = TextEditingController();
  String _invoiceDate = 'انتخاب تاریخ';
  int? _editingInvoiceId;
  String? _editingInvoiceNumber;

  @override
  void initState() {
    super.initState();
    _invoiceDate = PersianDateHelper.getCurrentDate();
  }

  double get _totalWeight => _items.fold(0.0, (sum, item) => sum + item.weight);
  double get _totalAmount {
    double itemsTotal = _items.fold(0.0, (sum, item) => sum + item.rowTotal);
    double misc = double.tryParse(_miscCostController.text.replaceAll(',', '')) ?? 0.0;
    return itemsTotal + misc;
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tahoma')),
      ),
    );
  }

  void _pickDate() async {
    String? picked = await PersianDateHelper.pickDate(
      context,
      initialDateStr: _invoiceDate,
    );
    if (picked != null) {
      setState(() {
        _invoiceDate = picked;
      });
    }
  }

  Future<String?> _showRenameDialog(String currentName) async {
    String nameOnly = p.basenameWithoutExtension(currentName);
    String ext = p.extension(currentName);
    final controller = TextEditingController(text: nameOnly);

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('✏️ نام فایل پیوست'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'نام فایل',
              suffixText: ext,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim() + ext),
              child: const Text('تایید و افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (var file in result.files) {
        String? newName = await _showRenameDialog(file.name);
        if (newName != null) {
          setState(() {
            _pickedFiles.add(PlatformFile(
              name: newName,
              size: file.size,
              path: file.path,
              bytes: file.bytes,
            ));
          });
        }
      }
    }
  }

  Future<void> _openAttachment(Attachment att) async {
    String path = att.filePath;
    if (!await File(path).exists()) {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(appDir.path, 'invoice_attachments'));
      final uuidName = p.basename(path.replaceAll('\\', '/'));
      final candidate = File(p.join(dir.path, uuidName));
      if (await candidate.exists()) {
        path = candidate.path;
        if (att.id != null) {
          final db = await DatabaseHelper.instance.database;
          await db.update('attachments', {'file_path': path},
              where: 'id = ?', whereArgs: [att.id]);
          att.filePath = path;
        }
      }
    }
    if (!await File(path).exists()) {
      _showToast('❌ فایل پیدا نشد: ${att.fileName}');
      return;
    }
    await OpenFilex.open(path);
  }

  Future<void> _saveInvoice() async {
    if (_items.isEmpty) {
      _showToast("⚠️ لیست کالاها خالی است!");
      return;
    }

    try {
      final invoice = Invoice(
        id: _editingInvoiceId,
        invoiceNumber: _editingInvoiceNumber,
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        date: _invoiceDate,
        totalAmount: _totalAmount,
        miscCost: double.tryParse(_miscCostController.text.replaceAll(',', '')) ?? 0.0,
        miscNotes: _miscNotesController.text,
        items: _items,
        attachments: [],
      );

      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(appDir.path, 'invoice_attachments'));
      if (!await attachmentsDir.exists()) await attachmentsDir.create(recursive: true);

      for (var file in _pickedFiles) {
        if (file.path != null) {
          final targetPath = p.join(attachmentsDir.path, "${DateTime.now().millisecondsSinceEpoch}_${file.name}");
          await File(file.path!).copy(targetPath);
          invoice.attachments.add(Attachment(
            invoiceId: 0,
            fileName: file.name,
            filePath: targetPath,
            fileType: p.extension(file.name),
          ));
        }
      }

      invoice.attachments.addAll(_savedAttachments);

      await DatabaseHelper.instance.saveInvoice(invoice);
      _showToast("✅ فاکتور ذخیره شد");
      _resetForm();
    } catch (e) {
      _showToast("❌ خطا در ذخیره: $e");
    }
  }

  void _resetForm() {
    setState(() {
      _editingInvoiceId = null;
      _editingInvoiceNumber = null;
      _customerNameController.clear();
      _customerPhoneController.clear();
      _miscCostController.clear();
      _miscNotesController.clear();
      _invoiceDate = PersianDateHelper.getCurrentDate();
      _items.clear();
      _pickedFiles.clear();
      _savedAttachments.clear();
    });
  }

  Future<void> _loadInvoiceForEdit(int id) async {
    final invoice = await DatabaseHelper.instance.getInvoice(id);
    if (invoice != null) {
      setState(() {
        _editingInvoiceId = invoice.id;
        _editingInvoiceNumber = invoice.invoiceNumber;
        _customerNameController.text = invoice.customerName;
        _customerPhoneController.text = invoice.customerPhone;
        _miscCostController.text = invoice.miscCost > 0 ? NumberFormat("#,###").format(invoice.miscCost) : '';
        _miscNotesController.text = invoice.miscNotes;
        _invoiceDate = invoice.date;
        _items.clear();
        _items.addAll(invoice.items);
        _savedAttachments.clear();
        _savedAttachments.addAll(invoice.attachments);
        _pickedFiles.clear();
      });
      _showToast("📂 فاکتور بارگذاری شد");
    }
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_editingInvoiceNumber ?? 'فاکتور هوشمند کشاورزی', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(_customerNameController, 'نام مشتری', Icons.edit, textInputAction: TextInputAction.next),
                  const SizedBox(height: 12),
                  _buildTextField(_customerPhoneController, 'شماره تماس', Icons.call, isPhone: true, textInputAction: TextInputAction.next),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    child: IgnorePointer(
                      child: _buildTextField(TextEditingController(text: _invoiceDate), 'تاریخ فاکتور', Icons.calendar_today, readOnly: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_miscCostController, 'هزینه متفرقه (تومان)', Icons.attach_money, isNumber: true, formatters: [ThousandSeparatorFormatter()], onChanged: (_) => setState(() {}), textInputAction: TextInputAction.next),
                  const SizedBox(height: 12),
                  _buildTextField(_miscNotesController, 'توضیحات متفرقه', Icons.note, maxLines: 2, textInputAction: TextInputAction.done),
                  const SizedBox(height: 16),
                  _buildAttachmentsSection(),
                  const SizedBox(height: 16),
                  const Text('📦 لیست کالاهای فاکتور:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  _buildInvoiceTable(),
                ],
              ),
            ),
          ),
          _buildTotalSummary(),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.attach_file, color: Colors.orange),
          label: const Text('📎 افزودن فایل پیوست', style: TextStyle(color: Colors.orange)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: Colors.orange),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        ..._savedAttachments.asMap().entries.map((e) => _buildAttachmentTile(e.value.fileName, true,
            onView: () => _openAttachment(e.value),
            onEdit: () async {
              String? n = await _showRenameDialog(e.value.fileName);
              if (n != null) {
                await DatabaseHelper.instance.updateAttachmentFileName(e.value.id!, n);
                setState(() => e.value.fileName = n);
              }
            },
            onDelete: () async {
              await DatabaseHelper.instance.deleteAttachment(e.value.id!);
              setState(() => _savedAttachments.removeAt(e.key));
            }
        )),
        ..._pickedFiles.asMap().entries.map((e) => _buildAttachmentTile(e.value.name, false,
            onView: () => e.value.path != null ? OpenFilex.open(e.value.path!) : null,
            onEdit: () async {
              String? n = await _showRenameDialog(e.value.name);
              if (n != null) {
                setState(() {
                  _pickedFiles[e.key] = PlatformFile(
                    name: n,
                    size: e.value.size,
                    path: e.value.path,
                    bytes: e.value.bytes,
                  );
                });
              }
            },
            onDelete: () => setState(() => _pickedFiles.removeAt(e.key))
        )),
      ],
    );
  }

  Widget _buildAttachmentTile(String name, bool isSaved, {required VoidCallback onView, required VoidCallback onEdit, required VoidCallback onDelete}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: Colors.blueGrey[50],
      child: ListTile(
        dense: true,
        leading: Icon(isSaved ? Icons.check_circle : Icons.file_present, color: isSaved ? Colors.green : Colors.blue),
        title: Text(name, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.visibility, size: 18, color: Colors.blue), onPressed: onView),
            IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.orange), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPhone = false, bool isNumber = false, bool readOnly = false, List<TextInputFormatter>? formatters, int maxLines = 1, ValueChanged<String>? onChanged, TextInputAction? textInputAction}) {
    return TextField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        onChanged: onChanged,
        textInputAction: textInputAction,
        keyboardType: isPhone ? TextInputType.phone : (isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
        inputFormatters: formatters,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.green[800]),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            labelStyle: const TextStyle(fontFamily: 'Tahoma')),
        style: const TextStyle(fontFamily: 'Tahoma'));
  }

  Widget _buildInvoiceTable() {
    final currencyFormat = NumberFormat("#,###");
    final ScrollController scrollController = ScrollController();

    const double tableWidth = 955;

    return Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: tableWidth,
                    color: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Row(children: [
                      TableHeaderCell(text: 'ردیف', width: 50),
                      TableHeaderCell(text: 'محصول', width: 120),
                      TableHeaderCell(text: 'وزن', width: 80),
                      TableHeaderCell(text: 'قیمت', width: 100),
                      TableHeaderCell(text: 'فروشنده', width: 100),
                      TableHeaderCell(text: 'موبایل', width: 100),
                      TableHeaderCell(text: 'آدرس', width: 120),
                      TableHeaderCell(text: 'توضیحات', width: 100),
                      TableHeaderCell(text: 'جمع', width: 100),
                      TableHeaderCell(text: 'عملیات', width: 80),
                    ])),
                Container(
                    constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
                    width: tableWidth,
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, border: Border.all(color: Colors.grey[300]!)),
                    child: _items.isEmpty
                        ? const Center(child: Text('هنوز کالایی اضافه نشده است'))
                        : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Container(
                              decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                TableDataCell(text: '${index + 1}', width: 50, isBold: true),
                                TableDataCell(text: item.productName, width: 120),
                                TableDataCell(text: currencyFormat.format(item.weight), width: 80),
                                TableDataCell(text: currencyFormat.format(item.unitPrice), width: 100),
                                TableDataCell(text: item.name, width: 100),
                                TableDataCell(text: item.mobile, width: 100),
                                TableDataCell(text: item.address, width: 120),
                                TableDataCell(text: item.notes, width: 100),
                                TableDataCell(
                                    text: currencyFormat.format(item.rowTotal),
                                    width: 100,
                                    color: Colors.red,
                                    isBold: true),
                                SizedBox(
                                    width: 80,
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                              onPressed: () => _showAddItemDialog(index: index)),
                                          IconButton(
                                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                              onPressed: () => setState(() => _items.removeAt(index))),
                                        ]))
                              ]));
                        })),
              ]),
            )));
  }

  Widget _buildTotalSummary() {
    final currencyFormat = NumberFormat("#,###");
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFE8F5E9),
      child: Text(
        '💰 جمع کل: ${currencyFormat.format(_totalAmount)} تومان | ⚖️ وزن کل: ${currencyFormat.format(_totalWeight)} کیلوگرم',
        style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 16, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ==================== دکمه‌های پایین (بدون دکمه‌های PDF) ====================
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          // دکمه افزودن کالا
          FloatingActionButton(
            onPressed: () => _showAddItemDialog(),
            backgroundColor: Colors.green[800],
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(width: 8),
          // دکمه ثبت و ذخیره نهایی
          Expanded(
            child: ElevatedButton(
              onPressed: _saveInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ثبت و ذخیره نهایی فاکتور',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green[800]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.local_shipping, color: Colors.white, size: 48),
                SizedBox(height: 10),
                Text('هوشمند ترابر کشاورزی',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tahoma')),
              ],
            ),
          ),
          _drawerItem(Icons.add_box, 'ایجاد فاکتور جدید', () {
            Navigator.pop(context);
            _resetForm();
          }),
          _drawerItem(Icons.list, 'لیست فاکتورها', () async {
            Navigator.pop(context);
            final res = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: InvoiceListPage(),
                ),
              ),
            );
            if (res != null && res is int) {
              _loadInvoiceForEdit(res);
            }
          }),
          _drawerItem(Icons.cloud_download, 'بارگیری فاکتور', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Directionality(textDirection: ui.TextDirection.rtl, child: LoadInvoicePage())));
          }),
          _drawerItem(Icons.location_on, 'ترخیص مرز', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Directionality(textDirection: ui.TextDirection.rtl, child: ClearancePage())));
          }),
          _drawerItem(Icons.delivery_dining, 'تحویل به خریدار', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Directionality(textDirection: ui.TextDirection.rtl, child: BuyerDeliveryPage())));
          }),
          const Divider(),
          _drawerItem(Icons.map, 'نمایش نقشه', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Directionality(textDirection: ui.TextDirection.rtl, child: MapPage())));
          }),
          _drawerItem(Icons.trending_up, 'گزارش سود و ضرر', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Directionality(textDirection: ui.TextDirection.rtl, child: ProfitReportPage())));
          }),
          const Divider(),
          _drawerItem(Icons.backup, 'پشتیبان گیری از اطلاعات', () async {
            Navigator.pop(context);
            _showToast("⏳ در حال آماده‌سازی پشتیبان...");
            final result = await BackupHelper.createBackup();
            if (result != null) _showToast(result);
          }),
          _drawerItem(Icons.restore, 'بازگردانی اطلاعات', () async {
            Navigator.pop(context);
            final result = await BackupHelper.restoreBackup();
            if (result != null) _showToast(result);
          }),
          _drawerItem(Icons.settings, 'تنظیمات', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: SettingsPage(),
                ),
              ),
            );
          }),
          const Divider(),
          _drawerItem(Icons.info, 'درباره اپ', () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: AboutPage()
                    )
                )
            );
          }),
          _drawerItem(Icons.phone, 'ارتباط با ما', () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: ContactPage()
                    )
                )
            );
          }),
          _drawerItem(Icons.exit_to_app, 'خروج از برنامه', () async {
            Navigator.pop(context);
            try { await SystemNavigator.pop(); } catch (_) {}
            exit(0);
          }, color: Colors.red),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.green[800]),
      title: Text(title, style: TextStyle(color: color, fontFamily: 'Tahoma')),
      onTap: onTap,
    );
  }

  void _showAddItemDialog({int? index}) {
    final isEditing = index != null;
    final item = isEditing ? _items[index] : null;
    final currencyFormat = NumberFormat("#,###");

    final nameC = TextEditingController(text: item?.productName);
    final weightC = TextEditingController(text: item != null ? currencyFormat.format(item.weight) : '');
    final priceC = TextEditingController(text: item != null ? currencyFormat.format(item.unitPrice) : '');
    final sellerC = TextEditingController(text: item?.name);
    final mobileC = TextEditingController(text: item?.mobile);
    final addressC = TextEditingController(text: item?.address);
    final notesC = TextEditingController(text: item?.notes);

    showDialog(
        context: context,
        builder: (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
                title: Text(isEditing ? '✏️ ویرایش کالا' : '🥬 افزودن کالای جدید', style: const TextStyle(fontFamily: 'Tahoma')),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _buildDialogField(nameC, 'نام محصول', Icons.eco, textInputAction: TextInputAction.next),
                      _buildDialogField(weightC, 'وزن', Icons.scale, isNumber: true, formatters: [ThousandSeparatorFormatter()], textInputAction: TextInputAction.next),
                      _buildDialogField(priceC, 'قیمت واحد', Icons.money, isNumber: true, formatters: [ThousandSeparatorFormatter()], textInputAction: TextInputAction.next),
                      _buildDialogField(sellerC, 'فروشنده', Icons.person, textInputAction: TextInputAction.next),
                      _buildDialogField(mobileC, 'موبایل', Icons.phone, isNumber: true, textInputAction: TextInputAction.next),
                      _buildDialogField(addressC, 'آدرس', Icons.location_on, textInputAction: TextInputAction.next),
                      _buildDialogField(notesC, 'توضیحات', Icons.notes, textInputAction: TextInputAction.done),
                    ])),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو', style: TextStyle(fontFamily: 'Tahoma'))),
                  ElevatedButton(
                      onPressed: () {
                        final ni = InvoiceItem(
                          productName: nameC.text,
                          weight: double.tryParse(weightC.text.replaceAll(',', '')) ?? 0,
                          unitPrice: double.tryParse(priceC.text.replaceAll(',', '')) ?? 0,
                          name: sellerC.text,
                          mobile: mobileC.text,
                          address: addressC.text,
                          notes: notesC.text,
                        );
                        setState(() {
                          if (isEditing)
                            _items[index] = ni;
                          else
                            _items.add(ni);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('ذخیره', style: TextStyle(fontFamily: 'Tahoma')))
                ])));
  }

  Widget _buildDialogField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, List<TextInputFormatter>? formatters, TextInputAction? textInputAction}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0),
        child: TextField(
            controller: controller,
            textInputAction: textInputAction,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            inputFormatters: formatters,
            decoration: InputDecoration(labelText: hint, prefixIcon: Icon(icon, color: Colors.green), border: const OutlineInputBorder())));
  }
}