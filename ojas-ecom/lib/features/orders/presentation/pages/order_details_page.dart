import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/services/invoice_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/order_model.dart';

class OrderDetailsPage extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late OrderModel _currentOrder;
  bool _verifyingOtp = false;
  bool _resendingOtp = false;
  String? _otpError;
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_auth_token');
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() => _otpError = 'Please enter a valid OTP');
      return;
    }

    setState(() {
      _verifyingOtp = true;
      _otpError = null;
    });

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/order/verify-delivery-otp'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'orderId': _currentOrder.id,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _currentOrder = OrderModel.fromJson(data['order']);
          _otpController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order delivered successfully!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() {
          _otpError = data['message'] ?? 'Verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _otpError = 'Network error: $e';
      });
    } finally {
      setState(() {
        _verifyingOtp = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _resendingOtp = true;
      _otpError = null;
    });

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/order/resend-delivery-otp'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'orderId': _currentOrder.id,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP resent: ${data['deliveryOtp']}'), backgroundColor: Colors.green),
        );
      } else {
        setState(() {
          _otpError = data['message'] ?? 'Failed to resend OTP';
        });
      }
    } catch (e) {
      setState(() {
        _otpError = 'Network error: $e';
      });
    } finally {
      setState(() {
        _resendingOtp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('--- Order Tracking URL: ${_currentOrder.trackingUrl} ---');
    final bool isMobile = Responsive.isMobile(context);

    return OjasLayout(
      activeTitle: 'ORDER DETAILS',
      child: Container(
        color: const Color(0xFFF8F9FA),
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 60),
        child: CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button & Title
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Order Details',
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              if (isMobile)
                Column(
                  children: [
                    _deliveryOtpCard(isMobile),
                    _orderSummaryCard(isMobile),
                    const SizedBox(height: 24),
                    _trackingCard(isMobile),
                    const SizedBox(height: 24),
                    _itemsCard(isMobile),
                    const SizedBox(height: 24),
                    _shippingCard(isMobile),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _deliveryOtpCard(isMobile),
                          _trackingCard(isMobile),
                          const SizedBox(height: 24),
                          _itemsCard(isMobile),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _orderSummaryCard(isMobile),
                          const SizedBox(height: 24),
                          _shippingCard(isMobile),
                        ],
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

  Widget _deliveryOtpCard(bool isMobile) {
    if (_currentOrder.status == 'DELIVERED' || _currentOrder.status == 'CANCELLED') {
      return const SizedBox.shrink();
    }

    final otp = _currentOrder.deliveryOtp;
    if (otp == null || otp.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Secure Delivery OTP',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Share this OTP with the delivery partner only when you receive your order safely.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  otp,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: otp));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('OTP copied to clipboard!'), duration: Duration(seconds: 2)),
                  );
                },
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                tooltip: 'Copy OTP',
              ),
            ],
          ),
          //           const SizedBox(height: 24),
          // const Divider(color: Colors.white24),
          // const SizedBox(height: 16),
          // Text(
          //   'Delivery Partner OTP Verification (Agent Use Only)',
          //   style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          // ),
          // const SizedBox(height: 12),
          // Row(
          //   children: [
          //     Expanded(
          //       child: SizedBox(
          //         height: 48,
          //         child: TextField(
          //           controller: _otpController,
          //           keyboardType: TextInputType.number,
          //           style: GoogleFonts.inter(color: Colors.white),
          //           decoration: InputDecoration(
          //             hintText: 'Enter 6-digit OTP',
          //             hintStyle: GoogleFonts.inter(color: Colors.white38),
          //             filled: true,
          //             fillColor: Colors.white.withOpacity(0.1),
          //             contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          //             border: OutlineInputBorder(
          //               borderRadius: BorderRadius.circular(8),
          //               borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          //             ),
          //             enabledBorder: OutlineInputBorder(
          //               borderRadius: BorderRadius.circular(8),
          //               borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          //             ),
          //             focusedBorder: OutlineInputBorder(
          //               borderRadius: BorderRadius.circular(8),
          //               borderSide: const BorderSide(color: Colors.white),
          //             ),
          //           ),
          //         ),
          //       ),
          //     ),
          //     const SizedBox(width: 12),
          //     SizedBox(
          //       height: 48,
          //       child: ElevatedButton(
          //         onPressed: _verifyingOtp ? null : _verifyOtp,
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor: Colors.white,
          //           foregroundColor: Colors.blue.shade900,
          //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          //           padding: const EdgeInsets.symmetric(horizontal: 20),
          //         ),
          //         child: _verifyingOtp
          //             ? const SizedBox(
          //                 width: 20, height: 20,
          //                 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
          //               )
          //             : Text('Verify', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          //       ),
          //     ),
          //   ],
          // ),
          // if (_otpError != null) ...[
          //   const SizedBox(height: 8),
          //   Text(
          //     _otpError!,
          //     style: GoogleFonts.inter(color: Colors.red.shade200, fontSize: 12, fontWeight: FontWeight.bold),
          //   ),
          // ],
          // const SizedBox(height: 16),
          // TextButton.icon(
          //   onPressed: _resendingOtp ? null : _resendOtp,
          //   icon: _resendingOtp
          //       ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          //       : const Icon(Icons.refresh_rounded, color: Colors.white70, size: 16),
          //   label: Text(
          //     'Resend Delivery OTP',
          //     style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          //   ),
          // ),
       
       
        ],
      ),
    );
  }

  Widget _orderSummaryCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Summary',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_currentOrder.isBusinessPurchase)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'BUSINESS',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                  ),
                ),
            ],
          ),
          const Divider(height: 32),
          _summaryRow('Order ID', _currentOrder.orderId),
          _summaryRow('Date', DateFormat('MMM dd, yyyy').format(_currentOrder.createdAt)),
          _summaryRow('Status', _currentOrder.status, isStatus: true),
          _summaryRow('Payment', _currentOrder.paymentStatus, isStatus: true, statusColor: _getPaymentStatusColor()),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              Text(
                '\u20b9${_currentOrder.totalAmount.ceil()}',
                style: GoogleFonts.hind(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: const Color(0xFFF01B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await InvoiceService.generateAndDownloadInvoice(_currentOrder.toJson());
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF01B6B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
          if (_currentOrder.status != 'DELIVERED')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'Invoice will be available after delivery',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isStatus = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.black87, fontSize: 14)),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (statusColor ?? _getStatusColor(value)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor ?? _getStatusColor(value),
                ),
              ),
            )
          else
            Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _trackingCard(bool isMobile) {
    final List<Map<String, dynamic>> stages = [
      {'title': 'Ordered', 'subtitle': 'Your order has been placed successfully.', 'icon': Icons.shopping_bag_outlined, 'status': 'CREATED'},
      {'title': 'Packed', 'subtitle': 'Your items have been packed and are ready.', 'icon': Icons.archive_outlined, 'status': 'PROCESSING'},
      {'title': 'Shipped', 'subtitle': 'Your order is on the way.', 'icon': Icons.local_shipping_outlined, 'status': 'SHIPPED'},
      {'title': 'Out for Delivery', 'subtitle': 'Delivery partner is bringing your order.', 'icon': Icons.directions_run_outlined, 'status': 'OUT_FOR_DELIVERY'},
      {'title': 'Delivered', 'subtitle': 'Successfully delivered.', 'icon': Icons.check_circle_outline, 'status': 'DELIVERED'},
    ];

    // Determine current stage index
    int currentStage = 0;
    final String s = _currentOrder.status.toUpperCase();
    if (s == 'PROCESSING') {
      currentStage = 1;
    } else if (s == 'SHIPPED') {
      currentStage = 2;
    } else if (s == 'OUT_FOR_DELIVERY') {
      currentStage = 3;
    } else if (s == 'DELIVERED') {
      currentStage = 4;
    } else if (s == 'CANCELLED') {
      stages.insert(1, {'title': 'Cancelled', 'subtitle': 'This order was cancelled.', 'icon': Icons.cancel_outlined, 'status': 'CANCELLED'});
      currentStage = 1;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: Color(0xFFF01B6B), size: 22),
              const SizedBox(width: 12),
              Text(
                'Order Tracking',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final stage = stages[index];
              final bool isCompleted = index <= currentStage;
              final bool isLast = index == stages.length - 1;
              final bool isCurrent = index == currentStage;
              final Color activeColor = stage['status'] == 'CANCELLED' ? Colors.red : Colors.green;

              return IntrinsicHeight(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted ? activeColor : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: isCurrent ? Border.all(color: activeColor.withOpacity(0.3), width: 6) : null,
                          ),
                          child: Icon(stage['icon'], size: 16, color: isCompleted ? Colors.white : Colors.grey.shade400),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: index < currentStage ? activeColor : Colors.grey.shade200,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage['title'],
                              style: GoogleFonts.inter(
                                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                                color: isCompleted ? Colors.black87 : Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stage['subtitle'],
                              style: GoogleFonts.inter(color: isCompleted ? Colors.grey.shade600 : Colors.grey.shade300, fontSize: 13),
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
          
          if (_currentOrder.awb.isNotEmpty) ...[
            const Divider(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.local_shipping, color: Colors.blue.shade700, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_currentOrder.courierPartner, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade900)),
                            Text('AWB: ${_currentOrder.awb}', style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_currentOrder.trackingUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(_currentOrder.trackingUrl);
                          try {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            debugPrint('Could not launch tracking URL: $e');
                          }
                        },
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Track Shipment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemsCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${_currentOrder.items.length})',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: 32),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentOrder.items.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = _currentOrder.items[index];
              return Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                      image: DecorationImage(
                        image: NetworkImage(ApiService.formatImageUrl(item.image)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Qty: ${item.quantity}',
                          style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '\u20b9${(item.price * item.quantity).ceil()}',
                    style: GoogleFonts.hind(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _shippingCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipping Address',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFFF01B6B), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentOrder.shippingAddress.street,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currentOrder.shippingAddress.city}, ${_currentOrder.shippingAddress.state}',
                      style: GoogleFonts.inter(color: Colors.black87, fontSize: 14),
                    ),
                    Text(
                      _currentOrder.shippingAddress.zipCode,
                      style: GoogleFonts.inter(color: Colors.black87, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentOrder.gstNumber != null || _currentOrder.panNumber != null) ...[
            const Divider(height: 32),
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: Color(0xFFF01B6B), size: 20),
                const SizedBox(width: 12),
                Text(
                  'Tax Invoice Details',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentOrder.isBusinessPurchase) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.business_center_outlined, color: Colors.green.shade700, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Business Purchase enabled',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            ],
            if (_currentOrder.gstNumber != null)
              _summaryRow('GST Number', _currentOrder.gstNumber!),
            if (_currentOrder.panNumber != null)
              _summaryRow('PAN Number', _currentOrder.panNumber!),
            _summaryRow('Invoice Type', _currentOrder.invoiceType.replaceAll('_', ' ')),
          ],
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.amber;
      case 'Processing':
        return Colors.blue;
      case 'Shipped':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor() {
    switch (_currentOrder.paymentStatus) {
      case 'Paid':
        return Colors.green;
      case 'Unpaid':
        return Colors.amber;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
