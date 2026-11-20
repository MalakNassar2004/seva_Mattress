import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:seva_mattress/app/utils/money.dart';
import 'package:seva_mattress/data/repositories/company_repository.dart';
import 'package:seva_mattress/modules/customers/customer_models.dart'
    show formatPhone;
import 'package:seva_mattress/modules/orders/order_models.dart';

/// Builds the invoice of an order as a PDF (US Letter, as used in Canada).
///
/// The built-in PDF font only knows Latin characters, so any other character
/// (for example Arabic letters in a customer name) is printed as "?".
class InvoiceService {
  const InvoiceService();

  static const PdfColor _blue = PdfColor.fromInt(0xFF0B5FC4);
  static const PdfColor _green = PdfColor.fromInt(0xFF15803D);
  static const PdfColor _amber = PdfColor.fromInt(0xFFB45309);

  /// The brand logo and the flag shown in the header. If a file is missing
  /// the invoice is still printed, just without it.
  static const String _logoAsset = 'assets/images/invoice_logo.png';
  static const String _logoFallbackAsset = 'assets/images/logo.png';
  static const String _flagAsset = 'assets/images/canada_flag.png';

  static Future<pw.MemoryImage?> _loadImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  /// Keeps only the characters the built-in font can draw.
  static String _t(String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      if (r == 0x2013 || r == 0x2014) {
        b.write('-');
      } else if (r == 0x2018 || r == 0x2019) {
        b.write("'");
      } else if (r == 0x201C || r == 0x201D) {
        b.write('"');
      } else if (r == 0x2026) {
        b.write('...');
      } else if (r == 0x0A || r < 0x20) {
        b.write(' ');
      } else if (r < 256) {
        b.writeCharCode(r);
      } else {
        b.write('?');
      }
    }
    return b.toString();
  }

  static pw.TextStyle _s(
    double size, {
    bool bold = false,
    PdfColor color = PdfColors.black,
  }) =>
      pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      );

  /// 500 -> "5%", 725 -> "7.25%".
  static String _pct(int bp) =>
      bp % 100 == 0 ? '${bp ~/ 100}%' : '${(bp / 100).toStringAsFixed(2)}%';

  String _m(int cents) => formatCad(cents / 100);

  int _c(Object? v) => (v as num?)?.toInt() ?? 0;

  Future<Uint8List> build({
    required CompanyInfo company,
    required Map<String, dynamic> order,
    required List<PaymentRecord> payments,
  }) async {
    final logo =
        await _loadImage(_logoAsset) ?? await _loadImage(_logoFallbackAsset);
    final flag = await _loadImage(_flagAsset);

    final number = _t((order['number'] as String?) ?? '');
    final createdAt =
        (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final lines = ((order['lines'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final subtotal = _c(order['subtotalCents']);
    final tax = _c(order['taxCents']);
    final total = _c(order['totalCents']);
    final paid = _c(order['paidCents']);
        final discount = _c(order['discountCents']);
    final refunded = _c(order['refundedCents']);
    final balance = total - paid > 0 ? total - paid : 0;

    // GST and PST are printed on separate lines. An order saved before the
    // tax was split has only the total: GST 5%, and the rest is PST.
    final taxBp = _c(order['taxBp']);
    int gstBp;
    int pstBp;
    int gst;
    int pst;
    if (order['gstCents'] == null) {
      gstBp = 500;
      pstBp = taxBp > 500 ? taxBp - 500 : 0;
      gst = (subtotal * gstBp + 5000) ~/ 10000;
      pst = tax - gst;
    } else {
      gstBp = _c(order['gstBp']);
      pstBp = _c(order['pstBp']);
      gst = _c(order['gstCents']);
      pst = _c(order['pstCents']);
    }

    final customerName = _t((order['customerName'] as String?) ?? '');
    final phoneKey = (order['customerPhone'] as String?) ?? '';
    final phone = phoneKey.isEmpty ? '' : formatPhone(phoneKey);
    final city = _t((order['customerCity'] as String?) ?? '');
    final address = _t((order['customerAddress'] as String?) ?? '');

    final delivery = (order['deliveryDate'] as Timestamp?)?.toDate();
    final nextPayment = (order['nextPaymentDate'] as Timestamp?)?.toDate();

    final spec = order['isCustom'] == true && order['spec'] is Map
        ? Map<String, dynamic>.from(order['spec'] as Map)
        : null;

    final doc = pw.Document(
      title: 'Invoice $number',
      author: _t(company.name),
    );

    pw.Widget cell(
      String text, {
      pw.TextStyle? style,
      pw.Alignment align = pw.Alignment.centerLeft,
    }) =>
        pw.Container(
          alignment: align,
          padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          child: pw.Text(text, style: style ?? _s(10)),
        );

    pw.Widget totalRow(
      String label,
      String value, {
      bool bold = false,
      PdfColor color = PdfColors.black,
    }) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: _s(bold ? 12 : 10.5, bold: bold, color: color)),
              pw.Text(value, style: _s(bold ? 12 : 10.5, bold: bold, color: color)),
            ],
          ),
        );

    final companyLines = <String>[
      if (company.address.isNotEmpty) company.address,
      [
        if (company.phone.isNotEmpty) company.phone,
        if (company.email.isNotEmpty) company.email,
      ].join('  |  '),
      if (company.gstNumber.isNotEmpty) 'GST No: ${company.gstNumber}',
      if (company.pstNumber.isNotEmpty) 'PST No: ${company.pstNumber}',    ].where((l) => l.trim().isNotEmpty).toList();

    final paidInFull = total > 0 && balance == 0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: _s(8.5, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          // ---------- Header ----------
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logo != null) ...[
                      // A fixed box: the logo is scaled to fit it.
                      pw.SizedBox(
                        width: 104,
                        height: 46,
                        child: pw.Image(
                          logo,
                          fit: pw.BoxFit.contain,
                          alignment: pw.Alignment.centerLeft,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                    ],
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Flexible(
                                child: pw.Text(
                                  _t(company.name),
                                  style: _s(17, bold: true, color: _blue),
                                ),
                              ),
                              if (flag != null) ...[
                                pw.SizedBox(width: 8),
                                pw.SizedBox(
                                  width: 26,
                                  height: 13,
                                  child: pw.Image(flag, fit: pw.BoxFit.contain),
                                ),
                              ],
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          for (final l in companyLines)
                            pw.Text(_t(l),
                                style: _s(9.5, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(_t(company.invoiceTitle), style: _s(22, bold: true)),
                  pw.SizedBox(height: 4),
                  pw.Text(number, style: _s(11, bold: true, color: _blue)),
                  pw.Text(fmtOrderDate(createdAt),
                      style: _s(10, color: PdfColors.grey700)),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: paidInFull ? _green : _amber,
                        width: 1,
                      ),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      paidInFull ? 'PAID IN FULL' : 'BALANCE DUE',
                      style: _s(9, bold: true, color: paidInFull ? _green : _amber),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey400, thickness: 0.8),
          pw.SizedBox(height: 10),

          // ---------- Bill to ----------
          pw.Text('BILL TO',
              style: _s(8.5, bold: true, color: PdfColors.grey600)),
          pw.SizedBox(height: 3),
          pw.Text(customerName, style: _s(12, bold: true)),
          if (phone.isNotEmpty) pw.Text(_t(phone), style: _s(10)),
          if (address.isNotEmpty) pw.Text(address, style: _s(10)),
          if (city.isNotEmpty) pw.Text(city, style: _s(10)),
          pw.SizedBox(height: 16),

          // ---------- Items ----------
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(5),
              1: const pw.FixedColumnWidth(36),
              2: const pw.FixedColumnWidth(82),
              3: const pw.FixedColumnWidth(92),
            },
            border: const pw.TableBorder(
              horizontalInside:
                  pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.8),
            ),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  cell('ITEM',
                      style: _s(8.5, bold: true, color: PdfColors.grey700)),
                  cell('QTY',
                      style: _s(8.5, bold: true, color: PdfColors.grey700),
                      align: pw.Alignment.centerRight),
                  cell('UNIT PRICE',
                      style: _s(8.5, bold: true, color: PdfColors.grey700),
                      align: pw.Alignment.centerRight),
                  cell('TOTAL',
                      style: _s(8.5, bold: true, color: PdfColors.grey700),
                      align: pw.Alignment.centerRight),
                ],
              ),
              for (final l in lines)
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 7, horizontal: 4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_t((l['name'] as String?) ?? ''),
                              style: _s(10.5, bold: true)),
                          if (((l['details'] as String?) ?? '').isNotEmpty)
                            pw.Text(_t((l['details'] as String?) ?? ''),
                                style: _s(8.5, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    cell('${_c(l['qty'])}', align: pw.Alignment.centerRight),
                    cell(_m(_c(l['unitCents'])),
                        align: pw.Alignment.centerRight),
                    cell(_m(_c(l['unitCents']) * _c(l['qty'])),
                        style: _s(10, bold: true),
                        align: pw.Alignment.centerRight),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 12),

          // ---------- Totals ----------
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 230,
              child: pw.Column(
                children: [
                  totalRow('Subtotal', _m(subtotal)),
                  if (discount > 0) totalRow('Discount', '-${_m(discount)}'),                  totalRow('GST (${_pct(gstBp)})', _m(gst)),
                  totalRow('PST (${_pct(pstBp)})', _m(pst)),
                  pw.Divider(color: PdfColors.grey400, thickness: 0.6),
                  totalRow('Total', _m(total), bold: true),
                  totalRow('Paid', _m(paid), color: _green),
                  if (refunded > 0)
                    totalRow('Refunded', '-${_m(refunded)}', color: _amber),                  pw.Divider(color: PdfColors.grey400, thickness: 0.6),
                  totalRow(
                    'Balance due',
                    _m(balance),
                    bold: true,
                    color: balance > 0 ? _amber : _green,
                  ),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('All amounts in CAD',
                        style: _s(8, color: PdfColors.grey600)),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Payments ----------
          if (payments.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('PAYMENTS',
                style: _s(8.5, bold: true, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            for (final p in payments)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        _t('${p.dateLabel}   ${p.method}   ${p.kind}'),
                        style: _s(9.5),
                      ),
                    ),
                    pw.Text(formatCad(p.amount), style: _s(9.5, bold: true)),
                  ],
                ),
              ),
          ],

          // ---------- Dates ----------
          if (delivery != null || (nextPayment != null && balance > 0)) ...[
            pw.SizedBox(height: 14),
            if (delivery != null)
              pw.Text('Delivery date: ${fmtOrderDate(delivery)}',
                  style: _s(10, bold: true)),
            if (nextPayment != null && balance > 0)
              pw.Text(
                'Next payment due: ${fmtOrderDate(nextPayment)} (${_m(balance)})',
                style: _s(10, bold: true, color: _amber),
              ),
          ],

          // ---------- Custom build ----------
          if (spec != null) ...[
            pw.SizedBox(height: 14),
            pw.Text('CUSTOM BUILD',
                style: _s(8.5, bold: true, color: PdfColors.grey600)),
            pw.SizedBox(height: 3),
            pw.Text(
              _t([
                if (((spec['width'] as String?) ?? '').isNotEmpty &&
                    ((spec['length'] as String?) ?? '').isNotEmpty)
                  'Size: ${spec['width']} x ${spec['length']} in',
                if (((spec['angle'] as String?) ?? '').isNotEmpty)
                  'Cut angle: ${spec['angle']} deg',
                if (((spec['thickness'] as String?) ?? '').isNotEmpty)
                  'Thickness: ${spec['thickness']} in',
              ].join('   |   ')),
              style: _s(10),
            ),
            if (((spec['notes'] as String?) ?? '').isNotEmpty)
              pw.Text(_t('Notes: ${spec['notes']}'), style: _s(9.5)),
          ],

          // ---------- Footer text ----------
          pw.SizedBox(height: 24),
          if (company.thankYou.isNotEmpty)
            pw.Text(_t(company.thankYou),
                style: _s(11, bold: true, color: _blue)),
          if (company.terms.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(_t(company.terms),
                style: _s(8.5, color: PdfColors.grey700)),
          ],
        ],
      ),
    );

    return doc.save();
  }
}