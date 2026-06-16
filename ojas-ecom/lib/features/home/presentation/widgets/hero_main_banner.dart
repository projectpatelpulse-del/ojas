import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroMainBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String badgeText;

  const HeroMainBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.badgeText = 'Hot Deal 🔥',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 768;

    return Container(
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
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.45),
              Colors.transparent,
            ],
          ),
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
                  color: const Color(0xFFF01B6B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
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
            //     color: Colors.white70,
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
                color: Colors.white,
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
                  color: Colors.white.withOpacity(0.85),
                  fontSize: isMobile ? 13 : 17,
                  height: 1.6,
                ),
              ),
            ),

            SizedBox(height: isMobile ? 22 : 32),

            /// BUTTON
            isMobile
                ? Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/shop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF01B6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'SHOP NOW',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/shop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF01B6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'SHOP NOW',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}