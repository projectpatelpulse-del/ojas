import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
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

        var products = HomeController.instance.trendingProducts;

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
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: CategoryFilter(
                        categories: categories,
                        selectedCategory: _selectedCategory,
                        onCategoryChanged: (cat) {
                          Navigator.pushNamed(
                            context,
                            '/shop',
                            arguments: <String, dynamic>{
                              'category': cat,
                              'subcategory': 'All',
                            },
                          );
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
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                    const Spacer(),
                    CategoryFilter(
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (cat) {
                        Navigator.pushNamed(
                          context,
                          '/shop',
                          arguments: <String, dynamic>{
                            'category': cat,
                            'subcategory': 'All',
                          },
                        );
                      },
                    ),
                  ],
                ),
              SizedBox(height: isMobile ? 24 : 40),
              
              // 2. Styled Gifting Partner Section (from image layout / Admin dynamic banner)
              if (settings.showTrendingB2BBanner) ...[
                Builder(
                  builder: (context) {
                    final allBanners = HomeController.instance.banners;
                    final b2bBanners = allBanners
                        .where((b) => b.type == 'b2b_partner')
                        .toList();
                    final banner = b2bBanners.isNotEmpty ? b2bBanners[0] : null;

                    if (banner != null && banner.imageUrl.isNotEmpty) {
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            final targetLink = banner.link.isEmpty ? '/shop' : banner.link;
                            Navigator.pushNamed(context, targetLink);
                          },
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              maxHeight: isMobile ? 180 : (isTablet ? 280 : 360),
                            ),
                            decoration:  BoxDecoration(
                            borderRadius: BorderRadius.circular(12),

                              color: Colors.transparent,
                               boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              banner.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      );
                    }

                    final String tagText = (banner != null && banner.tag.isNotEmpty)
                        ? banner.tag.toUpperCase()
                        : 'WHY CHOOSE OJAS INDIA?';
                    final String titleText = (banner != null && banner.title.isNotEmpty)
                        ? banner.title
                        : 'Your Trusted B2B\nGifting Partner';
                    final String buttonText = 'Know More About Us';
                    final String link = (banner != null && banner.link.isNotEmpty) ? banner.link : '/about-us';

                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 40,
                        vertical: isMobile ? 32 : 48,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryIndigo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tagText,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFBBF24),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  titleText,
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBBF24),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => Navigator.pushNamed(context, link),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.transparent,
                                    foregroundColor: const Color(0xFFFBBF24),
                                    side: const BorderSide(color: Color(0xFFFBBF24), width: 1.5),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    buttonText,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                const Divider(color: AppColors.white24, height: 1),
                                const SizedBox(height: 24),
                                _buildFeatureItem(Icons.verified_outlined, '40+ Years of Experience'),
                                const SizedBox(height: 16),
                                _buildFeatureItem(Icons.diamond_outlined, 'Wide Range Premium Quality Products'),
                                const SizedBox(height: 16),
                                _buildFeatureItem(Icons.inventory_2_outlined, 'Bulk Order Support & Best Pricing'),
                                const SizedBox(height: 16),
                                _buildFeatureItem(Icons.edit_note_outlined, 'Custom Branding & Private Label Solutions'),
                                const SizedBox(height: 16),
                                _buildFeatureItem(Icons.card_giftcard_outlined, 'Premium Packaging'),
                                const SizedBox(height: 16),
                                _buildFeatureItem(Icons.local_shipping_outlined, 'PAN India Delivery'),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left Content Block
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        tagText,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFBBF24),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        titleText,
                                        style: GoogleFonts.outfit(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.white,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: 60,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFBBF24),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pushNamed(context, link),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.transparent,
                                          foregroundColor: const Color(0xFFFBBF24),
                                          side: const BorderSide(color: Color(0xFFFBBF24), width: 1.5),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          buttonText,
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32),
                                // Right Features Grid List
                                Expanded(
                                  flex: 7,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildGridFeatureItem(Icons.verified_outlined, '40+', 'Years of\nExperience'),
                                      _buildVerticalDivider(),
                                      _buildGridFeatureItem(Icons.diamond_outlined, 'Wide Range', 'Premium Quality\nProducts'),
                                      _buildVerticalDivider(),
                                      _buildGridFeatureItem(Icons.inventory_2_outlined, 'Bulk Order', 'Support & Best\nPricing'),
                                      _buildVerticalDivider(),
                                      _buildGridFeatureItem(Icons.edit_note_outlined, 'Custom Branding &', 'Private Label\nSolutions'),
                                      _buildVerticalDivider(),
                                      _buildGridFeatureItem(Icons.card_giftcard_outlined, 'Premium', 'Packaging'),
                                      _buildVerticalDivider(),
                                      _buildGridFeatureItem(Icons.local_shipping_outlined, 'PAN India', 'Delivery'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ],
              
              SizedBox(height: isMobile ? 32 : 48),
              
              // 3. Trending Product Grid
              if (settings.showTrendingProducts) ...[
                if (products.isEmpty)
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
                          'No trending products at the moment.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.grey500,
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
              // SizedBox(height: isMobile ? 32 : 60),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFBBF24), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridFeatureItem(IconData icon, String boldText, String subText) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFBBF24), size: 36),
          const SizedBox(height: 12),
          Text(
            boldText,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFBBF24),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontSize: 12,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 60,
      width: 1,
      color: AppColors.white24,
    );
  }
}

