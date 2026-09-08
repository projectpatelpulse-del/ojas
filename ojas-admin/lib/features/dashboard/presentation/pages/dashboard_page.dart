import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/admin_layout.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import 'package:ojas_admin/features/dashboard/data/services/dashboard_service.dart';

class DashboardPage extends StatefulWidget {
  final String currentRoute;
  const DashboardPage({super.key, this.currentRoute = '/admin-overview'});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final data = await sl<DashboardService>().getStats();
    setState(() {
      _stats = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AdminLayout(
        currentRoute: widget.currentRoute,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    final summary = _stats['summary'] ?? {};
    final trendingProducts = _stats['trendingProducts'] as List? ?? [];
    final topVendors = _stats['topVendors'] as List? ?? [];
    final latestCategories = _stats['latestCategories'] as List? ?? [];
    final latestSubcategories = _stats['latestSubcategories'] as List? ?? [];

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
                Text('Custom Dashboard', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Overview of platform performance and key metrics',
                      style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                    ),
                    const SizedBox(height: 28),

                    // Top Stats Cards
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Total Revenue', '₹${summary['totalRevenue'] ?? 0}', summary['revenueChange'] ?? 0.0, Icons.attach_money, Colors.green)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatCard('Total Orders', '${summary['totalOrders'] ?? 0}', summary['ordersChange'] ?? 0.0, Icons.shopping_cart_outlined, Colors.blue)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatCard('Active Vendors', '${summary['activeVendors'] ?? 0}', summary['vendorsChange'] ?? 0.0, Icons.storefront_outlined, Colors.purple)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatCard('Total Customers', '${summary['totalCustomers'] ?? 0}', summary['customersChange'] ?? 0.0, Icons.group_outlined, Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Row 1: Charts
                    Row(
                      children: [
                        Expanded(child: _buildChartCard('Weekly Revenue', 'Last 7 days revenue trends', Icons.bar_chart, Colors.purple, _buildBarChart(_stats['charts']?['weeklyRevenue']))),
                        const SizedBox(width: 20),
                        Expanded(child: _buildChartCard('Sales Trend', 'Monthly growth analysis', Icons.trending_up, Colors.green, _buildLineChart(_stats['charts']?['monthlyRevenue']))),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Row 2: Products & Vendors
                    Row(
                      children: [
                        Expanded(child: _buildListCard('Trending Products', 'Configured trending items', Icons.widgets_outlined, Colors.blue, trendingProducts, (item) => '${item['name']}', (item) => 'Stock: ${item['count'] ?? 0} | Price: ₹${item['price'] ?? 0}', imageFn: (item) => item['image'])),
                        const SizedBox(width: 20),
                        Expanded(child: _buildListCard('Top Revenue Vendors', 'Highest earning sellers', Icons.store_outlined, Colors.purple, topVendors, (item) => '${item['businessName']}', (item) => 'Revenue: ₹${item['revenue']}', imageFn: (item) => item['photo'])),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Row 3: Categories & Subcategories
                    Row(
                      children: [
                        Expanded(child: _buildListCard('Recent Categories', 'Latest product categories', Icons.category_outlined, Colors.purple, latestCategories, (item) => '${item['name']}', (item) => 'Status: ${item['status']}', imageFn: (item) => item['image'])),
                        const SizedBox(width: 20),
                        Expanded(child: _buildListCard('Recent Subcategories', 'Latest sub-divisions', Icons.account_tree_outlined, Colors.blue, latestSubcategories, (item) => '${item['name']}', (item) => 'Status: ${item['status']}')),
                      ],
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

  Widget _buildStatCard(String title, String value, num percentage, IconData icon, MaterialColor color) {
    final isPositive = percentage >= 0;
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
              Text(title, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color.shade400, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.north_east : Icons.south_east, 
                  color: isPositive ? Colors.green : Colors.red, 
                  size: 14),
              Text(
                ' ${percentage.abs()}% ',
                style: GoogleFonts.inter(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'vs last month',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, String subtitle, IconData icon, MaterialColor color, Widget content) {
    return Container(
      height: 350,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
              Icon(icon, color: color.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, String subtitle, IconData icon, MaterialColor color, List items, String Function(dynamic) titleFn, String Function(dynamic) subFn, {String? Function(dynamic)? imageFn}) {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                  Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color.shade400, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No data available', style: GoogleFonts.inter(color: Colors.grey.shade400)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final imageUrl = imageFn?.call(item);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 44,
                                height: 44,
                                color: color.shade100,
                                child: Icon(Icons.image_not_supported_outlined, color: color.shade300, size: 20),
                              ),
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: color.shade100,
                            child: Text(
                              titleFn(item).substring(0, 1).toUpperCase(), 
                              style: TextStyle(color: color.shade700, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleFn(item), 
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B), fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(subFn(item), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade300),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List? data) {
    if (data == null || data.isEmpty) {
      return Center(child: Text('No recent orders', style: GoogleFonts.inter(color: Colors.grey.shade400)));
    }

    double maxRevenue = 0;
    for (var item in data) {
      double rev = (item['revenue'] ?? 0).toDouble();
      if (rev > maxRevenue) maxRevenue = rev;
    }
    if (maxRevenue == 0) maxRevenue = 1000;

    return Stack(
      children: [
        // Background Gridlines
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) => Container(
            height: 1,
            color: Colors.grey.shade100,
          )),
        ),
        // Chart Bars
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final revenue = (item['revenue'] ?? 0).toDouble();
              final date = item['_id']?.toString().split('-').last ?? '';
              final barHeight = (revenue / maxRevenue * 160).clamp(8.0, 160.0);
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '₹${(revenue >= 1000 ? (revenue/1000).toStringAsFixed(1) + 'k' : revenue.toStringAsFixed(0))}', 
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.2), 
                          blurRadius: 6, 
                          offset: const Offset(0, 3)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date, 
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List? data) {
    if (data == null || data.isEmpty) {
      return Center(child: Text('No historical data', style: GoogleFonts.inter(color: Colors.grey.shade400)));
    }

    final doubleMaxList = data.map((item) => (item['revenue'] ?? 0).toDouble()).toList().cast<double>();
    final labelsList = data.map((item) => item['_id']?.toString().split('-').last ?? '').toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight - 30),
                painter: SmoothLineChartPainter(doubleMaxList, labelsList),
              ),
            ),
            const SizedBox(height: 8),
            // Month Labels below painter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labelsList.map((m) => Expanded(
                child: Text(
                  m, 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
              )).toList(),
            ),
          ],
        );
      }
    );
  }
}

// Premium Bezier line chart painter with gradients & gridlines
class SmoothLineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;

