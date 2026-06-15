import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DeliveryChallanHelper {
  static Future<void> generateAndDownload(BuildContext context, Map<String, dynamic> order) async {
    final pdf = pw.Document();

    final orderId = order['orderId'] ?? 'N/A';
    final rawDate = order['createdAt'] ?? '';
    final dateStr = rawDate.isNotEmpty ? rawDate.toString().split('T')[0] : 'N/A';
    final paymentMethod = order['paymentMethod'] ?? 'N/A';

    final user = order['user'] ?? {};
    final userName = user['name'] ?? 'Guest Customer';
    final userEmail = user['email'] ?? '-';
    final userMobile = user['mobile'] ?? '-';

    final address = order['shippingAddress'] ?? {};
    final shippingStr = "${address['street'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['zipCode'] ?? ''}";

    final vendor = order['vendor'] ?? {};
    final vendorName = vendor['storeName'] ?? vendor['name'] ?? 'Ojas India';
    final vendorEmail = vendor['email'] ?? 'info@ojasindia.com';
    final vendorMobile = vendor['mobile'] ?? '-';

    final items = List<dynamic>.from(order['items'] ?? []);

    final subtotal = order['subtotal'] ?? 0.0;
    final totalGst = order['totalGst'] ?? 0.0;
    final totalAmount = order['totalAmount'] ?? 0.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DELIVERY CHALLAN',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Challan No: $orderId', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Payment Method: $paymentMethod', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'OJAS INDIA',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700),
                      ),
                      pw.Text('www.ojasindia.com', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Addresses Block
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SUPPLIER / VENDOR:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(vendorName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Email: $vendorEmail', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Mobile: $vendorMobile', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SHIP TO / BUYER:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(userName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text(shippingStr, style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Mobile: $userMobile', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Text('ITEM DETAILS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Product Name', 'HSN', 'Qty', 'Rate (Base)', 'GST %', 'GST Amt', 'Amount'],
                data: items.map((item) {
                  final prod = item['product'];
                  final hsn = (prod is Map) ? (prod['hsnCode'] ?? item['hsnCode'] ?? '-') : (item['hsnCode'] ?? '-');
                  final qty = item['quantity'] ?? 0;
                  final unitPrice = item['price'] ?? 0.0;
                  final gstPercent = item['gstPercent'] ?? 0;
                  final gstAmount = item['gstAmount'] ?? 0.0;
                  final finalPrice = item['finalPrice'] ?? (unitPrice * qty);

                  return [
                    item['name'] ?? 'Product',
                    hsn.toString(),
                    qty.toString(),
                    'Rs. ${unitPrice.toStringAsFixed(2)}',
                    '$gstPercent%',
                    'Rs. ${gstAmount.toStringAsFixed(2)}',
                    'Rs. ${finalPrice.toStringAsFixed(2)}',
                  ];
                }).toList(),
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  top: pw.BorderSide(color: PdfColors.grey300, width: 1),
                ),
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 16),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Subtotal:  ', style: const pw.TextStyle(fontSize: 9.5)),
                          pw.Text('Rs. ${subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('Total Tax (GST):  ', style: const pw.TextStyle(fontSize: 9.5)),
                          pw.Text('Rs. ${totalGst.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        child: pw.Row(
                          children: [
                            pw.Text('Grand Total:  ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rs. ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Thank you for shopping with Ojas India!', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                  pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 800,
          height: 600,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Delivery Challan Preview'),
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: PdfPreview(
              build: (format) async => pdf.save(),
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              dynamicLayout: false,
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: 'Challan_$orderId.pdf',
            ),
          ),
        ),
      ),
    );
  }
}
