// import 'package:ojas_user/core/constants/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:ojas_user/core/widgets/ojas_layout.dart';
// import 'package:ojas_user/core/widgets/centered_content.dart';
// import 'package:ojas_user/features/home/domain/models/product_model.dart';
// import 'package:ojas_user/core/controllers/home_controller.dart';
// import 'package:ojas_user/features/home/presentation/widgets/product_card.dart';
// import 'package:ojas_user/features/cart/application/cart_controller.dart';
// import 'package:ojas_user/core/utils/responsive.dart';
// import 'package:ojas_user/core/services/session_service.dart';
// import 'package:ojas_user/core/widgets/youtube_embed_widget.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:ojas_user/features/auth/presentation/pages/auth_screen.dart';
// import 'package:sizer/sizer.dart';

// import '../../../../core/services/api_service.dart';

// class ProductDetailPage extends StatefulWidget {
//   final ProductModel? product;
//   final String? productId;
//   final String? refCode;

//   const ProductDetailPage({
//     super.key,
//     this.product,
//     this.productId,
//     this.refCode,
//   });

//   @override
//   State<ProductDetailPage> createState() => _ProductDetailPageState();
// }

// class _ProductDetailPageState extends State<ProductDetailPage> {
//   ProductModel? _loadedProduct;
//   bool _isLoading = true;
//   String? _errorMessage;

//   late String _selectedImageUrl;
//   String? _selectedSize;
//   String? _selectedColor;
//   String? _selectedMaterial;
//   String? _selectedWeight;
//   String? _selectedVariationTitle;
//   late double _currentPrice;
//   late int _currentStock;
//   double? _currentWeight;

//   ProductModel get product => _loadedProduct ?? widget.product!;

//   String _formatWeight(double w) {
//     if (w >= 70) {
//       return '${w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 2)} GM';
//     } else if (w >= 1) {
//       return '${w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 2)} KG';
//     } else {
//       return '${(w * 1000).toStringAsFixed(0)} GM';
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _isLoading = widget.product == null && widget.productId != null;
//     if (widget.product != null) {
//       _initProductDetails(widget.product!);
//       if (widget.refCode != null) {
//         _fetchProductDetails();
//       }
//     } else if (widget.productId != null) {
//       _fetchProductDetails();
//     } else {
//       _errorMessage = "Product not found";
//     }
//   }

//   void _initProductDetails(ProductModel p) {
//     _selectedImageUrl = p.imageUrl;
//     _currentPrice = p.price;
//     _currentStock = p.available ?? 0;
//     _currentWeight = p.weight;
//     _selectedWeight = null;
//     _selectedVariationTitle = null;

//     if (p.variations.isNotEmpty) {
//       final firstVar = p.variations[0];
//       _selectedSize = firstVar.size;
//       _selectedColor = firstVar.color;
//       _selectedMaterial = firstVar.material;
//       _selectedWeight = firstVar.weightStr;
//       _currentPrice = firstVar.price;
//       _currentStock = firstVar.stock;
//       _currentWeight = firstVar.weight ?? p.weight;
//       _selectedVariationTitle = firstVar.title;
//     }
//   }

//   Future<void> _fetchProductDetails() async {
//     final id = widget.productId ?? widget.product?.id;
//     if (id == null) return;

//     setState(() {
//       _isLoading = _loadedProduct == null;
//       _errorMessage = null;
//     });

//     try {
//       final url =
//           '${ApiService.baseUrl}/home/products/$id${widget.refCode != null ? '?ref=${widget.refCode}' : ''}';
//       final response = await http.get(Uri.parse(url));

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> body = jsonDecode(response.body);
//         if (body['data'] != null) {
//           final fetched = ProductModel.fromMap(body['data']);
//           if (fetched.status != 'Active') {
//             setState(() {
//               _errorMessage = "Product is not available";
//               _isLoading = false;
//             });
//             return;
//           }
//           setState(() {
//             _loadedProduct = fetched;
//             _initProductDetails(fetched);
//             _isLoading = false;
//           });
//           return;
//         }
//       }
//       setState(() {
//         _errorMessage = "Failed to load product details";
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Failed to load product details: $e";
//         _isLoading = false;
//       });
//     }
//   }

//   List<String> _currentVariationImages = [];

//   void _updateSelectedVariation() {
//     if (product.variations.isEmpty) return;

//     var validVars = product.variations.where((v) => v.price > 0 || v.stock > 0).toList();
//     if (validVars.isEmpty) validVars = product.variations;

//     final match = validVars.firstWhere(
//       (v) =>
//           (_selectedSize == null || v.size == _selectedSize) &&
//           (_selectedColor == null || v.color == _selectedColor) &&
//           (_selectedMaterial == null || v.material == _selectedMaterial) &&
//           (_selectedWeight == null || v.weightStr == _selectedWeight),
//       orElse: () => validVars.firstWhere(
//         (v) => (_selectedSize == null || v.size == _selectedSize),
//         orElse: () => validVars[0],
//       ),
//     );

//     setState(() {
//       _selectedSize = match.size ?? _selectedSize;
//       _selectedColor = match.color ?? _selectedColor;
//       _selectedMaterial = match.material ?? _selectedMaterial;
//       _selectedWeight = match.weightStr ?? _selectedWeight;
//       _currentPrice = match.price > 0 ? match.price : product.price;
//       _currentStock = match.stock;
//       _currentWeight = match.weight ?? product.weight;
//       _selectedVariationTitle = match.title;

//       // Extract all images uploaded for this specific variation
//       List<String> varImages = [];
//       if (match.images.isNotEmpty) {
//         varImages.addAll(match.images.where((img) => img.isNotEmpty));
//       }
//       if (match.image != null && match.image!.isNotEmpty && !varImages.contains(match.image)) {
//         varImages.insert(0, match.image!);
//       }

//       _currentVariationImages = varImages;

//       if (varImages.isNotEmpty) {
//         _selectedImageUrl = varImages[0];
//       } else if (product.imageUrl.isNotEmpty) {
//         _selectedImageUrl = product.imageUrl;
//       } else if (product.images.isNotEmpty) {
//         _selectedImageUrl = product.images[0];
//       }
//     });
//   }

//   Widget _buildVariationSelectors() {
//     if (product.variations.isEmpty) return const SizedBox.shrink();

//     final uniqueSizes = product.variations
//         .map((v) => v.size)
//         .whereType<String>()
//         .where((s) => s.isNotEmpty)
//         .toSet()
//         .toList();

