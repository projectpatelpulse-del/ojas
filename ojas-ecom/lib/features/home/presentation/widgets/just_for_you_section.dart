import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';
import 'package:ojas_user/features/home/presentation/widgets/just_for_you_card.dart';

class JustForYouSection extends StatelessWidget {
  const JustForYouSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);
    
    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) {
        final products = HomeController.instance.justForYouProducts;
        final List<ProductModel> productModels = products.map((p) => ProductModel.fromMap(p)).toList();

        return CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Just For You',
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/shop'),
                      child: Text(
                        'View all',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                if (productModels.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.grey300),
                        const SizedBox(height: 16),
                        Text(
                          'No products available in this section yet.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.grey500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: productModels.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 5),
                      crossAxisSpacing: isMobile ? 12 : 16,
                      mainAxisSpacing: isMobile ? 12 : 16,
                      mainAxisExtent: isMobile ? 320 : 360,
                    ),
                    itemBuilder: (context, index) {
                      final product = productModels[index];
                      return JustForYouCard(
                        imageUrl: product.imageUrl,
                        brand: 'Ojas',
                        title: product.name,
                        price: product.price,
                        oldPrice: product.oldPrice ?? (product.price * 1.2),
                        discount: product.discount,
                        hasBestSellerBadge: product.discount > 50,
                        onAddToCart: () async {
                          final success = await CartController.instance.addToCart(product.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Added to cart!' : 'Failed to add to cart'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}


