import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/core/controllers/settings_controller.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';
import 'package:ojas_user/features/home/presentation/widgets/product_card.dart';
import 'package:ojas_user/features/home/presentation/widgets/service_card.dart';
import 'package:ojas_user/features/home/presentation/widgets/category_filter.dart';
import 'package:ojas_user/features/home/presentation/widgets/trending_promo_banner.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';

import '../../../../core/services/session_service.dart';

class TrendingItemsSection extends StatefulWidget {
  const TrendingItemsSection({super.key});

  @override
  State<TrendingItemsSection> createState() => _TrendingItemsSectionState();
}

class _TrendingItemsSectionState extends State<TrendingItemsSection> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final settingsController = SettingsController.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([HomeController.instance, settingsController]),
      builder: (context, _) {
        final settings = settingsController.settings;
        final List<String> categories = settings.trendingCategories
            .split(',')
            .map((e) => e.trim())
            .toList();
        
        if (!categories.contains('All')) {
          categories.insert(0, 'All');
        }

        var products = HomeController.instance.homeProducts;

        // Apply filtering
        if (_selectedCategory != 'All') {
          products = products.where((p) {
            final category = p['category'];
            String? catName;
            if (category is Map) {
              catName = category['name']?.toString();
            } else if (p['categoryName'] != null) {
              catName = p['categoryName'].toString();
            }
            
            // Match against selected category (partial match or exact)
            if (catName == null) return false;
            return catName.toLowerCase().contains(_selectedCategory.split(' ')[0].toLowerCase());
          }).toList();
        }

        final bool isMobile = Responsive.isMobile(context);
        final bool isTablet = Responsive.isTablet(context);

        return CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Column(
            children: [
              SizedBox(height: isMobile ? 32 : 60),
              // 1. Header
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TRENDING ITEMS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: CategoryFilter(
                        categories: categories,
                        selectedCategory: _selectedCategory,
                        onCategoryChanged: (cat) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TRENDING ITEMS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                    const Spacer(),
                    CategoryFilter(
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (cat) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  ],
                ),
              SizedBox(height: isMobile ? 24 : 40),
              
              // 2. Service Grid & Banner
              if (isMobile || isTablet)
                Column(
                  children: [
                    GridView(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 150,
                      ),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ServiceCard(
                          title: settings.serviceCard1Title,
                          subtitle: settings.serviceCard1Subtitle,
                          iconUrl: settings.serviceCard1Icon,
                        ),
                        ServiceCard(
                          title: settings.serviceCard2Title,
                          subtitle: settings.serviceCard2Subtitle,
                          iconUrl: settings.serviceCard2Icon,
                        ),
                        ServiceCard(
                          title: settings.serviceCard3Title,
                          subtitle: settings.serviceCard3Subtitle,
                          iconUrl: settings.serviceCard3Icon,
                        ),
                        ServiceCard(
                          title: settings.serviceCard4Title,
                          subtitle: settings.serviceCard4Subtitle,
                          iconUrl: settings.serviceCard4Icon,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 300, child: TrendingPromoBanner()),
                  ],
                )
              else
                SizedBox(
                  height: 580,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ServiceCard(
                              title: settings.serviceCard1Title,
                              subtitle: settings.serviceCard1Subtitle,
                              iconUrl: settings.serviceCard1Icon,
                            ),
                            ServiceCard(
                              title: settings.serviceCard2Title,
                              subtitle: settings.serviceCard2Subtitle,
                              iconUrl: settings.serviceCard2Icon,
                            ),
                            ServiceCard(
                              title: settings.serviceCard3Title,
                              subtitle: settings.serviceCard3Subtitle,
                              iconUrl: settings.serviceCard3Icon,
                            ),
                            ServiceCard(
                              title: settings.serviceCard4Title,
                              subtitle: settings.serviceCard4Subtitle,
                              iconUrl: settings.serviceCard4Icon,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Expanded(
                        flex: 2,
                        child: TrendingPromoBanner(),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: isMobile ? 32 : 48),
              
              // 3. Trending Product Grid
              if (products.isEmpty)
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
                      Icon(Icons.trending_up_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No trending products at the moment.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length > 5 ? 5 : products.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 5),
                    mainAxisSpacing: isMobile ? 12 : 24,
                    crossAxisSpacing: isMobile ? 12 : 24,
                    mainAxisExtent: isMobile ? 380 : 420,
                  ),
                  itemBuilder: (context, index) {
                    final product = ProductModel.fromMap(products[index]);
                    return ProductCard(
                      product: product,
                      onAddToCart: () async {
                        final String? token = SessionService.instance.token;
                        if (token == null) {
                          CartController.instance.setPendingItem(product.id, null);
                          Navigator.pushNamed(context, '/login');
                          return;
                        }
                        
                        final success = await CartController.instance.addToCart(product.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success ? '${product.name} added to cart!' : 'Failed to add. Please login.'),
                            backgroundColor: success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ));
                        }
                      },
                    );
                  },
                ),
              SizedBox(height: isMobile ? 32 : 60),
            ],
          ),
        );
      },
    );
  }
}
