import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/routes/app_router.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';

class OrderSuccessPage extends StatefulWidget {
  final String? orderId;
  final String? amount;
  final String? paymentMethod;
  final String? referralCode;
  final String? referredProductId;
  final Map<String, dynamic>? shippingAddress;

  const OrderSuccessPage({
    super.key,
    this.orderId,
    this.amount,
    this.paymentMethod,
    this.referralCode,
    this.referredProductId,
    this.shippingAddress,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  bool _copied = false;

  void _copyOrderId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order ID copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final String formattedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now());
    final displayOrderId = (widget.orderId != null && widget.orderId!.isNotEmpty)
        ? widget.orderId!
        : 'OJAS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    return OjasLayout(
      activeTitle: 'ORDER CONFIRMATION',
      child: Container(
        color: const Color(0xFFF8FAFC),
        padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 48),
        child: CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Confirmation Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Animated checkmark badge
                      Container(
                        width: isMobile ? 72 : 88,
                        height: isMobile ? 72 : 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A).withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: const Color(0xFF16A34A),
                          size: isMobile ? 44 : 54,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Thank You For Your Order!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Your order has been placed successfully and is now being processed. A confirmation email and SMS have been sent to you.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 15,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Order Details Strip
                      Container(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              title: 'Order ID',
                              isMobile: isMobile,
                              customWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SelectableText(
                                    displayOrderId,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _copyOrderId(displayOrderId),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        _copied ? Icons.check : Icons.copy_rounded,
                                        size: 16,
                                        color: _copied ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(color: Color(0xFFE2E8F0), height: 24),
                            _buildInfoRow(
                              title: 'Order Date',
                              value: formattedDate,
                              isMobile: isMobile,
                            ),
                            const Divider(color: Color(0xFFE2E8F0), height: 24),
                            _buildInfoRow(
                              title: 'Payment Method',
                              isMobile: isMobile,
                              customWidget: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (widget.paymentMethod == 'COD' || widget.paymentMethod == null)
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.paymentMethod == 'COD' ? 'Cash on Delivery' : (widget.paymentMethod ?? 'Online Payment'),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: (widget.paymentMethod == 'COD' || widget.paymentMethod == null)
                                        ? const Color(0xFF92400E)
                                        : const Color(0xFF166534),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.amount != null && widget.amount!.isNotEmpty) ...[
                              const Divider(color: Color(0xFFE2E8F0), height: 24),
                              _buildInfoRow(
                                title: 'Total Amount',
                                value: '₹${widget.amount}',
                                isMobile: isMobile,
                                isBold: true,
                              ),
                            ],
                            if (widget.shippingAddress != null) ...[
                              const Divider(color: Color(0xFFE2E8F0), height: 24),
                              _buildShippingAddressSummary(isMobile),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Order Progress Steps
                      _buildOrderTimeline(isMobile),
                      const SizedBox(height: 40),

                      // Primary Call-To-Action Buttons
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              AppRouter.push(context, '/orders');
                            },
                            icon: const Icon(Icons.receipt_long_rounded, size: 18),
                            label: const Text('View All Orders'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                              elevation: 0,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              AppRouter.go(context, '/shop');
                            },
                            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                            label: const Text('Continue Shopping'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Need Help Support Strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Have questions about your order?',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reach out to our customer support team for any assistance or inquiries.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          AppRouter.push(context, '/contact');
                        },
                        child: Text(
                          'Contact Us',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
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
      ),
    );
  }

  Widget _buildInfoRow({
    required String title,
    String? value,
    Widget? customWidget,
    required bool isMobile,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        if (customWidget != null)
          customWidget
        else
          Text(
            value ?? '',
            style: GoogleFonts.inter(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
            ),
          ),
      ],
    );
  }

  Widget _buildShippingAddressSummary(bool isMobile) {
    final addr = widget.shippingAddress!;
    final name = addr['name']?.toString() ?? '';
    final street = addr['street']?.toString() ?? addr['buildingName']?.toString() ?? '';
    final city = addr['city']?.toString() ?? '';
    final state = addr['state']?.toString() ?? '';
    final zip = addr['zipCode']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivering To',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            Text(
              name,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        if (street.isNotEmpty || city.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$street, $city, $state - $zip',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderTimeline(bool isMobile) {
    final steps = [
      {'title': 'Order Placed', 'subtitle': 'Confirmed', 'done': true},
      {'title': 'Processing', 'subtitle': 'Quality Check', 'done': false},
      {'title': 'Shipped', 'subtitle': 'On the way', 'done': false},
      {'title': 'Delivered', 'subtitle': 'At your doorstep', 'done': false},
    ];

    if (isMobile) {
      return Column(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isDone = step['done'] as bool;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      size: isDone ? 14 : 8,
                      color: isDone ? AppColors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: const Color(0xFFE2E8F0),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                      color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    step['subtitle'] as String,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          );
        }).toList(),
      );
    }

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isDone = step['done'] as bool;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                      ),
                      child: Icon(
                        isDone ? Icons.check : Icons.circle,
                        size: isDone ? 18 : 8,
                        color: isDone ? AppColors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                        color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      step['subtitle'] as String,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 30,
                  height: 2,
                  color: isDone ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.only(bottom: 24),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