//     final uniqueColors = product.variations
//         .map((v) => v.color)
//         .whereType<String>()
//         .where((c) => c.isNotEmpty)
//         .toSet()
//         .toList();

//     final uniqueMaterials = product.variations
//         .map((v) => v.material)
//         .whereType<String>()
//         .where((m) => m.isNotEmpty)
//         .toSet()
//         .toList();

//     final allUniqueWeights = product.variations
//         .map((v) => v.weightStr)
//         .whereType<String>()
//         .where((w) => w.isNotEmpty)
//         .toSet()
//         .toList();

//     final customTitles = product.variations
//         .map((v) => v.title)
//         .whereType<String>()
//         .where((t) => t.isNotEmpty)
//         .toSet()
//         .toList();

//     final bool hasStandardAttrs = uniqueSizes.isNotEmpty || uniqueColors.isNotEmpty || uniqueMaterials.isNotEmpty || allUniqueWeights.isNotEmpty;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (uniqueSizes.isNotEmpty) ...[
//           Text(
//             'Select Size',
//             style: GoogleFonts.outfit(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: const Color(0xFF0F172A),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: uniqueSizes.map((size) {
//               final isSelected = _selectedSize == size;

//               // Check if size has any variation with price > 0
//               final hasValidPrice = product.variations.any(
//                 (v) => v.size == size && v.price > 0,
//               );

//               return ChoiceChip(
//                 label: Text(
//                   size,
//                   style: GoogleFonts.inter(
//                     color: isSelected
//                         ? AppColors.white
//                         : (hasValidPrice ? AppColors.black87 : AppColors.grey),
//                     fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                     decoration: hasValidPrice ? null : TextDecoration.lineThrough,
//                   ),
//                 ),
//                 selected: isSelected,
//                 disabledColor: Colors.grey.shade200,
//                 onSelected: hasValidPrice
//                     ? (selected) {
//                         if (selected) {
//                           setState(() {
//                             _selectedSize = size;
//                             final validForSize = product.variations
//                                 .where((v) => v.size == size && v.price > 0)
//                                 .toList();
//                             if (validForSize.isNotEmpty) {
//                               final matchedVar = validForSize.firstWhere(
//                                 (v) => v.weightStr == _selectedWeight && v.price > 0,
//                                 orElse: () => validForSize.first,
//                               );
//                               _selectedWeight = matchedVar.weightStr;
//                               _selectedColor = matchedVar.color;
//                               _selectedMaterial = matchedVar.material;
//                             }
//                             _updateSelectedVariation();
//                           });
//                         }
//                       }
//                     : null,
//                 selectedColor: AppColors.primaryPink,
//                 backgroundColor: hasValidPrice ? AppColors.grey100 : Colors.grey.shade200,
//                 side: BorderSide(
//                   color: isSelected
//                       ? AppColors.transparent
//                       : (hasValidPrice ? AppColors.grey300 : Colors.grey.shade300),
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 16),
//         ],

//         if (allUniqueWeights.isNotEmpty) ...[
//           Text(
//             'Select Weight / Variant Option',
//             style: GoogleFonts.outfit(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: const Color(0xFF0F172A),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: allUniqueWeights.map((w) {
//               final isSelected = _selectedWeight == w;
//               String labelText = w;
//               final doubleVal = double.tryParse(w);
//               if (doubleVal != null) {
//                 labelText = _formatWeight(doubleVal);
//               }

//               // Check if weight is valid for currently selected size and has price > 0
//               final hasValidPriceForCurrentSelection = product.variations.any(
//                 (v) =>
//                     (_selectedSize == null || v.size == _selectedSize) &&
//                     v.weightStr == w &&
//                     v.price > 0,
//               );

//               // Check if valid across ANY size
//               final hasValidPriceAnywhere = product.variations.any(
//                 (v) => v.weightStr == w && v.price > 0,
//               );

//               final bool isValid = hasValidPriceForCurrentSelection;

//               return ChoiceChip(
//                 label: Text(
//                   labelText,
//                   style: GoogleFonts.inter(
//                     color: isSelected
//                         ? AppColors.white
//                         : (isValid ? AppColors.black87 : AppColors.grey400),
//                     fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                     decoration: isValid ? null : TextDecoration.lineThrough,
//                   ),
//                 ),
//                 selected: isSelected,
//                 disabledColor: Colors.grey.shade200,
//                 onSelected: (isValid || hasValidPriceAnywhere)
//                     ? (selected) {
//                         if (selected) {
//                           setState(() {
//                             _selectedWeight = w;
//                             final validForWeight = product.variations
//                                 .where((v) => v.weightStr == w && v.price > 0)
//                                 .toList();
//                             if (validForWeight.isNotEmpty) {
//                               final matchedVar = validForWeight.firstWhere(
//                                 (v) => v.size == _selectedSize && v.price > 0,
//                                 orElse: () => validForWeight.first,
//                               );
//                               if (matchedVar.size != null && matchedVar.size!.isNotEmpty) {
//                                 _selectedSize = matchedVar.size;
//                               }
//                             }
//                             _updateSelectedVariation();
//                           });
//                         }
//                       }
//                     : null,
//                 selectedColor: AppColors.primaryPink,
//                 backgroundColor: isValid ? AppColors.grey100 : Colors.grey.shade200,
//                 side: BorderSide(
//                   color: isSelected
//                       ? AppColors.transparent
//                       : (isValid ? AppColors.grey300 : Colors.grey.shade300),
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 16),
//         ],

//         if (uniqueColors.isNotEmpty) ...[
//           Text(
//             'Select Color',
//             style: GoogleFonts.outfit(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: const Color(0xFF0F172A),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: uniqueColors.map((color) {
//               final isSelected = _selectedColor == color;
//               final isValid = product.variations.any(
//                 (v) =>
//                     (_selectedSize == null || v.size == _selectedSize) &&
//                     v.color == color &&
//                     v.price > 0,
//               );

//               return ChoiceChip(
//                 label: Text(
//                   color,
//                   style: GoogleFonts.inter(
//                     color: isSelected
//                         ? AppColors.white
//                         : (isValid ? AppColors.black87 : AppColors.grey400),
//                     fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                     decoration: isValid ? null : TextDecoration.lineThrough,
//                   ),
//                 ),
//                 selected: isSelected,
//                 disabledColor: Colors.grey.shade200,
//                 onSelected: isValid
//                     ? (selected) {
//                         if (selected) {
//                           setState(() {
//                             _selectedColor = color;
//                             _updateSelectedVariation();
//                           });
//                         }
//                       }
//                     : null,
//                 selectedColor: AppColors.primaryPink,
//                 backgroundColor: isValid ? AppColors.grey100 : Colors.grey.shade200,
//                 side: BorderSide(
//                   color: isSelected
//                       ? AppColors.transparent
//                       : (isValid ? AppColors.grey300 : Colors.grey.shade300),
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 16),
//         ],

