import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/controllers/wishlist_controller.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:ojas_user/core/routes/app_router.dart';
import 'package:ojas_user/core/utils/responsive.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OjasLayout(
      activeTitle: 'WISHLIST',
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: CenteredContent(
          child: ListenableBuilder(
            listenable: WishlistController.instance,
            builder: (context, _) {
              final items = WishlistController.instance.wishlistItems;
              final isLoading = WishlistController.instance.isLoading;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  
                  // Header
                  Text(
                    'My Wishlist',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save items for later and never lose track of what you love',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  if (isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(100.0),
                      child: CircularProgressIndicator(color: AppColors.primaryPink),
                    ))
                  else if (!SessionService.instance.isLoggedIn)
                    _buildNotLoggedInState(context)
                  else if (items.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildWishlistGrid(context, items),

                  const SizedBox(height: 120),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedInState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.lock_outline_rounded,
            size: 120,
            color: const Color(0xFF94A3B8).withOpacity(0.5),
          ),
          const SizedBox(height: 32),
          Text(
            'Sign In to View Wishlist',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please log in to your account to view and manage your saved items.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => AppRouter.push(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sign In Now',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.favorite_border_rounded,
            size: 150,
            color: const Color(0xFF94A3B8).withOpacity(0.5),
          ),
          const SizedBox(height: 48),
          Text(
            'Your wishlist is empty',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start adding items you love to keep track of them',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => AppRouter.go(context, '/shop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Start Shopping',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistGrid(BuildContext context, List<dynamic> items) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isMobile ? 0.95 : 0.65,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return _WishlistItemCard(product: product);
      },
    );
  }
}

class _WishlistItemCard extends StatelessWidget {
  final dynamic product;
  const _WishlistItemCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final String? productId = (product['productId'] ?? product['_id'])?.toString();
    final String? variationId = product['variationId']?.toString();
    final String? variationTitle = product['variationTitle']?.toString();

    final imageList = product['images'];
    final String imageUrl = (imageList != null && imageList is List && imageList.isNotEmpty)
        ? imageList[0].toString()
        : (product['image'] ?? '').toString();

    final double price = ((product['discountPrice'] != null && product['discountPrice'] > 0)
        ? product['discountPrice']
        : (product['price'] ?? 0)).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  onTap: () {
                    if (productId != null) {
                      AppRouter.push(
                        context,
                        '/product/$productId${variationId != null ? "?variation=$variationId" : ""}',
                        extra: product,
                      );
                    }
                  },
                  child: Image.network(
                    ApiService.formatImageUrl(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported_outlined, color: AppColors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: CircleAvatar(
                    backgroundColor: AppColors.white,
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: AppColors.primaryPink),
                      onPressed: () {
                        if (productId != null) {
                          WishlistController.instance.removeFromWishlist(
                            productId,
                            variationId: variationId,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          if (productId != null) {
                            AppRouter.push(
                              context,
                              '/product/$productId${variationId != null ? "?variation=$variationId" : ""}',
                              extra: product,
                            );
                          }
                        },
                        child: Text(
                          product['name'] ?? 'Product Name',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (variationTitle != null && variationTitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPink.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primaryPink.withOpacity(0.2)),
                          ),
                          child: Text(
                            variationTitle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (productId == null) return;

                        debugPrint('[WishlistPage] "Move to Cart" clicked -> Product ID: $productId, Variation ID: $variationId ("$variationTitle")');

                        // 1. Add to Cart with the exact variation!
                        final success = await CartController.instance.addToCart(
                          productId,
                          variationId: variationId,
                        );

                        if (success) {
                          // 2. Remove from Wishlist with the exact variation!
                          await WishlistController.instance.removeFromWishlist(
                            productId,
                            variationId: variationId,
                          );

                          if (context.mounted) {
                            final label = variationTitle != null && variationTitle.isNotEmpty
                                ? '${product['name'] ?? 'Item'} ($variationTitle)'
                                : '${product['name'] ?? 'Item'}';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$label moved to cart!'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to add to cart. Please check your connection.'),
                                backgroundColor: AppColors.errorRed,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryPink),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Move to Cart',
                        style: GoogleFonts.inter(
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
