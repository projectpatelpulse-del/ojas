// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class HeroSideBanner extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final String imageUrl;
//   final String badgeText;
//   final Color badgeColor;

//   const HeroSideBanner({
//     super.key,
//     required this.title,
//     required this.subtitle,
//     required this.imageUrl,
//     required this.badgeText,
//     required this.badgeColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final bool isMobile = MediaQuery.of(context).size.width < 768;

//     return InkWell(
//       onTap: () => Navigator.pushNamed(context, '/shop'),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           image: DecorationImage(
//             image: (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
//                 ? NetworkImage(imageUrl) as ImageProvider
//                 : AssetImage(imageUrl.isEmpty ? 'assets/images/colorful_pillows_promo.png' : imageUrl),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: Container(
//           padding: EdgeInsets.all(isMobile ? 16 : 24),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             gradient: LinearGradient(
//               begin: isMobile ? Alignment.centerLeft : Alignment.bottomCenter,
//               end: isMobile ? Alignment.centerRight : Alignment.topCenter,
//               colors: [
//                 Colors.black.withOpacity(0.8),
//                 Colors.black.withOpacity(0.4),
//                 Colors.transparent,
//               ],
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.end,
//             children: [
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 4,
//                 crossAxisAlignment: WrapCrossAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: badgeColor,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.flash_on, color: Colors.white, size: 12),
//                         const SizedBox(width: 4),
//                         Text(
//                           badgeText.toUpperCase(),
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 10,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Flexible(
//                 child: Text(
//                   title,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: GoogleFonts.outfit(
//                     color: Colors.white,
//                     fontSize: 16, // Reduced from 18 for better fitting
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Flexible(
//                 child: Text(
//                   subtitle,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               if (isMobile)
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF01B6B),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Text(
//                     'SHOP NOW',
//                     style: GoogleFonts.inter(
//                       color: Colors.white,
//                       fontSize: 11,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 )
//               else
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       'Shop now',
//                       style: GoogleFonts.inter(
//                         color: Colors.white,
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const Icon(Icons.chevron_right, color: Colors.white, size: 16),
//                   ],
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }





import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroSideBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String badgeText;
  final Color badgeColor;

  const HeroSideBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.badgeText,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 768;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/shop'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: isMobile ? 220 : 320,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
                ? NetworkImage(imageUrl) as ImageProvider
                : AssetImage(
                    imageUrl.isEmpty
                        ? 'assets/images/colorful_pillows_promo.png'
                        : imageUrl,
                  ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin:
                  isMobile ? Alignment.centerLeft : Alignment.bottomCenter,
              end: isMobile ? Alignment.centerRight : Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.45),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isMobile ? MainAxisAlignment.center : MainAxisAlignment.end,
            children: [
              /// BADGE
              if (badgeText.trim().isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeText.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 14 : 18),
              ],

              /// TITLE
              Text(
                title,
                maxLines: isMobile ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: isMobile ? 20 : 25,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              /// SUBTITLE
              Text(
                subtitle,
                maxLines: isMobile ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: isMobile ? 13 : 15,
                  height: 1.4,
                ),
              ),

              SizedBox(height: isMobile ? 18 : 24),

              /// BUTTON
              isMobile
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF01B6B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'SHOP NOW',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Shop now',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}