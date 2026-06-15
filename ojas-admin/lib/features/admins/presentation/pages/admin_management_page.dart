import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/admin_layout.dart';
import 'package:ojas_admin/features/admins/data/services/admin_management_service.dart';
import 'package:ojas_admin/features/admins/domain/models/admin_model.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import 'package:intl/intl.dart';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  String _selectedStatus = 'All Statuses';
  String _searchQuery = '';
  List<AdminModel> _admins = [];
  bool _isLoading = true;

  final List<String> _statusOptions = ['All Statuses', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);
    try {
      final admins = await sl<AdminManagementService>().getAllAdmins();
      setState(() {
        _admins = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching admins: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final success = await sl<AdminManagementService>().updateAdminStatus(id, status);
      if (success) {
        _fetchAdmins();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Admin status updated to $status')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _deleteAdmin(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this admin account? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
        final success = await sl<AdminManagementService>().deleteAdmin(id);
        if (success) {
          _fetchAdmins();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Admin deleted successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting admin: $e')),
          );
        }
      }
    }
  }

  Future<void> _showPermissionsDialog(AdminModel admin) async {
    final List<String> availablePermissions = [
      'manage_users',
      'manage_vendors',
      'manage_products',
      'manage_orders',
      'manage_settings',
    ];

    final Map<String, String> permissionLabels = {
      'manage_users': 'Manage Users',
      'manage_vendors': 'Manage Vendors',
      'manage_products': 'Manage Products',
      'manage_orders': 'Manage Orders',
      'manage_settings': 'Manage Settings',
    };

    List<String> selectedPermissions = List.from(admin.permissions);

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Permissions for ${admin.name}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availablePermissions.map((permission) {
              return CheckboxListTile(
                title: Text(permissionLabels[permission] ?? permission, style: GoogleFonts.inter()),
                value: selectedPermissions.contains(permission),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      selectedPermissions.add(permission);
                    } else {
                      selectedPermissions.remove(permission);
                    }
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final success = await sl<AdminManagementService>().updateAdminPermissions(admin.id, selectedPermissions);
                  if (success) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating permissions: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      _fetchAdmins();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions updated successfully')),
        );
      }
    }
  }

  List<AdminModel> get _filteredAdmins {
    return _admins.where((admin) {
      final matchesSearch = admin.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          admin.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'All Statuses' || admin.status == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _admins.where((a) => a.status == 'Pending').length;
    final approvedCount = _admins.where((a) => a.status == 'Approved').length;
    final rejectedCount = _admins.where((a) => a.status == 'Rejected').length;
    final totalCount = _admins.length;

    return AdminLayout(
      currentRoute: '/admin-management',
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
                Text('Admin Management', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
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
                            'Admin Management',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Approve or reject admin applications and manage existing admins.',
                            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _fetchAdmins,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text('Refresh', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6), // Purple
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Metrics Cards
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Pending Applications', pendingCount.toString(), Icons.access_time, const Color(0xFFFEF08A), const Color(0xFFEAB308))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildMetricCard('Approved Admins', approvedCount.toString(), Icons.check_circle_outline, const Color(0xFFDCFCE7), const Color(0xFF22C55E))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildMetricCard('Rejected', rejectedCount.toString(), Icons.highlight_off, const Color(0xFFFEE2E2), const Color(0xFFEF4444))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildMetricCard('Total Admins', totalCount.toString(), Icons.verified_user_outlined, const Color(0xFFF3E8FF), const Color(0xFFA855F7))),
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
                                          onChanged: (v) => setState(() => _searchQuery = v),
                                          decoration: InputDecoration(
                                            hintText: 'Search admin name or email',
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
                              _buildDropdown(
                                value: _selectedStatus,
                                items: _statusOptions,
                                onChanged: (v) => setState(() => _selectedStatus = v!),
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
                              _tableHeader('ADMIN DETAILS', flex: 3),
                              _tableHeader('DEPARTMENT', flex: 2),
                              _tableHeader('ROLE', flex: 1),
                              _tableHeader('STATUS', flex: 2),
                              _tableHeader('APPLIED DATE', flex: 2),
                              _tableHeader('LAST LOGIN', flex: 2),
                              _tableHeader('ACTIONS', flex: 1),
                            ],
                          ),
                        ),

                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_filteredAdmins.isEmpty)
                          // Empty State
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: Text(
                                'No admin applications found.',
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
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredAdmins.length,
                            itemBuilder: (context, index) {
                              final admin = _filteredAdmins[index];
                              return _buildAdminRow(admin);
                            },
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

  Widget _buildAdminRow(AdminModel admin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Admin Details
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Text(
                    admin.name[0].toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(admin.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                      Text(admin.email, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Department
          Expanded(
            flex: 2,
            child: Text(admin.department, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
          ),

          // Role
          Expanded(
            flex: 1,
            child: Text(admin.role, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(admin.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    admin.status,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusTextColor(admin.status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Applied Date
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM dd, yyyy').format(admin.appliedDate),
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
            ),
          ),

          // Last Login
          Expanded(
            flex: 2,
            child: Text(
              admin.lastLogin != null ? DateFormat('MMM dd, HH:mm').format(admin.lastLogin!) : 'Never',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
            ),
          ),

          // Actions
          Expanded(
            flex: 1,
            child: Row(
              children: [
                if (admin.status == 'Pending') ...[
                  IconButton(
                    onPressed: () => _updateStatus(admin.id, 'Approved'),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                    tooltip: 'Approve',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _updateStatus(admin.id, 'Rejected'),
                    icon: const Icon(Icons.highlight_off, color: Colors.red, size: 20),
                    tooltip: 'Reject',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ] else ...[
                   IconButton(
                    onPressed: () => _showPermissionsDialog(admin),
                    icon: const Icon(Icons.lock_person_outlined, color: Color(0xFF8B5CF6), size: 20),
                    tooltip: 'Permissions',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                   IconButton(
                    onPressed: () => _deleteAdmin(admin.id),
                    icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                    tooltip: 'Delete Admin',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFFEF9C3);
      case 'Approved':
        return const Color(0xFFDCFCE7);
      case 'Rejected':
        return const Color(0xFFFEE2E2);
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFA16207);
      case 'Approved':
        return const Color(0xFF15803D);
      case 'Rejected':
        return const Color(0xFFB91C1C);
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color iconBgColor, Color textColor) {
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
              Text(title, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: textColor, size: 24),
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
      height: 44,
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

  Widget _tableHeader(String title, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
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
