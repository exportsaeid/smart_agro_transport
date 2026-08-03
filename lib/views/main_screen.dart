import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/attachment.dart';
import '../utils/number_formatter.dart';
import '../utils/persian_date_picker.dart';
import '../ui/invoice_list_screen.dart';
import '../ui/shipment_screen.dart';
import '../views/clearance_screen.dart';
import '../views/iraqi_handover_screen.dart';
import '../views/buyer_delivery_screen.dart';
import '../views/profit_report_screen.dart';
import '../views/backup_screen.dart';

class MainScreen extends StatefulWidget {
  final int? editInvoiceId;

  const MainScreen({super.key, this.editInvoiceId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _horizontalScrollController = ScrollController();

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();
  final TextEditingController _extraCostController = TextEditingController();
  final TextEditingController _extraDescriptionController = TextEditingController();

  String _selectedDate = '';
  final List<InvoiceItem> _items = [];
  final List<AttachmentItem> _attachments = [];
  int? _editingInvoiceId;
  String? _pendingFilePath;
  String? _pendingFileName;

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    _selectedDate =
    '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
    _invoiceDateController.text = _selectedDate;

    if (widget.editInvoiceId != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadInvoiceForEdit(widget.editInvoiceId!));
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _invoiceDateController.dispose();
    _extraCostController.dispose();
    _extraDescriptionController.dispose();
    super.dispose();
  }

  int get _grandTotal {
    int total = 0;
    for (var item in _items) total += item.rowTotal;
    return total;
  }

  int get _finalTotal {
    final extra = NumberFormatter.parseNumber(_extraCostController.text);
    return _grandTotal + extra;
  }

  double get _totalWeight {
    double weight = 0;
    for (var item in _items) weight += item.weight.toDouble();
    return weight;
  }

  void _addItem(InvoiceItem item) => setState(() => _items.add(item));

  void _editItem(int index, InvoiceItem newItem) =>
      setState(() => _items[index] = newItem);

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  void _showItemDialog({InvoiceItem? item, int? index}) {
    final bool isEdit = item != null;

    final TextEditingController productController =
    TextEditingController(text: isEdit ? item.productName : '');
    final TextEditingController weightController = TextEditingController(
        text: isEdit ? NumberFormatter.formatNumber(item.weight) : '');
    final TextEditingController priceController = TextEditingController(
        text: isEdit ? NumberFormatter.formatNumber(item.unitPrice) : '');
    final TextEditingController nameController =
    TextEditingController(text: isEdit ? item.name : '');
    final TextEditingController mobileController =
    TextEditingController(text: isEdit ? item.mobile : '');
    final TextEditingController addressController =
    TextEditingController(text: isEdit ? item.address : '');
    final TextEditingController notesController =
    TextEditingController(text: isEdit ? item.notes : '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? '✏️ ویرایش محصول' : '➕ افزودن محصول'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: productController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '🥬 نام محصول',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: weightController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '⚖️ وزن (کیلوگرم)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  onChanged: (value) {
                    final formatted = NumberFormatter.formatInput(value);
                    if (formatted != value) {
                      weightController.value = TextEditingValue(
                        text: formatted,
                        selection:
                        TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '💰 قیمت واحد (تومان)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  onChanged: (value) {
                    final formatted = NumberFormatter.formatInput(value);
                    if (formatted != value) {
                      priceController.value = TextEditingValue(
                        text: formatted,
                        selection:
                        TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '👤 نام فروشنده',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: mobileController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '📞 تلفن فروشنده',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '📍 آدرس فروشنده',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '📝 توضیحات',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('لغو', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final product = productController.text.trim();
                final weight = NumberFormatter.parseNumber(weightController.text);
                final price = NumberFormatter.parseNumber(priceController.text);
                final name = nameController.text.trim();
                final mobile = mobileController.text.trim();
                final address = addressController.text.trim();
                final notes = notesController.text.trim();

                if (product.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('نام محصول الزامی است')),
                  );
                  return;
                }

                final newItem = InvoiceItem(
                  invoiceId: 0,
                  productName: product,
                  weight: weight,
                  unitPrice: price,
                  name: name,
                  mobile: mobile,
                  address: address,
                  notes: notes,
                );

                if (isEdit && index != null) {
                  _editItem(index, newItem);
                } else {
                  _addItem(newItem);
                }
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? '💾 ویرایش' : '💾 ذخیره'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final String? pickedDate = await CustomPersianDatePicker.show(context);
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _invoiceDateController.text = pickedDate;
      });
    }
  }

  Future<void> _pickAttachment() async {
    try {
      FilePickerResult? result =
      await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result != null) {
        final file = result.files.first;
        _pendingFilePath = file.path;
        String baseName = file.name;
        int dotIndex = file.name.lastIndexOf('.');
        if (dotIndex > 0) baseName = file.name.substring(0, dotIndex);
        _pendingFileName = baseName;
        _showFileNameDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطا در انتخاب فایل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFileNameDialog() {
    final TextEditingController nameController =
    TextEditingController(text: _pendingFileName ?? '');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✏️ نام فایل را وارد کنید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('نام جدید فایل را وارد کنید:'),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'نام فایل',
                prefixIcon: Icon(Icons.edit),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pendingFilePath = null;
              _pendingFileName = null;
              Navigator.pop(context);
            },
            child: const Text('لغو', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              String newName = nameController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ نام فایل نمی‌تواند خالی باشد!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              String extension = '';
              String originalName = _pendingFileName ?? '';
              int dotIndex = originalName.lastIndexOf('.');
              if (dotIndex > 0) extension = originalName.substring(dotIndex);

              String finalName = newName + extension;

              setState(() => _attachments.add(
                AttachmentItem(
                  name: finalName,
                  path: _pendingFilePath!,
                  size: 0,
                  isSaved: false,
                ),
              ));

              _pendingFilePath = null;
              _pendingFileName = null;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ فایل با نام "$finalName" اضافه شد'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _viewAttachment(int index) {
    final att = _attachments[index];
    try {
      final file = File(att.path);
      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فایل پیدا نشد!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final ext = att.path.split('.').last.toLowerCase();
      final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);

      if (isImage) {
        _showImageDialog(att);
      } else {
        _openWithDefaultApp(att.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطا در باز کردن فایل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openWithDefaultApp(String path) {
    try {
      if (Platform.isWindows) {
        Process.run('start', [path], runInShell: true);
      } else if (Platform.isMacOS) {
        Process.run('open', [path]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [path]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطا در باز کردن فایل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageDialog(AttachmentItem att) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      att.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Center(
                  child: Image.file(
                    File(att.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeAttachment(int index) =>
      setState(() => _attachments.removeAt(index));

  Future<void> _previewInvoice() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ فاکتور خالی است! حداقل یک آیتم اضافه کنید.'),
        ),
      );
      return;
    }

    try {
      final extraCost = NumberFormatter.parseNumber(_extraCostController.text);

      final invoice = Invoice(
        invoiceNumber: '',
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        date: _selectedDate,
        totalAmount: _finalTotal,
        extraCost: extraCost,
        extraDescription: _extraDescriptionController.text.trim(),
        items: List.from(_items),
      );

      int invoiceId;
      if (_editingInvoiceId == null) {
        invoiceId = await _dbHelper.insertInvoice(invoice);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📝 فاکتور جدید ذخیره شد!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        invoice.id = _editingInvoiceId;
        await _dbHelper.updateInvoice(invoice);
        invoiceId = _editingInvoiceId!;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✏️ فاکتور با موفقیت بروزرسانی شد!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      for (var att in _attachments) {
        if (!att.isSaved) {
          await _dbHelper.insertAttachment(
            invoiceId,
            att.name,
            att.path,
            'application/octet-stream',
          );
        }
      }

      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطا در ذخیره فاکتور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _customerNameController.clear();
      _customerPhoneController.clear();
      _extraCostController.clear();
      _extraDescriptionController.clear();
      _items.clear();
      _attachments.clear();
      _editingInvoiceId = null;
      final now = Jalali.now();
      _selectedDate =
      '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
      _invoiceDateController.text = _selectedDate;
    });
  }

  Future<void> _loadInvoiceForEdit(int invoiceId) async {
    try {
      final invoice = await _dbHelper.getInvoiceById(invoiceId);
      if (invoice == null) return;

      List<Map<String, dynamic>> attachments =
      await _dbHelper.getAttachmentsByInvoiceId(invoiceId);

      _attachments.clear();
      for (var att in attachments) {
        _attachments.add(
          AttachmentItem(
            id: att['id'],
            name: att['file_name'],
            path: att['file_path'],
            size: 0,
            isSaved: true,
          ),
        );
      }

      setState(() {
        _editingInvoiceId = invoice.id;
        _customerNameController.text = invoice.customerName;
        _customerPhoneController.text = invoice.customerPhone;
        _selectedDate = invoice.date;
        _invoiceDateController.text = invoice.date;
        _extraCostController.text =
            NumberFormatter.formatNumber(invoice.extraCost);
        _extraDescriptionController.text = invoice.extraDescription ?? '';
        _items.clear();
        _items.addAll(invoice.items);
      });
    } catch (e) {
      // Handle error
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🚪 خروج از برنامه'),
        content: const Text('آیا مطمئن هستید که می‌خواهید از برنامه خارج شوید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              exit(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📞 ارتباط با ما'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📱 تلفن: 0912-345-6789'),
            SizedBox(height: 8),
            Text('📧 ایمیل: info@agrotransport.com'),
            SizedBox(height: 8),
            Text('🌐 وب‌سایت: www.agrotransport.com'),
            SizedBox(height: 8),
            Text('📱 اینستاگرام: @agro_transport'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTable(double screenWidth) {
    final double minWidth = 1040;
    final double scaleFactor = screenWidth > minWidth ? screenWidth / minWidth : 1.0;
    final double colRow = 50 * scaleFactor;
    final double colProduct = 130 * scaleFactor;
    final double colWeight = 80 * scaleFactor;
    final double colPrice = 110 * scaleFactor;
    final double colSeller = 110 * scaleFactor;
    final double colMobile = 110 * scaleFactor;
    final double colAddress = 140 * scaleFactor;
    final double colNotes = 120 * scaleFactor;
    final double colTotal = 100 * scaleFactor;
    final double colActions = 90 * scaleFactor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // هدر جدول
        Container(
          color: const Color(0xFF1976D2),
          child: Row(
            children: [
              _buildTableHeader('ردیف', colRow),
              _buildTableHeader('نام محصول', colProduct),
              _buildTableHeader('وزن', colWeight),
              _buildTableHeader('قیمت واحد', colPrice),
              _buildTableHeader('فروشنده', colSeller),
              _buildTableHeader('موبایل', colMobile),
              _buildTableHeader('آدرس', colAddress),
              _buildTableHeader('توضیحات', colNotes),
              _buildTableHeader('جمع ردیف', colTotal),
              _buildTableHeader('عملیات', colActions),
            ],
          ),
        ),

        // وقتی جدول خالیه
        if (_items.isEmpty)
          Container(
            width: minWidth * scaleFactor,
            height: 70,
            alignment: Alignment.center,
            color: Colors.grey[50],
            child: const Text(
              'هیچ کالایی اضافه نشده است',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),

        // ردیف‌های جدول
        ..._items.asMap().entries.map((entry) {
          int index = entry.key;
          InvoiceItem item = entry.value;
          return Container(
            color: index.isEven ? Colors.white : Colors.grey[50],
            child: Row(
              children: [
                _buildTableCell('${index + 1}', colRow),
                _buildTableCell(item.productName, colProduct),
                _buildTableCell(
                    NumberFormatter.formatNumber(item.weight), colWeight),
                _buildTableCell(
                    NumberFormatter.formatNumber(item.unitPrice), colPrice),
                _buildTableCell(item.name, colSeller),
                _buildTableCell(item.mobile, colMobile),
                _buildTableCell(item.address, colAddress),
                _buildTableCell(item.notes, colNotes),
                _buildTableCell(
                    NumberFormatter.formatNumber(item.rowTotal), colTotal),
                SizedBox(
                  width: colActions,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                        onPressed: () =>
                            _showItemDialog(item: item, index: index),
                        padding: EdgeInsets.zero,
                        constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _removeItem(index),
                        padding: EdgeInsets.zero,
                        constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'فاکتور هوشمند کشاورزی',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 4,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[900]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.local_shipping, size: 40, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'حمل و نقل هوشمند کشاورزی',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'نسخه 1.0.0',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.green),
                title: const Text('ایجاد فاکتور جدید'),
                onTap: () {
                  _resetForm();
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.list_alt, color: Colors.blue),
                title: const Text('لیست فاکتورها'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const InvoiceListScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.orange),
                title: const Text('بارگیری فاکتور'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const ShipmentScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.purple),
                title: const Text('ترخیص مرز'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const ClearanceScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.send, color: Colors.teal),
                title: const Text('تحویل به خریدار'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const BuyerDeliveryScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blue),
                title: const Text('نمایش نقشه'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🗺️ بخش نقشه در حال توسعه...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_up, color: Colors.green),
                title: const Text('گزارش سود و ضرر'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const ProfitReportScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.save, color: Colors.blue),
                title: const Text('پشتیبان‌گیری از اطلاعات'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const BackupScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.orange),
                title: const Text('بازگردانی اطلاعات'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(const BackupScreen());
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('تنظیمات'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚙️ بخش تنظیمات در حال توسعه...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: const Text('درباره اپ'),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.call, color: Colors.green),
                title: const Text('ارتباط با ما'),
                onTap: () {
                  Navigator.pop(context);
                  _showContactDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.power_settings_new, color: Colors.red),
                title: const Text('خروج از برنامه'),
                onTap: () {
                  Navigator.pop(context);
                  _showExitDialog();
                },
              ),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth - 32;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            labelText: 'نام مشتری',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customerPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'شماره تماس',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _invoiceDateController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          decoration: const InputDecoration(
                            labelText: 'تاریخ فاکتور',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.today),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickAttachment,
                          icon: const Icon(Icons.attach_file,
                              color: Color(0xFFFF9800)),
                          label: const Text(
                            '📎 افزودن فایل پیوست',
                            style: TextStyle(color: Color(0xFFFF9800)),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: Color(0xFFFF9800)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_attachments.isNotEmpty) ...[
                          const Text(
                            'فایل‌های پیوست:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: _attachments.asMap().entries.map((entry) {
                                int index = entry.key;
                                var att = entry.value;
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.insert_drive_file,
                                    color: att.isSaved
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  title: Text(
                                    att.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _viewAttachment(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _removeAttachment(index),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ========== هزینه متفرقه ==========
                        TextField(
                          controller: _extraCostController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'هزینه متفرقه (تومان)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          onChanged: (value) {
                            final formatted = NumberFormatter.formatInput(value);
                            if (formatted != value) {
                              _extraCostController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                            setState(() {}); // آپدیت لحظه‌ای جمع کل
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _extraDescriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'توضیحات هزینه متفرقه',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                        // ==================================

                        const SizedBox(height: 16),
                        const Text(
                          'لیست کالاها:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context)
                                  .copyWith(scrollbars: true),
                              child: Scrollbar(
                                controller: _horizontalScrollController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                thickness: 8,
                                radius: const Radius.circular(4),
                                child: SingleChildScrollView(
                                  controller: _horizontalScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics:
                                  const AlwaysScrollableScrollPhysics(),
                                  child: _buildTable(screenWidth),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Text(
                    'جمع کل: ${NumberFormatter.formatNumber(_finalTotal)} تومان | وزن کل: ${NumberFormatter.formatNumber(_totalWeight.toInt())} کیلوگرم',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                    maxLines: 2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _showItemDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.add, size: 28),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _previewInvoice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'ثبت و نمایش پیش‌فاکتور',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📱 درباره برنامه'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حمل و نقل هوشمند کشاورزی',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نسخه: 1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'این برنامه برای مدیریت هوشمند حمل و نقل محصولات کشاورزی طراحی شده است.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'امکانات:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('✅ ثبت و مدیریت فاکتورها'),
            Text('✅ مدیریت بارگیری و حمل و نقل'),
            Text('✅ ترخیص مرز'),
            Text('✅ تحویل نهایی به خریدار'),
            Text('✅ گزارش سود و زیان'),
            Text('✅ پشتیبان‌گیری از اطلاعات'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }
}