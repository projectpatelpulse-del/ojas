import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/widgets/sidebar_layout.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';
import 'package:ojas_vendor/core/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  List<dynamic> _topProducts = [];
  List<dynamic> _revenueTrend = [];
  List<dynamic> _ordersTrend = [];

  String _selectedDateRange = 'Last 30 days';
  String _selectedStatus = 'All';
  String _selectedProductId = 'All';
  List<dynamic> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchAnalytics();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await ApiService().dio.get('/vendor/products');
      if (response.statusCode == 200) {
        setState(() {
          _allProducts = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  Future<void> _fetchAnalytics() async {
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
      
      if (_selectedStatus != 'All') {
        params['status'] = _selectedStatus;
      }
      
      if (_selectedProductId != 'All') {
        params['productId'] = _selectedProductId;
      }

      final response = await ApiService().dio.get('/vendor/analytics', queryParameters: params);
      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _summary = data['summary'];
          _topProducts = data['topProducts'] ?? [];
          _revenueTrend = data['trends']?['revenue'] ?? [];
          _ordersTrend = data['trends']?['orders'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      activeRoute: '/analytics',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const VendorTopBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(32),
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
                              'Analytics',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Track your store performance and insights',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        _buildFilters(),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Summary Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.attach_money,
                            iconColor: Colors.green,
                            iconBgColor: Colors.green.shade50,
                            value: '₹${(_summary?['totalSales'] ?? 0).toStringAsFixed(2)}',
                            label: 'Revenue',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.shopping_cart_outlined,
                            iconColor: Colors.blue,
                            iconBgColor: Colors.blue.shade50,
                            value: (_summary?['totalOrders'] ?? 0).toString(),
                            label: 'Orders',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.people_outline,
                            iconColor: Colors.purple,
                            iconBgColor: Colors.purple.shade50,
                            value: (_summary?['totalCustomers'] ?? 0).toString(),
                            label: 'Customers',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.primary,
                            iconBgColor: const Color(0xFFFFF4EB),
                            value: (_summary?['totalProducts'] ?? 0).toString(),
                            label: 'Products',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Charts Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildChartPlaceholder(
                            title: 'Revenue by Day',
                            subtitle: 'Recent daily performance',
                            isCurrency: true,
                            trendData: _revenueTrend,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildChartPlaceholder(
                            title: 'Orders Trend',
                            subtitle: 'Daily order volume',
                            isCurrency: false,
                            trendData: _ordersTrend,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Top Performing Products Table
                    _buildTopProductsTable(),
                    const SizedBox(height: 24),

                    // Colored Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildColoredStatCard(
                            bgColor: const Color(0xFFEDFCF2),
                            textColor: const Color(0xFF16A34A),
                            title: 'Avg. Order Value',
                            value: '₹${(_summary?['avgOrderValue'] ?? 0).toStringAsFixed(2)}',
                            subtitle: 'Per order average',
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildColoredStatCard(
                            bgColor: const Color(0xFFEFFFFF),
                            textColor: const Color(0xFF2563EB),
                            title: 'Total Revenue',
                            value: '₹${(_summary?['totalSales'] ?? 0).toStringAsFixed(2)}',
                            subtitle: 'All time earnings',
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildColoredStatCard(
                            bgColor: const Color(0xFFFAF5FF),
                            textColor: const Color(0xFF9333EA),
                            title: 'Products Sold',
                            value: _topProducts.fold(0, (sum, p) => sum + (p['sales'] as int? ?? 0)).toString(),
                            subtitle: 'Units sold (top items)',
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

  Widget _buildFilters() {
    return Row(
      children: [
        // Date Range
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
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedDateRange = val);
                  _fetchAnalytics();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Status Filter
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
              value: _selectedStatus,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedStatus = val);
                  _fetchAnalytics();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Product Filter
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
              value: _selectedProductId,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: [
                DropdownMenuItem<String>(
                  value: 'All',
                  child: Text('All Products', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
                ),
                ..._allProducts.map((p) {
                  return DropdownMenuItem<String>(
                    value: p['_id'],
                    child: SizedBox(
                      width: 120, // Limit width so it doesn't break layout
                      child: Text(
                        p['name'] ?? 'Product',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedProductId = val);
                  _fetchAnalytics();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductsTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Top Performing Products',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade100),
                bottom: BorderSide(color: Colors.grey.shade100),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('PRODUCT', style: _columnHeaderStyle())),
                Expanded(flex: 1, child: Text('SALES', style: _columnHeaderStyle())),
                Expanded(flex: 1, child: Text('REVENUE', style: _columnHeaderStyle())),
                Expanded(flex: 1, child: Text('PRICE', style: _columnHeaderStyle())),
              ],
            ),
          ),
          if (_topProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('No data available')),
            )
          else
            ..._topProducts.map((p) => _buildProductRow(p)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProductRow(dynamic p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    image: p['image'] != null && p['image'].isNotEmpty
                        ? DecorationImage(image: NetworkImage(p['image']), fit: BoxFit.cover)
                        : null,
                  ),
                  child: p['image'] == null || p['image'].isEmpty ? const Icon(Icons.image_outlined, size: 20, color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] ?? 'N/A', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                      Text(p['title'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text(p['sales'].toString(), style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary))),
          Expanded(flex: 1, child: Text('₹${(p['revenue'] ?? 0).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green))),
          Expanded(flex: 1, child: Text('₹${(p['price'] ?? 0).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  TextStyle _columnHeaderStyle() {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade400,
      letterSpacing: 0.5,
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder({
    required String title,
    required String subtitle,
    required bool isCurrency,
    required List<dynamic> trendData,
  }) {
    if (trendData.isEmpty) {
      return Container(
        height: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(child: Text('No data available')),
      );
    }

    // Limit to last 15 days for clarity
    final displayData = trendData.length > 15 ? trendData.sublist(trendData.length - 15) : trendData;
    
    double maxVal = 0;
    for (var d in displayData) {
      final v = (d['value'] as num).toDouble();
      if (v > maxVal) maxVal = v;
    }
    // Add some padding to top of chart
    maxVal = maxVal == 0 ? 100 : maxVal * 1.2;

    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (displayData.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCurrency 
                      ? 'Total: ₹${displayData.fold(0.0, (sum, item) => sum + (item['value'] as num).toDouble()).toStringAsFixed(0)}'
                      : 'Total: ${displayData.fold(0.0, (sum, item) => sum + (item['value'] as num).toDouble()).toInt()}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = displayData[groupIndex]['date'] ?? '';
                      final value = rod.toY;
                      return BarTooltipItem(
                        '$date\n',
                        GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: isCurrency ? '₹${value.toStringAsFixed(2)}' : value.toInt().toString(),
                            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.normal),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= displayData.length) return const SizedBox();
                        
                        // Show labels for every 3rd bar if many bars, or all if few
                        if (displayData.length > 8 && index % 3 != 0 && index != displayData.length - 1) {
                          return const SizedBox();
                        }

                        final dateStr = displayData[index]['date'] ?? '';
                        String label = '';
                        try {
                          final date = DateTime.parse(dateStr);
                          label = DateFormat('dd MMM').format(date);
                        } catch (_) {
                          label = dateStr.length > 5 ? dateStr.substring(dateStr.length - 5) : dateStr;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label,
                            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        String label = '';
                        if (value >= 1000) {
                          label = '${(value / 1000).toStringAsFixed(1)}k';
                        } else {
                          label = value.toInt().toString();
                        }
                        return Text(
                          label,
                          style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: displayData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: (entry.value['value'] as num).toDouble(),
                        color: AppColors.primary,
                        width: displayData.length > 10 ? 12 : 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal,
                          color: Colors.grey.shade50,
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
    );
  }

  Widget _buildColoredStatCard({
    required Color bgColor,
    required Color textColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

