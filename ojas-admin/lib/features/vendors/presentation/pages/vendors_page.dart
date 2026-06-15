import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/admin_layout.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import 'package:ojas_admin/features/vendors/data/services/vendor_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ojas_admin/core/services/global_search_service.dart';

class VendorsPage extends StatefulWidget {
  const VendorsPage({super.key});

  @override
  State<VendorsPage> createState() => _VendorsPageState();
}

class _VendorsPageState extends State<VendorsPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalSearchService _globalSearchService = sl<GlobalSearchService>();
  List<dynamic> _vendors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVendors();
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

  List<dynamic> get _filteredVendors {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _vendors;
    return _vendors.where((v) {
      final bizName = v['businessName']?.toString().toLowerCase() ?? '';
      final ownerName = v['user']?['name']?.toString().toLowerCase() ?? '';
      final email = v['user']?['email']?.toString().toLowerCase() ?? '';
      return bizName.contains(query) ||
          ownerName.contains(query) ||
          email.contains(query);
    }).toList();
  }

  Future<void> _fetchVendors() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final vendors = await sl<VendorService>().getVendorRequests();
      if (mounted) {
        setState(() {
          _vendors = vendors;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch vendors: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await sl<VendorService>().updateVendorStatus(id, status);
      await _fetchVendors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vendor ${status == 'inactive' ? 'deactivated' : (status == 'approved' ? 'activated' : status)} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  Future<void> _deleteVendor(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: const Text(
          'Are you sure you want to delete this vendor? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await sl<VendorService>().deleteVendor(id);
        await _fetchVendors();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendor deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete vendor: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateCommission(String id, double commission) async {
    try {
      await sl<VendorService>().updateVendorCommission(id, commission);
      await _fetchVendors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commission updated successfully to $commission%'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update commission: $e')),
        );
      }
    }
  }

  Future<void> _updateAllCommissions(double commission) async {
    try {
      await sl<VendorService>().updateAllVendorsCommission(commission);
      await _fetchVendors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All vendors updated to $commission% commission'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update all commissions: $e')),
        );
      }
    }
  }

  void _showBulkCommissionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Bulk Commission Update',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter a commission percentage that will be applied to EVERY vendor on the platform.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Global Commission Rate (%)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: '%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                Navigator.pop(context);
                _updateAllCommissions(val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update All Vendors'),
          ),
        ],
      ),
    );
  }

  void _showLedgerDialog(Map<String, dynamic> vendor) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendor Ledger',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              vendor['businessName'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 800,
          height: 600,
          child: FutureBuilder<Map<String, dynamic>>(
            future: sl<VendorService>().getVendorLedger(vendor['user']['_id']),
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
                        _buildLedgerSummaryItem(
                          'Total Earnings',
                          '₹${data['vendor']['totalEarnings']}',
                        ),
                        _buildLedgerSummaryItem(
                          'Current Wallet',
                          '₹${data['vendor']['walletBalance']}',
                        ),
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
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = ledger[index];
                          final isEarning = item['type'] == 'earning';
                          return ListTile(
                            leading: Icon(
                              isEarning
                                  ? Icons.add_circle_outline
                                  : Icons.remove_circle_outline,
                              color: isEarning ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              isEarning
                                  ? 'Order #${item['referenceId']}'
                                  : 'Payout #${item['referenceId']}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
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
                                    color: isEarning
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                if (isEarning)
                                  Text(
                                    'Comm: ₹${item['commission']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  void _showCommissionDialog(Map<String, dynamic> vendor) {
    final controller = TextEditingController(
      text: (vendor['commissionRate'] ?? 10).toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set Commission for ${vendor['businessName']}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the commission percentage for this vendor.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Commission Rate (%)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: '%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                Navigator.pop(context);
                _updateCommission(vendor['_id'], val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showVendorDetailsDialog(Map<String, dynamic> vendor) {
    final user = vendor['user'] ?? {};
    final address = vendor['address'] ?? {};
    final docs = vendor['documents'] ?? {};

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vendor Application Details',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
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

                // Row 1: Personal & Business Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Personal Information'),
                          _buildDetailItem('Full Name', user['name'] ?? 'N/A'),
                          _buildDetailItem(
                            'Email Address',
                            user['email'] ?? 'N/A',
                          ),
                          _buildDetailItem(
                            'Phone Number',
                            user['mobile'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Business Information'),
                          _buildDetailItem(
                            'Business Name',
                            vendor['businessName'] ?? 'N/A',
                          ),
                          _buildDetailItem(
                            'Business Type',
                            vendor['businessType'] ?? 'N/A',
                          ),
                          _buildDetailItem(
                            'Website',
                            vendor['website'] ?? 'N/A',
                          ),
                          _buildDetailItem(
                            'Status',
                            vendor['status']?.toString().toUpperCase() ??
                                'PENDING',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Row 2: Address & Products
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Address Details'),
                          _buildDetailItem(
                            'Street',
                            address['street'] ?? 'N/A',
                          ),
                          _buildDetailItem('City', address['city'] ?? 'N/A'),
                          _buildDetailItem('State', address['state'] ?? 'N/A'),
                          _buildDetailItem(
                            'Zip Code',
                            address['zipCode'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Product & Sales'),
                          _buildDetailItem(
                            'Categories',
                            (vendor['categories'] as List?)?.join(', ') ??
                                'N/A',
                          ),
                          _buildDetailItem(
                            'Avg Order Value',
                            vendor['avgOrderValue'] ?? 'N/A',
                          ),
                          _buildDetailItem(
                            'Monthly Volume',
                            vendor['monthlyVolume'] ?? 'N/A',
                          ),
                          _buildDetailItem(
                            'Description',
                            vendor['description'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Row 3: Documents & Bank
                _buildSectionTitle('Documents & Compliance'),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'GST Number',
                              docs['gstNumber'] ?? docs['taxId'] ?? 'N/A',
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDetailItem(
                              'Bank Name',
                              docs['bankName'] ?? 'N/A',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'Account Number',
                              docs['bankAccount'] ?? 'N/A',
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDetailItem(
                              'IFSC Code',
                              docs['ifscCode'] ?? 'N/A',
                            ),
                          ),
                        ],
                      ),
                      if (docs['license'] != null ||
                          docs['documentUrl'] != null) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildDocumentSection(
                          'Business License / GST Certificate',
                          docs['license'] ?? docs['documentUrl'],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(String label, String url) {
    final isImage =
        url.toLowerCase().contains('.jpg') ||
        url.toLowerCase().contains('.png') ||
        url.toLowerCase().contains('.jpeg');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 12),
        if (isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: double.infinity,
              height: 400,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                padding: const EdgeInsets.all(20),
                color: Colors.grey.shade100,
                child: const Text('Unable to load document image'),
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open document link'),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('View Document File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E293B),
              elevation: 0,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/vendors',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  'Master Admin',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                Text(
                  'Vendors',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading && _vendors.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6B21A8),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vendor Management',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Approve storefronts, monitor performance, and take actions.',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showBulkCommissionDialog,
                        icon: const Icon(Icons.group_work_outlined, size: 18),
                        label: const Text('Bulk Commission Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Metrics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Active Vendors',
                          value: _vendors
                              .where((v) => v['status'] == 'approved')
                              .length
                              .toString(),
                          icon: Icons.check_circle_outline,
                          iconBgColor: const Color(0xFFD1FAE5), // Light green
                          iconColor: const Color(0xFF10B981), // Green
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Pending Approvals',
                          value: _vendors
                              .where((v) => v['status'] == 'pending')
                              .length
                              .toString(),
                          icon: Icons.filter_alt_outlined,
                          iconBgColor: const Color(0xFFFEF3C7), // Light yellow
                          iconColor: const Color(0xFFF59E0B), // Orange-yellow
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total Vendors',
                          value: _vendors.length.toString(),
                          icon: Icons.store_outlined,
                          iconBgColor: const Color(0xFFDBEAFE), // Light blue
                          iconColor: const Color(0xFF3B82F6), // Blue
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Table Container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search vendor, owner, or email',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.grey.shade400,
                                        fontSize: 13,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 1500,
                              maxWidth: 1500,
                            ),
                            child: Column(
                              children: [
                                // Table Headers
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    border: Border.symmetric(
                                      horizontal: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _tableHeader('BUSINESS', flex: 3),
                                      _tableHeader('OWNER', flex: 2),
                                      _tableHeader('CATEGORIES', flex: 3),
                                      _tableHeader('STATUS', flex: 2),
                                      _tableHeader('COMMISSION', flex: 2),
                                      _tableHeader('JOINED', flex: 2),
                                      _tableHeader(
                                        'ACTIONS',
                                        flex: 2,
                                        align: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),

                                // Table Rows
                                if (_isLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 60),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (_filteredVendors.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 60,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _searchController.text.isEmpty
                                            ? 'No vendor applications yet.'
                                            : 'No vendors match your search.',
                                        style: GoogleFonts.inter(
                                          color: Colors.grey.shade500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredVendors.length,
                                    itemBuilder: (context, index) {
                                      final vendor = _filteredVendors[index];
                                      return _buildVendorRow(vendor);
                                    },
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorRow(Map<String, dynamic> vendor) {
    final status = vendor['status'] ?? 'pending';
    final user = vendor['user'] ?? {};
    final statusColor = status == 'approved'
        ? const Color(0xFF10B981)
        : (status == 'rejected'
              ? Colors.red
              : (status == 'inactive' ? Colors.grey : const Color(0xFFF59E0B)));
    final statusBg = status == 'approved'
        ? const Color(0xFFD1FAE5)
        : (status == 'rejected'
              ? Colors.red.shade50
              : (status == 'inactive'
                    ? Colors.grey.shade100
                    : const Color(0xFFFEF3C7)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vendor['businessName'] ?? 'No Name',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  user['email'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              (vendor['categories'] as List?)?.join(', ') ?? 'General',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  '${vendor["commissionRate"] ?? 10}%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                IconButton(
                  onPressed: () => _showCommissionDialog(vendor),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              vendor['createdAt'] != null
                  ? DateFormat(
                      'MMM dd, yyyy',
                    ).format(DateTime.parse(vendor['createdAt']))
                  : 'N/A',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending') ...[
                  IconButton(
                    onPressed: () => _showVendorDetailsDialog(vendor),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    tooltip: 'View Details',
                  ),
                  IconButton(
                    onPressed: () => _updateStatus(vendor['_id'], 'approved'),
                    icon: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    onPressed: () => _updateStatus(vendor['_id'], 'rejected'),
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                    tooltip: 'Reject',
                  ),
                ] else ...[
                  if (status == 'approved')
                    IconButton(
                      onPressed: () => _updateStatus(vendor['_id'], 'inactive'),
                      icon: const Icon(
                        Icons.pause_circle_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      tooltip: 'Deactivate',
                    )
                  else if (status == 'inactive')
                    IconButton(
                      onPressed: () => _updateStatus(vendor['_id'], 'approved'),
                      icon: const Icon(
                        Icons.play_circle_outline,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      tooltip: 'Activate',
                    ),
                  IconButton(
                    onPressed: () => _showLedgerDialog(vendor),
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF8B5CF6),
                      size: 20,
                    ),
                    tooltip: 'View Ledger',
                  ),
                  IconButton(
                    onPressed: () => _showVendorDetailsDialog(vendor),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    tooltip: 'View Details',
                  ),
                  IconButton(
                    onPressed: () => _deleteVendor(vendor['_id']),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(
    String title, {
    required int flex,
    TextAlign align = TextAlign.start,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
