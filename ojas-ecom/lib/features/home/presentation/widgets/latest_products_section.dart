import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/features/home/presentation/widgets/latest_product_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';

class LatestProductsSection extends StatelessWidget {
  const LatestProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    return CenteredContent(
      horizontalPadding: isMobile ? 16 : 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Products',
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
            
            ListenableBuilder(
              listenable: HomeController.instance,
              builder: (context, _) {
                final backendProducts = HomeController.instance.latestProducts;

                if (backendProducts.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey100),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.new_releases_outlined, size: 40, color: AppColors.grey300),
                        const SizedBox(height: 12),
                        Text(
                          'Stay tuned! New products arriving soon.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: backendProducts.length > 5 ? 5 : backendProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 5),
                    crossAxisSpacing: isMobile ? 12 : 16,
                    mainAxisSpacing: isMobile ? 12 : 16,
                    mainAxisExtent: isMobile ? 400 : 380,
                  ),
                  itemBuilder: (context, index) {
                    final p = backendProducts[index];
                    final id = p['_id']?.toString() ?? p['id']?.toString() ?? '';
                    
                    final productModel = ProductModel.fromMap(p);
                    
                    return LatestProductCard(
                      product: productModel,
                      rating: 4.0,
                      onAddToCart: () async {
                        final success = await CartController.instance.addToCart(id, moq: productModel.moq);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success ? 'Added to cart!' : 'Failed. Please login.'),
                            backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ));
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

