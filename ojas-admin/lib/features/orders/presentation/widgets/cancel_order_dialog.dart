import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_admin/features/orders/application/order_controller.dart';

class CancelOrderDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final OrderController controller;
  final VoidCallback? onSuccess;

  const CancelOrderDialog({
    super.key,
    required this.order,
    required this.controller,
    this.onSuccess,
  });

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  String _selectedAction = 'CANCELLED'; // 'CANCELLED' or 'REJECTED'
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  final List<String> _presetReasons = [
    'Out of stock',
    'Customer requested cancellation',
    'Invalid / unserviceable address',
    'Payment verification failed',
    'Vendor unable to fulfill',
    'Duplicate order placed',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String orderId = (widget.order['_id'] ?? widget.order['id'] ?? '').toString();
    if (orderId.isEmpty) return;

    final String reason = _reasonController.text.trim();

    setState(() {
      _isLoading = true;
    });

    final success = await widget.controller.cancelOrRejectOrder(
      orderId,
      status: _selectedAction,
      reason: reason.isNotEmpty ? reason : (_selectedAction == 'REJECTED' ? 'Rejected by Admin' : 'Cancelled by Admin'),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order ${_selectedAction == "REJECTED" ? "rejected" : "cancelled"} successfully! Stock restored.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSuccess?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${_selectedAction.toLowerCase()} order. Please try again.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayOrderId = widget.order['orderId'] ?? 'Order';
    final customerName = widget.order['user']?['name'] ?? widget.order['shippingAddress']?['name'] ?? 'Customer';
    final isOnlinePaid = widget.order['paymentMethod'] == 'ONLINE' && widget.order['paymentStatus'] == 'SUCCESS';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel / Reject Order',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '#$displayOrderId • $customerName',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const Divider(height: 28, color: Color(0xFFE2E8F0)),

              // Action Selection
              Text(
                'Select Action',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: 'Cancel Order',
                      subtitle: 'Mark order as Cancelled',
                      value: 'CANCELLED',
                      icon: Icons.highlight_off,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      title: 'Reject Order',
                      subtitle: 'Reject & notify buyer',
                      value: 'REJECTED',
                      icon: Icons.block,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Preset reasons
              Text(
                'Quick Reason',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetReasons.map((r) {
                  final bool isSelected = _reasonController.text == r;
                  return ChoiceChip(
                    label: Text(
                      r,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFEF4444),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _reasonController.text = r;
                        } else if (_reasonController.text == r) {
                          _reasonController.clear();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Reason input field
              Text(
                'Reason / Note to Customer',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'Enter reason for ${_selectedAction.toLowerCase()}...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Automated Consequences notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 6),
                        Text(
                          'Automated Actions on Confirmation:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Inventory: Product stock will be automatically restocked back to catalog.\n'
                      '${isOnlinePaid ? "• Refund: Order payment status will be marked as REFUNDED.\n" : ""}'
                      '• Notification: Automated WhatsApp status message will be dispatched to customer.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7F1D1D), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Keep Order',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _selectedAction == 'REJECTED' ? 'Confirm Rejection' : 'Confirm Cancellation',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final bool isSelected = _selectedAction == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF991B1B) : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
