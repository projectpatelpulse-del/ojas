import 'package:flutter/material.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/features/home/data/models/banner_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';

class BannerWidget extends StatelessWidget {
  final BannerModel banner;
  final bool isHero;

  const BannerWidget({
    super.key,
    required this.banner,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLink = banner.link.isNotEmpty && banner.link != '/' && banner.link != '#';

    Widget mainContent = Container(
      width: double.infinity,
      height: isHero ? 450 : 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(banner.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(isHero ? 60 : 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: CenteredContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                banner.title,
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: isHero ? 48 : 32,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: isHero ? 500 : 400,
                child: Text(
                  banner.subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.white.withOpacity(0.9),
                    fontSize: isHero ? 18 : 16,
                  ),
                ),
              ),
            ],
          ),
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
  }
}
