import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/widgets/sidebar_layout.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';
import 'package:ojas_vendor/features/orders/application/order_controller.dart';
import 'package:ojas_vendor/features/orders/presentation/widgets/edit_invoice_dialog.dart';
import 'package:ojas_vendor/features/orders/presentation/widgets/shipping_label_dialog.dart';
import 'package:ojas_vendor/features/orders/presentation/widgets/assign_delhivery_dialog.dart';
import 'package:ojas_vendor/features/orders/presentation/widgets/order_details_dialog.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderController _controller = OrderController();
  String _selectedStatus = 'All Status';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusOptions = [
    'All Status',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
    'Escalated',
  ];

  @override
  void initState() {
    super.initState();
    _controller.fetchVendorOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      activeRoute: '/orders',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const VendorTopBar(),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final orders = _controller.orders.where((o) {
               if (_selectedStatus == 'All Status') return true;
               return o['status'] == _selectedStatus;
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (_controller.isLoading)
                    const LinearProgressIndicator(color: Color(0xFFF01B6B)),
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total Orders',
                          value: '${_controller.totalOrders}',
                          dotColor: Colors.blue,
                          onTap: () => setState(() => _selectedStatus = 'All Status'),
                          isSelected: _selectedStatus == 'All Status',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _StatCard(
                          label: 'Pending',
                          value: '${_controller.pendingOrders}',
                          dotColor: Colors.amber,
                          onTap: () => setState(() => _selectedStatus = 'Pending'),
                          isSelected: _selectedStatus == 'Pending',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _StatCard(
                          label: 'Processing',
                          value: '${_controller.processingOrders}',
                          dotColor: Colors.blue,
                          onTap: () => setState(() => _selectedStatus = 'Processing'),
                          isSelected: _selectedStatus == 'Processing',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _StatCard(
                          label: 'Shipped',
                          value: '${_controller.shippedOrders}',
                          dotColor: Colors.purple,
                          onTap: () => setState(() => _selectedStatus = 'Shipped'),
                          isSelected: _selectedStatus == 'Shipped',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _StatCard(
                          label: 'Delivered',
                          value: '${_controller.deliveredOrders}',
                          dotColor: Colors.green,
                          onTap: () => setState(() => _selectedStatus = 'Delivered'),
                          isSelected: _selectedStatus == 'Delivered',
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
                        // Search + Filter Bar
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
                                  onChanged: (v) => setState(() {}),
                                  style: GoogleFonts.inter(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Search orders...',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey.shade400,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      size: 18,
                                      color: Colors.grey.shade400,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
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
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                    items: _statusOptions.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedStatus = val);
                                      }
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Filter Button
                              OutlinedButton.icon(
                                onPressed: () => _controller.fetchVendorOrders(),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: Text(
                                  'Refresh',
                                  style: GoogleFonts.inter(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              _headerCell('ORDER ID', flex: 2),
                              _headerCell('CUSTOMER', flex: 2),
                              _headerCell('PRODUCTS', flex: 2),
                              _headerCell('AMOUNT', flex: 2),
                              _headerCell('STATUS', flex: 2),
                              _headerCell('AWB', flex: 2),
                              _headerCell('DATE', flex: 2),
                              _headerCell('ACTIONS', flex: 3),
                            ],
                          ),
                        ),

                        if (orders.isEmpty)
                          // Empty State
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
                                      Icons.receipt_long_outlined,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No orders found',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'No orders match the selected filter criteria.',
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
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              debugPrint('--- Vendor Order [${order['orderId']}] Tracking URL: ${order['trackingUrl']} ---');
                              final String orderId = order['orderId'] ?? 'ID';
                              final String customer = order['user'] != null ? order['user']['name'] : 'Guest';
                              final List items = order['items'] ?? [];
                              final String products = items.isNotEmpty ? items[0]['name'] : 'Item';
                              final double amount = (order['totalAmount'] ?? 0).toDouble();
                              final String status = order['status'] ?? 'Pending';
                              final String date = order['createdAt'] != null ? DateTime.parse(order['createdAt']).toString().split(' ')[0] : '-';

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 14,
                                      child: InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => OrderDetailsDialog(order: order, controller: _controller),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Expanded(flex: 2, child: Text(orderId, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500))),
                                            Expanded(flex: 2, child: Text(customer, style: GoogleFonts.inter(fontSize: 13))),
                                            Expanded(flex: 2, child: Text(products + (items.length > 1 ? ' +${items.length - 1}' : ''), style: GoogleFonts.inter(fontSize: 13), overflow: TextOverflow.ellipsis)),
                                            Expanded(flex: 2, child: Text('₹$amount', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold))),
                                            Expanded(flex: 2, child: _buildStatusBadge(status)),
                                            Expanded(
                                              flex: 2, 
                                              child: Text(
                                                order['awb'] ?? '-', 
                                                style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(flex: 2, child: Text(date, style: GoogleFonts.inter(fontSize: 13))),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => EditInvoiceDialog(order: order),
                                                );
                                              },
                                            icon: const Icon(
                                              Icons.download_for_offline_rounded,
                                              size: 20,
                                              color: Colors.blue,
                                            ),
                                            tooltip: 'Download Invoice',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: (order['status'].toString().toLowerCase() != 'cancelled' &&
                                                    order['status'].toString().toLowerCase() != 'pending')
                                                ? () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => ShippingLabelDialog(order: order),
                                                    );
                                                  }
                                                : null,
                                            icon: Icon(
                                              Icons.local_shipping_outlined,
                                              size: 20,
                                              color: (order['status'].toString().toLowerCase() != 'cancelled' &&
                                                      order['status'].toString().toLowerCase() != 'pending')
                                                  ? Colors.orange.shade700
                                                  : Colors.grey.withOpacity(0.3),
                                            ),
                                            tooltip: 'Download Shipping Label',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: (status == 'Pending' || status == 'Processing')
                                                ? () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (dialogContext) => AssignDelhiveryDialog(
                                                        order: order,
                                                        onConfirm: (data) async {
                                                          final success = await _controller.assignDelhivery(order['_id'], data: data);
                                                          if (!mounted) return;
                                                          if (success) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Delivery assigned successfully!'), backgroundColor: Colors.green),
                                                            );
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Failed to assign delivery'), backgroundColor: Colors.red),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    );
                                                  }
                                                : null,
                                            icon: Icon(
                                              Icons.local_shipping,
                                              size: 20,
                                              color: (status == 'Pending' || status == 'Processing')
                                                  ? Colors.blue.shade700
                                                  : Colors.grey.withOpacity(0.3),
                                            ),
                                            tooltip: 'Assign Delhivery',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          const SizedBox(width: 8),
                                          if (order['trackingUrl'] != null && order['trackingUrl'].toString().isNotEmpty)
                                            IconButton(
                                              icon: const Icon(Icons.open_in_new, size: 20, color: Colors.blue),
                                              tooltip: 'Track Package',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () async {
                                                final url = Uri.parse(order['trackingUrl']);
                                                try {
                                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                                } catch (e) {
                                                  debugPrint('Error launching URL: $e');
                                                }
                                              },
                                            ),
                                          const SizedBox(width: 8),
                                          PopupMenuButton<String>(
                                            tooltip: 'Update Status',
                                            enabled: order['status'].toString().toLowerCase() != 'delivered',
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Icon(Icons.more_horiz, size: 18, color: Colors.black),
                                            ),
                                            onSelected: (val) => _controller.updateOrderStatus(order['_id'], val),
                                            itemBuilder: (context) => ['Processing', 'Shipped', 'Delivered', 'Cancelled']
                                                .map((e) => PopupMenuItem(value: e, child: Text(e)))
                                                .toList(),
                                          ),
                                        ],
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.amber;
    final s = status.toUpperCase();
    if (s == 'SHIPPED' || s == 'OUT_FOR_DELIVERY') {
      color = Colors.blue;
    } else if (s == 'DELIVERED') color = Colors.green;
    else if (s == 'CANCELLED') color = Colors.red;
    else if (s == 'PROCESSING') color = Colors.indigo;
    else if (s == 'ESCALATED') color = Colors.deepOrange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;
  final VoidCallback onTap;
  final bool isSelected;

  const _StatCard({
    required this.label,
    required this.value,
    required this.dotColor,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      ),
    );
  }
}
