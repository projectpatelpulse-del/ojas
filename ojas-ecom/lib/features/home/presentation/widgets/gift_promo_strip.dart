import 'package:flutter/material.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/features/home/data/models/banner_model.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';

class GiftPromoStrip extends StatelessWidget {
  const GiftPromoStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) {
        final allBanners = HomeController.instance.banners;
        final matchingBanners = allBanners.where((b) => b.type == 'gift_promo_strip').toList();
        final BannerModel? banner = matchingBanners.isNotEmpty ? matchingBanners[0] : null;

        final String imageUrl = banner != null ? banner.imageUrl : '';
        final String link = banner != null && banner.link.isNotEmpty ? banner.link : '/shop';

        if (imageUrl.isNotEmpty) {
          final bool isTablet = Responsive.isTablet(context);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, link),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: isMobile ? 180 : (isTablet ? 280 : 360),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    // border: Border.all(color: AppColors.borderLight.withOpacity(0.8)),
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
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 600;

              final String title = banner != null && banner.title.isNotEmpty ? banner.title : 'Why choose Ojas India';
              final String subtitle = banner != null && banner.subtitle.isNotEmpty ? banner.subtitle : 'Shop now and get extra 20% off with code';
              final String tag = banner != null && banner.tag.isNotEmpty ? banner.tag : 'GIFT20';
              final String buttonText = 'Shop Now';

                final bool hasLink = link.isNotEmpty && link != '/' && link != '#';

                Widget mainContent = Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight.withOpacity(0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Main Primary Strip
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 16 : 24,
                          vertical: isSmall ? 16 : 20,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: isSmall
                              ? WrapAlignment.center
                              : WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: isSmall
                                  ? MainAxisSize.max
                                  : MainAxisSize.min,
                              mainAxisAlignment: isSmall
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.card_giftcard,
                                    color: AppColors.white,
                                    size: isSmall ? 24 : 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.white,
                                      fontSize: isSmall ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Subtext Strip
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 16 : 24,
                          vertical: 15,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: isSmall
                                ? WrapAlignment.center
                                : WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                subtitle,
                                textAlign: isSmall ? TextAlign.center : TextAlign.start,
                                style: GoogleFonts.inter(
                                  color: AppColors.black87,
                                  fontSize: isSmall ? 13 : 14,
                                ),
                              ),
                              if (tag.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE7EF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.inter(
                                      color: AppColors.primaryPink,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );

              if (hasLink) {
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, link),
                    child: mainContent,
                  ),
                );
              }

              return mainContent;
              },
            ),
          );
      },
    );
  }
}
