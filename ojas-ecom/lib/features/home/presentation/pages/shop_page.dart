import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/core/controllers/wishlist_controller.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';

import '../../../../core/services/session_service.dart';

class ShopPage extends StatefulWidget {
  final String? initialCategory;
  final String? initialSubCategory;
  final String? initialSearch;

  const ShopPage({
    super.key,
    this.initialCategory,
    this.initialSubCategory,
    this.initialSearch,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String _selectedCategory = 'All';
  String _selectedSubCategory = 'All';
  String _selectedBrand = 'All';
  String _selectedPrice = 'All';
  bool _inStockOnly = false;
  String _sortBy = 'Featured';
  String _searchQuery = '';
  final TextEditingController _searchTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialSubCategory != null) {
      _selectedSubCategory = widget.initialSubCategory!;
    }
    if (widget.initialSearch != null) {
      _searchQuery = widget.initialSearch!;
      _searchTextController.text = _searchQuery;
    }
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  List<dynamic> get _shopProducts {
    var list = HomeController.instance.shopProducts.toList();
    
    // 0. Filtering by Search Query
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final brand = (p['brand'] ?? '').toString().toLowerCase();
        final category = (p['category'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || brand.contains(query) || category.contains(query);
      }).toList();
    }
    
    // 1. Filtering by Category
    if (_selectedCategory != 'All') {
      list = list.where((p) => (p['category'] ?? '') == _selectedCategory).toList();
    }

    // 1.1 Filtering by SubCategory
    if (_selectedSubCategory != 'All') {
      list = list.where((p) => (p['subCategory'] ?? '') == _selectedSubCategory).toList();
    }

    // 2. Filtering by Brand
    if (_selectedBrand != 'All') {
      list = list.where((p) => (p['brand'] ?? '') == _selectedBrand).toList();
    }

    // 3. Filtering by Price
    if (_selectedPrice != 'All') {
      list = list.where((p) {
        final double price = (p['discountPrice'] != null && p['discountPrice'] > 0 
            ? p['discountPrice'] 
            : (p['price'] ?? 0)).toDouble();
            
        switch (_selectedPrice) {
          case 'Under ₹50':
            return price < 50;
          case '₹50 - ₹100':
            return price >= 50 && price <= 100;
          case '₹100 - ₹200':
            return price >= 100 && price <= 200;
          case '₹200+':
            return price > 200;
          default:
            return true;
        }
      }).toList();
    }

    // 4. In Stock Only
    if (_inStockOnly) {
      list = list.where((p) => (p['stock'] ?? 0) > 0).toList();
    }

    // 5. Sorting
    switch (_sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) {
          final double pa = (a['discountPrice'] != null && a['discountPrice'] > 0 ? a['discountPrice'] : (a['price'] ?? 0)).toDouble();
          final double pb = (b['discountPrice'] != null && b['discountPrice'] > 0 ? b['discountPrice'] : (b['price'] ?? 0)).toDouble();
          return pa.compareTo(pb);
        });
        break;
      case 'Price: High to Low':
        list.sort((a, b) {
          final double pa = (a['discountPrice'] != null && a['discountPrice'] > 0 ? a['discountPrice'] : (a['price'] ?? 0)).toDouble();
          final double pb = (b['discountPrice'] != null && b['discountPrice'] > 0 ? b['discountPrice'] : (b['price'] ?? 0)).toDouble();
          return pb.compareTo(pa);
        });
        break;
      case 'Featured':
      default:
        // Sort by ID (Newest first)
        list.sort((a, b) => (b['_id'] ?? '').toString().compareTo((a['_id'] ?? '').toString()));
        break;
    }
    
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) => OjasLayout(
        activeTitle: 'SHOP',
        child: Container(
          color: const Color(0xFFF8FAFC),
          child: CenteredContent(
            horizontalPadding: isMobile ? 16 : 40,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar - hidden on mobile
                  if (!isMobile) ...[
                    _buildSidebar(),
                    const SizedBox(width: 30),
                  ],
                  
                  // Main Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(isMobile),
                        const SizedBox(height: 20),
                        if (HomeController.instance.isLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator())),
                        if (!HomeController.instance.isLoading && _shopProducts.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(100),
                              child: Column(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 60, color: Color(0xFFCBD5E1)),
                                  const SizedBox(height: 16),
                                  Text('No products found', style: GoogleFonts.outfit(fontSize: 18, color: const Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ),
                        if (!HomeController.instance.isLoading && _shopProducts.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _shopProducts.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 2 : (isTablet ? 2 : 3),
                              crossAxisSpacing: isMobile ? 12 : 20,
                              mainAxisSpacing: isMobile ? 12 : 20,
                              mainAxisExtent: isMobile ? 380 : 420,
                            ),
                            itemBuilder: (context, index) {
                              return _ShopProductCard(product: _shopProducts[index]);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          isMobile 
            ? Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildFilterButton(),
                  _buildSortDropdown(),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_shopProducts.length} products found',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                  Row(
                    children: [
                      _buildSortDropdown(),
                      const SizedBox(width: 12),
                      _buildViewToggles(),
                    ],
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: SingleChildScrollView(child: _buildSidebar()),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list, size: 20, color: Color(0xFFF01B6B)),
          const SizedBox(width: 8),
          Text(
            'Filters',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFF01B6B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 8 : 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          isDense: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF64748B)),
          style: GoogleFonts.inter(
            fontSize: 13, 
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
          items: ['Featured', 'Price: Low to High', 'Price: High to Low'].map((v) {
            return DropdownMenuItem(
              value: v, 
              child: Text(v, style: GoogleFonts.inter(color: const Color(0xFF1E293B))),
            );
          }).toList(),
          onChanged: (v) => setState(() => _sortBy = v!),
        ),
      ),
    );
  }

  Widget _buildViewToggles() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF01B6B),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(Icons.grid_view, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(Icons.view_list, color: Colors.grey, size: 18),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sidebarTitle('Search Products'),
          const SizedBox(height: 12),
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchTextController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _sidebarTitle('Categories'),
          _radioGroup(
            ['All', ...HomeController.instance.categories.map((c) => (c['name'] ?? '').toString()).where((n) => n.isNotEmpty)], 
            _selectedCategory, 
            (v) {
              setState(() {
                _selectedCategory = v!;
                _selectedSubCategory = 'All'; // Reset subcategory when category changes
              });
            }
          ),
          
          if (_selectedCategory != 'All') ...[
            const SizedBox(height: 20),
            _sidebarTitle('Subcategories'),
            Builder(
              builder: (context) {
                final cat = HomeController.instance.categories.firstWhere(
                  (c) => c['name'] == _selectedCategory,
                  orElse: () => {},
                );
                final List<dynamic> subs = cat['subcategories'] ?? [];
                if (subs.isEmpty) return const SizedBox.shrink();
                
                return _radioGroup(
                  ['All', ...subs.map((s) => s['name'].toString())],
                  _selectedSubCategory,
                  (v) => setState(() => _selectedSubCategory = v!)
                );
              },
            ),
          ],
          
          const SizedBox(height: 24),
          _sidebarTitle('Brands'),
          _radioGroup(['All', 'Official Store', 'Premium'], _selectedBrand, (v) => setState(() => _selectedBrand = v!)),
          
          const SizedBox(height: 24),
          _sidebarTitle('Price Range'),
          _radioGroup(['All', 'Under ₹50', '₹50 - ₹100', '₹100 - ₹200', '₹200+'], _selectedPrice, (v) => setState(() => _selectedPrice = v!)),
          
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 20, height: 20,
                child: Checkbox(value: _inStockOnly, onChanged: (v) => setState(() => _inStockOnly = v!), activeColor: const Color(0xFFF01B6B)),
              ),
              const SizedBox(width: 12),
              Text('In Stock Only', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sidebarTitle(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)));
  }

  Widget _radioGroup(List<String> options, String currentValue, ValueChanged<String?> onChanged) {
    return Column(
      children: options.map((option) {
        return InkWell(
          onTap: () => onChanged(option),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 16, height: 16,
                  child: Radio<String>(
                    value: option,
                    groupValue: currentValue,
                    onChanged: onChanged,
                    activeColor: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(option, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _ratingGroup(List<String> options, String currentValue, ValueChanged<String?> onChanged) {
    return Column(
      children: [
        // First is "All ratings"
        InkWell(
          onTap: () => onChanged(options[0]),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 16, height: 16,
                  child: Radio<String>(value: options[0], groupValue: currentValue, onChanged: onChanged, activeColor: Colors.blueAccent),
                ),
                const SizedBox(width: 12),
                Text(options[0], style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
              ],
            ),
          ),
        ),
        // Rest are stars
        for (int i = 1; i < options.length; i++)
          InkWell(
            onTap: () => onChanged(options[i]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: Radio<String>(value: options[i], groupValue: currentValue, onChanged: onChanged, activeColor: Colors.blueAccent),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: List.generate(5, (index) {
                      int startsCount = 5 - i;
                      return Icon(
                        index < startsCount ? Icons.star : Icons.star_border,
                        size: 14,
                        color: index < startsCount ? Colors.amber : Colors.grey.shade400,
                      );
                    }),
                  ),
                  const SizedBox(width: 6),
                  Text('& up', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ShopProductCard extends StatelessWidget {
  final dynamic product;

  const _ShopProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final String id = product['_id'] ?? '';
    final String name = product['name'] ?? 'Product';
    final String vendor = product['brand'] ?? 'Official Store';
    final double price = (product['discountPrice'] != null && product['discountPrice'] > 0 
        ? product['discountPrice'] 
        : (product['price'] ?? 0)).toDouble();
    final double oldPrice = (product['price'] ?? 0).toDouble();
    final int discount = oldPrice > 0 && oldPrice > price ? (((oldPrice - price) / oldPrice) * 100).toInt() : 0;
    final String imageUrl = product['image'] ?? 'https://via.placeholder.com/300';

    return ListenableBuilder(
      listenable: WishlistController.instance,
      builder: (context, _) {
        final bool isWishlisted = WishlistController.instance.isWishlisted(id);
        
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/product-detail?id=$id', arguments: ProductModel.fromMap(product)),
          child: Container(
            decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: const Offset(0, 4),
                blurRadius: 12,
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Box
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Color(0xFFCBD5E1))),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Discount Badge
                    if (discount > 0)
                      Positioned(
                        top: 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$discount% OFF',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    // Wishlist Button
                    Positioned(
                      top: 10, right: 10,
                      child: _actionButton(
                        isWishlisted ? Icons.favorite : Icons.favorite_border, 
                        () => WishlistController.instance.toggleWishlist(product),
                        color: isWishlisted ? const Color(0xFFF01B6B) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                       style: GoogleFonts.outfit(
                        fontSize: isMobile ? 13 : 15, 
                        fontWeight: FontWeight.bold, 
                        color: const Color(0xFF0F172A), 
                        height: 1.2
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '₹${price.ceil()}',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFFF01B6B)),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₹${oldPrice.ceil()}',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 13,
                          color: (product['stock'] ?? 0) > 0 ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (product['stock'] ?? 0) > 0 ? 'In Stock': 'Out of Stock',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (product['stock'] ?? 0) > 0 ? Colors.green.shade600 : Colors.red.shade600,
                          ),
                        ),
                        if ((product['moq'] ?? 1) > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            // padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              'MOQ: ${product['moq']}',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                  
                      ],
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final String? token = SessionService.instance.token;
                          if (token == null) {
                            final int moq = product['moq'] ?? 1;
                            CartController.instance.setPendingItem(id, moq);
                            Navigator.pushNamed(context, '/login');
                            return;
                          }

                          final int moq = product['moq'] ?? 1;
                          final success = await CartController.instance.addToCart(id, moq: moq);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? '$name added to cart' : 'Failed to add to cart. Please login first.'),
                                backgroundColor: success ? Colors.green : Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                margin: const EdgeInsets.all(20),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 13),
                        label: Text(
                          'Add to Cart',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
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
}

  Widget _actionButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x1A000000), offset: Offset(0, 2), blurRadius: 4)],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Icon(icon, size: 14, color: color ?? const Color(0xFF475569)),
      ),
    );
  }

