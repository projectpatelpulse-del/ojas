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
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    '₹${product.price.ceil()}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF01B6B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (product.oldPrice != null)
                    Text(
                      '₹${product.oldPrice!.ceil()}',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Premium quality guaranteed. High durability and modern design.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Available: ${product.available}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Flexible(child: Text('Sold: ${product.sold}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF01B6B)), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF01B6B)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            
            // Buttons
            // Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/product-detail?id=${product.id}', arguments: product),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove_red_eye_outlined, size: 20, color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final success = await CartController.instance.addToCart(product.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '${product.name} added to cart' : 'Failed to add to cart. Please login first.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF01B6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(100, 40),
                  ),
                  child: const FittedBox(
                    child: Text(
                      'Add to Cart', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isMobile 
            ? Column(
                children: [
                  _buildImage(isWishlisted),
                  const SizedBox(height: 20),
                  content,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildImage(isWishlisted),
                  const SizedBox(width: 24),
                  Expanded(child: content),
                ],
              ),
        );
      },
    );
  }

  Widget _buildImage(bool isWishlisted) {
    return Stack(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, _, __) => const Center(
                child: Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF01B6B),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${product.discount}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
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
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Icon(
                isWishlisted ? Icons.favorite : Icons.favorite_border, 
                size: 18, 
                color: isWishlisted ? const Color(0xFFF01B6B) : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
