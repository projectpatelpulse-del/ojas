import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/admin_layout.dart';
import 'package:ojas_admin/features/resellers/data/services/reseller_service.dart';
import 'package:ojas_admin/core/services/global_search_service.dart';

class ResellersPage extends StatefulWidget {
  const ResellersPage({super.key});

  @override
  State<ResellersPage> createState() => _ResellersPageState();
}

class _ResellersPageState extends State<ResellersPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalSearchService _globalSearchService = sl<GlobalSearchService>();
  List<dynamic> _resellers = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';

  final List<String> _statusOptions = ['All', 'Pending', 'Approved', 'Blocked'];

  @override
  void initState() {
    super.initState();
    _fetchResellers();
    _searchController.addListener(() => setState(() {}));
    _globalSearchService.searchQuery.addListener(_onGlobalSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _globalSearchService.searchQuery.removeListener(_onGlobalSearchChanged);
    super.dispose();
  }

  void _onGlobalSearchChanged() {
    _searchController.text = _globalSearchService.searchQuery.value;
  }

  Future<void> _fetchResellers() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final resellers = await sl<ResellerService>().getResellers();
      if (mounted) {
        setState(() {
          _resellers = resellers;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch resellers: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveReseller(String id) async {
    try {
      await sl<ResellerService>().approveReseller(id);
      await _fetchResellers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseller approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve reseller: $e')),
        );
      }
    }
  }

  Future<void> _blockReseller(String id) async {
    try {
      await sl<ResellerService>().blockReseller(id);
      await _fetchResellers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseller blocked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block reseller: $e')),
        );
      }
    }
  }

  List<dynamic> get _filteredResellers {
    final query = _searchController.text.toLowerCase();
    return _resellers.where((r) {
      // Status filter
      if (_selectedStatus != 'All') {
        if (r['status']?.toString().toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
      }

      // Search query filter
      if (query.isNotEmpty) {
        final name = r['user']?['name']?.toString().toLowerCase() ?? '';
        final email = r['user']?['email']?.toString().toLowerCase() ?? '';
        final code = r['resellerCode']?.toString().toLowerCase() ?? '';
        return name.contains(query) || email.contains(query) || code.contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/resellers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Text('Master Admin', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                Text('Resellers', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchResellers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reseller Management',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Approve applications, monitor sales, and control reseller status.',
                              style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _fetchResellers,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text('Refresh', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B21A8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Table Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Filter Bar
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // Search
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      children: [
                                        Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            decoration: InputDecoration(
                                              hintText: 'Search by name, email or code',
                                              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                                              border: InputBorder.none,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),

                                // Status Filter
                                Row(
                                  children: [
                                    Text('Status', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    _buildDropdown(
                                      value: _selectedStatus,
                                      items: _statusOptions,
                                      onChanged: (v) => setState(() => _selectedStatus = v!),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Table Headers
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('RESELLER DETAILS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                                Expanded(flex: 2, child: Text('RESELLER CODE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                                Expanded(flex: 2, child: Text('STATUS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                                Expanded(flex: 2, child: Text('COMMISSION (%)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                                Expanded(flex: 2, child: Text('WALLET (AVAIL/WITHDRAWN)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                                Expanded(flex: 2, child: Text('JOINED DATE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                                Expanded(flex: 2, child: Text('ACTIONS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500), textAlign: TextAlign.right)),
                              ],
                            ),
                          ),

                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(60.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_filteredResellers.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Center(
                                child: Text(
                                  'No resellers found.',
                                  style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredResellers.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                              itemBuilder: (context, index) {
                                final reseller = _filteredResellers[index];
                                final user = reseller['user'] ?? {};
                                final status = reseller['status']?.toString().toLowerCase() ?? 'pending';
                                final code = reseller['resellerCode'] ?? 'N/A';
                                final name = user['name'] ?? 'N/A';
                                final email = user['email'] ?? 'N/A';
                                final mobile = user['mobile'] ?? 'N/A';
                                final comm = reseller['commissionPercentage'] ?? 8;
                                final avail = reseller['availableBalance'] ?? 0;
                                final withdrawn = reseller['withdrawnBalance'] ?? 0;
                                final createdAt = reseller['createdAt'] != null
                                    ? DateFormat('MMM dd, yyyy').format(DateTime.parse(reseller['createdAt']))
                                    : 'N/A';

                                Color statusColor = Colors.orange;
                                if (status == 'approved') statusColor = Colors.green;
                                if (status == 'blocked') statusColor = Colors.red;

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    children: [
                                      // Reseller Details
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
                                            Text(email, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                                            Text(mobile, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400)),
                                          ],
                                        ),
                                      ),

                                      // Reseller Code
                                      Expanded(
                                        flex: 2,
                                        child: Text(code, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                      ),

                                      // Status
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Commission
                                      Expanded(
                                        flex: 2,
                                        child: Text('$comm%', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                                      ),

                                      // Wallet
                                      Expanded(
                                        flex: 2,
                                        child: Text('₹$avail / ₹$withdrawn', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                                      ),

                                      // Joined Date
                                      Expanded(
                                        flex: 2,
                                        child: Text(createdAt, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                                      ),

                                      // Actions
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
                                              onPressed: () => _showResellerDetailsDialog(reseller),
                                              tooltip: 'View Details',
                                            ),
                                            if (status == 'pending') ...[
                                              IconButton(
                                                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                                onPressed: () => _approveReseller(reseller['_id']),
                                                tooltip: 'Approve',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.block, color: Colors.red),
                                                onPressed: () => _blockReseller(reseller['_id']),
                                                tooltip: 'Block',
                                              ),
                                            ] else if (status == 'approved') ...[
                                              IconButton(
                                                icon: const Icon(Icons.block, color: Colors.red),
                                                onPressed: () => _blockReseller(reseller['_id']),
                                                tooltip: 'Block',
                                              ),
                                            ] else if (status == 'blocked') ...[
                                              IconButton(
                                                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                                onPressed: () => _approveReseller(reseller['_id']),
                                                tooltip: 'Approve / Unblock',
                                              ),
                                            ],
                                          ],
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)),
                  ))
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          isDense: true,
        ),
      ),
    );
  }

  void _showResellerDetailsDialog(Map<String, dynamic> reseller) {
    final user = reseller['user'] ?? {};
    final bank = reseller['bankDetails'] ?? {};
    final upi = reseller['upiDetails'] ?? {};
    final status = reseller['status']?.toString().toLowerCase() ?? 'pending';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 650,
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reseller Application Details',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Section 1: Account Information
                Text(
                  'Account Information',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDetailField('Full Name', user['name'] ?? 'N/A')),
                    Expanded(child: _buildDetailField('Email Address', user['email'] ?? 'N/A')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDetailField('Mobile Number', user['mobile'] ?? 'N/A')),
                    Expanded(child: _buildDetailField('Reseller Code', reseller['resellerCode'] ?? 'N/A')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDetailField('Application Status', status.toUpperCase())),
                    Expanded(child: _buildDetailField('Commission Rate', '${reseller['commissionPercentage'] ?? 8}%')),
                  ],
                ),

                const Divider(height: 32),

                // Section 2: Bank Details
                Text(
                  'Bank Details',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDetailField('Account Holder Name', bank['accountHolderName'] ?? 'N/A')),
                    Expanded(child: _buildDetailField('Bank Name', bank['bankName'] ?? 'N/A')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDetailField('Account Number', bank['accountNumber'] ?? 'N/A')),
                    Expanded(child: _buildDetailField('IFSC Code', bank['ifsc'] ?? 'N/A')),
                  ],
                ),

                const Divider(height: 32),

                // Section 3: UPI & Compliance
                Text(
                  'UPI & Compliance Information',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDetailField('UPI ID', upi['upiId'] ?? 'N/A')),
                    Expanded(child: _buildDetailField('PAN Number', reseller['panNumber'] ?? 'N/A')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDetailField('GST Number', reseller['gstNumber'] ?? 'N/A')),
                    Expanded(child: _buildDetailField('Referral Count', (reseller['referralCount'] ?? 0).toString())),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
