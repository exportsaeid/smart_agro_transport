import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agro_transport/utils/invoice_number_helper.dart';

void main() {
  test('smoke: invoice number format', () {
    expect(InvoiceNumberHelper.format(1405, 1), '14050001');
  });
}
