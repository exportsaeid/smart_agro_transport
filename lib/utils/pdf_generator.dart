// lib/utils/pdf_generator.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/invoice.dart';

class PdfGenerator {
  static pw.Font? _persianFont;
  static pw.Font? _persianFontBold;
  static bool _fontLoaded = false;

  // ==================== بارگذاری فونت ====================
  static Future<void> _loadFont() async {
    if (_fontLoaded) return;

    try {
      final fontData = await rootBundle.load('assets/fonts/vazir.ttf');
      _persianFont = pw.Font.ttf(fontData.buffer.asByteData());

      try {
        final boldData = await rootBundle.load('assets/fonts/vazir_bold.ttf');
        _persianFontBold = pw.Font.ttf(boldData.buffer.asByteData());
      } catch (_) {
        _persianFontBold = _persianFont;
      }

      _fontLoaded = true;
      print('✅ فونت فارسی بارگذاری شد');
    } catch (e) {
      print('⚠️ خطا در بارگذاری فونت: $e');
      _persianFont = pw.Font.helvetica();
      _persianFontBold = pw.Font.helveticaBold();
      _fontLoaded = true;
    }
  }

  static pw.TextStyle _t({
    double fontSize = 11,
    PdfColor color = PdfColors.black,
    bool bold = false,
  }) {
    return pw.TextStyle(
      font: bold ? (_persianFontBold ?? _persianFont) : _persianFont,
      fontFallback: [_persianFont!],
      fontSize: fontSize,
      color: color,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
  }

  // ==================== تولید PDF ====================
  static Future<Uint8List> generatePdf(Invoice invoice) async {
    await _loadFont();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _persianFont!,
        bold: _persianFontBold ?? _persianFont!,
      ),
    );

