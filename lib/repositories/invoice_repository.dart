import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../utils/persian_date_helper.dart';

/// لایه Repository برای جدا کردن منطق دیتابیس از UI
class InvoiceRepository {
  InvoiceRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  Future<List<Invoice>> getAllSortedByDateDesc() async {
    final list = await _db.getAllInvoices();
    list.sort(_compareDateDesc);
    return list;
  }

  Future<Invoice?> getById(int id) => _db.getInvoice(id);

  Future<int> save(Invoice invoice) => _db.saveInvoice(invoice);

  Future<void> delete(int id) => _db.deleteInvoice(id);

  Future<String> nextInvoiceNumber() => _db.generateInvoiceNumber();

  static int _compareDateDesc(Invoice a, Invoice b) {
    final ka = PersianDateHelper.toSortableKey(a.date) ?? 0;
    final kb = PersianDateHelper.toSortableKey(b.date) ?? 0;
    final c = kb.compareTo(ka);
    if (c != 0) return c;
    return (b.id ?? 0).compareTo(a.id ?? 0);
  }

  /// محاسبه جمع اقلام + متفرقه (برای تست و استفاده مشترک)
  static double calcGrandTotal({
    required List<double> rowTotals,
    double miscCost = 0,
  }) {
    final items = rowTotals.fold<double>(0, (s, v) => s + v);
    return items + miscCost;
  }

  static double calcRowTotal(double weight, double unitPrice) {
    if (weight < 0 || unitPrice < 0) {
      throw ArgumentError('وزن و قیمت نمی‌توانند منفی باشند');
    }
    return weight * unitPrice;
  }
}
