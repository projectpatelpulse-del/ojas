import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/admin_layout.dart';
import 'package:ojas_admin/features/users/data/services/user_service.dart';
import 'package:ojas_admin/core/services/global_search_service.dart';

class UsersPage extends StatefulWidget {
  final String currentRoute;
  
  const UsersPage({super.key, this.currentRoute = '/users'});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final UserService _userService = sl<UserService>();
  final GlobalSearchService _globalSearchService = sl<GlobalSearchService>();
  List<dynamic> _allUsers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  String _selectedRole = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final Set<String> _selectedEmails = {};

  final List<String> _roleOptions = ['All', 'Admin', 'Customer', 'Vendor', 'Reseller'];
  final List<String> _statusOptions = ['All', 'Active', 'Inactive', 'Banned'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _globalSearchService.searchQuery.addListener(_onGlobalSearchChanged);
  }

  @override
  void dispose() {
    _globalSearchService.searchQuery.removeListener(_onGlobalSearchChanged);
    super.dispose();
  }

  void _onGlobalSearchChanged() {
    setState(() {
      _searchQuery = _globalSearchService.searchQuery.value;
    });
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _selectedEmails.clear();
    });
    try {
      final users = await _userService.getUsers();
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() {
        _errorMessage = 'Failed to load users. Please check if the server is running.';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredUsers {
    return _allUsers.where((user) {
      // Role Filter
      bool roleMatch = _selectedRole == 'All';
      if (!roleMatch) {
        String roleStr = user['role']?.toString().toLowerCase() ?? '';
        if (_selectedRole == 'Admin' && roleStr == 'admin') roleMatch = true;
        if (_selectedRole == 'Customer' && roleStr == 'user') roleMatch = true;
        if (_selectedRole == 'Vendor' && roleStr == 'vendor') roleMatch = true;
        if (_selectedRole == 'Reseller' && roleStr == 'reseller') roleMatch = true;
      }

      // Status Filter
      bool statusMatch = _selectedStatus == 'All' || 
          (user['status']?.toString().toLowerCase() == _selectedStatus.toLowerCase());

      // Search Query
      bool searchMatch = _searchQuery.isEmpty ||
          (user['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (user['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      return roleMatch && statusMatch && searchMatch;
    }).toList();
  }

  int get _activeUsersCount => _allUsers.where((u) => u['status'] == 'active').length;
  int get _inactiveUsersCount => _allUsers.where((u) => u['status'] == 'inactive').length;
  int get _bannedUsersCount => _allUsers.where((u) => u['status'] == 'banned').length;
  int get _customersCount => _allUsers.where((u) => u['role'] == 'user').length;
  int get _vendorsCount => _allUsers.where((u) => u['role'] == 'vendor').length;
  int get _totalUsersCount => _allUsers.length;

  void _handleUserAction(String action, dynamic user) {
    switch (action) {
      case 'role':
        _showRoleChangeDialog(user);
        break;
      case 'status':
        _showStatusChangeDialog(user);
        break;
      case 'password':
        _showResetPasswordDialog(user);
        break;
      case 'email':
        if (user['email'] != null && user['email'].toString().isNotEmpty) {
          _showSendEmailDialog(sendToAll: false, targetEmail: user['email']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This user does not have a valid email address.'), backgroundColor: Colors.red),
          );
        }
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
    }
  }

  void _showRoleChangeDialog(dynamic user) {
    String currentRole = user['role'] ?? 'user';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${user['name']}', style: GoogleFonts.outfit()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['admin', 'user', 'vendor', 'reseller'].map((role) => RadioListTile<String>(
            title: Text(role.toUpperCase()),
            value: role,
            groupValue: currentRole,
            onChanged: (val) {
              Navigator.pop(context);
              _updateUserRole(user['_id'], val!);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showStatusChangeDialog(dynamic user) {
    String currentStatus = user['status'] ?? 'active';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Status for ${user['name']}', style: GoogleFonts.outfit()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['active', 'inactive', 'banned'].map((status) {
            Color statusColor = Colors.green;
            if (status == 'inactive') statusColor = Colors.orange;
            if (status == 'banned') statusColor = Colors.red;
            
            return RadioListTile<String>(
              title: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              value: status,
              groupValue: currentStatus,
              onChanged: (val) {
                Navigator.pop(context);
                _updateUserStatus(user['_id'], val!);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResetPasswordDialog(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Are you sure you want to send a password reset link to ${user['email']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password reset link sent to ${user['email']}')),
              );
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to permanently delete ${user['name']}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user['_id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _userService.updateUserRole(userId, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to $newRole successfully')),
        );
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateUserStatus(String userId, String newStatus) async {
    try {
      await _userService.updateUserStatus(userId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus successfully')),
        );
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await _userService.deleteUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSendEmailDialog({bool sendToAll = false, String? targetEmail}) {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.mail_outline, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  Text(
                    sendToAll
                        ? 'Send Email to All Users'
                        : (targetEmail != null ? 'Send Email to User' : 'Send Email to Selected Users'),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 600,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sendToAll
                            ? 'This email will be sent to all $_totalUsersCount registered users.'
                            : (targetEmail != null ? 'This email will be sent to $targetEmail.' : 'This email will be sent to ${_selectedEmails.length} selected recipients.'),
                        style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          labelStyle: GoogleFonts.inter(fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Subject is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bodyController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Email Content (HTML supported)',
                          labelStyle: GoogleFonts.inter(fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          alignLabelWithHint: true,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Content is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() {
                              isSending = true;
                            });

                            try {
                              List<String> recipients = [];
                              if (sendToAll) {
                                recipients = _allUsers
                                    .map((u) => u['email']?.toString() ?? '')
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                              } else if (targetEmail != null) {
                                recipients = [targetEmail];
                              } else {
                                recipients = _selectedEmails.toList();
                              }

                              if (recipients.isEmpty) {
                                throw 'No recipients found with valid email addresses.';
                              }

                              final result = await _userService.sendBulkEmail(
                                emails: recipients,
                                subject: subjectController.text.trim(),
                                htmlContent: bodyController.text.trim(),
                              );

                              final successList = result['data']?['successful'] as List?;
                              final failList = result['data']?['failed'] as List?;
                              final successCount = successList?.length ?? 0;
                              final failCount = failList?.length ?? 0;

                              if (context.mounted) {
                                Navigator.pop(context);
                                if (failCount > 0 && successCount == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to send emails. Error: SMTP sending limit exceeded or credentials invalid.'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                } else if (failCount > 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Mixed results: Sent to $successCount users, failed for $failCount users. Check server logs.'),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Emails sent successfully to $successCount users!'),
                                      backgroundColor: const Color(0xFF22C55E),
                                    ),
                                  );
                                }

                                if (targetEmail == null) {
                                  setState(() {
                                    _selectedEmails.clear();
                                  });
                                }
                              }
                            } catch (e) {
                              setDialogState(() {
                                isSending = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to send emails: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Send', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: widget.currentRoute,
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
                Text('Users', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchUsers,
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
                              'User & Customer Management',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monitor accounts, adjust roles, and control access.',
                              style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (_selectedEmails.isNotEmpty) ...[
                              ElevatedButton.icon(
                                onPressed: () => _showSendEmailDialog(sendToAll: false),
                                icon: const Icon(Icons.mail_outline, size: 18),
                                label: Text('Send to Selected (${_selectedEmails.length})', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ] else ...[
                              ElevatedButton.icon(
                                onPressed: () => _showSendEmailDialog(sendToAll: true),
                                icon: const Icon(Icons.mail_outline, size: 18),
                                label: Text('Send Email to All', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            ElevatedButton.icon(
                              onPressed: _fetchUsers,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text('Refresh', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E), // Green
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Metrics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildClickableMetricCard(
                            title: 'Total Users',
                            value: _totalUsersCount.toString(),
                            icon: Icons.group_outlined,
                            iconBgColor: const Color(0xFFF1F5F9),
                            iconColor: const Color(0xFF64748B),
                            onTap: () => setState(() {
                              _selectedRole = 'All';
                              _selectedStatus = 'All';
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildClickableMetricCard(
                            title: 'Active Users',
                            value: _activeUsersCount.toString(),
                            icon: Icons.shield_outlined,
                            iconBgColor: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF22C55E),
                            onTap: () => setState(() {
                              _selectedRole = 'All';
                              _selectedStatus = 'Active';
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildClickableMetricCard(
                            title: 'Customers',
                            value: _customersCount.toString(),
                            icon: Icons.person_add_alt_1_outlined,
                            iconBgColor: const Color(0xFFDBEAFE),
                            iconColor: const Color(0xFF3B82F6),
                            onTap: () => setState(() {
                              _selectedRole = 'Customer';
                              _selectedStatus = 'All';
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildClickableMetricCard(
                            title: 'Vendors',
                            value: _vendorsCount.toString(),
                            icon: Icons.filter_alt_outlined,
                            iconBgColor: const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFFA855F7),
                            onTap: () => setState(() {
                              _selectedRole = 'Vendor';
                              _selectedStatus = 'All';
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildClickableMetricCard(
                            title: 'Inactive',
                            value: _inactiveUsersCount.toString(),
                            icon: Icons.pause_circle_outline,
                            iconBgColor: const Color(0xFFFEF9C3),
                            iconColor: const Color(0xFFEAB308),
                            onTap: () => setState(() {
                              _selectedRole = 'All';
                              _selectedStatus = 'Inactive';
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildClickableMetricCard(
                            title: 'Banned',
                            value: _bannedUsersCount.toString(),
                            icon: Icons.block_outlined,
                            iconBgColor: const Color(0xFFFEE2E2),
                            iconColor: const Color(0xFFEF4444),
                            onTap: () => setState(() {
                              _selectedRole = 'All';
                              _selectedStatus = 'Banned';
                            }),
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
                                            onChanged: (v) => setState(() => _searchQuery = v),
                                            decoration: InputDecoration(
                                              hintText: 'Search by name or email',
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

                                // Role Filter
                                Row(
                                  children: [
                                    Text('Role', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    _buildDropdown(
                                      value: _selectedRole,
                                      items: _roleOptions,
                                      onChanged: (v) => setState(() => _selectedRole = v!),
                                    ),
                                  ],
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
                                SizedBox(
                                  width: 40,
                                  child: Checkbox(
                                    value: _filteredUsers.isNotEmpty &&
                                        _filteredUsers.every((u) => u['email'] != null && _selectedEmails.contains(u['email'])),
                                    tristate: true,
                                    activeColor: const Color(0xFF22C55E),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          for (var u in _filteredUsers) {
                                            if (u['email'] != null) {
                                              _selectedEmails.add(u['email']);
                                            }
                                          }
                                        } else {
                                          _selectedEmails.clear();
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _tableHeader('USER/VENDOR DETAILS', flex: 3),
                                _tableHeader('PHONE', flex: 2),
                                _tableHeader('ROLE', flex: 1),
                                _tableHeader('STATUS', flex: 1),
                                _tableHeader('BUSINESS NAME', flex: 2),
                                _tableHeader('JOINED DATE', flex: 2),
                                _tableHeader('ACTIONS', flex: 1, align: TextAlign.right),
                              ],
                            ),
                          ),

                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(60.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(60.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Text(
                                      _errorMessage,
                                      style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchUsers,
                                      child: const Text('Retry'),
                                    )
                                  ],
                                ),
                              ),
                            )
                          else if (_filteredUsers.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Center(
                                child: Text(
                                  'No users match the current filters.',
                                  style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredUsers.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return _buildUserRow(user);
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

  Widget _buildUserRow(dynamic user) {
    String roleStr = user['role']?.toString().toLowerCase() ?? 'user';
    String role = roleStr.toUpperCase();
    String name = user['name'] ?? 'N/A';
    String email = user['email'] ?? 'N/A';
    String phone = user['mobile'] ?? 'N/A';
    String createdAt = user['createdAt'] != null 
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(user['createdAt']))
        : 'N/A';
    String businessName = user['businessName'] ?? '-';
    String photoUrl = user['photo'] ?? '';

    Color roleColor = Colors.blue;
    if (roleStr == 'admin') roleColor = Colors.red;
    if (roleStr == 'vendor') roleColor = Colors.purple;
    if (roleStr == 'reseller') roleColor = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: user['email'] != null && user['email'].toString().isNotEmpty
                ? Checkbox(
                    value: _selectedEmails.contains(user['email']),
                    activeColor: const Color(0xFF22C55E),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedEmails.add(user['email']);
                        } else {
                          _selectedEmails.remove(user['email']);
                        }
                      });
                    },
                  )
                : const SizedBox(),
          ),
          const SizedBox(width: 8),
          // User Details
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty ? Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
                      Text(email, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Phone
          Expanded(
            flex: 2,
            child: Text(phone, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
          ),

          // Role
          Expanded(
            flex: 1,
            child: UnconstrainedBox(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  role,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                ),
              ),
            ),
          ),

          // Status
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusIndicator(user['status'] ?? 'active'),
            ),
          ),

          // Business Name
          Expanded(
            flex: 2,
            child: Text(businessName, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
          ),

          // Joined Date
          Expanded(
            flex: 2,
            child: Text(createdAt, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
          ),

          // Actions
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onSelected: (value) => _handleUserAction(value, user),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'role',
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 18, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Change Role', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 18, color: Colors.green),
                        SizedBox(width: 12),
                        Text('Change Status', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'password',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset, size: 18, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('Reset Password', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'email',
                    child: Row(
                      children: [
                        Icon(Icons.mail_outline, size: 18, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Send Email', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete User', style: TextStyle(fontSize: 14, color: Colors.red)),
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

  Widget _buildStatusIndicator(String status) {
    Color color = const Color(0xFF22C55E); // Green
    IconData icon = Icons.check;
    Color bgColor = const Color(0xFFDCFCE7);

    if (status == 'inactive') {
      color = Colors.orange;
      icon = Icons.pause;
      bgColor = Colors.orange.withOpacity(0.1);
    } else if (status == 'banned') {
      color = Colors.red;
      icon = Icons.block;
      bgColor = const Color(0xFFFEE2E2);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 10, color: color),
    );
  }

  Widget _buildClickableMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
        ),
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

  Widget _tableHeader(String title, {required int flex, TextAlign align = TextAlign.left}) {
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
