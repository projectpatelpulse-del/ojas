import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';

class SummerSaleBanner extends StatelessWidget {
  const SummerSaleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) {
        final banner = HomeController.instance.summerSaleBanner;
        final bool isTablet = Responsive.isTablet(context);
        final bool hasLink = banner.link.isNotEmpty && banner.link != '/' && banner.link != '#';
        final String imageUrl = banner.imageUrl;

        Widget mainContent;
        if (imageUrl.isNotEmpty) {
          mainContent = CenteredContent(
            horizontalPadding: isMobile ? 16 : 40,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: isMobile ? 180 : (isTablet ? 280 : 360),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    )
                  : Image.asset(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
            ),
          );
        } else {
          mainContent = CenteredContent(
            horizontalPadding: isMobile ? 16 : 40,
            child: Container(
              height: isMobile ? 200 : 280,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade100,
              ),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 20 : 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (banner.tag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, color: AppColors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              banner.tag,
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    if (banner.tag.isNotEmpty) const SizedBox(height: 16),
                    Text(
                      banner.title,
                      style: GoogleFonts.outfit(
                        color: AppColors.white,
                        fontSize: isMobile ? 24 : 36,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (hasLink) {
          final targetLink = banner.link.isEmpty ? '/shop' : banner.link;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, targetLink),
              child: mainContent,
            ),
          );
        }

        return mainContent;
      },
    );
  }
}