    final currencyFormat = NumberFormat('#,###');
    final totalWeight = invoice.items.fold(0.0, (sum, item) => sum + item.weight);
    final itemsTotal = invoice.items.fold(0.0, (sum, item) => sum + item.rowTotal);
    final grandTotal = itemsTotal + (invoice.miscCost);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: _persianFont!,
          bold: _persianFontBold ?? _persianFont!,
        ),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(invoice),
                pw.SizedBox(height: 18),
                _buildItemsTable(
                  invoice.items,
                  currencyFormat,
                  invoice.miscCost,
                  invoice.miscNotes,
                  totalWeight,
                  grandTotal,
                ),
                pw.Spacer(),
                _buildSignatures(),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ==================== هدر ====================
  static pw.Widget _buildHeader(Invoice invoice) {
    final invNo = invoice.invoiceNumber ?? 'پیش‌نویس';
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: pw.BoxDecoration(
        color: PdfColors.green800,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'فاکتور فروش',
            style: _t(fontSize: 22, color: PdfColors.white, bold: true),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
          if ((invoice.invoiceNumber ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 10),
            // بارکد خطی بدون عدد زیرش
            pw.Container(
              color: PdfColors.white,
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: pw.BarcodeWidget(
                barcode: Barcode.code128(),
                data: invoice.invoiceNumber!,
                width: 160,
                height: 40,
                drawText: false,
              ),
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'مشتری: ${invoice.customerName}',
                    style: _t(fontSize: 11, color: PdfColors.white),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  if (invoice.customerPhone.isNotEmpty)
                    pw.Text(
                      'تلفن: ${invoice.customerPhone}',
                      style: _t(fontSize: 11, color: PdfColors.white),
                      textDirection: pw.TextDirection.rtl,
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'تاریخ: ${invoice.date}',
                    style: _t(fontSize: 11, color: PdfColors.white),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  // شماره فقط زیر تاریخ — یک‌جا
                  pw.Text(
                    'شماره فاکتور: $invNo',
                    style: _t(fontSize: 11, color: PdfColors.white, bold: true),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== جدول محصولات با سطرهای جمع ====================
  static pw.Widget _buildItemsTable(
      List items,
      NumberFormat currencyFormat,
      double miscCost,
      String miscNotes,
      double totalWeight,
      double grandTotal,
      ) {
    if (items.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'فاکتور خالی است',
          style: _t(fontSize: 14),
          textDirection: pw.TextDirection.rtl,
        ),
      );
    }

    // ترتیب ستون‌ها از چپ به راست
    final headers = [
      'جمع',
      'آدرس',
      'موبایل',
      'فروشنده',
      'قیمت واحد',
      'وزن',
      'نام محصول',
      'ردیف',
    ];

    pw.Widget cell(String text, {
      bool header = false,
      bool isTotal = false,
      bool isSummary = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
        child: pw.Text(
          text,
          style: _t(
            fontSize: header ? 9 : (isSummary ? 10 : 8.5),
            color: header
                ? PdfColors.white
                : (isTotal || isSummary ? PdfColors.red800 : PdfColors.black),
            bold: header || isTotal || isSummary,
          ),
          textAlign: pw.TextAlign.center,
          textDirection: pw.TextDirection.rtl,
          maxLines: 2,
        ),
      );
    }

    // سطر هدر
    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.green700),
      children: headers.map((h) => cell(h, header: true)).toList(),
    );

    // سطرهای داده
    final dataRows = <pw.TableRow>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final rowTotal = item.weight * item.unitPrice;

      dataRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
          ),
          children: [
            cell(currencyFormat.format(rowTotal), isTotal: true),
            cell(item.address.isEmpty ? '-' : item.address),
            cell(item.mobile.isEmpty ? '-' : item.mobile),
            cell(item.name.isEmpty ? '-' : item.name),
            cell(currencyFormat.format(item.unitPrice)),
            cell(_formatWeight(item.weight)),
            cell(item.productName.isEmpty ? '-' : item.productName),
            cell('${i + 1}'),
          ],
        ),
      );
    }

    // ==================== سطر هزینه متفرقه (2 ستون) ====================
    if (miscCost > 0 || miscNotes.isNotEmpty) {
      // خط جداکننده
      dataRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.white,
          ),
          children: [
            pw.Container(height: 2, color: PdfColors.grey300),
            pw.Container(height: 2, color: PdfColors.grey300),
            pw.Container(height: 2, color: PdfColors.grey300),
            pw.Container(height: 2, color: PdfColors.grey300),
            pw.Container(height: 2, color: PdfColors.grey300),
            pw.Container(height: 2, color: PdfColors.grey300),
            pw.Container(height: 2, color: PdfColors.grey300),
            pw.Container(height: 2, color: PdfColors.grey300),
          ],
        ),
      );

      // سطر هزینه متفرقه
      dataRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.orange50,
          ),
          children: [
            cell(
              miscCost > 0 ? currencyFormat.format(miscCost) : '۰',
              isSummary: true,
            ),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            pw.Container(),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
              child: pw.Text(
                miscNotes.isNotEmpty ? 'هزینه متفرقه: $miscNotes' : 'هزینه متفرقه',
                style: _t(fontSize: 10, color: PdfColors.red800, bold: true),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
                maxLines: 2,
              ),
            ),
            pw.Container(),
          ],
        ),
      );
    }

    // ==================== خط جداکننده قبل از جمع ====================
    dataRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.white,
        ),
        children: [
          pw.Container(height: 2, color: PdfColors.grey300),
          pw.Container(height: 2, color: PdfColors.grey300),
          pw.Container(height: 2, color: PdfColors.grey300),
          pw.Container(height: 2, color: PdfColors.grey300),
          pw.Container(height: 2, color: PdfColors.grey300),
          pw.Container(height: 2, color: PdfColors.grey300),
          pw.Container(height: 2, color: PdfColors.grey300),
          pw.Container(height: 2, color: PdfColors.grey300),
        ],
      ),
    );

    // ==================== سطر وزن کل (2 ستون) ====================
    dataRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
        ),
        children: [
          // ستون جمع: خالی
          pw.Container(),
          // ستون آدرس: خالی
          pw.Container(),
          // ستون موبایل: خالی
          pw.Container(),
          // ستون فروشنده: خالی
          pw.Container(),
          // ستون قیمت واحد: خالی
          pw.Container(),
          // ستون وزن: وزن کل
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            child: pw.Text(
              _formatWeight(totalWeight),
              style: _t(fontSize: 10, color: PdfColors.red800, bold: true),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          // ستون نام محصول: متن "وزن کل"
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            child: pw.Text(
              'وزن کل',
              style: _t(fontSize: 10, color: PdfColors.red800, bold: true),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          // ستون ردیف: خالی
          pw.Container(),
        ],
      ),
    );

    // ==================== سطر جمع کل (2 ستون) ====================
    dataRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: PdfColors.green100,
          border: const pw.Border(
            bottom: pw.BorderSide(color: PdfColors.green800, width: 2),
          ),
        ),
        children: [
          // ستون جمع: جمع کل
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            child: pw.Text(
              currencyFormat.format(grandTotal),
              style: _t(fontSize: 10, color: PdfColors.red800, bold: true),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          // ستون آدرس: خالی
          pw.Container(),
          // ستون موبایل: خالی
          pw.Container(),
          // ستون فروشنده: خالی
          pw.Container(),
          // ستون قیمت واحد: خالی
          pw.Container(),
          // ستون وزن: خالی
          pw.Container(),
          // ستون نام محصول: متن "جمع کل"
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            child: pw.Text(
              'جمع کل',
              style: _t(fontSize: 10, color: PdfColors.red800, bold: true),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          // ستون ردیف: خالی
          pw.Container(),
        ],
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.1),  // جمع
        1: const pw.FlexColumnWidth(1.2),  // آدرس
        2: const pw.FlexColumnWidth(1.1),  // موبایل
        3: const pw.FlexColumnWidth(1.1),  // فروشنده
        4: const pw.FlexColumnWidth(1.0),  // قیمت واحد
        5: const pw.FlexColumnWidth(0.9),  // وزن
        6: const pw.FlexColumnWidth(1.6),  // نام محصول
        7: const pw.FixedColumnWidth(32),  // ردیف
      },
      children: [headerRow, ...dataRows],
    );
  }

  // ==================== امضاها ====================
  static pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          children: [
            pw.Text(
              'امضا فروشنده',
              style: _t(fontSize: 11),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 28),
            pw.Container(width: 140, height: 1, color: PdfColors.black),
          ],
        ),
        pw.Column(
          children: [
            pw.Text(
              'امضا خریدار',
              style: _t(fontSize: 11),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 28),
            pw.Container(width: 140, height: 1, color: PdfColors.black),
          ],
        ),
      ],
    );
  }

  // ==================== توابع عمومی ====================

  static Future<void> printPdf(Invoice invoice) async {
    try {
      final pdfBytes = await generatePdf(invoice);
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'فاکتور_${invoice.invoiceNumber ?? 'پیش‌نویس'}.pdf',
      );
    } catch (e) {
      print('❌ خطا در چاپ: $e');
      rethrow;
    }
  }

  static Future<String?> savePdf(Invoice invoice) async {
    try {
      final pdfBytes = await generatePdf(invoice);

      String? directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return null;

      final fileName =
          'فاکتور_${invoice.invoiceNumber ?? 'پیش‌نویس'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$directory/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      return filePath;
    } catch (e) {
      print('❌ خطا در ذخیره PDF: $e');
      return null;
    }
  }

  static Future<void> sharePdf(Invoice invoice) async {
    try {
      final pdfBytes = await generatePdf(invoice);

      final tempDir = await getTemporaryDirectory();
      final fileName = 'فاکتور_${invoice.invoiceNumber ?? 'پیش‌نویس'}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'فاکتور شماره ${invoice.invoiceNumber ?? ''} - ${invoice.customerName}',
      );
    } catch (e) {
      print('❌ خطا در اشتراک‌گذاری: $e');
      rethrow;
    }
  }

  static String _formatWeight(double weight) {
    if (weight == weight.roundToDouble()) {
      return NumberFormat('#,###').format(weight);
    }
    return weight.toStringAsFixed(2);
  }
}