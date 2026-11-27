import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agro_transport/utils/invoice_number_helper.dart';
import 'package:smart_agro_transport/utils/persian_date_helper.dart';
import 'package:smart_agro_transport/repositories/invoice_repository.dart';

void main() {
  group('InvoiceNumberHelper', () {
    test('format builds yearly sequential number', () {
      expect(InvoiceNumberHelper.format(1404, 1), '14040001');
      expect(InvoiceNumberHelper.format(1404, 13), '14040013');
      expect(InvoiceNumberHelper.format(1405, 100), '14050100');
    });

    test('parseSequence reads last 4 digits', () {
      expect(InvoiceNumberHelper.parseSequence('14050013'), 13);
      expect(InvoiceNumberHelper.parseSequence('14040001'), 1);
      expect(InvoiceNumberHelper.parseSequence(null), isNull);
    });

    test('parseYear reads prefix', () {
      expect(InvoiceNumberHelper.parseYear('14050013'), 1405);
    });
  });

  group('PersianDateHelper.toSortableKey', () {
    test('parses slash format', () {
      final k = PersianDateHelper.toSortableKey('1404/08/15');
      expect(k, isNotNull);
      expect(k, greaterThan(14040000));
    });

    test('newer date has larger key', () {
      final a = PersianDateHelper.toSortableKey('1404/01/01')!;
      final b = PersianDateHelper.toSortableKey('1404/12/29')!;
      expect(b, greaterThan(a));
    });
  });

  group('InvoiceRepository totals', () {
    test('calcRowTotal multiplies weight and price', () {
      expect(InvoiceRepository.calcRowTotal(10, 1000), 10000);
    });

    test('calcRowTotal rejects negative', () {
      expect(() => InvoiceRepository.calcRowTotal(-1, 10), throwsArgumentError);
      expect(() => InvoiceRepository.calcRowTotal(1, -5), throwsArgumentError);
    });

    test('calcGrandTotal sums rows and misc', () {
      expect(
        InvoiceRepository.calcGrandTotal(rowTotals: [100, 200], miscCost: 50),
        350,
      );
    });
  });
}
