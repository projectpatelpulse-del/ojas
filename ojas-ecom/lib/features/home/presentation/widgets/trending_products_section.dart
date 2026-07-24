import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';
import 'package:ojas_user/features/home/presentation/widgets/product_card.dart';
import 'package:ojas_user/features/home/presentation/widgets/section_title.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:google_fonts/google_fonts.dart';

class TrendingProductsSection extends StatelessWidget {
  const TrendingProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final trendingProducts = ProductModel.dummyProducts;

    return CenteredContent(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            const SectionTitle(title: 'Trending Products', onSeeAll: null),
            const SizedBox(height: 32),
            if (trendingProducts.isEmpty)
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
                    Icon(Icons.trending_up_outlined, size: 48, color: AppColors.grey300),
                    const SizedBox(height: 16),
                    Text(
                      'No trending products available right now.',
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.72,
                ),
                itemCount: trendingProducts.length,
                itemBuilder: (context, index) {
                  final product = trendingProducts[index];
                  return ProductCard(
                    product: product,
                    onAddToCart: () async {
                      final success = await CartController.instance.addToCart(product.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success ? '${product.name} added to cart!' : 'Failed. Please login.'),
                          backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ));
                      }
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
