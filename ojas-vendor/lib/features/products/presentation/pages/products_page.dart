import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/widgets/sidebar_layout.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';
import 'package:ojas_vendor/core/services/service_locator.dart';
import 'package:ojas_vendor/features/products/data/services/product_service.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchProducts();
  }

  int _activeCount = 0;
  int _lowStockCount = 0;

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await sl<ProductService>().getProducts();
      int active = 0;
      int lowStock = 0;
      
      for (var p in products) {
        final status = p['status'] ?? 'Draft';
        if (status == 'Active' || status == 'Published') active++;
        final threshold = p['lowStockThreshold'] ?? 5;
        if ((p['stock'] ?? 0) <= threshold) lowStock++;
      }

      setState(() {
        _products = products;
        _activeCount = active;
        _lowStockCount = lowStock;
        _onSearchChanged();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch products: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await sl<ProductService>().deleteProduct(id);
      _fetchProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredProducts = _products.where((product) {
        final status = (product['status'] ?? '').toString();
        final stock = product['stock'] ?? 0;
        final threshold = product['lowStockThreshold'] ?? 5;

        bool matchesFilter = true;
        if (_selectedFilter == 'Active') {
          matchesFilter = (status == 'Active' || status == 'Published');
        } else if (_selectedFilter == 'Inactive') {
          matchesFilter = (status == 'Archived' || status == 'Inactive');
        } else if (_selectedFilter == 'Draft') {
          matchesFilter = (status == 'Draft');
        } else if (_selectedFilter == 'Low Stock') {
          matchesFilter = (stock <= threshold);
        }

        if (!matchesFilter) return false;

        final name = (product['name'] ?? '').toString().toLowerCase();
        final category = (product['category'] ?? '').toString().toLowerCase();
        final sku = (product['sku'] ?? '').toString().toLowerCase();
        return name.contains(query) || category.contains(query) || sku.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      activeRoute: '/products',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const VendorTopBar(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Page Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your product inventory. ${_products.length} total products.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/products/add'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Add Product',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Products',
                      value: _products.length.toString(),
                      valueColor: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StatCard(
                      label: 'Active Products',
                      value: _activeCount.toString(),
                      valueColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StatCard(
                      label: 'Low Stock',
                      value: _lowStockCount.toString(),
                      valueColor: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Search + View Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // Search Field
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // View Toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _viewToggleBtn(
                            icon: Icons.grid_view_rounded,
                            isActive: _isGridView,
                            onTap: () => setState(() => _isGridView = true),
                            isLeft: true,
                          ),
                          _viewToggleBtn(
                            icon: Icons.menu,
                            isActive: !_isGridView,
                            onTap: () => setState(() => _isGridView = false),
                            isLeft: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 12),

              // Product List/Grid Area
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (_filteredProducts.isEmpty)
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
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
                            _searchController.text.isNotEmpty ? Icons.search_off_outlined : Icons.inventory_2_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty ? 'No products match your search' : 'No products found',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_searchController.text.isEmpty) ...[
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => context.go('/products/add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Add Your First Product',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                _isGridView ? _buildGridView() : _buildListView(),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _viewToggleBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(7) : Radius.zero,
            right: !isLeft ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    int allCount = _products.length;
    int activeCount = _products.where((p) => p['status'] == 'Active' || p['status'] == 'Published').length;
    int inactiveCount = _products.where((p) => p['status'] == 'Archived' || p['status'] == 'Inactive').length;
    int draftCount = _products.where((p) => p['status'] == 'Draft').length;
    int lowStockCount = _products.where((p) => (p['stock'] ?? 0) <= (p['lowStockThreshold'] ?? 5)).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('All', allCount),
          const SizedBox(width: 10),
          _filterChip('Active', activeCount),
          const SizedBox(width: 10),
          _filterChip('Inactive', inactiveCount),
          const SizedBox(width: 10),
          _filterChip('Draft', draftCount),
          const SizedBox(width: 10),
          _filterChip('Low Stock', lowStockCount),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(
        "$label ($count)",
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
            _onSearchChanged();
          });
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: 1,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return GestureDetector(
          onTap: () => context.go('/products/add', extra: product),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: product['image'] != null && product['image'].isNotEmpty
                            ? Image.network(
                                product['image'],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey.shade100,
                                  child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 40),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade100,
                                child: Icon(Icons.image_outlined, color: Colors.grey.shade300, size: 40),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              radius: 14,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                                onPressed: () => context.go('/products/add', extra: product),
                              ),
                            ),
                            const SizedBox(width: 4),
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              radius: 14,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                onPressed: () => _showDeleteDialog(product['_id']),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${product['price']}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (product['status'] == 'Active' || product['status'] == 'Published' ? Colors.green : Colors.grey).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product['status'] ?? 'Active',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: product['status'] == 'Active' || product['status'] == 'Published' ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 12,
                                color: (product['stock'] ?? 0) < 30 ? Colors.red : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${product['stock'] ?? 0}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: (product['stock'] ?? 0) < 30 ? Colors.red : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildListView() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 20,
                horizontalMargin: 20,
                showCheckboxColumn: false,
                columns: [
                  const DataColumn(label: Text('Product')),
                  const DataColumn(label: Text('Category')),
                  const DataColumn(label: Text('Stock')),
                  const DataColumn(label: Text('Price')),
                  const DataColumn(label: Text('Status')),
                  const DataColumn(label: Text('Action')),
                ],
                rows: _filteredProducts.map((product) {
                  final int stock = product['stock'] ?? 0;
                  final bool isLowStock = stock < 30;
                  final List variations = product['variations'] ?? [];

                  return DataRow(
                    onSelectChanged: (selected) {
                      if (selected != null) context.go('/products/add', extra: product);
                    },
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: product['image'] != null && product['image'].isNotEmpty
                                  ? Image.network(
                                      product['image'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.grey.shade100,
                                        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 20),
                                      ),
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey.shade100,
                                      child: Icon(Icons.image_outlined, color: Colors.grey.shade300, size: 20),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (variations.isNotEmpty)
                                  Text(
                                    '${variations.length} Variations',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(product['category'] ?? 'N/A', style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stock.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isLowStock ? Colors.red : AppColors.textPrimary,
                                )),
                            if (isLowStock)
                              Text('Low Stock', style: GoogleFonts.inter(fontSize: 10, color: Colors.red)),
                          ],
                        ),
                      ),
                      DataCell(Text('₹${product['price']}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (product['status'] == 'Active' || product['status'] == 'Published' ? Colors.green : Colors.grey).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product['status'] ?? 'Draft',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: product['status'] == 'Active' || product['status'] == 'Published' ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                              onPressed: () => context.go('/products/add', extra: product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _showDeleteDialog(product['_id']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
