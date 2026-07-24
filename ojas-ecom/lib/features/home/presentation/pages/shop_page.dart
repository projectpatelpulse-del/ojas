import 'package:ojas_user/core/constants/app_colors.dart';
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

  int _currentPage = 1;
  int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
      _resolveInitialCategory();
    }
    if (widget.initialSubCategory != null) {
      _selectedSubCategory = widget.initialSubCategory!;
      _resolveInitialSubCategory();
    }
    if (widget.initialSearch != null) {
      _searchQuery = widget.initialSearch!;
      _searchTextController.text = _searchQuery;
    }
  }

  void _resolveInitialCategory() {
    final initial = widget.initialCategory;
    if (initial == null || initial == 'All') return;
    
    final categories = HomeController.instance.categories;
    final initialLower = initial.toLowerCase();
    
    for (final cat in categories) {
      final String catName = (cat['name'] ?? '').toString();
      final catLower = catName.toLowerCase();
      
      if (catLower == initialLower || 
          catLower.contains(initialLower) || 
          initialLower.contains(catLower) ||
          (catLower.split(' ')[0].length > 2 && catLower.split(' ')[0] == initialLower.split(' ')[0])) {
        _selectedCategory = catName;
        break;
      }
    }
  }

  void _resolveInitialSubCategory() {
    final initialSub = widget.initialSubCategory;
    if (initialSub == null || initialSub == 'All') return;
    
    final cat = HomeController.instance.categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => null,
    );
    if (cat == null) return;
    
    final List<dynamic> subs = cat['subcategories'] ?? [];
    final initialSubLower = initialSub.toLowerCase();
    
    for (final sub in subs) {
      final String subName = (sub['name'] ?? '').toString();
      final subLower = subName.toLowerCase();
      
      if (subLower == initialSubLower ||
          subLower.contains(initialSubLower) ||
          initialSubLower.contains(subLower) ||
          (subLower.split(' ')[0].length > 2 && subLower.split(' ')[0] == initialSubLower.split(' ')[0])) {
        _selectedSubCategory = subName;
        break;
      }
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
      final words = _searchQuery.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.isNotEmpty) {
        list = list.where((p) {
          final name = (p['name'] ?? '').toString().toLowerCase();
          final brand = (p['brand'] ?? '').toString().toLowerCase();
          
          final categoryObj = p['category'];
          String category = '';
          if (categoryObj is Map) {
            category = (categoryObj['name'] ?? '').toString().toLowerCase();
          } else if (categoryObj is String) {
            category = categoryObj.toLowerCase();
          }

          // Match if every search word is found in either name, brand, or category
          return words.every((word) =>
              name.contains(word) ||
              brand.contains(word) ||
              category.contains(word));
        }).toList();
      }
    }
    
    // 1. Filtering by Category
    if (_selectedCategory != 'All') {
      list = list.where((p) {
        final category = p['category'];
        String? catName;
        if (category is Map) {
          catName = category['name']?.toString();
        } else if (category is String) {
          catName = category;
        }
        if (p['categoryName'] != null) {
          catName = p['categoryName'].toString();
        }

        if (catName == null) return false;
        
        final selectedLower = _selectedCategory.toLowerCase();
        final catLower = catName.toLowerCase();
        
        if (selectedLower == catLower) return true;
        
        // Also check if they map to the same category object in HomeController.instance.categories
        final matchedSelectedCat = HomeController.instance.categories.firstWhere(
          (c) => (c['name'] ?? '').toString().toLowerCase() == selectedLower,
          orElse: () => null,
        );
        final matchedProductCat = HomeController.instance.categories.firstWhere(
          (c) => c['_id'] == catLower || c['id'] == catLower || (c['name'] ?? '').toString().toLowerCase() == catLower,
          orElse: () => null,
        );
        if (matchedSelectedCat != null && matchedProductCat != null) {
          if (matchedSelectedCat['_id'] == matchedProductCat['_id']) return true;
        }

        final firstWordSelected = selectedLower.split(' ')[0];
        final firstWordProduct = catLower.split(' ')[0];
        if (firstWordSelected.length > 2 && firstWordProduct.length > 2) {
          if (firstWordSelected == firstWordProduct) return true;
        }

        return catLower.contains(selectedLower) || selectedLower.contains(catLower);
      }).toList();
    }

    // 1.1 Filtering by SubCategory
    if (_selectedSubCategory != 'All') {
      list = list.where((p) {
        final subCategory = p['subCategory'];
        String? subCatName;
        if (subCategory is Map) {
          subCatName = subCategory['name']?.toString();
        } else if (subCategory is String) {
          subCatName = subCategory;
        }
        
        if (subCatName == null) return false;

        final selectedLower = _selectedSubCategory.toLowerCase();
        final subCatLower = subCatName.toLowerCase();

        if (selectedLower == subCatLower) return true;

        final firstWordSelected = selectedLower.split(' ')[0];
        final firstWordSubCat = subCatLower.split(' ')[0];
        if (firstWordSelected.length > 2 && firstWordSubCat.length > 2) {
          if (firstWordSelected == firstWordSubCat) return true;
        }

        return subCatLower.contains(selectedLower) || selectedLower.contains(subCatLower);
      }).toList();
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
          case '₹0 - ₹200':
            return price >= 0 && price <= 200;
          case '₹200 - ₹500':
            return price >= 200 && price <= 500;
          case '₹500 - ₹1000':
            return price >= 500 && price <= 1000;
          case '₹1000+':
            return price > 1000;
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

  int get _totalPages => (_shopProducts.length / _pageSize).ceil();

  List<dynamic> get _paginatedProducts {
    final fullList = _shopProducts;
    final total = _totalPages;
    if (_currentPage > total && total > 0) {
      _currentPage = total;
    }
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= fullList.length || startIndex < 0) return [];
    final endIndex = (startIndex + _pageSize).clamp(0, fullList.length);
    return fullList.sublist(startIndex, endIndex);
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
                        if (!HomeController.instance.isLoading && _shopProducts.isNotEmpty) ...[
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _paginatedProducts.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 2 : (isTablet ? 2 : 3),
                              crossAxisSpacing: isMobile ? 12 : 20,
                              mainAxisSpacing: isMobile ? 12 : 20,
                              mainAxisExtent: isMobile ? 380 : 420,
                            ),
                            itemBuilder: (context, index) {
                              return _ShopProductCard(product: _paginatedProducts[index]);
                            },
                          ),
                          _buildPaginationControls(),
                        ],
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

  Widget _buildPaginationControls() {
    final total = _totalPages;
    if (total <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                'Page $_currentPage of $total',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous Button
                IconButton(
                  onPressed: _currentPage > 1 
                      ? () => setState(() => _currentPage--) 
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                
                // Page Numbers
                ...List.generate(total, (index) {
                  final page = index + 1;
                  final isCurrent = page == _currentPage;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _currentPage = page),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrent ? AppColors.primaryPink : Colors.white,
                        foregroundColor: isCurrent ? Colors.white : const Color(0xFF475569),
                        elevation: 0,
                        side: BorderSide(color: isCurrent ? Colors.transparent : const Color(0xFFCBD5E1)),
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('$page', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),

                // Next Button
                IconButton(
                  onPressed: _currentPage < total 
                      ? () => setState(() => _currentPage++) 
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageSizeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 8 : 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _pageSize,
          isDense: true,
          dropdownColor: AppColors.white,
          icon: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
          style: GoogleFonts.inter(
            fontSize: 13, 
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
          items: [20, 50, 100].map((v) {
            return DropdownMenuItem(
              value: v, 
              child: Text('Show $v', style: GoogleFonts.inter(color: const Color(0xFF1E293B))),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _pageSize = v;
                _currentPage = 1;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
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
                  _buildPageSizeDropdown(),
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
                      _buildPageSizeDropdown(),
                      const SizedBox(width: 12),
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
            color: AppColors.white,
            child: SingleChildScrollView(child: _buildSidebar()),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list, size: 20, color: AppColors.primaryPink),
          const SizedBox(width: 8),
          Text(
            'Filters',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryPink),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 8 : 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          isDense: true,
          dropdownColor: AppColors.white,
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
          onChanged: (v) => setState(() {
            _sortBy = v!;
            _currentPage = 1;
          }),
        ),
      ),
    );
  }

  Widget _buildViewToggles() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryPink,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(Icons.grid_view, color: AppColors.white, size: 18),
        ),
        const SizedBox(width: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(Icons.view_list, color: AppColors.grey, size: 18),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.white,
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
                const Icon(Icons.search, size: 18, color: AppColors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchTextController,
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _currentPage = 1;
                    }),
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.black),
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
                _currentPage = 1;
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
                  (v) => setState(() {
                    _selectedSubCategory = v!;
                    _currentPage = 1;
                  })
                );
              },
            ),
          ],
          
          const SizedBox(height: 24),
          _sidebarTitle('Price Range'),
          _radioGroup(['All', '₹0 - ₹200', '₹200 - ₹500', '₹500 - ₹1000', '₹1000+'], _selectedPrice, (v) => setState(() {
            _selectedPrice = v!;
            _currentPage = 1;
          })),
          
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 20, height: 20,
                child: Checkbox(value: _inStockOnly, onChanged: (v) => setState(() {
                  _inStockOnly = v!;
                  _currentPage = 1;
                }), activeColor: AppColors.primaryPink),
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
                        color: index < startsCount ? Colors.amber : AppColors.grey400,
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
    // final String vendor = product['brand'] ?? 'Official Store';
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
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.03),
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
                      color: AppColors.white,
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
                            style: GoogleFonts.inter(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    // Wishlist Button
                    Positioned(
                      top: 10, right: 10,
                      child: _actionButton(
                        isWishlisted ? Icons.favorite : Icons.favorite_border, 
                        () => WishlistController.instance.toggleWishlist(product),
                        color: isWishlisted ? AppColors.primaryPink : const Color(0xFF475569),
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
                    // Text(
                    //   vendor,
                    //   style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    // ),
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
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryPink),
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
                          color: (product['stock'] ?? 0) > 0 ? AppColors.green600 : AppColors.red600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (product['stock'] ?? 0) > 0 ? 'In Stock': 'Out of Stock',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (product['stock'] ?? 0) > 0 ? AppColors.green600 : AppColors.red600,
                          ),
                        ),
                        if ((product['moq'] ?? 1) > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            // padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.blue50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.blue200),
                            ),
                            child: Text(
                              'MOQ: ${product['moq']}',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blue700,
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
                                backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
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
                          foregroundColor: AppColors.white,
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
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x1A000000), offset: Offset(0, 2), blurRadius: 4)],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Icon(icon, size: 14, color: color ?? const Color(0xFF475569)),
      ),
    );
  }

