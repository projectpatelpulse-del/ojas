import 'package:flutter/material.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/core/controllers/wishlist_controller.dart';

class DailyDealCard extends StatelessWidget {
  final ProductModel product;

  const DailyDealCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final double progress = (product.sold ?? 0) / ((product.available ?? 1) + (product.sold ?? 0));
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return ListenableBuilder(
      listenable: WishlistController.instance,
      builder: (context, _) {
        final bool isWishlisted = WishlistController.instance.isWishlisted(product.id);
        
        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category/Brand Label
            Text(
              (product.brand ?? product.category ?? 'Ojas Premium').toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),

            // Product Name
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              product.shortDescription ?? 'Premium quality guaranteed. High durability and modern design.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B), 
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            
            // Pricing Block
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹${product.price.ceil()}',
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                if (product.oldPrice != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '₹${product.oldPrice!.ceil()}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      decoration: TextDecoration.lineThrough,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 14),
            
            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await CartController.instance.addToCart(product.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? '${product.name} added to cart' : 'Failed to add to cart. Please login first.'),
                        backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.white),
                label: const Text('Add to Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        );

        return InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/product-detail?id=${product.id}',
            arguments: product,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPink.withOpacity(0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(isWishlisted),
                const SizedBox(height: 14),
              content,
            ],
          ),
        ));
      },
    );
  }

  Widget _buildImage(bool isWishlisted) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFF8FAFC),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, _, __) => const Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 36, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
          ),
        ),
        
        // Discount Badge
        if (product.discount > 0)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.errorRed.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '${product.discount}% OFF',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          
        // Wishlist Button
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: () {
              final productMap = {
                '_id': product.id,
                'name': product.name,
                'price': product.price,
                'images': [product.imageUrl],
              };
              WishlistController.instance.toggleWishlist(productMap);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isWishlisted ? Icons.favorite : Icons.favorite_border_rounded, 
                size: 16, 
                color: isWishlisted ? AppColors.primaryPink : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