//         if (uniqueMaterials.isNotEmpty) ...[
//           Text(
//             'Select Material',
//             style: GoogleFonts.outfit(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: const Color(0xFF0F172A),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: uniqueMaterials.map((mat) {
//               final isSelected = _selectedMaterial == mat;
//               final isValid = product.variations.any(
//                 (v) =>
//                     (_selectedSize == null || v.size == _selectedSize) &&
//                     v.material == mat &&
//                     v.price > 0,
//               );

//               return ChoiceChip(
//                 label: Text(
//                   mat,
//                   style: GoogleFonts.inter(
//                     color: isSelected
//                         ? AppColors.white
//                         : (isValid ? AppColors.black87 : AppColors.grey400),
//                     fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                     decoration: isValid ? null : TextDecoration.lineThrough,
//                   ),
//                 ),
//                 selected: isSelected,
//                 disabledColor: Colors.grey.shade200,
//                 onSelected: isValid
//                     ? (selected) {
//                         if (selected) {
//                           setState(() {
//                             _selectedMaterial = mat;
//                             _updateSelectedVariation();
//                           });
//                         }
//                       }
//                     : null,
//                 selectedColor: AppColors.primaryPink,
//                 backgroundColor: isValid ? AppColors.grey100 : Colors.grey.shade200,
//                 side: BorderSide(
//                   color: isSelected
//                       ? AppColors.transparent
//                       : (isValid ? AppColors.grey300 : Colors.grey.shade300),
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 16),
//         ],

//         if (!hasStandardAttrs && customTitles.isNotEmpty) ...[
//           Text(
//             'Select Option',
//             style: GoogleFonts.outfit(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: const Color(0xFF0F172A),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: customTitles.map((title) {
//               final isSelected = _selectedVariationTitle == title;
//               return ChoiceChip(
//                 label: Text(title),
//                 selected: isSelected,
//                 onSelected: (selected) {
//                   if (selected) {
//                     setState(() {
//                       _selectedVariationTitle = title;
//                       final match = product.variations.firstWhere(
//                         (v) => v.title == title,
//                         orElse: () => product.variations.first,
//                       );
//                       _currentPrice = match.price > 0 ? match.price : product.price;
//                       _currentStock = match.stock;
//                       if (match.image != null && match.image!.isNotEmpty) {
//                         _selectedImageUrl = match.image!;
//                       }
//                     });
//                   }
//                 },
//                 selectedColor: AppColors.primaryPink,
//                 backgroundColor: AppColors.grey100,
//                 side: BorderSide(
//                   color: isSelected ? AppColors.transparent : AppColors.grey300,
//                 ),
//                 labelStyle: GoogleFonts.inter(
//                   color: isSelected ? AppColors.white : AppColors.black87,
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 16),
//         ],
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: SessionService.instance,
//       builder: (context, _) {
//         final token = SessionService.instance.token;
//         final refCode = widget.refCode ?? SessionService.instance.refCode;

//         if (token == null && refCode != null) {
//           return const AuthScreen(isInitialLogin: true);
//         }

//         if (_isLoading ||
//             (_loadedProduct == null &&
//                 widget.product == null &&
//                 _errorMessage == null)) {
//           return OjasLayout(
//             activeTitle: 'PRODUCT DETAIL',
//             hideNavigation: false,
//             child: const Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
//               ),
//             ),
//           );
//         }

//         if (_errorMessage != null &&
//             _loadedProduct == null &&
//             widget.product == null) {
//           return OjasLayout(
//             activeTitle: 'PRODUCT DETAIL',
//             hideNavigation: false,
//             child: Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(
//                       Icons.error_outline,
//                       size: 60,
//                       color: AppColors.errorRed,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _errorMessage!,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton(
//                       onPressed: _fetchProductDetails,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryPink,
//                       ),
//                       child: const Text(
//                         'Retry',
//                         style: TextStyle(color: AppColors.white),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }

//         final bool isMobile = Responsive.isMobile(context);
        
//         List<ProductModel> relatedProducts = [];
//         if (product.relatedProducts.isNotEmpty) {
//           relatedProducts = HomeController.instance.products
//               .where((p) => product.relatedProducts.contains(p['_id']))
//               .map((p) => ProductModel.fromMap(p))
//               .toList();
//         }
        
//         // Fallback: If no explicit related products, find products in the same category
//         if (relatedProducts.isEmpty) {
//           relatedProducts = HomeController.instance.products
//               .where((p) => p['_id'] != product.id && p['category'] == product.category)
//               .take(5)
//               .map((p) => ProductModel.fromMap(p))
//               .toList();
//         }
        
//         // Secondary Fallback: If still empty, grab any recent trending products
//         if (relatedProducts.isEmpty) {
//           relatedProducts = HomeController.instance.products
//               .where((p) => p['_id'] != product.id)
//               .take(5)
//               .map((p) => ProductModel.fromMap(p))
//               .toList();
//         }

//         return OjasLayout(
//           activeTitle: 'PRODUCT DETAIL',
//           hideNavigation: false,
//           child: CenteredContent(
//             horizontalPadding: isMobile ? 16 : 40,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 40),
//                 if (isMobile)
//                   _buildMobileLayout(context)
//                 else
//                   _buildDesktopLayout(context),

//                 const SizedBox(height: 60),

//                 // Related Products Section
//                 if (widget.refCode == null && relatedProducts.isNotEmpty) ...[
//                   Text(
//                     'Related Products',
//                     style: GoogleFonts.outfit(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: const Color(0xFF0F172A),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   GridView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: relatedProducts.length,
//                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: isMobile ? 2 : 5,
//                       crossAxisSpacing: 16,
//                       mainAxisSpacing: 16,
//                       childAspectRatio: isMobile ? 0.65 : 0.62,
//                     ),
//                     itemBuilder: (context, index) {
//                       return ProductCard(
//                         product: relatedProducts[index],
//                         onAddToCart: () =>
//                             _addToCart(context, relatedProducts[index]),
//                       );
//                     },
//                   ),
//                 ],
//                 const SizedBox(height: 60),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   List<String> get _activeGalleryImages {
//     if (_currentVariationImages.isNotEmpty) {
//       return _currentVariationImages;
//     }
//     if (product.images.isNotEmpty) {
//       return product.images;
//     }
//     if (product.imageUrl.isNotEmpty) {
//       return [product.imageUrl];
//     }
//     return [_selectedImageUrl];
//   }

