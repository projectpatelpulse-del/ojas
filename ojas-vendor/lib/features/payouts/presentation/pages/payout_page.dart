import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/services/api_service.dart';
import 'package:ojas_vendor/core/widgets/sidebar_layout.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';
import 'package:dio/dio.dart';

class PayoutPage extends StatefulWidget {
  const PayoutPage({super.key});

  @override
  State<PayoutPage> createState() => _PayoutPageState();
}

class _PayoutPageState extends State<PayoutPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? wallet;
  List<dynamic> methods = [];
  List<dynamic> payouts = [];
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final walletRes = await ApiService().dio.get('/vendor/wallet');
      final methodsRes = await ApiService().dio.get('/vendor/payment-methods');
      final payoutsRes = await ApiService().dio.get('/vendor/payout-history');
      
      setState(() {
        wallet = walletRes.data['data'];
        methods = methodsRes.data['data'];
        payouts = payoutsRes.data['data'];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching payout data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> addMethod(String type, Map<String, String> details) async {
    setState(() => isSaving = true);
    try {
      final res = await ApiService().dio.post('/vendor/payment-method', data: {
        'type': type,
        'details': details,
        'isDefault': methods.isEmpty
      });
      fetchData();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment method added successfully")));
      }
    } catch (e) {
      debugPrint('Error adding method: $e');
      String msg = "Failed to add payment method";
      if (e is DioException) {
        msg = e.response?.data['message'] ?? msg;
      } else if (e.toString().contains('DioException')) msg = (e as dynamic).response?.data['message'] ?? msg;
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> setDefault(String id) async {
    try {
      await ApiService().dio.put('/vendor/payment-method/$id');
      fetchData();
    } catch (e) {
      debugPrint('Error setting default: $e');
    }
  }

  Future<void> importRegistrationBank() async {
    try {
      final res = await ApiService().dio.post('/vendor/import-registration-bank');
      fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'])));
      }
    } catch (e) {
      String msg = "Failed to import details";
      if (e is DioException) msg = e.response?.data['message'] ?? msg;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> requestPayout(double amount, String methodId) async {
    try {
      await ApiService().dio.post('/vendor/request-payout', data: {
        'amount': amount,
        'methodId': methodId
      });
      fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payout Request Submitted")));
      }
    } catch (e) {
      String msg = "Failed to request payout";
      if (e is DioException) {
        msg = e.response?.data['message'] ?? msg;
      } else if (e.toString().contains('DioException')) msg = (e as dynamic).response?.data['message'] ?? msg;
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showAddMethodDialog() {
    String type = 'upi';
    final upiController = TextEditingController();
    final holderController = TextEditingController();
    final accController = TextEditingController();
    final ifscController = TextEditingController();
    final bankController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Payout Method', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Method Type', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => type = 'upi'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'upi' ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                            border: Border.all(color: type == 'upi' ? AppColors.primary : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.qr_code, color: type == 'upi' ? AppColors.primary : Colors.grey),
                              const Text('UPI'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => type = 'bank'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'bank' ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                            border: Border.all(color: type == 'bank' ? AppColors.primary : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.account_balance, color: type == 'bank' ? AppColors.primary : Colors.grey),
                              const Text('Bank Acc'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (type == 'upi') ...[
                  TextField(controller: holderController, decoration: const InputDecoration(labelText: 'Beneficiary Name', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: upiController, decoration: const InputDecoration(labelText: 'UPI ID (e.g. name@okaxis)', border: OutlineInputBorder())),
                ] else ...[
                  TextField(controller: holderController, decoration: const InputDecoration(labelText: 'Account Holder Name', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: accController, decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: ifscController, decoration: const InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: bankController, decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder())),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () {
                Map<String, String> details = {};
                if (type == 'upi') {
                  if (upiController.text.isEmpty || holderController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                    return;
                  }
                  details = {'upiId': upiController.text, 'accountHolderName': holderController.text};
                } else {
                  if (accController.text.isEmpty || ifscController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                    return;
                  }
                  details = {
                    'accountHolderName': holderController.text,
                    'accountNumber': accController.text,
                    'ifsc': ifscController.text,
                    'bankName': bankController.text
                  };
                }
                addMethod(type, details);
              },
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Method'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestPayoutDialog() {
    if (methods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add a payment method first")));
      return;
    }

    final amountController = TextEditingController();
    String? selectedMethodId;
    
    try {
      final defaultMethod = methods.firstWhere(
        (m) => m['isDefault'] == true || m['isDefault'] == "true", 
        orElse: () => methods.first
      );
      selectedMethodId = defaultMethod['_id']?.toString();
    } catch (e) {
      selectedMethodId = methods.isNotEmpty ? methods.first['_id']?.toString() : null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Request Payout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available Balance', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('₹${wallet?["walletBalance"] ?? 0}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Payout Details', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Amount to Withdraw',
                    hintText: 'Min ₹500',
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethodId?.toString(),
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Receiving Method',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: methods.map<DropdownMenuItem<String>>((m) => DropdownMenuItem(
                    value: m['_id'].toString(),
                    child: Row(
                      children: [
                        Icon(m["type"] == "upi" ? Icons.qr_code : Icons.account_balance, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(m["type"] == "upi" 
                          ? "UPI: ${m["details"]?["upiId"] ?? 'N/A'}" 
                          : "Bank: ${m["details"]?["accountNumber"] ?? 'N/A'}"),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedMethodId = v),
                ),
                const SizedBox(height: 8),
                Text('* Processing time: 24-48 business hours', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountController.text);
                if (amt == null || amt < 500) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimum payout amount is ₹500")));
                  return;
                }
                if (selectedMethodId == null) return;
                
                Navigator.pop(context);
                requestPayout(amt, selectedMethodId!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Confirm Request', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      activeRoute: '/payouts',
      child: Column(
        children: [
          const VendorTopBar(),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Wallet & Payouts', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: _showRequestPayoutDialog,
                            icon: const Icon(Icons.account_balance_wallet_outlined),
                            label: const Text('Request Payout'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Wallet Overview
                      Row(
                        children: [
                          _buildWalletCard('Available Balance', '₹${wallet?["walletBalance"]?.toString() ?? "0"}', Icons.wallet, Colors.blue),
                          const SizedBox(width: 24),
                          _buildWalletCard('Pending Clearance', '₹${wallet?["pendingBalance"]?.toString() ?? "0"}', Icons.timer_outlined, Colors.orange),
                          const SizedBox(width: 24),
                          _buildWalletCard('Total Earnings', '₹${wallet?["totalEarnings"]?.toString() ?? "0"}', Icons.trending_up, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Tabs Container
                      DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              child: TabBar(
                                labelColor: AppColors.primary,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: AppColors.primary,
                                tabs: const [
                                  Tab(text: 'Payment Methods'),
                                  Tab(text: 'Payout History'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Since we are inside SingleChildScrollView, we can't use TabBarView easily without fixed height.
                            // We will use a state-based approach or just show both sections.
                            _buildPaymentMethodsTab(),
                            const SizedBox(height: 48),
                            _buildPayoutHistoryTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(String title, String amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Text(amount, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Saved Methods', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: importRegistrationBank,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Use Registration Bank'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _showAddMethodDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (methods.isEmpty)
            Center(child: Text('No payment methods added yet', style: GoogleFonts.inter(color: Colors.grey)))
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: methods.length,
              itemBuilder: (context, index) {
                final m = methods[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: m['isDefault'] ? AppColors.primary : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(m['type']?.toString() == 'upi' ? Icons.qr_code : Icons.account_balance, color: AppColors.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m["type"]?.toString() == "upi" 
                                ? "UPI: ${m["details"]?["upiId"] ?? 'N/A'}" 
                                : "Bank: ${m["details"]?["accountNumber"] ?? 'N/A'}", 
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold)
                            ),
                            Text(
                              m["type"]?.toString() == "upi" 
                                ? (m["details"]?["holderName"] ?? 'No Name') 
                                : (m["details"]?["bankName"] ?? 'No Bank'), 
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)
                            ),
                          ],
                        ),
                      ),
                      if (m["isDefault"] == true || m["isDefault"]?.toString() == "true")
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text('DEFAULT', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      else
                        TextButton(onPressed: () => setDefault(m["_id"]?.toString() ?? ""), child: const Text('Set Default')),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPayoutHistoryTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transaction History', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (payouts.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No payout requests yet', style: GoogleFonts.inter(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell('#', flex: 1),
                          _buildHeaderCell('DATE', flex: 2),
                          _buildHeaderCell('METHOD', flex: 2),
                          _buildHeaderCell('AMOUNT', flex: 2),
                          _buildHeaderCell('TRANSACTION ID', flex: 3),
                          _buildHeaderCell('STATUS', flex: 2),
                        ],
                      ),
                    ),
                    // Table Rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payouts.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final p = payouts[index];
                        final dateStr = p["createdAt"]?.toString() ?? "-";
                        final date = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              _buildDataCell((index + 1).toString(), flex: 1, isBold: false),
                              _buildDataCell(date, flex: 2, isBold: false),
                              _buildDataCell(p["methodType"]?.toString().toUpperCase() ?? "UNKNOWN", flex: 2, isBold: true),
                              _buildDataCell('₹${p["amount"]?.toString() ?? "0"}', flex: 2, isBold: true, color: Colors.green.shade700),
                              _buildDataCell(p["transactionId"]?.toString() ?? '-', flex: 3, isBold: false),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildStatusBadge(p["status"]?.toString() ?? "pending"),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDataCell(String value, {required int flex, bool isBold = false, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'pending') color = Colors.orange;
    if (status == 'approved') color = Colors.blue;
    if (status == 'paid') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