  SmoothLineChartPainter(this.dataPoints, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;
    
    final gridLines = 4;
    for (int i = 0; i < gridLines; i++) {
      final y = size.height * (i / (gridLines - 1));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    final range = maxVal > 0 ? maxVal : 1.0;

    final path = Path();
    final fillPath = Path();

    // Horizontal step size
    final double stepX = dataPoints.length > 1 
        ? size.width / (dataPoints.length - 1) 
        : size.width;

    // Build the curve coordinates
    final List<Offset> points = [];
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      // Leave 15px padding at top and 10px at bottom of paint height
      final y = 15 + (size.height - 25) - (dataPoints[i] / range * (size.height - 25));
      points.add(Offset(x, y));
    }

    // Draw smooth Bezier curve
    if (points.length == 1) {
      path.moveTo(0, points[0].dy);
      path.lineTo(size.width, points[0].dy);
      fillPath.moveTo(0, size.height);
      fillPath.lineTo(0, points[0].dy);
      fillPath.lineTo(size.width, points[0].dy);
      fillPath.lineTo(size.width, size.height);
    } else {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }
      fillPath.lineTo(points.last.dx, size.height);
    }
    fillPath.close();

    // Draw Gradient Fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF10B981).withOpacity(0.25),
          const Color(0xFF10B981).withOpacity(0.00),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw Main Line
    final linePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw point circles and values
    final pointPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final val = dataPoints[i];

      // Draw shadow circle
      canvas.drawCircle(p, 7, shadowPaint);
      // Draw white outline circle
      canvas.drawCircle(p, 6.5, whitePaint);
      // Draw center active green circle
      canvas.drawCircle(p, 4.5, pointPaint);

      // Draw text label on top of point
      final textSpan = TextSpan(
        text: '₹${val >= 1000 ? (val/1000).toStringAsFixed(1) + 'k' : val.toStringAsFixed(0)}',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF047857),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(p.dx - textPainter.width / 2, p.dy - 24),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