//   Widget _buildDesktopLayout(BuildContext context) {
//     final displayImages = _activeGalleryImages;

//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Image Gallery (Left)
//         Expanded(
//           flex: 1,
//           child: Column(
//             children: [
//               Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: AppColors.grey200),
//                 ),
//                 clipBehavior: Clip.antiAlias,
//                 child: AspectRatio(
//                   aspectRatio: 1,
//                   child: ZoomableProductImage(
//                     imageUrl: _selectedImageUrl,
//                     allImages: displayImages,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               // Thumbnails
//               if (displayImages.length > 1)
//                 SizedBox(
//                   height: 80,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: displayImages.length,
//                     itemBuilder: (context, index) {
//                       final imgUrl = displayImages[index];
//                       final isSelected = imgUrl == _selectedImageUrl;
//                       return GestureDetector(
//                         onTap: () => setState(() => _selectedImageUrl = imgUrl),
//                         child: Container(
//                           width: 80,
//                           margin: const EdgeInsets.only(right: 12),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(
//                               color: isSelected
//                                   ? AppColors.primaryPink
//                                   : AppColors.grey300,
//                               width: isSelected ? 2 : 1,
//                             ),
//                           ),
//                           clipBehavior: Clip.antiAlias,
//                           child: Image.network(
//                             imgUrl,
//                             fit: BoxFit.cover,
//                             errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 24, color: AppColors.grey),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 60),
//         // Product Info (Right)
//         Expanded(flex: 1, child: _buildProductInfo(context)),
//       ],
//     );
//   }

//   Widget _buildMobileLayout(BuildContext context) {
//     final displayImages = _activeGalleryImages;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: AppColors.grey200),
//           ),
//           clipBehavior: Clip.antiAlias,
//           child: AspectRatio(
//             aspectRatio: 1,
//             child: ZoomableProductImage(
//               imageUrl: _selectedImageUrl,
//               allImages: displayImages,
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         // Thumbnails
//         if (displayImages.length > 1)
//           SizedBox(
//             height: 60,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: displayImages.length,
//               itemBuilder: (context, index) {
//                 final imgUrl = displayImages[index];
//                 final isSelected = imgUrl == _selectedImageUrl;
//                 return GestureDetector(
//                   onTap: () => setState(() => _selectedImageUrl = imgUrl),
//                   child: Container(
//                     width: 60,
//                     margin: const EdgeInsets.only(right: 8),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: isSelected
//                             ? AppColors.primaryPink
//                             : AppColors.grey300,
//                         width: isSelected ? 2 : 1,
//                       ),
//                     ),
//                     clipBehavior: Clip.antiAlias,
//                     child: Image.network(
//                       imgUrl,
//                       fit: BoxFit.cover,
//                       errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20, color: AppColors.grey),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         const SizedBox(height: 24),
//         _buildProductInfo(context),
//       ],
//     );
//   }

