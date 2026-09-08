import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/features/home/presentation/widgets/category_promo_card.dart';
import 'package:ojas_user/features/home/presentation/widgets/weekend_deals_slider.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';

class PromoGridSection extends StatelessWidget {
  const PromoGridSection({super.key});

  Color _parseHexColor(String hexString, Color defaultColor) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return defaultColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return CenteredContent(
      horizontalPadding: isMobile ? 16 : 40,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 40.0),
        child: ListenableBuilder(
          listenable: HomeController.instance,
          builder: (context, _) {
            final home = HomeController.instance;
            final promoBanners = [
              home.promoGrid0,
              home.promoGrid1,
              home.promoGrid2,
              home.promoGrid3,
            ];

            // Build 4 dynamic cards
            final cards = List.generate(4, (index) {
              final banner = promoBanners[index];
              final Color color = _parseHexColor(banner.bgColor, Colors.blue);
              
              IconData badgeIcon;
              IconData trailingIcon;
              switch (index) {
                case 1:
                  badgeIcon = Icons.star_border;
                  trailingIcon = Icons.extension_outlined;
                  break;
                case 2:
                  badgeIcon = Icons.local_offer_outlined;
                  trailingIcon = Icons.watch_outlined;
                  break;
                case 3:
                  badgeIcon = Icons.local_shipping_outlined;
                  trailingIcon = Icons.headphones_outlined;
                  break;
                case 0:
                default:
                  badgeIcon = Icons.bolt;
                  trailingIcon = Icons.laptop_mac_outlined;
                  break;
              }

              return CategoryPromoCard(
                backgroundColor: color,
                badgeText: banner.tag,
                badgeColor: color,
                badgeIcon: badgeIcon,
                title: banner.title,
                subtitle: banner.subtitle,
                trailingIcon: trailingIcon,
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
