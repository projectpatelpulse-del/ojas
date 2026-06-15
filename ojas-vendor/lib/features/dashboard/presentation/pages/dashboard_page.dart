import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/widgets/sidebar_layout.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';

import 'package:ojas_vendor/core/services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  int _totalOrders = 0;
  double _totalSales = 0.0;
  int _totalProducts = 0;
  int _totalCustomers = 0;
  List<dynamic> _recentOrders = [];
  String _selectedDateRange = 'Last 30 days';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate;
      
      if (_selectedDateRange == 'Today') {
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
      } else if (_selectedDateRange == 'Last 7 days') {
        startDate = endDate.subtract(const Duration(days: 7));
      } else if (_selectedDateRange == 'Last Year') {
        startDate = endDate.subtract(const Duration(days: 365));
      } else {
        startDate = endDate.subtract(const Duration(days: 30));
      }

      final Map<String, dynamic> params = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final response = await ApiService().dio.get('/vendor/dashboard', queryParameters: params);
      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _totalSales = (data['totalSales'] ?? 0).toDouble();
          _totalOrders = data['totalOrders'] ?? 0;
          _totalProducts = data['totalProducts'] ?? 0;
          _totalCustomers = data['totalCustomers'] ?? 0;
          _recentOrders = data['recentOrders'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      activeRoute: '/',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const VendorTopBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Navigate your store with ppv',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDateRange,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        items: ['Today', 'Last 7 days', 'Last 30 days', 'Last Year'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDateRange = val);
                            _fetchDashboardData();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Top Stats Row
              if (_isLoading) 
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(child: _StatCard(title: 'Total Sales', value: '₹${_totalSales.toStringAsFixed(2)}', icon: Icons.attach_money, iconColor: Colors.green, iconBg: const Color(0xFFE8F5E9))),
                    const SizedBox(width: 24),
                    Expanded(child: _StatCard(title: 'Orders', value: _totalOrders.toString(), icon: Icons.shopping_cart_outlined, iconColor: Colors.blue, iconBg: const Color(0xFFE3F2FD))),
                    const SizedBox(width: 24),
                    Expanded(child: _StatCard(title: 'Products', value: _totalProducts.toString(), icon: Icons.inventory_2_outlined, iconColor: Colors.purple, iconBg: const Color(0xFFF3E5F5))),
                    const SizedBox(width: 24),
                    Expanded(child: _StatCard(title: 'Customers', value: _totalCustomers.toString(), icon: Icons.people_outline, iconColor: Colors.orange, iconBg: const Color(0xFFFFF3E0))),
                  ],
                ),
              
              const SizedBox(height: 24),
              
              // Middle Section: Recent Orders & Sales Statistics
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Orders Table
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                              Text(
                                'Recent Orders',
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              InkWell(
                                onTap: () => context.go('/orders'),
                                child: Text(
                                  'View All',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Table Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _th('Order ID'),
                              _th('Customer'),
                              _th('Product'),
                              _th('Amount'),
                              _th('Status'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_recentOrders.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text("No recent orders found.")),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentOrders.length,
                              itemBuilder: (context, index) {
                                final order = _recentOrders[index];
                                final amount = order['totalAmount'] ?? 0;
                                final status = order['status'] ?? 'Pending';
                                final orderId = order['orderId'] ?? order['_id'].toString().substring(0, 8);
                                final customerName = order['user'] != null ? order['user']['name'] : 'Unknown';
                                final itemsCount = (order['items'] as List?)?.length ?? 1;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(orderId, style: GoogleFonts.inter(fontSize: 12))),
                                      Expanded(child: Text(customerName, style: GoogleFonts.inter(fontSize: 12))),
                                      Expanded(child: Text('$itemsCount items', style: GoogleFonts.inter(fontSize: 12))),
                                      Expanded(child: Text('₹${amount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(status, style: GoogleFonts.inter(fontSize: 10, color: Colors.blue.shade700)),
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
                  ),
                  const SizedBox(width: 24),
                  
                  // Sales Statistics Donut Chart
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales Statistics',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 32),
                          // Placeholder for real Donut Chart
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFFFEBEE), width: 16),
                                  ),
                                ),
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border(top: BorderSide(color: Color(0xFF4CAF50), width: 16)),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text('Total', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                                    Text('${_totalOrders + _totalProducts + _totalCustomers}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _legendItem(Colors.orange, 'Orders', _totalOrders.toString()),
                          _legendItem(Colors.purple, 'Products', _totalProducts.toString()),
                          _legendItem(Colors.green, 'Customers', _totalCustomers.toString()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              // Trends Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTrendCard('Revenue Trend', '₹${_totalSales.toStringAsFixed(2)}', 'Total Revenue', AppColors.primary),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildTrendCard('Orders Trend', _totalOrders.toString(), 'Total Orders', Colors.blue),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions Row
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'Add Product',
                      'Add new products to your store',
                      Icons.inventory_2_outlined,
                      const Color(0xFFE8EAF6),
                      Colors.indigo,
                      Colors.indigoAccent,
                      'Add Product',
                      onPressed: () => context.go('/products/add'),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildActionCard(
                      'View Analytics',
                      'Check your store performance',
                      Icons.trending_up,
                      const Color(0xFFE8F5E9),
                      Colors.green,
                      Colors.green,
                      'View Analytics',
                      onPressed: () => context.go('/analytics'),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildActionCard(
                      'Manage Orders',
                      'Process pending orders',
                      Icons.shopping_cart_outlined,
                      const Color(0xFFF3E5F5),
                      Colors.purple,
                      Colors.purpleAccent,
                      'Manage Orders',
                      onPressed: () => context.go('/orders'),
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

  Widget _th(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
    );
  }

  Widget _legendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Last 7 days', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          // Placeholder for the Line Chart (using empty container with axis labels for now to match screenshot)
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (_) => Text('0', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 2,
                            width: double.infinity,
                            color: color,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (_) => Transform.translate(
                                offset: const Offset(0, -4),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: color, width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => 
                          Text(day, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400))
                        ).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color iconBg, Color iconColor, Color btnColor, String btnText, {required VoidCallback onPressed}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(btnText, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
