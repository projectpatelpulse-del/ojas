import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/widgets/sidebar_layout.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';
import 'package:ojas_vendor/core/services/api_service.dart';
import 'package:intl/intl.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String _selectedStatus = 'All Status';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusOptions = [
    'All Status',
    'Active',
    'VIP',
    'Inactive',
  ];

  bool _isLoading = true;
  List<dynamic> _allCustomers = [];
  List<dynamic> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      final response = await ApiService().dio.get('/vendor/customers');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        setState(() {
          _allCustomers = data;
          _filteredCustomers = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching customers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterCustomers() {
    setState(() {
      _filteredCustomers = _allCustomers.where((c) {
        final searchMatch = _searchController.text.isEmpty || 
          (c['user']['name'] ?? '').toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (c['user']['email'] ?? '').toString().toLowerCase().contains(_searchController.text.toLowerCase());
          
        if (!searchMatch) return false;
        
        if (_selectedStatus == 'All Status') return true;
        if (_selectedStatus == 'VIP') {
          return (c['totalSpent'] ?? 0) > 50000;
        }
        final status = c['user']['status'] ?? 'Active';
        return status == _selectedStatus;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      activeRoute: '/customers',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const VendorTopBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Customers',
                      value: _allCustomers.length.toString(),
                      dotColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StatCard(
                      label: 'Active',
                      value: _allCustomers.where((c) => (c['user']['status'] ?? 'Active') == 'Active').length.toString(),
                      dotColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StatCard(
                      label: 'VIP',
                      value: _allCustomers.where((c) => (c['totalSpent'] ?? 0) > 50000).length.toString(), // VIP logic based on spent
                      dotColor: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StatCard(
                      label: 'Inactive',
                      value: _allCustomers.where((c) => (c['user']['status'] ?? '') == 'Inactive').length.toString(),
                      dotColor: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Table Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Toolbar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Search Field
                          SizedBox(
                            width: 260,
                            height: 40,
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search customers...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 18,
                                  color: Colors.grey.shade400,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: AppColors.primary),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (val) => _filterCustomers(),
                            ),
                          ),

                          const Spacer(),

                          // Status Dropdown
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    size: 18),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                items: _statusOptions.map((s) {
                                  return DropdownMenuItem(
                                      value: s, child: Text(s));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedStatus = val;
                                      _filterCustomers();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Filter Button
                          OutlinedButton.icon(
                            onPressed: _filterCustomers,
                            icon: const Icon(Icons.filter_list, size: 16),
                            label: Text(
                              'Filter',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Refresh Button
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _isLoading = true);
                              _fetchCustomers();
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(
                              'Refresh',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Header
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: const Color(0xFFF8FAFC),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          _headerCell('CUSTOMER', flex: 3),
                          _headerCell('CONTACT', flex: 3),
                          _headerCell('ORDERS', flex: 2),
                          _headerCell('TOTAL SPENT', flex: 2),
                          _headerCell('LAST ORDER', flex: 2),
                          _headerCell('STATUS', flex: 2),
                          _headerCell('ACTIONS', flex: 1),
                        ],
                      ),
                    ),

                    // Empty State or Data List
                    if (_isLoading)
                      const SizedBox(
                        height: 280,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_filteredCustomers.isEmpty)
                      SizedBox(
                        height: 280,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.people_outline,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No customers found',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No customers match the selected filter criteria.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          final user = customer['user'] ?? {};
                          final name = user['name'] ?? 'Unknown User';
                          final email = user['email'] ?? 'No email';
                          final mobile = user['mobile'] ?? 'No phone';
                          final totalOrders = customer['totalOrders'] ?? 0;
                          final totalSpent = customer['totalSpent'] ?? 0;
                          final status = user['status'] ?? 'Active';
                          
                          DateTime? lastOrderDate;
                          if (customer['lastOrderDate'] != null) {
                            lastOrderDate = DateTime.tryParse(customer['lastOrderDate']);
                          }
                          final dateStr = lastOrderDate != null 
                              ? DateFormat('MMM dd, yyyy').format(lastOrderDate)
                              : 'N/A';

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade100),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                // Customer Info
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primary.withOpacity(0.1),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                          style: GoogleFonts.inter(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Contact
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        email,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (mobile.isNotEmpty && mobile != 'No phone')
                                        Text(
                                          mobile,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Orders
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '$totalOrders orders',
                                    style: GoogleFonts.inter(fontSize: 14),
                                  ),
                                ),
                                // Total Spent
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹${totalSpent.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                                // Last Order
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    dateStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                // Status
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'Active' ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: status == 'Active' ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                // Actions
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: PopupMenuButton<String>(
                                      tooltip: 'Actions',
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'view') {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Viewing details for $name')),
                                          );
                                        } else if (value == 'email') {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Composing email to $email')),
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'view',
                                          child: ListTile(
                                            leading: Icon(Icons.visibility, size: 18),
                                            title: Text('View Details'),
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'email',
                                          child: ListTile(
                                            leading: Icon(Icons.mail_outline, size: 18),
                                            title: Text('Send Email'),
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
