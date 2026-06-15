import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/features/home/presentation/widgets/product_card.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:ojas_user/core/widgets/youtube_embed_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ojas_user/features/auth/presentation/pages/auth_screen.dart';

import '../../../../core/services/api_service.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel? product;
  final String? productId;
  final String? refCode;

  const ProductDetailPage({
    super.key,
    this.product,
    this.productId,
    this.refCode,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  ProductModel? _loadedProduct;
  bool _isLoading = true;
  String? _errorMessage;

  late String _selectedImageUrl;
  String? _selectedSize;
  String? _selectedColor;
  String? _selectedMaterial;
  late double _currentPrice;
  late int _currentStock;

  ProductModel get product => _loadedProduct ?? widget.product!;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.product == null && widget.productId != null;
    if (widget.product != null) {
      _initProductDetails(widget.product!);
      if (widget.refCode != null) {
        _fetchProductDetails();
      }
    } else if (widget.productId != null) {
      _fetchProductDetails();
    } else {
      _errorMessage = "Product not found";
    }
  }

  void _initProductDetails(ProductModel p) {
    _selectedImageUrl = p.imageUrl;
    _currentPrice = p.price;
    _currentStock = p.available ?? 0;

    if (p.variations.isNotEmpty) {
      final firstVar = p.variations[0];
      _selectedSize = firstVar.size;
      _selectedColor = firstVar.color;
      _selectedMaterial = firstVar.material;
      _currentPrice = firstVar.price;
      _currentStock = firstVar.stock;
    }
  }

  Future<void> _fetchProductDetails() async {
    final id = widget.productId ?? widget.product?.id;
    if (id == null) return;

    setState(() {
      _isLoading = _loadedProduct == null;
      _errorMessage = null;
    });

    try {
      final url = '${ApiService.baseUrl}/home/products/$id${widget.refCode != null ? '?ref=${widget.refCode}' : ''}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['data'] != null) {
          final fetched = ProductModel.fromMap(body['data']);
          if (fetched.status != 'Active') {
            setState(() {
              _errorMessage = "Product is not available";
              _isLoading = false;
            });
            return;
          }
          setState(() {
            _loadedProduct = fetched;
            _initProductDetails(fetched);
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _errorMessage = "Failed to load product details";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load product details: $e";
        _isLoading = false;
      });
    }
  }

  void _updateSelectedVariation() {
    if (product.variations.isEmpty) return;

    final uniqueSizes = product.variations
        .map((v) => v.size)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet();

    final uniqueColors = product.variations
        .map((v) => v.color)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet();

    final uniqueMaterials = product.variations
        .map((v) => v.material)
        .whereType<String>()
        .where((m) => m.isNotEmpty)
        .toSet();

    // Try to find exact match
    final match = product.variations.firstWhere(
      (v) =>
          (uniqueSizes.isNotEmpty ? v.size == _selectedSize : true) &&
          (uniqueColors.isNotEmpty ? v.color == _selectedColor : true) &&
          (uniqueMaterials.isNotEmpty ? v.material == _selectedMaterial : true),
      orElse: () => product.variations[0],
    );

    setState(() {
      _currentPrice = match.price;
      _currentStock = match.stock;
      if (match.image != null && match.image!.isNotEmpty) {
        _selectedImageUrl = match.image!;
      } else {
        _selectedImageUrl = product.imageUrl;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionService.instance,
      builder: (context, _) {
        final token = SessionService.instance.token;
        final refCode = widget.refCode ?? SessionService.instance.refCode;

        if (token == null && refCode != null) {
          return const AuthScreen(isInitialLogin: true);
        }

        if (_isLoading || (_loadedProduct == null && widget.product == null && _errorMessage == null)) {
          return OjasLayout(
            activeTitle: 'PRODUCT DETAIL',
            hideNavigation: false,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF01B6B)),
              ),
            ),
          );
        }

        if (_errorMessage != null && _loadedProduct == null && widget.product == null) {
          return OjasLayout(
            activeTitle: 'PRODUCT DETAIL',
            hideNavigation: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchProductDetails,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF01B6B)),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final bool isMobile = Responsive.isMobile(context);
        final relatedProducts = HomeController.instance.products
            .where((p) => product.relatedProducts.contains(p['_id']))
            .map((p) => ProductModel.fromMap(p))
            .toList();

        return OjasLayout(
          activeTitle: 'PRODUCT DETAIL',
          hideNavigation: false,
          child: CenteredContent(
            horizontalPadding: isMobile ? 16 : 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                if (isMobile)
                  _buildMobileLayout(context)
                else
                  _buildDesktopLayout(context),
                
                const SizedBox(height: 60),
                
                // Related Products Section
                if (widget.refCode == null && relatedProducts.isNotEmpty) ...[
                  Text(
                    'Related Products',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: relatedProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isMobile ? 0.65 : 0.62,
                    ),
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: relatedProducts[index],
                        onAddToCart: () => _addToCart(context, relatedProducts[index]),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Gallery (Left)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    _selectedImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Thumbnails
              if (product.images.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: product.images.length,
                    itemBuilder: (context, index) {
                      final imgUrl = product.images[index];
                      final isSelected = imgUrl == _selectedImageUrl;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedImageUrl = imgUrl),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? const Color(0xFFF01B6B) : Colors.grey.shade300, width: isSelected ? 2 : 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(imgUrl, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 60),
        // Product Info (Right)
        Expanded(
          flex: 1,
          child: _buildProductInfo(context),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              _selectedImageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Thumbnails
        if (product.images.isNotEmpty)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: product.images.length,
              itemBuilder: (context, index) {
                final imgUrl = product.images[index];
                final isSelected = imgUrl == _selectedImageUrl;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageUrl = imgUrl),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? const Color(0xFFF01B6B) : Colors.grey.shade300, width: isSelected ? 2 : 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(imgUrl, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
        _buildProductInfo(context),
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.brand != null && product.brand!.isNotEmpty)
          Text(
            product.brand!.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 1,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          product.name,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '₹${_currentPrice.ceil()}',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFF01B6B),
              ),
            ),
            if (product.oldPrice != null) ...[
              const SizedBox(width: 16),
              Text(
                '₹${product.oldPrice!.ceil()}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${product.discount}% OFF',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _currentStock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _currentStock > 0 ? Colors.green.shade100 : Colors.red.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: _currentStock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentStock > 0 ? 'In Stock: $_currentStock units' : 'Currently Out of Stock',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _currentStock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (product.moq > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'MOQ: ${product.moq} units',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 32),
        _buildVariationSelectors(),
        const SizedBox(height: 16),
        if (product.shortDescription != null && product.shortDescription!.isNotEmpty) ...[
          Text(
            'Highlights',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            product.shortDescription!,
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black, height: 1.6),
          ),
          const SizedBox(height: 24),
        ],

        Text(
          'Product Description',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product.fullDescription ?? 'No detailed description available.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.black,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // ── Product Video ──────────────────────────────────────────────────
        if (product.youtubeLink != null &&
            product.youtubeLink!.trim().isNotEmpty) ...[
          Text(
            'Product Video',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          YoutubeEmbedWidget(youtubeUrl: product.youtubeLink!),
          const SizedBox(height: 32),
        ],

        // Specifications
        if (product.specifications != null && product.specifications!.isNotEmpty) ...[
          Text(
            'Specifications',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade200),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
            },
            children: product.specifications!.map((spec) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(spec.key, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(spec.value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black)),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],

        // Dimensions & Weight
        if ((product.weight ?? 0) > 0 ||
            (product.length ?? 0) > 0 ||
            (product.width ?? 0) > 0 ||
            (product.height ?? 0) > 0) ...[
          Text(
            'Dimensions & Weight',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade200),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
            },
            children: [
              if ((product.weight ?? 0) > 0)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('Weight', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('${product.weight} kg', style: GoogleFonts.inter(fontSize: 14, color: Colors.black)),
                    ),
                  ],
                ),
              if ((product.length ?? 0) > 0 ||
                  (product.width ?? 0) > 0 ||
                  (product.height ?? 0) > 0)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('Dimensions', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('${product.length} x ${product.width} x ${product.height} cm', style: GoogleFonts.inter(fontSize: 14, color: Colors.black)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // Tags
        if (product.tags != null && product.tags!.isNotEmpty) ...[
          Text(
            'Tags',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.tags!.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(tag, style: GoogleFonts.inter(fontSize: 13, color: Colors.black)),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
        ],

        // Action Buttons
        isMobile 
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _addToCart(context, product),
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: Text(
                      'Add to Cart',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF01B6B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _addToCart(context, product);
                      Navigator.pushNamed(context, '/cart');
                    },
                    icon: const Icon(Icons.flash_on),
                    label: Text(
                      'Buy Now',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(context, product),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: Text(
                        'Add to Cart',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF01B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _addToCart(context, product);
                        Navigator.pushNamed(context, '/cart');
                      },
                      icon: const Icon(Icons.flash_on),
                      label: Text(
                        'Buy Now',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ],
    );
  }

  Widget _buildVariationSelectors() {
    if (product.variations.isEmpty) return const SizedBox.shrink();

    final uniqueSizes = product.variations
        .map((v) => v.size)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    final uniqueColors = product.variations
        .map((v) => v.color)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    final uniqueMaterials = product.variations
        .map((v) => v.material)
        .whereType<String>()
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (uniqueSizes.isNotEmpty) ...[
          Text(
            'Select Size',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: uniqueSizes.map((size) {
              final isSelected = _selectedSize == size;
              return ChoiceChip(
                label: Text(size),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _selectedSize = size;
                    _updateSelectedVariation();
                  }
                },
                selectedColor: const Color(0xFFF01B6B),
                backgroundColor: Colors.grey.shade100,
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                labelStyle: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (uniqueColors.isNotEmpty) ...[
          Text(
            'Select Color',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: uniqueColors.map((color) {
              final isSelected = _selectedColor == color;
              return ChoiceChip(
                label: Text(color),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _selectedColor = color;
                    _updateSelectedVariation();
                  }
                },
                selectedColor: const Color(0xFFF01B6B),
                backgroundColor: Colors.grey.shade100,
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                labelStyle: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (uniqueMaterials.isNotEmpty) ...[
          Text(
            'Select Material',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: uniqueMaterials.map((material) {
              final isSelected = _selectedMaterial == material;
              return ChoiceChip(
                label: Text(material),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _selectedMaterial = material;
                    _updateSelectedVariation();
                  }
                },
                selectedColor: const Color(0xFFF01B6B),
                backgroundColor: Colors.grey.shade100,
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                labelStyle: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  void _addToCart(BuildContext context, ProductModel p) async {
    final String? token = SessionService.instance.token;
    if (token == null) {
      CartController.instance.setPendingItem(p.id, p.moq);
      Navigator.pushNamed(context, '/login');
      return;
    }

    final success = await CartController.instance.addToCart(p.id, moq: p.moq);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '${p.name} added to cart' : 'Failed to add. Please login.'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }
}
