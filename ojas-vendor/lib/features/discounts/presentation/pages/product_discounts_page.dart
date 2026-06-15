import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/services/api_service.dart';
import 'package:ojas_vendor/core/widgets/sidebar_layout.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';

class ProductDiscountsPage extends StatefulWidget {
  const ProductDiscountsPage({super.key});

  @override
  State<ProductDiscountsPage> createState() => _ProductDiscountsPageState();
}

class _ProductDiscountsPageState extends State<ProductDiscountsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Per-product discount state
  final Map<String, TextEditingController> _discountControllers = {};
  final Map<String, String> _discountTypes = {}; // 'percentage' | 'fixed'
  final Set<String> _savingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    for (final c in _discountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.dio.get('/vendor/products');
      final List<dynamic> products = response.data['data'] ?? [];
      setState(() {
        _products = products;
        for (final p in products) {
          final id = p['_id'].toString();
          final discountPrice = (p['discountPrice'] ?? 0).toDouble();
          final price = (p['price'] ?? 0).toDouble();
          
          // Determine initial type
          final type = (discountPrice > 0 && price > 0)
              ? 'percentage' // Default to percentage if there's a discount
              : 'percentage';
          _discountTypes[id] = type;

          // Calculate initial value for the text field
          String initialText = '';
          if (discountPrice > 0 && discountPrice < price) {
            if (type == 'percentage') {
              initialText = (((price - discountPrice) / price) * 100).round().toString();
            } else {
              initialText = (price - discountPrice).round().toString();
            }
          }

          _discountControllers[id] = TextEditingController(text: initialText);
        }
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyDiscount(Map<String, dynamic> product) async {
    final id = product['_id'].toString();
    final price = (product['price'] ?? 0).toDouble();
    final input = double.tryParse(_discountControllers[id]?.text ?? '');

    if (input == null || input <= 0) {
      _showSnack('Enter a valid discount value', isError: true);
      return;
    }

    double discountPrice;
    if (_discountTypes[id] == 'percentage') {
      if (input >= 100) {
        _showSnack('Percentage must be less than 100%', isError: true);
        return;
      }
      discountPrice = price - (price * input / 100);
    } else {
      if (input >= price) {
        _showSnack('Fixed discount must be less than the original price', isError: true);
        return;
      }
      discountPrice = price - input;
    }

    setState(() => _savingIds.add(id));
    try {
      await _apiService.dio.put(
        '/vendor/product/$id',
        data: FormData.fromMap({'discountPrice': discountPrice.toStringAsFixed(2)}),
      );
      await _fetchProducts();
      _showSnack('Discount applied to ${product['name']}!');
    } catch (e) {
      _showSnack('Failed to apply discount', isError: true);
    } finally {
      setState(() => _savingIds.remove(id));
    }
  }

  Future<void> _removeDiscount(Map<String, dynamic> product) async {
    final id = product['_id'].toString();
    setState(() => _savingIds.add(id));
    try {
      await _apiService.dio.put(
        '/vendor/product/$id',
        data: FormData.fromMap({'discountPrice': '0'}),
      );
      _discountControllers[id]?.clear();
      await _fetchProducts();
      _showSnack('Discount removed from ${product['name']}');
    } catch (e) {
      _showSnack('Failed to remove discount', isError: true);
    } finally {
      setState(() => _savingIds.remove(id));
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: isError ? Colors.red : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  List<dynamic> get _filteredProducts => _products.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      activeRoute: '/discounts',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const VendorTopBar(),
        body: SingleChildScrollView(
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
                      Text('Product Discounts',
                          style: GoogleFonts.outfit(
                              fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text('Set discount prices directly on your products.',
                          style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _fetchProducts,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('Refresh', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Set a discounted price for each product. You can use percentage (e.g. 20%) or fixed amount (e.g. ₹100 off). The discounted price will be shown to customers on the store.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search your products...',
                          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(80), child: CircularProgressIndicator()))
              else if (_filteredProducts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No products found',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text('Add products from the Products section first.',
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = _filteredProducts[index];
                    return _buildProductCard(p);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final id = product['_id'].toString();
    final price = (product['price'] ?? 0).toDouble();
    final discountPrice = (product['discountPrice'] ?? 0).toDouble();
    final hasDiscount = discountPrice > 0 && discountPrice < price;
    final discountPercent = hasDiscount ? ((price - discountPrice) / price * 100).round() : 0;
    final isSaving = _savingIds.contains(id);
    final type = _discountTypes[id] ?? 'percentage';

    String? imageUrl;
    if (product['images'] != null && (product['images'] as List).isNotEmpty) {
      imageUrl = product['images'][0].toString();
    } else if (product['image'] != null) {
      imageUrl = product['image'].toString();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDiscount ? const Color(0xFFBBF7D0) : Colors.grey.shade100,
          width: hasDiscount ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null && imageUrl.startsWith('http')
                ? Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder())
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 16),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? 'Product',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('₹${price.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: hasDiscount ? Colors.grey.shade400 : AppColors.textPrimary,
                            decoration: hasDiscount ? TextDecoration.lineThrough : null)),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text('₹${discountPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('-$discountPercent%',
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('Stock: ${product['stock'] ?? 0}  •  ${product['category'] ?? ''}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Discount Controls
          SizedBox(
            width: 340,
            child: Row(
              children: [
                // Type Toggle
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _typeBtn(id, 'percentage', Icons.percent, type, price),
                      _typeBtn(id, 'fixed', Icons.currency_rupee, type, price),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Input
                Expanded(
                  child: TextField(
                    controller: _discountControllers[id],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: type == 'percentage' ? 'e.g. 20' : 'e.g. 100',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                      prefixText: type == 'percentage' ? '' : '₹ ',
                      suffixText: type == 'percentage' ? '%' : ' off',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Apply Button
                isSaving
                    ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
                    : ElevatedButton(
                        onPressed: () => _applyDiscount(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),

                if (hasDiscount) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isSaving ? null : () => _removeDiscount(product),
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.red.shade400,
                    tooltip: 'Remove discount',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(String id, String typeVal, IconData icon, String currentType, double price) {
    final isActive = currentType == typeVal;
    return GestureDetector(
      onTap: () {
        if (isActive) return;
        
        final controller = _discountControllers[id];
        final currentValue = double.tryParse(controller?.text ?? '');
        
        if (currentValue != null && currentValue > 0) {
          if (typeVal == 'percentage') {
            // Convert fixed amount to percentage
            final percent = (currentValue / price * 100).round();
            controller?.text = percent.toString();
          } else {
            // Convert percentage to fixed amount
            final amount = (price * currentValue / 100).round();
            controller?.text = amount.toString();
          }
        }
        
        setState(() => _discountTypes[id] = typeVal);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 16, color: isActive ? Colors.white : Colors.grey.shade500),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade100,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade300, size: 28),
    );
  }
}
