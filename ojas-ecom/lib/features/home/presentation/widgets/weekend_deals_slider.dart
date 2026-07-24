// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class WeekendDealsSlider extends StatelessWidget {
//   const WeekendDealsSlider({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         image: const DecorationImage(
//           image: NetworkImage(
//             'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200',
//           ),
//           fit: BoxFit.cover,
//         ),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           color: AppColors.black.withOpacity(0.4), // Dark overlay
//         ),
//         child: Stack(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(40.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFD81B60),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(
//                           Icons.local_offer_outlined,
//                           color: AppColors.white,
//                           size: 14,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           'LIMITED OFFER',
//                           style: GoogleFonts.inter(
//                             color: AppColors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   Text(
//                     'Weekend Deals',
//                     style: GoogleFonts.outfit(
//                       color: AppColors.white,
//                       fontSize: 48,
//                       fontWeight: FontWeight.bold,
//                       height: 1.1,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Accessories • Speakers • Smart Home',
//                     style: GoogleFonts.inter(
//                       color: AppColors.white.withOpacity(0.9),
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Navigation Arrows
//             Positioned(
//               left: 16,
//               top: 0,
//               bottom: 0,
//               child: Center(child: _navButton(Icons.arrow_back)),
//             ),
//             Positioned(
//               right: 16,
//               top: 0,
//               bottom: 0,
//               child: Center(child: _navButton(Icons.arrow_forward)),
//             ),

//             // Highlight Dots
//             Positioned(
//               bottom: 24,
//               left: 0,
//               right: 0,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _dot(AppColors.white.withOpacity(0.5), width: 8),
//                   const SizedBox(width: 6),
//                   _dot(AppColors.white, width: 24), // Active dot
//                   const SizedBox(width: 6),
//                   _dot(AppColors.white.withOpacity(0.5), width: 8),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _navButton(IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 4),
//         ],
//       ),
//       child: Icon(icon, color: AppColors.black87, size: 20),
//     );
//   }

//   Widget _dot(Color color, {required double width}) {
//     return Container(
//       width: width,
//       height: 8,
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(4),
//       ),
//     );
//   }
// }




import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/features/home/data/models/banner_model.dart';
import 'package:ojas_user/core/constants/app_colors.dart';

class WeekendDealsSlider extends StatefulWidget {
  const WeekendDealsSlider({super.key});

  @override
  State<WeekendDealsSlider> createState() => _WeekendDealsSliderState();
}

class _WeekendDealsSliderState extends State<WeekendDealsSlider> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final homeController = HomeController.instance;

    return ListenableBuilder(
      listenable: homeController,
      builder: (context, _) {
        final List<BannerModel> displayBanners = homeController.promoBanners.isEmpty
            ? [
                BannerModel(
                  id: "default_wd1",
                  title: "Weekend Deals",
                  subtitle: "Accessories • Speakers • Smart Home",
                  imageUrl: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200",
                  link: "/shop",
                  tag: "LIMITED OFFER",
                  type: "promo",
                ),
                BannerModel(
                  id: "default_wd2",
                  title: "Modern Furniture",
                  subtitle: "Luxury Sofas • Tables • Decor",
                  imageUrl: "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1200",
                  link: "/shop",
                  tag: "LIMITED OFFER",
                  type: "promo",
                ),
                BannerModel(
                  id: "default_wd3",
                  title: "Office Essentials",
                  subtitle: "Workstations • Chairs • Cabinets",
                  imageUrl: "https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=1200",
                  link: "/shop",
                  tag: "LIMITED OFFER",
                  type: "promo",
                ),
              ]
            : homeController.promoBanners;

        final screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 768;

        if (_currentIndex >= displayBanners.length) {
          _currentIndex = 0;
        }

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: isMobile ? 320 : 500,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                /// SLIDER
                CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: displayBanners.length,
                  options: CarouselOptions(
                    height: isMobile ? 320 : 500,
                    viewportFraction: 1,
                    autoPlay: true,
                    enlargeCenterPage: false,
                    autoPlayInterval: const Duration(seconds: 5),
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    final item = displayBanners[index];
                    final bool hasLink = item.link.isNotEmpty && item.link != '/' && item.link != '#';

                    Widget slideContent = Stack(
                      fit: StackFit.expand,
                      children: [
                        /// IMAGE
                        item.imageUrl.startsWith('http')
                            ? Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColors.grey800,
                                  child: const Icon(Icons.broken_image, color: AppColors.white),
                                ),
                              )
                            : Image.asset(
                                item.imageUrl,
                                fit: BoxFit.cover,
                              ),

                        /// OVERLAY
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.black.withOpacity(0.75),
                                AppColors.black.withOpacity(0.35),
                                AppColors.transparent,
                              ],
                            ),
                          ),
                        ),

                        /// CONTENT
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 60,
                            vertical: isMobile ? 24 : 50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              /// BADGE
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryIndigo,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_offer_outlined,
                                      color: AppColors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.tag.isEmpty ? 'LIMITED OFFER' : item.tag.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        color: AppColors.white,
                                        fontSize: isMobile ? 10 : 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: isMobile ? 18 : 28),

                              /// TITLE
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isMobile ? double.infinity : 600,
                                ),
                                child: Text(
                                  item.title,
                                  maxLines: isMobile ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: AppColors.white,
                                    fontSize: isMobile ? 34 : 58,
                                    fontWeight: FontWeight.bold,
                                    height: 1.05,
                                  ),
                                ),
                              ),

                              SizedBox(height: isMobile ? 10 : 16),

                              /// SUBTITLE
                              Text(
                                item.subtitle,
                                style: GoogleFonts.inter(
                                  color: AppColors.white.withOpacity(0.92),
                                  fontSize: isMobile ? 14 : 18,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (hasLink) {
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, item.link),
                          child: slideContent,
                        ),
                      );
                    }

                    return slideContent;
                  },
                ),

                /// LEFT BUTTON
                Positioned(
                  left: isMobile ? 12 : 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _navButton(
                      Icons.arrow_back_rounded,
                      () {
                        _carouselController.previousPage();
                      },
                      isMobile,
                    ),
                  ),
                ),

                /// RIGHT BUTTON
                Positioned(
                  right: isMobile ? 12 : 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _navButton(
                      Icons.arrow_forward_rounded,
                      () {
                        _carouselController.nextPage();
                      },
                      isMobile,
                    ),
                  ),
                ),

                /// DOTS
                Positioned(
                  bottom: isMobile ? 16 : 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      displayBanners.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        width: _currentIndex == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index ? AppColors.white : AppColors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _navButton(
    IconData icon,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: isMobile ? 42 : 56,
        width: isMobile ? 42 : 56,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black12,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.black87,
          size: isMobile ? 20 : 24,
        ),
      ),
    );
  }
}