import 'package:flutter/material.dart';
import 'package:ojas_user/core/services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/features/orders/data/services/order_service.dart';
import 'package:ojas_user/features/orders/domain/models/order_model.dart';
import 'package:ojas_user/features/orders/presentation/pages/order_details_page.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await _orderService.getUserOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return OjasLayout(
      activeTitle: 'TRACK ORDERS',
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 60),
        color: const Color(0xFFF8F9FA),
        child: CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'My Orders',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track and manage your order history',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 14 : 16,
                  color: AppColors.black87,
                ),
              ),
              const SizedBox(height: 48),

              // Summary Cards
              if (isMobile)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: _getSummaryCards(isMobile),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _getSummaryCards(isMobile).map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: c))).toList(),
                ),
              const SizedBox(height: 48),

              // Order List
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
              else if (_orders.isEmpty)
                _buildEmptyState(isMobile)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    return _orderCard(
                      context,
                      isMobile: isMobile,
                      order: _orders[index],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No orders found',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t placed any orders yet.',
            style: GoogleFonts.inter(color: AppColors.black54),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/shop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Start Shopping', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  List<Widget> _getSummaryCards(bool isMobile) {
    int pending = _orders.where((o) => o.status == 'Pending' || o.status == 'Processing' || o.status == 'Shipped').length;
    int delivered = _orders.where((o) => o.status == 'Delivered').length;
    int cancelled = _orders.where((o) => o.status == 'Cancelled').length;

    return [
      _summaryCard(
        isMobile: isMobile,
        icon: Icons.inventory_2_outlined,
        count: _orders.length.toString(),
        label: 'Total Orders',
        color: AppColors.primaryPink,
        isActive: true,
      ),
      _summaryCard(
        isMobile: isMobile,
        icon: Icons.history_toggle_off,
        count: pending.toString(),
        label: 'Pending',
        color: Colors.amber,
      ),
      _summaryCard(
        isMobile: isMobile,
        icon: Icons.task_alt,
        count: delivered.toString(),
        label: 'Delivered',
        color: AppColors.successGreen,
      ),
      _summaryCard(
        isMobile: isMobile,
        icon: Icons.cancel_outlined,
        count: cancelled.toString(),
        label: 'Cancelled',
        color: AppColors.errorRed,
      ),
    ];
  }

  Widget _summaryCard({
    required bool isMobile,
    required IconData icon,
    required String count,
    required String label,
    required Color color,
    bool isActive = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primaryPink : AppColors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 24),
          ),
          SizedBox(height: isMobile ? 8 : 16),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: AppColors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              color: AppColors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(
    BuildContext context, {
    required bool isMobile,
    required OrderModel order,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderDetailsPage(order: order)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Header: Order ID & Date
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ORDER ID', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey500, letterSpacing: 0.5)),
                      Text(order.orderId, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black87)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('PLACED ON', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey500, letterSpacing: 0.5)),
                      Text(DateFormat('MMM dd, yyyy').format(order.createdAt), style: GoogleFonts.inter(fontSize: 14, color: AppColors.black87)),
                    ],
                  ),
                ],
              ),
            ),

            // Middle: Product Info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Thumbnails
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.grey200),
                          image: DecorationImage(
                            image: NetworkImage(ApiService.formatImageUrl(order.items[0].image)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (order.items.length > 1)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                            child: Text('+${order.items.length - 1}', style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // Product Name & Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items[0].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.items.length} Item${order.items.length > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey500),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '\u20b9${order.subtotal.ceil()}',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryPink),
                        ),
                      ],
                    ),
                  ),

                  // Status & Action
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusBadge(order.status),
                      const SizedBox(height: 20),
                      Icon(Icons.chevron_right, color: AppColors.grey400),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Tracking Info (If Shipped)
            if (order.awb.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.blue50.withOpacity(0.3),
                  border: Border(top: BorderSide(color: AppColors.blue50)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.blue700),
                    const SizedBox(width: 8),
                    Text(
                      'Tracking: ${order.awb}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.blue700),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () async {
                        if (order.trackingUrl.isNotEmpty) {
                          final url = Uri.parse(order.trackingUrl);
                          try {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            debugPrint('Could not launch tracking URL: $e');
                          }
                        }
                      },
                      child: Text('Track Package', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.blue700)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.amber;
    IconData icon = Icons.access_time_filled;
    
    final s = status.toLowerCase();
    if (s == 'shipped' || s == 'out_for_delivery') {
      color = AppColors.blue500;
      icon = Icons.local_shipping;
    } else if (s == 'delivered') {
      color = AppColors.successGreen;
      icon = Icons.check_circle;
    } else if (s == 'cancelled') {
      color = AppColors.errorRed;
      icon = Icons.cancel;
    } else if (s == 'processing') {
      color = Colors.indigo;
      icon = Icons.sync;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
