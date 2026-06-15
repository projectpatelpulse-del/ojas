import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';
import 'package:ojas_user/features/home/presentation/widgets/product_card.dart';
import 'package:ojas_user/features/home/presentation/widgets/section_title.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';

class FeaturedDealsSection extends StatelessWidget {
  const FeaturedDealsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final allProducts = ProductModel.dummyProducts;
    final featuredProducts = allProducts.take(3).toList();

    return CenteredContent(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            SectionTitle(title: 'Featured Deals of the Week', onSeeAll: null),
            const SizedBox(height: 32),
            if (featuredProducts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.stars_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Stay tuned for this week\'s featured deals!',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              MediaQuery.of(context).size.width < 850
                  ? Column(
                      children: [
                        for (var product in featuredProducts) ...[
                          SizedBox(
                            height: 380,
                            child: ProductCard(
                              product: product,
                              onAddToCart: () async {
                                final success = await CartController.instance.addToCart(product.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(success ? '${product.name} added to cart!' : 'Failed. Please login.'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    )
                  : SizedBox(
                      height: 420,
                      child: Row(
                        children: [
                          for (var i = 0; i < featuredProducts.length; i++) ...[
                            Expanded(
                              child: ProductCard(
                                product: featuredProducts[i],
                                onAddToCart: () async {
                                  final success = await CartController.instance.addToCart(featuredProducts[i].id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(success ? '${featuredProducts[i].name} added to cart!' : 'Failed. Please login.'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                },
                              ),
                            ),
                            if (i < featuredProducts.length - 1) const SizedBox(width: 24),
                          ],
                        ],
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
