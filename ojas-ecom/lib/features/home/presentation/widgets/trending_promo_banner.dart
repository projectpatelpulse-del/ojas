import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';

class TrendingPromoBanner extends StatelessWidget {
  const TrendingPromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) {
        final banner = HomeController.instance.trendingBanner;
        
        final bool hasLink = banner.link.isNotEmpty && banner.link != '/' && banner.link != '#';

        Widget mainContent = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: banner.imageUrl.startsWith('http') 
                  ? NetworkImage(banner.imageUrl) as ImageProvider
                  : AssetImage(banner.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner.subtitle,
                  style: GoogleFonts.inter(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  banner.title,
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        );

        if (hasLink) {
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, banner.link),
              child: mainContent,
            ),
          );
        }

        return mainContent;
      },
    );
  }
}
