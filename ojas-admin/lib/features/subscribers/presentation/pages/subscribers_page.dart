import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ojas_admin/core/services/api_service.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/admin_layout.dart';
import 'package:ojas_admin/features/users/data/services/user_service.dart';

class SubscribersPage extends StatefulWidget {
  final String currentRoute;

  const SubscribersPage({super.key, this.currentRoute = '/subscribers'});

  @override
  State<SubscribersPage> createState() => _SubscribersPageState();
}

class _SubscribersPageState extends State<SubscribersPage> {
  final ApiService _apiService = sl<ApiService>();
  final UserService _userService = sl<UserService>();

  List<dynamic> _subscribers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  final Set<String> _selectedEmails = {};

  @override
  void initState() {
    super.initState();
    _fetchSubscribers();
  }

  Future<void> _fetchSubscribers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _selectedEmails.clear();
    });

    try {
      final response = await _apiService.dio.get('/admin/subscribers');
      setState(() {
        _subscribers = response.data['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching subscribers: $e');
      setState(() {
        _errorMessage = 'Failed to load subscribers list.';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredSubscribers {
    if (_searchQuery.isEmpty) return _subscribers;
    return _subscribers.where((sub) {
      final email = sub['email']?.toString().toLowerCase() ?? '';
      return email.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _deleteSubscriber(String id, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscriber'),
        content: Text('Are you sure you want to remove "$email" from subscribers list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.dio.delete('/admin/subscriber/$id');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscriber removed successfully')),
          );
        }
        _fetchSubscribers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete subscriber: $e')),
          );
        }
      }
    }
  }

  void _showSendEmailDialog({required bool sendToAll, String? targetEmail}) {
    final List<String> recipients = sendToAll
        ? _filteredSubscribers.map((s) => s['email'].toString()).where((e) => e.isNotEmpty).toList()
        : (_selectedEmails.isNotEmpty
            ? _selectedEmails.toList()
            : (targetEmail != null ? [targetEmail] : []));

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recipient email addresses selected.')),
      );
      return;
    }

    final subjectController = TextEditingController();
    final contentController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.email_outlined, color: Color(0xFF6B21A8)),
                const SizedBox(width: 10),
                Text(
                  'Send Email to Subscribers (${recipients.length})',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Text(
                      'Recipients: ${recipients.take(5).join(', ')}${recipients.length > 5 ? ' + ${recipients.length - 5} more' : ''}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.purple.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Email Content',
                      hintText: 'Enter your newsletter updates or offer details...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B21A8),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: isSending
                    ? null
                    : () async {
                        if (subjectController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Subject and content are required.')),
                          );
                          return;
                        }

                        setModalState(() => isSending = true);

                        try {
                          final result = await _userService.sendBulkEmail(
                            emails: recipients,
                            subject: subjectController.text.trim(),
                            htmlContent: contentController.text.trim(),
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? 'Email sent successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSending = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to send email: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Send Email', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSubscribers;
    final allSelected = filtered.isNotEmpty && _selectedEmails.length == filtered.length;

    return AdminLayout(
      currentRoute: widget.currentRoute,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Newsletter Subscribers',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                    ),
                    Text(
                      'Manage users subscribed to your website newsletter',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchSubscribers,
                      tooltip: 'Refresh',
                    ),
                    const SizedBox(width: 8),
                    if (_selectedEmails.isNotEmpty)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        label: Text('Email Selected (${_selectedEmails.length})', style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B21A8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: () => _showSendEmailDialog(sendToAll: false),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.campaign_outlined, size: 18, color: Colors.white),
                      label: const Text('Email All Subscribers', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onPressed: () => _showSendEmailDialog(sendToAll: true),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stat Box & Search
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read_outlined, color: Color(0xFF6B21A8), size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Subscribers', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                          Text('${_subscribers.length}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search subscribers by email...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(48.0), child: CircularProgressIndicator()))
                  : _errorMessage.isNotEmpty
                      ? Center(child: Padding(padding: EdgeInsets.all(48.0), child: Text(_errorMessage)))
                      : filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(48.0),
                                child: Text('No subscribers found.', style: GoogleFonts.inter(color: Colors.grey)),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                                columns: [
                                  DataColumn(
                                    label: Checkbox(
                                      value: allSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedEmails.addAll(filtered.map((s) => s['email'].toString()));
                                          } else {
                                            _selectedEmails.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const DataColumn(label: Text('EMAIL')),
                                  const DataColumn(label: Text('STATUS')),
                                  const DataColumn(label: Text('SUBSCRIBED DATE')),
                                  const DataColumn(label: Text('ACTIONS')),
                                ],
                                rows: filtered.map((sub) {
                                  final id = sub['_id']?.toString() ?? '';
                                  final email = sub['email']?.toString() ?? '';
                                  final status = sub['status']?.toString() ?? 'Subscribed';
                                  final createdAt = sub['createdAt'] != null
                                      ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(sub['createdAt']))
                                      : 'N/A';
                                  final isChecked = _selectedEmails.contains(email);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Checkbox(
                                          value: isChecked,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedEmails.add(email);
                                              } else {
                                                _selectedEmails.remove(email);
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      DataCell(
                                        Text(email, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: status == 'Subscribed' ? Colors.green.shade50 : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: status == 'Subscribed' ? Colors.green.shade300 : Colors.orange.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: status == 'Subscribed' ? Colors.green.shade700 : Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(createdAt, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700))),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.mail_outline, color: Color(0xFF6B21A8), size: 20),
                                              tooltip: 'Send Email',
                                              onPressed: () => _showSendEmailDialog(sendToAll: false, targetEmail: email),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                              tooltip: 'Delete',
                                              onPressed: () => _deleteSubscriber(id, email),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