//   Widget _buildProductInfo(BuildContext context) {
//     final bool isMobile = Responsive.isMobile(context);
//     final String? specWeight = product.specifications
//         ?.firstWhere(
//           (s) => s.key.toLowerCase().contains('weight'),
//           orElse: () => ProductSpecification(id: '', key: '', value: ''),
//         )
//         ?.value;
//     final bool hasWeight =
//         (product.weight != null && product.weight! > 0) ||
//         (specWeight != null && specWeight.isNotEmpty);
//     final bool hasDimensions =
//         (product.length ?? 0) > 0 ||
//         (product.width ?? 0) > 0 ||
//         (product.height ?? 0) > 0;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // if (product.brand != null && product.brand!.isNotEmpty)
//         //   Text(
//         //     product.brand!.toUpperCase(),
//         //     style: GoogleFonts.inter(
//         //       fontSize: 14,
//         //       fontWeight: FontWeight.w600,
//         //       color: AppColors.grey600,
//         //       letterSpacing: 1,
//         //     ),
//         //   ),
//         // const SizedBox(height: 8),
//          Text(
//           _selectedVariationTitle != null && _selectedVariationTitle!.isNotEmpty
//               ? "${product.name} - $_selectedVariationTitle"
//               : product.name,
//           style: GoogleFonts.outfit(
//             fontSize: isMobile ? 24 : 32,
//             fontWeight: FontWeight.bold,
//             color: const Color(0xFF0F172A),
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Text(
//               '₹${_currentPrice.ceil()}',
//               style: GoogleFonts.outfit(
//                 fontSize: 28,
//                 fontWeight: FontWeight.w900,
//                 color: AppColors.primaryPink,
//               ),
//             ),
//             if (product.oldPrice != null) ...[
//               const SizedBox(width: 16),
//               Text(
//                 '₹${product.oldPrice!.ceil()}',
//                 style: GoogleFonts.inter(
//                   fontSize: 18,
//                   color: AppColors.grey,
//                   decoration: TextDecoration.lineThrough,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: AppColors.red50,
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Text(
//                   '${product.discount}% OFF',
//                   style: GoogleFonts.inter(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.errorRed,
//                   ),
//                 ),
//               ),
//             ],
//             const SizedBox(width: 24),
            
//                ElevatedButton.icon(
//                   onPressed: _currentStock <= 0 ? null : () {
//                     _addToCart(context, product);
//                     Navigator.pushNamed(context, '/cart');
//                   },
//                   icon: const Icon(Icons.flash_on),
//                   label: Text(
//                     _currentStock <= 0 ? 'Out of Stock' : 'Buy Now',
//                     style: GoogleFonts.inter(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _currentStock <= 0 ? AppColors.grey : Colors.orange.shade700,
//                     foregroundColor: AppColors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 0,
//                     minimumSize: Size(6.w, 6.h)
//                   ),
//                 ),
                  
//           ],
//         ),
//         const SizedBox(height: 24),

//         Wrap(
//           spacing: 12,
//           runSpacing: 12,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: _currentStock > 0
//                     ? AppColors.green50
//                     : AppColors.red50,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: _currentStock > 0
//                       ? AppColors.green100
//                       : AppColors.red100,
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.inventory_2_outlined,
//                     size: 18,
//                     color: _currentStock > 0
//                         ? AppColors.green700
//                         : AppColors.red700,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     _currentStock > 0
//                         ? 'In Stock: $_currentStock units'
//                         : 'Currently Out of Stock',
//                     style: GoogleFonts.inter(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: _currentStock > 0
//                           ? AppColors.green700
//                           : AppColors.red700,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (product.moq > 1 || product.moqTiers.isNotEmpty)
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: AppColors.blue50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: AppColors.blue100),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.shopping_basket_outlined,
//                           size: 18,
//                           color: AppColors.blue700,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           'Minimum Order Qty (MOQ): ${product.moq} units',
//                           style: GoogleFonts.inter(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.blue700,
//                           ),
//                         ),
//                       ],
//                     ),
//                     if (product.moqTiers.isNotEmpty) ...[
//                       const SizedBox(height: 8),
//                       Text(
//                         'Volume Discounts:',
//                         style: GoogleFonts.inter(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.blue800,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       ...product.moqTiers.split(',').map((tier) {
//                         final parts = tier.trim().split(':');
//                         if (parts.length == 2) {
//                           final qty = parts[0].trim();
//                           final discount = parts[1].replaceAll('%', '').trim();
//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 2),
//                             child: Text(
//                               '• Buy $qty+ units, get $discount% off',
//                               style: GoogleFonts.inter(
//                                 fontSize: 12,
//                                 color: AppColors.blue900,
//                               ),
//                             ),
//                           );
//                         }
//                         return const SizedBox.shrink();
//                       }),
//                     ] else if (product.moqDiscount > 0) ...[
//                       const SizedBox(height: 4),
//                       Text(
//                         '• Buy ${product.moq}+ units, get ${product.moqDiscount.toInt()}% off',
//                         style: GoogleFonts.inter(
//                           fontSize: 12,
//                           color: AppColors.blue900,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//           ],
//         ),

//         const SizedBox(height: 32),
//         _buildVariationSelectors(),
//         const SizedBox(height: 16),
//         if (product.shortDescription != null &&
//             product.shortDescription!.isNotEmpty) ...[
//           Text(
//             'Highlights',
//             style: GoogleFonts.outfit(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: AppColors.black,
//             ),
//           ),
//           const SizedBox(height: 8),
//           _buildBulletPoints(product.shortDescription!),
//           const SizedBox(height: 24),
//         ],

//         Text(
//           'Product Description',
//           style: GoogleFonts.outfit(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: AppColors.black,
//           ),
//         ),
//         const SizedBox(height: 12),
//         _buildBulletPoints(product.fullDescription ?? 'No detailed description available.'),
//         const SizedBox(height: 32),

//         // ── Product Video ──────────────────────────────────────────────────
//         if (product.youtubeLink != null &&
//             product.youtubeLink!.trim().isNotEmpty) ...[
//           Text(
//             'Product Video',
//             style: GoogleFonts.outfit(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: AppColors.black,
//             ),
//           ),
//           const SizedBox(height: 12),
//           YoutubeEmbedWidget(youtubeUrl: product.youtubeLink!),
//           const SizedBox(height: 32),
//         ],

//         // Specifications
//         if (product.specifications != null &&
//             product.specifications!.isNotEmpty) ...[
//           Text(
//             'Specifications',
//             style: GoogleFonts.outfit(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: AppColors.black,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: product.specifications!.map((spec) {
//               return Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       margin: const EdgeInsets.only(top: 8, right: 10),
//                       width: 6,
//                       height: 6,
//                       decoration: const BoxDecoration(
//                         color: AppColors.primaryPink,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     Expanded(
//                       child: RichText(
//                         text: TextSpan(
//                           style: GoogleFonts.inter(
//                             fontSize: 14,
//                             color: AppColors.black,
//                             height: 1.5,
//                           ),
//                           children: [
//                             TextSpan(
//                               text: '${spec.key}: ',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             TextSpan(text: spec.value),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 32),
//         ],

//         // Dimensions & Weight
//         if (hasWeight || hasDimensions) ...[
//           Text(
//             'Dimensions & Weight',
//             style: GoogleFonts.outfit(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: AppColors.black,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Table(
//             border: TableBorder.all(color: AppColors.grey200),
//             columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
//             children: [
//               if (hasWeight)
//                 TableRow(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Text(
//                         'Weight',
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: AppColors.black,
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Builder(
//                         builder: (context) {
//                           if (product.weight != null && product.weight! > 0) {
//                             return Text(
//                               _formatWeight(product.weight!),
//                               style: GoogleFonts.inter(
//                                 fontSize: 14,
//                                 color: AppColors.black,
//                               ),
//                             );
//                           }
//                           if (specWeight != null && specWeight.isNotEmpty) {
//                             return Text(
//                               specWeight,
//                               style: GoogleFonts.inter(
//                                 fontSize: 14,
//                                 color: AppColors.black,
//                               ),
//                             );
//                           }
//                           return const SizedBox.shrink();
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               if (hasDimensions)
//                 TableRow(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Text(
//                         'Dimensions',
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: AppColors.black,
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Text(
//                         '${product.length} x ${product.width} x ${product.height} cm',
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           color: AppColors.black,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//           const SizedBox(height: 32),
//         ],

//         // Tags
//         // if (product.tags != null && product.tags!.isNotEmpty) ...[
//         //   Text(
//         //     'Tags',
//         //     style: GoogleFonts.outfit(
//         //       fontSize: 18,
//         //       fontWeight: FontWeight.bold,
//         //       color: AppColors.black,
//         //     ),
//         //   ),
//         //   const SizedBox(height: 12),
//         //   Wrap(
//         //     spacing: 8,
//         //     runSpacing: 8,
//         //     children: product.tags!.map((tag) {
//         //       return Container(
//         //         padding: const EdgeInsets.symmetric(
//         //           horizontal: 12,
//         //           vertical: 6,
//         //         ),
//         //         decoration: BoxDecoration(
//         //           color: AppColors.grey100,
//         //           borderRadius: BorderRadius.circular(20),
//         //           border: Border.all(color: AppColors.grey300),
//         //         ),
//         //         child: Text(
//         //           tag,
//         //           style: GoogleFonts.inter(fontSize: 13, color: AppColors.black),
//         //         ),
//         //       );
//         //     }).toList(),
//         //   ),
//         //   const SizedBox(height: 40),
//         // ],

//         // Action Buttons
//         isMobile
//             ? Column(
//                 children: [
//                   SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton.icon(
//                       onPressed: _currentStock <= 0 ? null : () => _addToCart(context, product),
//                       icon: const Icon(Icons.shopping_cart_outlined),
//                       label: Text(
//                         _currentStock <= 0 ? 'Out of Stock' : 'Add to Cart',
//                         style: GoogleFonts.inter(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: _currentStock <= 0 ? AppColors.grey : AppColors.primaryPink,
//                         foregroundColor: AppColors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 0,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton.icon(
//                       onPressed: _currentStock <= 0 ? null : () {
//                         _addToCart(context, product);
//                         Navigator.pushNamed(context, '/cart');
//                       },
//                       icon: const Icon(Icons.flash_on),
//                       label: Text(
//                         _currentStock <= 0 ? 'Out of Stock' : 'Buy Now',
//                         style: GoogleFonts.inter(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: _currentStock <= 0 ? AppColors.grey : Colors.orange.shade700,
//                         foregroundColor: AppColors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 0,
//                       ),
//                     ),
//                   ),
               
//                 ],
//               )
//             : Row(
//                 children: [
//                   Expanded(
//                     child: SizedBox(
//                       height: 56,
//                       child: ElevatedButton.icon(
//                         onPressed: _currentStock <= 0 ? null : () => _addToCart(context, product),
//                         icon: const Icon(Icons.shopping_cart_outlined),
//                         label: Text(
//                           _currentStock <= 0 ? 'Out of Stock' : 'Add to Cart',
//                           style: GoogleFonts.inter(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _currentStock <= 0 ? AppColors.grey : AppColors.primaryPink,
//                           foregroundColor: AppColors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 0,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: SizedBox(
//                       height: 56,
//                       child: ElevatedButton.icon(
//                         onPressed: _currentStock <= 0 ? null : () {
//                           _addToCart(context, product);
//                           Navigator.pushNamed(context, '/cart');
//                         },
//                         icon: const Icon(Icons.flash_on),
//                         label: Text(
//                           _currentStock <= 0 ? 'Out of Stock' : 'Buy Now',
//                           style: GoogleFonts.inter(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _currentStock <= 0 ? AppColors.grey : Colors.orange.shade700,
//                           foregroundColor: AppColors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 0,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//       ],
//     );
//   }

// /*
//   Widget _buildVariationSelectorsOld() {
//     if (product.variations.isEmpty) return const SizedBox.shrink();

//     final uniqueSizes = product.variations
//         .map((v) => v.size)
//         .whereType<String>()
//         .where((s) => s.isNotEmpty)
//         .toSet()
//         .toList();

//     final uniqueColors = product.variations
//         .map((v) => v.color)
//         .whereType<String>()
//         .where((c) => c.isNotEmpty)
//         .toSet()
//         .toList();

//     final uniqueMaterials = product.variations
//         .map((v) => v.material)
//         .whereType<String>()
//         .where((m) => m.isNotEmpty)
//         .toSet()
//         .toList();

//     final uniqueWeights = product.variations
//         .map((v) => v.weightStr)
//         .whereType<String>()
//         .where((w) => w.isNotEmpty)
//         .toSet()
//         .toList();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (uniqueSizes.isNotEmpty) ...[
//           Text(
//             'Select Size',
//             style: GoogleFonts.outfit(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: const Color(0xFF0F172A),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: uniqueSizes.map((size) {
//               final isSelected = _selectedSize == size;
//               return ChoiceChip(
//                 label: Text(size),
//                 selected: isSelected,
//                 onSelected: (selected) {
//                   if (selected) {
//                     setState(() {
//                       _selectedSize = size;
//                       final validForSize = product.variations.where((v) => v.size == size && (v.price > 0 || v.stock > 0)).toList();
//                       if (validForSize.isNotEmpty) {
//                          bool hasCurrentWeight = validForSize.any((v) => v.weightStr == _selectedWeight);
//                          if (!hasCurrentWeight && validForSize.first.weightStr != null) {
//                             _selectedWeight = validForSize.first.weightStr;
//                          }
//                       }
//                       _updateSelectedVariation();
//                     });
//                   }
//                 },
//                 selectedColor: AppColors.primaryPink,
//                 backgroundColor: AppColors.grey100,
//                 side: BorderSide(
//                   color: isSelected ? AppColors.transparent : AppColors.grey300,
//                 ),
//                 labelStyle: GoogleFonts.inter(
//                   color: isSelected ? AppColors.white : AppColors.black87,
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 16),
//           // Show weight chips or a single weight label
//           Builder(
//             builder: (context) {
//               final String? specWeight = product.specifications
//                   ?.firstWhere(
//                     (s) => s.key.toLowerCase().contains('weight'),
//                     orElse: () => ProductSpecification(id: '', key: '', value: ''),
//                   )
//                   ?.value;

//               final parsedWeights = <Map<String, String>>[];

//               if (parsedWeights.isNotEmpty) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 16),
//                     Text(
//                       'Select Weight',
//                       style: GoogleFonts.outfit(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: const Color(0xFF0F172A),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: parsedWeights.map((item) {
//                         final String weightLabel = item['weight'] ?? '';
//                         final String sizeForWeight = item['size'] ?? '';
//                         final isSelected = _selectedSize == sizeForWeight;

//                         return ChoiceChip(
//                           label: Text(weightLabel),
//                           selected: isSelected,
//                           onSelected: (selected) {
//                             if (selected && sizeForWeight.isNotEmpty) {
//                               setState(() {
//                                 _selectedSize = sizeForWeight;
//                                 _updateSelectedVariation();
//                               });
//                             }
//                           },
//                           selectedColor: AppColors.primaryPink,
//                           backgroundColor: AppColors.grey100,
//                           side: BorderSide(
//                             color: isSelected ? AppColors.transparent : AppColors.grey300,
//                           ),
//                           labelStyle: GoogleFonts.inter(
//                             color: isSelected ? AppColors.white : AppColors.black87,
//                             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 );
//               }

//               // Fallback if no parsed comma-separated weights list:
//               if (uniqueWeights.length > 1) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 16),
//                     Text(
//                       'Select Weight',
//                       style: GoogleFonts.outfit(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: const Color(0xFF0F172A),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: uniqueWeights.map((w) {
//                         final isSelected = _selectedWeight == w;
//                         String labelText = w;
//                         final doubleVal = double.tryParse(w);
//                         if (doubleVal != null) {
//                           labelText = _formatWeight(doubleVal);
//                         }
                        
//                         return ChoiceChip(
//                           label: Text(labelText),
//                           selected: isSelected,
//                           onSelected: (selected) {
//                             if (selected) {
//                               setState(() {
//                                 _selectedWeight = w;
//                                 final validForWeight = product.variations.where((v) => v.weightStr == w && (v.price > 0 || v.stock > 0)).toList();
//                                 if (validForWeight.isNotEmpty) {
//                                    bool hasCurrentSize = validForWeight.any((v) => v.size == _selectedSize);
//                                    if (!hasCurrentSize && validForWeight.first.size != null) {
//                                       _selectedSize = validForWeight.first.size;
//                                    }
//                                 }
//                                 _updateSelectedVariation();
//                               });
//                             }
//                           },
//                           selectedColor: AppColors.primaryPink,
//                           backgroundColor: AppColors.grey100,
//                           side: BorderSide(
//                             color: isSelected ? AppColors.transparent : AppColors.grey300,
//                           ),
//                           labelStyle: GoogleFonts.inter(
//                             color: isSelected ? AppColors.white : AppColors.black87,
//                             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 );
//               }

//               // Single/Fallback label display:
//               if (_currentWeight != null && _currentWeight! > 0) {
//                 final w = _currentWeight!;
//                 final display = _formatWeight(w);
//                 return Padding(
//                   padding: const EdgeInsets.only(top: 16.0),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.scale, size: 18, color: AppColors.grey),
//                       const SizedBox(width: 8),
//                       Text('Weight: $display', style: GoogleFonts.inter(fontSize: 14, color: AppColors.black87, fontWeight: FontWeight.w600)),
//                     ],
//                   ),
//                 );
//               }

//               if (specWeight != null && specWeight.isNotEmpty) {
//                 return Padding(
//                   padding: const EdgeInsets.only(top: 16.0),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.scale, size: 18, color: AppColors.grey),
//                       const SizedBox(width: 8),
//                       Text('Weight: $specWeight', style: GoogleFonts.inter(fontSize: 14, color: AppColors.black87, fontWeight: FontWeight.w600)),
//                     ],
//                   ),
//                 );
//               }

//               return const SizedBox.shrink();
//             },
//           ),
//         ],
//         if (uniqueColors.isNotEmpty) ...[
//           Text(
//             'Select Color',
//             style: GoogleFonts.outfit(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: const Color(0xFF0F172A),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: uniqueColors.map((color) {
//               final isSelected = _selectedColor == color;
//               return ChoiceChip(
//                 label: Text(color),
//                 selected: isSelected,
//                 onSelected: (selected) {
//                   if (selected) {
//                     _selectedColor = color;
//                     _updateSelectedVariation();
//                   }
//                 },
//                 selectedColor: AppColors.primaryPink,
//                 backgroundColor: AppColors.grey100,
//                 side: BorderSide(
//                   color: isSelected ? AppColors.transparent : AppColors.grey300,
//                 ),
//                 labelStyle: GoogleFonts.inter(
//                   color: isSelected ? AppColors.white : AppColors.black87,
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 16),
//         ],
//       ]);
//   }
// */

//   Future<void> _addToCart(BuildContext context, ProductModel p) async {
//       final String? variationId = _selectedColor != null || _selectedSize != null || _selectedMaterial != null || _selectedWeight != null
//         ? product.variations.firstWhere(
//             (v) =>
//                 (_selectedColor == null || v.color == _selectedColor) &&
//                 (_selectedSize == null || v.size == _selectedSize) &&
//                 (_selectedMaterial == null || v.material == _selectedMaterial) &&
//                 (_selectedWeight == null || v.weightStr == _selectedWeight),
//             orElse: () => product.variations.isNotEmpty ? product.variations.first : ProductVariation(id: '', price: 0, stock: 0),
//           ).id
//         : null;

//     final success = await CartController.instance.addToCart(
//       p.id,
//       quantity: 1,
//       moq: p.moq,
//       variationId: variationId != null && variationId.isNotEmpty ? variationId : null,
//     );

//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             success
//                 ? '${p.name} added to cart'
//                 : 'Failed to add. Please login.',
//           ),
//           backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.all(20),
//         ),
//       );
//     }
//   }

//   Widget _buildBulletPoints(String text) {
//     if (text.isEmpty) return const SizedBox.shrink();

//     List<String> lines = text
//         .split(RegExp(r'\r?\n|(?<=\.|\?|\!)\s*(?=[A-Z\s_]{3,}:)'))
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();

//     if (lines.length <= 1 && !text.contains('\n') && text.contains('.')) {
//       lines = text
//           .split(RegExp(r'\.(?=\s*[A-Z\s_]{3,}:)|\.\s+'))
//           .map((e) => e.trim())
//           .where((e) => e.isNotEmpty)
//           .toList();
//     }

//     if (lines.isEmpty) {
//       return Text(
//         'No detailed description available.',
//         style: GoogleFonts.inter(
//           fontSize: 15,
//           color: AppColors.black,
//           height: 1.6,
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: lines.map((line) {
//         String cleanLine = line;
//         if (cleanLine.startsWith('•') ||
//             cleanLine.startsWith('-') ||
//             cleanLine.startsWith('*') ||
//             cleanLine.startsWith('o')) {
//           cleanLine = cleanLine.substring(1).trim();
//         } else {
//           final numMatch = RegExp(r'^\d+[\.\)]\s*').firstMatch(cleanLine);
//           if (numMatch != null) {
//             cleanLine = cleanLine.substring(numMatch.end).trim();
//           }
//         }

//         if (cleanLine.isEmpty) return const SizedBox.shrink();

//         // Append dot back if we split by dot and it's missing
//         if (!text.contains('\n') && !cleanLine.endsWith('.')) {
//           cleanLine = '$cleanLine.';
//         }

//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 margin: const EdgeInsets.only(top: 8, right: 10),
//                 width: 6,
//                 height: 6,
//                 decoration: const BoxDecoration(
//                   color: AppColors.primaryPink,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               Expanded(
//                 child: Text(
//                   cleanLine,
//                   style: GoogleFonts.inter(
//                     fontSize: 15,
//                     color: AppColors.black,
//                     height: 1.6,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// class ZoomableProductImage extends StatefulWidget {
//   final String imageUrl;
//   final List<String> allImages;

//   const ZoomableProductImage({
//     super.key,
//     required this.imageUrl,
//     required this.allImages,
//   });

//   @override
//   State<ZoomableProductImage> createState() => _ZoomableProductImageState();
// }

// class _ZoomableProductImageState extends State<ZoomableProductImage>
//     with SingleTickerProviderStateMixin {
//   late TransformationController _transformationController;
//   late AnimationController _animationController;
//   Animation<Matrix4>? _animation;

//   @override
//   void initState() {
//     super.initState();
//     _transformationController = TransformationController();
//     _animationController =
//         AnimationController(
//           vsync: this,
//           duration: const Duration(milliseconds: 200),
//         )..addListener(() {
//           _transformationController.value = _animation!.value;
//         });
//   }

//   @override
//   void dispose() {
//     _transformationController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _handleDoubleTap() {
//     if (_animationController.isAnimating) return;

//     final double currentScale = _transformationController.value
//         .getMaxScaleOnAxis();
//     final Matrix4 endMatrix;

//     if (currentScale > 1.1) {
//       endMatrix = Matrix4.identity();
//     } else {
//       endMatrix = Matrix4.identity()..scale(2.0, 2.0, 1.0);
//     }

//     _animation =
//         Matrix4Tween(
//           begin: _transformationController.value,
//           end: endMatrix,
//         ).animate(
//           CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//         );

//     _animationController.forward(from: 0.0);
//   }

//   void _openFullScreenViewer(BuildContext context) {
//     final int initialIndex = widget.allImages.indexOf(widget.imageUrl);
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         fullscreenDialog: true,
//         builder: (context) => FullScreenImageViewer(
//           imageUrl: widget.imageUrl,
//           images: widget.allImages,
//           initialIndex: initialIndex != -1 ? initialIndex : 0,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       cursor: SystemMouseCursors.zoomIn,
//       onHover: (event) {
//         // Stop any running reset animations
//         if (_animationController.isAnimating) {
//           _animationController.stop();
//         }
//         const scale = 2.0;
//         final x = event.localPosition.dx;
//         final y = event.localPosition.dy;
//         _transformationController.value = Matrix4.identity()
//           ..translate(-x * (scale - 1), -y * (scale - 1))
//           ..scale(scale);
//       },
//       onExit: (event) {
//         _animation = Matrix4Tween(
//           begin: _transformationController.value,
//           end: Matrix4.identity(),
//         ).animate(
//           CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//         );
//         _animationController.forward(from: 0.0);
//       },
//       child: GestureDetector(
//         onDoubleTap: _handleDoubleTap,
//         onTap: () => _openFullScreenViewer(context),
//         child: InteractiveViewer(
//           transformationController: _transformationController,
//           minScale: 1.0,
//           maxScale: 4.0,
//           clipBehavior: Clip.hardEdge,
//           child: Image.network(
//             widget.imageUrl,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) => const Center(
//               child: Icon(
//                 Icons.image_not_supported,
//                 size: 100,
//                 color: AppColors.grey,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class FullScreenImageViewer extends StatefulWidget {
//   final String imageUrl;
//   final List<String> images;
//   final int initialIndex;

//   const FullScreenImageViewer({
//     super.key,
//     required this.imageUrl,
//     this.images = const [],
//     this.initialIndex = 0,
//   });

//   @override
//   State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
// }

// class _FullScreenImageViewerState extends State<FullScreenImageViewer>
//     with SingleTickerProviderStateMixin {
//   late PageController _pageController;
//   late int _currentIndex;
//   late List<TransformationController> _transformationControllers;
//   late AnimationController _animationController;
//   Animation<Matrix4>? _animation;
//   int? _animatingIndex;

//   @override
//   void initState() {
//     super.initState();
//     final list = widget.images.isNotEmpty ? widget.images : [widget.imageUrl];
//     _currentIndex = widget.images.isNotEmpty ? widget.initialIndex : 0;
//     _pageController = PageController(initialPage: _currentIndex);
//     _transformationControllers = List.generate(
//       list.length,
//       (_) => TransformationController(),
//     );
//     _animationController =
//         AnimationController(
//           vsync: this,
//           duration: const Duration(milliseconds: 200),
//         )..addListener(() {
//           if (_animatingIndex != null) {
//             _transformationControllers[_animatingIndex!].value =
//                 _animation!.value;
//           }
//         });
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     for (var controller in _transformationControllers) {
//       controller.dispose();
//     }
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _handleDoubleTap(int index, Offset localPosition) {
//     if (_animationController.isAnimating) return;

//     _animatingIndex = index;
//     final controller = _transformationControllers[index];
//     final double currentScale = controller.value.getMaxScaleOnAxis();
//     final Matrix4 endMatrix;

//     if (currentScale > 1.1) {
//       endMatrix = Matrix4.identity();
//     } else {
//       endMatrix = Matrix4.identity()
//         ..translate(-localPosition.dx * 1.5, -localPosition.dy * 1.5, 0.0)
//         ..scale(3.0, 3.0, 1.0);
//     }

//     _animation = Matrix4Tween(begin: controller.value, end: endMatrix).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );

//     _animationController.forward(from: 0.0);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final list = widget.images.isNotEmpty ? widget.images : [widget.imageUrl];
//     return Scaffold(
//       backgroundColor: AppColors.black,
//       body: Stack(
//         children: [
//           // Interactive Image PageView
//           Center(
//             child: PageView.builder(
//               controller: _pageController,
//               itemCount: list.length,
//               onPageChanged: (index) {
//                 setState(() {
//                   _currentIndex = index;
//                   // Reset zoom of other pages when swipe
//                   for (int i = 0; i < _transformationControllers.length; i++) {
//                     if (i != index) {
//                       _transformationControllers[i].value = Matrix4.identity();
//                     }
//                   }
//                 });
//               },
//               itemBuilder: (context, index) {
//                 return GestureDetector(
//                   onDoubleTapDown: (details) =>
//                       _handleDoubleTap(index, details.localPosition),
//                   child: InteractiveViewer(
//                     transformationController: _transformationControllers[index],
//                     minScale: 1.0,
//                     maxScale: 5.0,
//                     child: Image.network(
//                       list[index],
//                       fit: BoxFit.contain,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return const Center(
//                           child: CircularProgressIndicator(color: AppColors.white),
//                         );
//                       },
//                       errorBuilder: (context, error, stackTrace) =>
//                           const Center(
//                             child: Icon(
//                               Icons.image_not_supported,
//                               size: 100,
//                               color: AppColors.grey,
//                             ),
//                           ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           // Top Bar with Close Button
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 10,
//             left: 16,
//             right: 16,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.close, color: AppColors.white, size: 30),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//                 if (list.length > 1)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppColors.black.withValues(alpha: 0.5),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Text(
//                       '${_currentIndex + 1} / ${list.length}',
//                       style: const TextStyle(
//                         color: AppColors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 const SizedBox(width: 48), // Spacer to balance close button
//               ],
//             ),
//           ),
//           // Bottom Zoom hint
//           Positioned(
//             bottom: MediaQuery.of(context).padding.bottom + 20,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.black.withValues(alpha: 0.6),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.zoom_in, color: AppColors.white, size: 16),
//                     SizedBox(width: 8),
//                     Text(
//                       'Pinch or Double-Tap to Zoom',
//                       style: TextStyle(color: AppColors.white, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
