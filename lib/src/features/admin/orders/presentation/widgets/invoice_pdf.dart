import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/shared/utils/order_status_display.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';

const _regularFont = 'assets/fonts/BeVietnamPro-Regular.ttf';
const _boldFont = 'assets/fonts/BeVietnamPro-Bold.ttf';

final _muted = PdfColor.fromInt(0xFF8A8A8A);
final _line = PdfColor.fromInt(0xFFE5E5E5);

/// Builds the A4 invoice for [order] — same structure as the web admin's
/// printable invoice (header + status, customer / info columns, items
/// table, totals, thank-you footer), with Vietnamese labels. Uses the
/// bundled Be Vietnam Pro TTFs because the built-in PDF fonts have no
/// Vietnamese glyphs.
Future<Uint8List> buildInvoicePdf(
  AdminOrder order, {
  String brand = 'Phương Loan Bakery',
}) async {
  final regular = pw.Font.ttf(await rootBundle.load(_regularFont));
  final bold = pw.Font.ttf(await rootBundle.load(_boldFont));
  final doc = pw.Document(
    title: 'Hoá đơn ${order.orderNumber}',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (_) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 24),
        padding: const pw.EdgeInsets.only(top: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _line)),
        ),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'Cảm ơn bạn đã đặt hàng! • $brand',
          style: pw.TextStyle(fontSize: 10, color: _muted),
        ),
      ),
      build: (_) => [
        _header(order, brand),
        pw.SizedBox(height: 24),
        _infoColumns(order),
        pw.SizedBox(height: 24),
        _itemsTable(order),
        pw.SizedBox(height: 16),
        _totals(order),
      ],
    ),
  );
  return doc.save();
}

pw.Widget _header(AdminOrder order, String brand) {
  final status = order.status;
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            brand,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('HOÁ ĐƠN', style: pw.TextStyle(fontSize: 11, color: _muted)),
        ],
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            order.orderNumber,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(orderStatusColor(status).toARGB32()),
              borderRadius: pw.BorderRadius.circular(AppRadius.sm),
            ),
            child: pw.Text(
              orderStatusLabel(status),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(
                  orderStatusTextColor(status).toARGB32(),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _infoColumns(AdminOrder order) {
  final address = order.customerAddress;
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: _infoBlock('KHÁCH HÀNG', [
          ('Tên', order.customerName),
          ('SĐT', order.customerPhone),
          if (address != null && address.trim().isNotEmpty)
            ('Địa chỉ', address),
        ]),
      ),
      pw.SizedBox(width: 24),
      pw.Expanded(
        child: _infoBlock('THÔNG TIN', [
          ('Ngày', formatDateTimeVi(order.createdAt.toLocal())),
          ('Thanh toán', order.paymentMethod ?? 'N/A'),
        ]),
      ),
    ],
  );
}

pw.Widget _infoBlock(String title, List<(String, String)> rows) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _muted,
          letterSpacing: 1,
        ),
      ),
      pw.SizedBox(height: 6),
      for (final (label, value) in rows)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 11),
              children: [
                pw.TextSpan(
                  text: '$label: ',
                  style: pw.TextStyle(color: _muted),
                ),
                pw.TextSpan(text: value),
              ],
            ),
          ),
        ),
    ],
  );
}

pw.Widget _itemsTable(AdminOrder order) {
  const headerStyle = pw.TextStyle(fontSize: 10);
  pw.Widget cell(
    pw.Widget child, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) => pw.Container(
    alignment: align,
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    child: child,
  );

  return pw.Table(
    columnWidths: const {
      0: pw.FlexColumnWidth(),
      1: pw.FixedColumnWidth(40),
      2: pw.FixedColumnWidth(90),
      3: pw.FixedColumnWidth(100),
    },
    border: pw.TableBorder(horizontalInside: pw.BorderSide(color: _line)),
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _muted)),
        ),
        children: [
          cell(pw.Text('Sản phẩm', style: headerStyle)),
          cell(pw.Text('SL', style: headerStyle), align: pw.Alignment.center),
          cell(
            pw.Text('Đơn giá', style: headerStyle),
            align: pw.Alignment.centerRight,
          ),
          cell(
            pw.Text('Thành tiền', style: headerStyle),
            align: pw.Alignment.centerRight,
          ),
        ],
      ),
      for (final item in order.items)
        pw.TableRow(
          children: [
            cell(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(item.name, style: const pw.TextStyle(fontSize: 11)),
                  if (item.message != null && item.message!.trim().isNotEmpty)
                    pw.Text(
                      'Lời nhắn: ${item.message}',
                      style: pw.TextStyle(fontSize: 9, color: _muted),
                    ),
                ],
              ),
            ),
            cell(pw.Text('${item.quantity}'), align: pw.Alignment.center),
            cell(
              pw.Text(formatVnd(item.price)),
              align: pw.Alignment.centerRight,
            ),
            cell(
              pw.Text(formatVnd(item.subtotal)),
              align: pw.Alignment.centerRight,
            ),
          ],
        ),
    ],
  );
}

pw.Widget _totals(AdminOrder order) {
  pw.Widget row(String label, String value, {bool strong = false}) {
    final style = pw.TextStyle(
      fontSize: strong ? 13 : 11,
      fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.SizedBox(
      width: 240,
      child: pw.Column(
        children: [
          row('Tạm tính', formatVnd(order.subtotal)),
          if (order.deliveryFee > 0)
            row('Phí giao hàng', formatVnd(order.deliveryFee)),
          if (order.discount > 0)
            row('Giảm giá', '-${formatVnd(order.discount)}'),
          pw.Divider(color: _line),
          row('Tổng cộng', formatVnd(order.total), strong: true),
        ],
      ),
    ),
  );
}
