import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceService {
  static pw.Font? _interRegular;
  static pw.Font? _interBold;
  static bool _fontsLoading = false;

  static Future<void> _loadFonts() async {
    if (_interRegular != null && _interBold != null) return;
    if (_fontsLoading) {
      while (_fontsLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_interRegular != null) return;
      }
    }

    _fontsLoading = true;
    try {
      print('Attempting to load Google Fonts...');
      _interRegular = await PdfGoogleFonts.interRegular();
      _interBold = await PdfGoogleFonts.interBold();
    } catch (e) {
      print('Font loading failed, using Helvetica: $e');
      _interRegular = pw.Font.helvetica();
      _interBold = pw.Font.helveticaBold();
    } finally {
      _fontsLoading = false;
    }
  }

  static Future<Uint8List> generateInvoiceBytes(Map<String, dynamic> order) async {
    try {
      await _loadFonts();
      final pdf = await _createDocument(order);
      return pdf.save();
    } catch (e) {
      print('Error generating invoice bytes: $e');
      // Fallback to a very simple document if something goes wrong
      final pdf = pw.Document();
      pdf.addPage(pw.Page(build: (c) => pw.Text('Error generating preview: $e')));
      return pdf.save();
    }
  }

  static Future<void> generateAndDownloadInvoice(Map<String, dynamic> order) async {
    try {
      final bytes = await generateInvoiceBytes(order);
      final String orderId = order['orderId'] ?? 'N/A';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'invoice_${orderId.replaceAll('#', '')}.pdf')
          ..style.display = 'none';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'invoice_$orderId.pdf',
        );
      }
    } catch (e) {
      print('Download error: $e');
    }
  }

  static Future<pw.Document> _createDocument(Map<String, dynamic> order) async {
    final pdf = pw.Document();
    
    // Ensure we have fonts, fallback to helvetica immediately if null
    final font = _interRegular ?? pw.Font.helvetica();
    final fontBold = _interBold ?? pw.Font.helveticaBold();

    final String orderId = order['orderId'] ?? 'N/A';
    final String invoiceNumber = order['invoiceNumber'] ?? '#INV-${orderId.replaceAll('ORD-', '')}';
    final String date = order['createdAt'] != null 
        ? DateFormat('MMMM dd, yyyy').format(DateTime.parse(order['createdAt']))
        : 'N/A';
    
    final customerData = order['user'];
    final Map<String, dynamic> customer = (customerData is Map) ? Map<String, dynamic>.from(customerData) : {};
    
    final vendorData = order['vendor'];
    final Map<String, dynamic> vendor = (vendorData is Map) ? Map<String, dynamic>.from(vendorData) : {};
    
    final items = order['items'] as List? ?? [];
    
    final double subtotal = items.fold(0.0, (sum, item) {
      final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      return sum + (price * qty);
    });
    final double taxRate = double.tryParse(order['taxRate']?.toString() ?? '10') ?? 10.0;
    final double tax = subtotal * (taxRate / 100);
    final double total = subtotal + tax;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Header with angled design
              pw.Container(
                height: 135,
                child: pw.Stack(
                  children: [
                    // Top blue bar
                    pw.Container(
                      height: 115,
                      width: double.infinity,
                      color: PdfColor.fromHex('#1E293B'),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 30,
                            height: 30,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.green,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(child: pw.Text('O', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text('OJAS', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold, font: fontBold)),
                              pw.Text('PREMIUM HANDMADE GIFTS', style: pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Top right Invoice info
                    pw.Positioned(
                      right: 40,
                      top: 15,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('INVOICE', style: pw.TextStyle(color: PdfColor.fromHex('#84CC16'), fontSize: 32, fontWeight: pw.FontWeight.bold, font: fontBold)),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            children: [
                              pw.Text('Invoice Number:', style: pw.TextStyle(color: PdfColor.fromHex('#FFFFFFCC'), fontSize: 9)),
                              pw.SizedBox(width: 5),
                              pw.Text(invoiceNumber, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Text('Order ID:', style: pw.TextStyle(color: PdfColor.fromHex('#FFFFFFCC'), fontSize: 9)),
                              pw.SizedBox(width: 5),
                              pw.Text('#$orderId', style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Text('Invoice Date:', style: pw.TextStyle(color: PdfColor.fromHex('#FFFFFFCC'), fontSize: 9)),
                              pw.SizedBox(width: 5),
                              pw.Text(order['invoiceDate'] ?? date, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 20),
                    // Address Section
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Invoice To:', style: pw.TextStyle(color: PdfColor.fromHex('#84CC16'), fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 5),
                            pw.Text(customer['name'] ?? 'Guest Customer', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: fontBold)),
                            pw.Text('Customer', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            pw.Text('Phone: ${customer['phone'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            pw.Text('Email: ${customer['email'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Invoice From:', style: pw.TextStyle(color: PdfColor.fromHex('#84CC16'), fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 5),
                            pw.Text(vendor['storeName'] ?? vendor['name'] ?? 'OJAS Vendor', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: fontBold)),
                            pw.Text('Authorized Vendor', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            pw.Text('Phone: ${vendor['phone'] ?? '+91 9876543210'}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            pw.Text('Email: ${vendor['email'] ?? 'vendor@ojas.com'}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 30),

                    // Table
                    pw.Table(
                      columnWidths: {
                        0: const pw.FixedColumnWidth(40),
                        1: const pw.FlexColumnWidth(),
                        2: const pw.FixedColumnWidth(80),
                        3: const pw.FixedColumnWidth(60),
                        4: const pw.FixedColumnWidth(80),
                      },
                      children: [
                        // Table Header
                        pw.TableRow(
                          children: [
                            _tableHeaderCell('NO.', color: PdfColor.fromHex('#84CC16')),
                            _tableHeaderCell('PRODUCT DESCRIPTION', color: PdfColor.fromHex('#84CC16'), align: pw.Alignment.centerLeft),
                            _tableHeaderCell('PRICE', color: PdfColor.fromHex('#1E293B')),
                            _tableHeaderCell('QTY.', color: PdfColor.fromHex('#1E293B')),
                            _tableHeaderCell('TOTAL', color: PdfColor.fromHex('#1E293B')),
                          ],
                        ),
                        // Table Data
                        ...List.generate(items.length, (index) {
                          final item = items[index];
                          final productData = item['product'];
                          final Map product = (productData is Map) ? productData : {'name': productData?.toString() ?? 'Product'};
                          final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                          final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                          final double rowTotal = price * qty;

                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: index % 2 == 0 ? PdfColors.white : PdfColor.fromHex('#F8FAFC'),
                            ),
                            children: [
                              _tableDataCell('${index + 1}'),
                              _tableDataCell(product['name'] ?? 'Product Name', align: pw.Alignment.centerLeft),
                              _tableDataCell('INR $price'),
                              _tableDataCell('$qty'),
                              _tableDataCell('INR $rowTotal'),
                            ],
                          );
                        }),
                      ],
                    ),

                    pw.SizedBox(height: 20),

                    // Totals Section
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Payment Method
                        pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if ((order['paymentAccNo']?.toString().isNotEmpty ?? false) || 
                                  (order['paymentAccName']?.toString().isNotEmpty ?? false) ||
                                  (order['paymentBranch']?.toString().isNotEmpty ?? false))
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Payment Method:', style: pw.TextStyle(color: PdfColor.fromHex('#84CC16'), fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                    pw.SizedBox(height: 5),
                                    if (order['paymentAccNo']?.toString().isNotEmpty ?? false)
                                      pw.Text(order['paymentAccNo'], style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                                    if (order['paymentAccName']?.toString().isNotEmpty ?? false)
                                      pw.Text(order['paymentAccName'], style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                                    if (order['paymentBranch']?.toString().isNotEmpty ?? false)
                                      pw.Text(order['paymentBranch'], style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                                    pw.SizedBox(height: 20),
                                  ],
                                ),
                              
                              if ((order['term1']?.toString().isNotEmpty ?? false) || 
                                  (order['term2']?.toString().isNotEmpty ?? false))
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Terms & Conditions:', style: pw.TextStyle(color: PdfColor.fromHex('#84CC16'), fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                    pw.SizedBox(height: 5),
                                    if (order['term1']?.toString().isNotEmpty ?? false)
                                      pw.Text(order['term1'], style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                                    if (order['term2']?.toString().isNotEmpty ?? false)
                                      pw.Text(order['term2'], style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Subtotals
                        pw.Expanded(
                          flex: 1,
                          child: pw.Column(
                            children: [
                              _totalRow('Subtotal:', 'INR $subtotal'),
                              _totalRow('Discount:', 'INR 0.00'),
                              _totalRow('Tax (${taxRate.toStringAsFixed(0)}%):', 'INR ${tax.toStringAsFixed(2)}', isTax: true),
                              pw.SizedBox(height: 15),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('#84CC16'),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                ),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Total Amount:', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13)),
                                    pw.Text('INR ${total.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 40),
                    
                    // Authorized sign
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        children: [
                          pw.Container(
                            width: 120,
                            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey))),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text('Authorised Sign', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Container(
                height: 40,
                width: double.infinity,
                color: PdfColor.fromHex('#1E293B'),
                padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('+91 9876543210', style: pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.SizedBox(width: 15),
                        pw.Text('support@ojas.com', style: pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                        pw.SizedBox(width: 15),
                        pw.Text('Mumbai, Maharashtra', style: pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                      ],
                    ),
                    pw.Text('Thank You For Your Business', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _tableHeaderCell(String text, {required PdfColor color, pw.Alignment align = pw.Alignment.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      color: color,
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  static pw.Widget _tableDataCell(String text, {pw.Alignment align = pw.Alignment.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      alignment: align,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool isTax = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: isTax ? PdfColor.fromHex('#84CC16') : PdfColors.grey700, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: isTax ? PdfColor.fromHex('#84CC16') : PdfColors.black)),
        ],
      ),
    );
  }
}
