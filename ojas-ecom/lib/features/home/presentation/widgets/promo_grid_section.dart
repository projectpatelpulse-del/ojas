import 'package:flutter/material.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/features/home/presentation/widgets/category_promo_card.dart';
import 'package:ojas_user/features/home/presentation/widgets/weekend_deals_slider.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';

class PromoGridSection extends StatelessWidget {
  const PromoGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return CenteredContent(
      horizontalPadding: isMobile ? 16 : 40,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 40.0),
        child: ListenableBuilder(
          listenable: HomeController.instance,
          builder: (context, _) {
            final categories = HomeController.instance.categories;
            
            // UI Styles to preserve the original look
            final List<Map<String, dynamic>> promoStyles = [
              {
                'color': Colors.blue,
                'badgeTextMobile': 'BEST SALE',
                'badgeTextDesktop': 'BEST SALE',
                'badgeIcon': Icons.bolt,
                'trailingIcon': Icons.laptop_mac_outlined,
                'defaultTitleMobile': 'Beauty',
                'defaultSubtitleMobile': 'Personal Care',
                'defaultTitleDesktop': 'Beauty & Personal Care',
                'defaultSubtitleDesktop': 'Beauty & Personal Care',
              },
              {
                'color': Colors.orange,
                'badgeTextMobile': 'NEW',
                'badgeTextDesktop': 'NEW ARRIVAL',
                'badgeIcon': Icons.star_border,
                'trailingIcon': Icons.extension_outlined,
                'defaultTitleMobile': 'Toys',
                'defaultSubtitleMobile': 'Games',
                'defaultTitleDesktop': 'Toys & Games',
                'defaultSubtitleDesktop': 'Toys & Games',
              },
              {
                'color': Colors.green,
                'badgeTextMobile': '15% OFF',
                'badgeTextDesktop': 'OFF 15%',
                'badgeIcon': Icons.local_offer_outlined,
                'trailingIcon': Icons.watch_outlined,
                'defaultTitleMobile': 'Gadgets',
                'defaultSubtitleMobile': 'Latest',
                'defaultTitleDesktop': 'Gadgets',
                'defaultSubtitleDesktop': 'Gadgets',
              },
              {
                'color': Colors.deepPurple,
                'badgeTextMobile': 'FREE SHIP',
                'badgeTextDesktop': 'FREE SHIPPING',
                'badgeIcon': Icons.local_shipping_outlined,
                'trailingIcon': Icons.headphones_outlined,
                'defaultTitleMobile': 'Books',
                'defaultSubtitleMobile': 'Stationery',
                'defaultTitleDesktop': 'Books & Stationery',
                'defaultSubtitleDesktop': 'Books & Stationery',
              },
            ];

            // Build 4 dynamic cards
            final cards = List.generate(4, (index) {
              final style = promoStyles[index];
              final cat = (index < categories.length) ? categories[index] : null;
              
              String title = cat != null ? cat['name'] : (isMobile ? style['defaultTitleMobile'] : style['defaultTitleDesktop']);
              String subtitle = cat != null ? (cat['description'] ?? (isMobile ? style['defaultSubtitleMobile'] : style['defaultSubtitleDesktop'])) : (isMobile ? style['defaultSubtitleMobile'] : style['defaultSubtitleDesktop']);

              return CategoryPromoCard(
                backgroundColor: style['color'],
                badgeText: isMobile ? style['badgeTextMobile'] : style['badgeTextDesktop'],
                badgeColor: style['color'],
                badgeIcon: style['badgeIcon'],
                title: title,
                subtitle: subtitle,
                trailingIcon: style['trailingIcon'],
              );
            });

            return isMobile
                ? Column(
                    children: [
                      const SizedBox(
                        height: 300,
                        child: WeekendDealsSlider(),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                        children: cards,
                      ),
                    ],
                  )
                : SizedBox(
                    height: 480,
                    child: Row(
                      children: [
                        // Left: 2x2 Grid
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: cards[0]),
                                    const SizedBox(width: 16),
                                    Expanded(child: cards[1]),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: cards[2]),
                                    const SizedBox(width: 16),
                                    Expanded(child: cards[3]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right: Weekend Deals Slider
                        const Expanded(
                          flex: 5,
                          child: WeekendDealsSlider(),
                        ),
                      ],
                    ),
                  );
          }
        ),
      ),
    );
  }
}
