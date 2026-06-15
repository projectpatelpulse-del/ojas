import 'package:flutter/material.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/features/home/presentation/widgets/featured_header.dart';
import 'package:ojas_user/features/home/presentation/widgets/featured_product_card.dart';
import 'package:ojas_user/features/home/presentation/widgets/why_choose_section.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    return OjasLayout(
      activeTitle: 'FEATURES',
      child: CenteredContent(
        horizontalPadding: isMobile ? 16 : 40,
        child: ListenableBuilder(
          listenable: HomeController.instance,
          builder: (context, _) {
            final backendProducts = HomeController.instance.featureProducts;
            final int count = backendProducts.length;

            if (count == 0 && !HomeController.instance.isLoading) {
              return Padding(
                padding: const EdgeInsets.all(100.0),
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No featured products found.',
                      style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                FeaturedHeader(productCount: count),
                SizedBox(height: isMobile ? 24 : 48),
                if (HomeController.instance.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                      crossAxisSpacing: isMobile ? 16 : 30,
                      mainAxisSpacing: isMobile ? 16 : 30,
                      childAspectRatio: isMobile ? 0.8 : 0.6,
                    ),
                    itemCount: count,
                    itemBuilder: (context, index) {
                      final p = backendProducts[index];
                      final id = p['_id']?.toString() ?? p['id']?.toString() ?? '';
                      final imageUrl = (p['images'] != null && (p['images'] as List).isNotEmpty)
                          ? p['images'][0].toString()
                          : (p['image']?.toString() ?? 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500');
                      
                      final discountPrice = (p['discountPrice'] ?? 0).toDouble();
                      final price = (p['price'] ?? 0).toDouble();
                      final int discountPct = discountPrice > 0 && price > 0
                          ? ((price - discountPrice) / price * 100).round()
                          : 0;

                      return FeaturedProductCard(
                        productId: id,
                        name: p['name']?.toString() ?? 'Product',
                        imageUrl: imageUrl,
                        price: discountPrice > 0 ? discountPrice : price,
                        oldPrice: discountPrice > 0 ? price : null,
                        discount: discountPct,
                        brand: p['brand']?.toString() ?? 'Brand',
                        category: p['category']?.toString() ?? 'Category',
                        description: p['description']?.toString() ?? '',
                        onAddToCart: () async {
                          final success = await CartController.instance.addToCart(id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(success ? 'Added to cart!' : 'Failed. Please login.'),
                              backgroundColor: success ? Colors.green : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ));
                          }
                        },
                      );
                    },
                  ),
                SizedBox(height: isMobile ? 40 : 60),
                const WhyChooseSection(),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }
}

