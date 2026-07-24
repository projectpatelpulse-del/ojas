import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroMainBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String badgeText;
  final String link;

  const HeroMainBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.badgeText = 'Hot Deal 🔥',
    this.link = '',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 768;
    final bool hasLink = link.isNotEmpty && link != '/' && link != '#';

    Widget mainContent = Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: isMobile ? 320 : 500,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
              ? NetworkImage(imageUrl) as ImageProvider
              : AssetImage(
                  imageUrl.isEmpty
                      ? 'assets/images/modern_furniture_hero.png'
                      : imageUrl,
                ),
          fit: BoxFit.fill,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// BADGE
            if (badgeText.trim().isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 18,
                  vertical: isMobile ? 7 : 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 10 : 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 18 : 28),
            ],

            // /// CATEGORY
            // Text(
            //   'OFFICE FURNITURE',
            //   style: GoogleFonts.inter(
            //     color: AppColors.white70,
            //     fontSize: isMobile ? 11 : 16,
            //     fontWeight: FontWeight.w600,
            //     letterSpacing: 1.4,
            //   ),
            // ),

            // SizedBox(height: isMobile ? 10 : 14),

            /// TITLE
            Text(
              title,
              maxLines: isMobile ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: AppColors.white,
                fontSize: isMobile ? 26 : 48,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),

            SizedBox(height: isMobile ? 12 : 18),

            /// SUBTITLE
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 600,
              ),
              child: Text(
                subtitle,
                maxLines: isMobile ? 3 : 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.white.withOpacity(0.85),
                  fontSize: isMobile ? 13 : 17,
                  height: 1.6,
                ),
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
          onTap: () => Navigator.pushNamed(context, link),
          child: mainContent,
        ),
      );
    }

    return mainContent;
  }
}