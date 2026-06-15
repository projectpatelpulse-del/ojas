import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/admin_layout.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import 'package:ojas_admin/features/help/data/services/admin_support_service.dart';
import 'package:ojas_admin/features/help/domain/models/support_ticket_model.dart';
import 'package:intl/intl.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final List<String> _tabs = ['Support Tickets'];
  String _selectedTab = 'Support Tickets';
  
  String _ticketType = 'Vendor'; // 'Vendor' or 'User'

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/help',
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
                Text('Help Management', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),

          // Tabs (Hidden if only one tab exists, but keeping structure for future)
          if (_tabs.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: _tabs.map<Widget>((tab) {
                  final isSelected = _selectedTab == tab;
                  return InkWell(
                    onTap: () => setState(() => _selectedTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: _buildSupportTickets(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSupportTickets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_ticketType Support Tickets',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and respond to help requests from ${_ticketType.toLowerCase()}s',
                  style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                _buildTicketTypeToggle(),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Tickets',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        FutureBuilder<List<SupportTicketModel>>(
          future: _ticketType == 'Vendor' 
            ? sl<AdminSupportService>().getAllTickets()
            : sl<AdminSupportService>().getAllUserTickets(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyTickets();
            }

            final tickets = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _buildTicketCard(ticket);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTicketTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: ['Vendor', 'User'].map((type) {
          final isSelected = _ticketType == type;
          return GestureDetector(
            onTap: () => setState(() => _ticketType = type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
              ),
              child: Text(
                '$type Tickets',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket) {
    Color statusColor;
    switch (ticket.status) {
      case 'Open': statusColor = Colors.blue; break;
      case 'In Progress': statusColor = Colors.orange; break;
      case 'Resolved': statusColor = Colors.green; break;
      default: statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ticket ID: ${ticket.ticketId}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.category,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(ticket.createdAt),
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ticket.subject,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(_ticketType == 'Vendor' ? Icons.business : Icons.person_outline, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                '${_ticketType == 'Vendor' ? 'Vendor' : 'User'}: ${ticket.vendorName}',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 20),
              Icon(Icons.phone, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                ticket.phone,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showTicketDetails(ticket),
                child: Text('View Details & Respond', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF8B5CF6))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTickets() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined, color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              'No support tickets raised yet',
              style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDetails(SupportTicketModel ticket) {
    final replyController = TextEditingController();
    String selectedStatus = ticket.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Ticket: ${ticket.ticketId}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            value: selectedStatus,
                            items: ['Open', 'In Progress', 'Resolved', 'Closed']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) async {
                              bool success = false;
                              if (_ticketType == 'Vendor') {
                                success = await sl<AdminSupportService>().updateStatus(ticket.id, v!);
                              } else {
                                success = await sl<AdminSupportService>().updateUserTicketStatus(ticket.id, v!);
                              }
                              if (success) setState(() => selectedStatus = v);
                            },
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Priority', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(ticket.priority, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text('Issue Description', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(ticket.message, style: GoogleFonts.inter(fontSize: 14)),
                  ),
                  const SizedBox(height: 24),
                  Text('Responses', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (ticket.responses != null && ticket.responses!.isNotEmpty)
                    ...ticket.responses!.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: r.sender == 'Admin' ? const Color(0xFFF5F3FF) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: r.sender == 'Admin' ? const Color(0xFFDDD6FE) : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.sender, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: r.sender == 'Admin' ? const Color(0xFF7C3AED) : Colors.grey)),
                                  Text(DateFormat('dd MMM, hh:mm a').format(r.createdAt), style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(r.message, style: GoogleFonts.inter(fontSize: 13)),
                            ],
                          ),
                        )),
                  const SizedBox(height: 16),
                  TextField(
                    controller: replyController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Type your response here...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton(
              onPressed: () async {
                if (replyController.text.isNotEmpty) {
                  bool success = false;
                  if (_ticketType == 'Vendor') {
                    success = await sl<AdminSupportService>().addResponse(ticket.id, replyController.text);
                  } else {
                    success = await sl<AdminSupportService>().addUserTicketResponse(ticket.id, replyController.text);
                  }
                  
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    this.setState(() {}); // Refresh main list
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
              child: const Text('Send Response'),
            ),
          ],
        ),
      ),
    );
  }
}
