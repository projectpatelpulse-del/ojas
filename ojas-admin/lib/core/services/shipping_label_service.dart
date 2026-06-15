import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ShippingLabelService {
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
      _interRegular = await PdfGoogleFonts.interRegular();
      _interBold = await PdfGoogleFonts.interBold();
    } catch (e) {
      _interRegular = pw.Font.helvetica();
      _interBold = pw.Font.helveticaBold();
    } finally {
      _fontsLoading = false;
    }
  }

  static Future<void> generateAndDownloadLabel(Map<String, dynamic> order, {Map<String, String>? customData}) async {
    try {
      print('Generating shipping label for order: ${order['orderId']}');
      await _loadFonts();
      final pdf = await _createLabelDocument(order, customData: customData);
      final bytes = await pdf.save();
      final String orderId = (order['orderId'] ?? 'N/A').toString();

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'shipping_label_${orderId.replaceAll('#', '')}.pdf')
          ..style.display = 'none';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'shipping_label_$orderId.pdf',
        );
      }
    } catch (e) {
      print('Label download error: $e');
    }
  }

  static Future<pw.Document> _createLabelDocument(Map<String, dynamic> order, {Map<String, String>? customData}) async {
    final pdf = pw.Document();
    final font = _interRegular ?? pw.Font.helvetica();
    final fontBold = _interBold ?? pw.Font.helveticaBold();

    final String orderId = (order['orderId'] ?? 'N/A').toString();
    
    final customerData = order['user'];
    final Map<String, dynamic> customer = (customerData is Map) ? Map<String, dynamic>.from(customerData) : {};
    final vendorData = order['vendor'];
    final Map<String, dynamic> vendor = (vendorData is Map) ? Map<String, dynamic>.from(vendorData) : {};

    // Use custom data if provided, otherwise fallback to order data
    final String shipToName = customData?['shipToName'] ?? customer['name'] ?? 'Guest Customer';
    final String shipToPhone = customData?['shipToPhone'] ?? customer['phone'] ?? 'N/A';
    final String shipToAddress = customData?['shipToAddress'] ?? customer['address'] ?? '123 Main Street, Apt 4B, New York, 10001, USA';

    final String fromName = customData?['fromName'] ?? vendor['storeName'] ?? vendor['name'] ?? 'OJAS PREMIUM GIFTS';
    final String fromPhone = customData?['fromPhone'] ?? vendor['phone'] ?? '+91 9876543210';
    final String fromAddress = customData?['fromAddress'] ?? vendor['address'] ?? '456 Industrial Blvd, Mumbai, 400001, India';

    final String weight = customData?['weight'] ?? '1.5 KG';
    final String dimensions = customData?['dimensions'] ?? '20x15x10 cm';
    final String date = customData?['date'] ?? (order['createdAt'] != null 
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(order['createdAt'].toString()))
        : DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final String remarks = customData?['remarks'] ?? 'HANDLE WITH CARE';

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(4 * PdfPageFormat.inch, 6 * PdfPageFormat.inch),
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              children: [
                // Top Section: SHIP TO and FROM
                pw.Expanded(
                  flex: 4,
                  child: pw.Row(
                    children: [
                      // SHIP TO
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 1)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.black,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text('SHIP TO:', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(shipToName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: fontBold)),
                              pw.SizedBox(height: 4),
                              pw.Text(shipToAddress, style: pw.TextStyle(fontSize: 10)),
                              pw.SizedBox(height: 4),
                              pw.Text('Phone: $shipToPhone', style: pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                      // FROM
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('FROM:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                              pw.SizedBox(height: 4),
                              pw.Text(fromName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: fontBold)),
                              pw.SizedBox(height: 2),
                              pw.Text(fromAddress, style: pw.TextStyle(fontSize: 8)),
                              pw.SizedBox(height: 2),
                              pw.Text('Phone: $fromPhone', style: pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Divider(height: 1, thickness: 1, color: PdfColors.black),
                
                // Middle Section
                pw.Expanded(
                  flex: 3,
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 1)),
                          ),
                          child: pw.Column(
                            children: [
                              _infoRow('ORDER ID:', orderId, fontBold),
                              _infoRow('WEIGHT:', weight, fontBold),
                              _infoRow('DIMENSIONS:', dimensions, fontBold),
                              _infoRow('SHIPPING DATE:', date, fontBold, isLast: true),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('REMARKS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                              pw.SizedBox(height: 4),
                              pw.Text(remarks, style: pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Divider(height: 1, thickness: 1, color: PdfColors.black),

                // Bottom Section: Barcode
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.code128(),
                          data: orderId,
                          width: double.infinity,
                          height: 60,
                          drawText: true,
                          textStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _infoRow(String label, String value, pw.Font boldFont, {bool isLast = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        border: isLast ? null : const pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, font: boldFont)),
        ],
      ),
    );
  }
}
