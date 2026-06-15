import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_admin/core/constants/app_colors.dart';
import 'package:ojas_admin/core/services/api_service.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/sidebar.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/top_bar.dart';
import 'package:dio/dio.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import 'package:ojas_admin/features/vendors/data/services/vendor_service.dart';
import 'package:intl/intl.dart';
import 'package:ojas_admin/core/services/download_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PayoutsPage extends StatefulWidget {
  const PayoutsPage({super.key});

  @override
  State<PayoutsPage> createState() => _PayoutsPageState();
}

class _PayoutsPageState extends State<PayoutsPage> {
  List<dynamic> payouts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPayouts();
  }

  Future<void> fetchPayouts() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiService().dio.get('/admin/payouts');
      setState(() {
        payouts = res.data['data'];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching payouts: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateStatus(String id, String action, {Map<String, dynamic>? extraData}) async {
    try {
      String endpoint = '/admin/payout/$id/$action';
      final res = await ApiService().dio.put(endpoint, data: extraData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? "Status updated")));
        fetchPayouts();
      }
    } catch (e) {
      debugPrint('Error updating payout: $e');
      String msg = "Failed to update payout";
      if (e is DioException) msg = e.response?.data['message'] ?? msg;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  void _showMarkPaidDialog(String id) {
    final txController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Paid', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: txController, decoration: const InputDecoration(labelText: 'Transaction ID / Ref No', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Admin Note', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              updateStatus(id, 'mark-paid', extraData: {
                'transactionId': txController.text,
                'adminNote': noteController.text
              });
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  void _downloadCSV(Map<String, dynamic> vendorData, List ledger) {
    String csv = "Date,Type,Reference ID,Amount,Commission\n";
    for (var item in ledger) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(item['date']));
      final type = item['type'] == 'earning' ? 'Earning' : 'Payout';
      final ref = item['referenceId'] ?? '-';
      final amount = item['amount'] ?? 0;
      final comm = item['commission'] ?? 0;
      csv += "$date,$type,$ref,$amount,$comm\n";
    }
    
    final fileName = "Ledger_${vendorData['businessName'] ?? vendorData['user']?['name'] ?? 'Vendor'}.csv";
    downloadFile(csv, fileName);
  }

  void _downloadPDF(Map<String, dynamic> vendorData, List ledger) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Vendor Ledger', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('Vendor: ${vendorData['businessName'] ?? vendorData['user']?['name'] ?? 'Unknown'}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Date', 'Type', 'Reference ID', 'Amount'],
                data: ledger.map((item) {
                  return [
                    DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(item['date'])),
                    item['type'] == 'earning' ? 'Earning' : 'Payout',
                    item['referenceId'] ?? '-',
                    'Rs. ${item['amount']}',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
    
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _showLedgerDialog(Map<String, dynamic> vendorData) async {
    final vendorUserId = vendorData['user']?['_id'];
    if (vendorUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor user ID not found')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vendor Ledger', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(vendorData['businessName'] ?? vendorData['user']?['name'] ?? '', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
        content: SizedBox(
          width: 800,
          height: 600,
          child: FutureBuilder<Map<String, dynamic>>(
            future: sl<VendorService>().getVendorLedger(vendorUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final data = snapshot.data!;
              final ledger = data['ledger'] as List;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _downloadPDF(vendorData, ledger),
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        label: const Text('Download PDF'),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => _downloadCSV(vendorData, ledger),
                        icon: const Icon(Icons.table_view, color: Colors.green),
                        label: const Text('Download CSV (Excel)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Summary Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLedgerSummaryItem('Total Earnings', '₹${data['vendor']['totalEarnings']}'),
                        _buildLedgerSummaryItem('Current Wallet', '₹${data['vendor']['walletBalance']}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Ledger Table
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        itemCount: ledger.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = ledger[index];
                          final isEarning = item['type'] == 'earning';
                          return ListTile(
                            leading: Icon(
                              isEarning ? Icons.add_circle_outline : Icons.remove_circle_outline,
                              color: isEarning ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              isEarning ? 'Order #${item['referenceId']}' : 'Payout #${item['referenceId']}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(item['date']))}',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isEarning ? "+" : "-"} ₹${item['amount']}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isEarning ? Colors.green : Colors.red,
                                  ),
                                ),
                                if (isEarning)
                                  Text(
                                    'Comm: ₹${item['commission']}',
                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildLedgerSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(currentRoute: '/payouts'),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vendor Payout Requests', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 32),
                            
                            // Stats Overview (Optional but makes UI better)
                            Row(
                              children: [
                                _buildStatCard('Pending', payouts.where((p) => p['status'] == 'pending').length.toString(), Colors.orange),
                                const SizedBox(width: 24),
                                _buildStatCard('Approved', payouts.where((p) => p['status'] == 'approved').length.toString(), Colors.blue),
                                const SizedBox(width: 24),
                                _buildStatCard('Paid', payouts.where((p) => p['status'] == 'paid').length.toString(), Colors.green),
                              ],
                            ),
                            const SizedBox(height: 32),

                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.grey.shade100,
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                    dataRowHeight: 80,
                                    horizontalMargin: 24,
                                    columns: const [
                                      DataColumn(label: Text('VENDOR INFO')),
                                      DataColumn(label: Text('AMOUNT')),
                                      DataColumn(label: Text('METHOD')),
                                      DataColumn(label: Text('DETAILS')),
                                      DataColumn(label: Text('STATUS')),
                                      DataColumn(label: Text('ACTIONS')),
                                    ],
                                    rows: payouts.map((p) {
                                      final vendorUser = p['vendor']?['user'];
                                      return DataRow(cells: [
                                        DataCell(Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: AppColors.primary.withOpacity(0.1),
                                              child: Text(vendorUser?['name']?[0] ?? 'V', style: TextStyle(color: AppColors.primary)),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(vendorUser?['name']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text(vendorUser?['email']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                          ],
                                        )),
                                        DataCell(Text('₹${p["amount"]?.toString() ?? "0"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                        DataCell(Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                                          child: Text(p["methodType"]?.toString().toUpperCase() ?? "UNKNOWN", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                        )),
                                        DataCell(_buildDetailsCell(p["methodType"]?.toString() ?? "", p["details"] ?? {})),
                                        DataCell(_buildStatusBadge(p["status"]?.toString() ?? "pending")),
                                        DataCell(_buildActions(p)),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCell(String type, Map<String, dynamic> details) {
    if (type == 'upi') {
      return Text('UPI: ${details["upiId"] ?? "N/A"}\n${details["holderName"] ?? "N/A"}');
    } else {
      return Text('Acc: ${details["accountNumber"] ?? "N/A"}\n${details["bankName"] ?? "N/A"} (${details["ifsc"] ?? "N/A"})');
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String statusStr = status.toString().toLowerCase();
    if (statusStr == 'pending') color = Colors.orange;
    if (statusStr == 'approved') color = Colors.blue;
    if (statusStr == 'paid') color = Colors.green;
    if (statusStr == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(statusStr.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActions(Map<String, dynamic> p) {
    final status = p['status']?.toString();
    if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF8B5CF6)), 
            onPressed: () => _showLedgerDialog(p['vendor']),
            tooltip: 'View Ledger',
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.blue), 
            onPressed: () => updateStatus(p['_id'], 'approve'),
            tooltip: 'Approve',
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.red), 
            onPressed: () => updateStatus(p['_id'], 'reject', extraData: {'adminNote': 'Rejected by admin'}),
            tooltip: 'Reject',
          ),
        ],
      );
    } else if (status == 'approved') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF8B5CF6)), 
            onPressed: () => _showLedgerDialog(p['vendor']),
            tooltip: 'View Ledger',
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () => _showMarkPaidDialog(p['_id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, 
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Mark Paid', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF8B5CF6), size: 18), 
          onPressed: () => _showLedgerDialog(p['vendor']),
          tooltip: 'View Ledger',
        ),
        Text(p['processedDate']?.toString().substring(0, 10) ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Text(count, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
