// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:ojas_user/core/widgets/centered_content.dart';
// import 'package:ojas_user/core/controllers/home_controller.dart';
// import 'package:ojas_user/features/home/domain/models/product_model.dart';
// import 'package:ojas_user/features/home/presentation/widgets/daily_deal_card.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:ojas_user/core/utils/responsive.dart';

// class DailyDealsSection extends StatefulWidget {
//   const DailyDealsSection({super.key});

//   @override
//   State<DailyDealsSection> createState() => _DailyDealsSectionState();
// }

// class _DailyDealsSectionState extends State<DailyDealsSection> {
//   int _currentIndex = 0;
//   final CarouselSliderController _carouselController = CarouselSliderController();

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: HomeController.instance,
//       builder: (context, _) {
//         final dailyDeals = HomeController.instance.dealProducts.map((p) => ProductModel.fromMap(p)).toList();
//         final bool isMobile = Responsive.isMobile(context);
//         final bool isTablet = Responsive.isTablet(context);

//         // Grouping deals
//         int maxOnScreen = isMobile ? 1 : (isTablet ? 2 : 3);
//         int itemsPerPage = dailyDeals.isNotEmpty && dailyDeals.length < maxOnScreen
//             ? dailyDeals.length
//             : maxOnScreen;

//         if (itemsPerPage == 0) itemsPerPage = 1;

//         return CenteredContent(
//           horizontalPadding: isMobile ? 16 : 40,
//           child: Column(
//             children: [
//               const SizedBox(height: 40),
//               // Header with Navigation
//               Row(
//                 children: [
//                   Text(
//                     'Daily Deals',
//                     style: GoogleFonts.outfit(
//                       fontSize: isMobile ? 20 : 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black
//                     ),
//                   ),
//                   const Spacer(),
//                   if (dailyDeals.length > itemsPerPage) ...[
//                     _navButton(Icons.chevron_left, () => _carouselController.previousPage()),
//                     const SizedBox(width: 8),
//                     _navButton(Icons.chevron_right, () => _carouselController.nextPage()),
//                   ],
//                 ],
//               ),
//               const SizedBox(height: 32),

//               if (dailyDeals.isEmpty)
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(vertical: 60),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.grey.shade200),
//                   ),
//                   child: Column(
//                     children: [
//                       Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade300),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Check back later for daily deals!',
//                         style: GoogleFonts.inter(
//                           fontSize: 15,
//                           color: Colors.grey.shade500,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               else
//                 CarouselSlider.builder(
//                   carouselController: _carouselController,
//                   itemCount: (dailyDeals.length / itemsPerPage).ceil(),
//                   options: CarouselOptions(
//                     height: isMobile ? 480 : 320,
//                     viewportFraction: 1.0,
//                     autoPlay: true,
//                     autoPlayInterval: const Duration(seconds: 7),
//                     enlargeCenterPage: false,
//                     onPageChanged: (index, reason) {
//                       setState(() {
//                         _currentIndex = index;
//                       });
//                     },
//                   ),
//                   itemBuilder: (context, index, realIndex) {
//                     final int start = index * itemsPerPage;
//                     final int end = (index + 1) * itemsPerPage;
//                     final List<ProductModel> pageDeals = dailyDeals.sublist(
//                       start,
//                       end > dailyDeals.length ? dailyDeals.length : end,
//                     );

//                     return Row(
//                       children: [
//                         for (var i = 0; i < pageDeals.length; i++) ...[
//                           Expanded(child: DailyDealCard(product: pageDeals[i])),
//                           if (i < pageDeals.length - 1) const SizedBox(width: 24),
//                         ],
//                         // Fill remaining space if last page has fewer items
//                         if (pageDeals.length < itemsPerPage)
//                           for (var i = 0; i < itemsPerPage - pageDeals.length; i++)
//                             const Expanded(child: SizedBox()),
//                       ],
//                     );
//                   },
//                 ),

//               const SizedBox(height: 32),
//               // Pagination Dots
//               if (dailyDeals.length > itemsPerPage)
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: List.generate(
//                     (dailyDeals.length / itemsPerPage).ceil(),
//                     (index) => _pageDot(_currentIndex == index, index),
//                   ),
//                 ),
//               const SizedBox(height: 40),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _navButton(IconData icon, VoidCallback onTap) {
//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       child: GestureDetector(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.grey[200]!),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Icon(icon, size: 20, color: Colors.grey[700]),
//         ),
//       ),
//     );
//   }

//   Widget _pageDot(bool active, int index) {
//     return GestureDetector(
//       onTap: () => _carouselController.animateToPage(index),
//       child: Container(
//         width: active ? 24 : 8,
//         height: 8,
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         decoration: BoxDecoration(
//           color: active ? const Color(0xFFF01B6B) : Colors.grey[300],
//           borderRadius: BorderRadius.circular(4),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';

class DailyDealsSection extends StatefulWidget {
  const DailyDealsSection({super.key});

  @override
  State<DailyDealsSection> createState() => _DailyDealsSectionState();
}

class _DailyDealsSectionState extends State<DailyDealsSection> {
  int _currentIndex = 0;

  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) {
        final dailyDeals = HomeController.instance.dealProducts
            .map((p) => ProductModel.fromMap(p))
            .toList();

        final screenWidth = MediaQuery.of(context).size.width;

        final bool isMobile = Responsive.isMobile(context);

        /// RESPONSIVE ITEMS COUNT
        int itemsPerPage;

        if (screenWidth >= 1600) {
          itemsPerPage = 4;
        } else if (screenWidth >= 1100) {
          itemsPerPage = 3;
        } else if (screenWidth >= 700) {
          itemsPerPage = 2;
        } else {
          itemsPerPage = 1;
        }

        if (dailyDeals.length < itemsPerPage) {
          itemsPerPage = dailyDeals.length;
        }

        if (itemsPerPage == 0) {
          itemsPerPage = 1;
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 70),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Colors.white],
            ),
          ),
          child: CenteredContent(
            horizontalPadding: isMobile ? 16 : 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF01B6B).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'LIMITED TIME DEALS',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFFF01B6B),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),

                          SizedBox(height: isMobile ? 14 : 18),

                          Text(
                            'Daily Deals',
                            style: GoogleFonts.outfit(
                              fontSize: isMobile ? 30 : 42,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              height: 1.1,
                            ),
                          ),

                          const SizedBox(height: 10),

                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobile ? 500 : 700,
                            ),
                            child: Text(
                              'Explore premium furniture collections with modern designs crafted for comfort, style and productivity.',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 14 : 16,
                                color: const Color(0xFF6B7280),
                                height: 1.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// NAV BUTTONS
                    if (dailyDeals.length > itemsPerPage && !isMobile)
                      Row(
                        children: [
                          _navButton(
                            Icons.arrow_back_rounded,
                            () => _carouselController.previousPage(),
                          ),

                          const SizedBox(width: 12),

                          _navButton(
                            Icons.arrow_forward_rounded,
                            () => _carouselController.nextPage(),
                          ),
                        ],
                      ),
                  ],
                ),

                SizedBox(height: isMobile ? 28 : 50),

                /// EMPTY STATE
                if (dailyDeals.isEmpty)
                  _emptyState()
                /// RESPONSIVE CAROUSEL
                else
               CarouselSlider.builder(
  carouselController: _carouselController,
  itemCount: (dailyDeals.length / itemsPerPage).ceil(),

  options: CarouselOptions(
    viewportFraction: 1,
    autoPlay: true,
    enlargeCenterPage: false,
    autoPlayInterval: const Duration(seconds: 5),

    /// FIXED RESPONSIVE HEIGHT
    height: isMobile
        ? 390
        : itemsPerPage == 4
            ? 500
            : 520,

    onPageChanged: (index, reason) {
      setState(() {
        _currentIndex = index;
      });
    },
  ),

  itemBuilder: (context, index, realIndex) {
    final int start = index * itemsPerPage;

    final int end = (index + 1) * itemsPerPage;

    final pageDeals = dailyDeals.sublist(
      start,
      end > dailyDeals.length
          ? dailyDeals.length
          : end,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < pageDeals.length; i++) ...[
          Expanded(
            child: _modernProductCard(
              product: pageDeals[i],
              isMobile: isMobile,
            ),
          ),

          if (i != pageDeals.length - 1)
            SizedBox(
              width: isMobile ? 14 : 24,
            ),
        ],

        /// FIX EMPTY GAP
        if (pageDeals.length < itemsPerPage)
          for (
            int i = 0;
            i < itemsPerPage - pageDeals.length;
            i++
          ) ...[
            const Expanded(
              child: SizedBox(),
            ),

            if (i !=
                itemsPerPage -
                        pageDeals.length -
                    1)
              SizedBox(
                width: isMobile ? 14 : 24,
              ),
          ],
      ],
    );
  },
),
               
                  // CarouselSlider.builder(
                  //   carouselController: _carouselController,
                  //   itemCount: (dailyDeals.length / itemsPerPage).ceil(),
                  //   options: CarouselOptions(
                  //     viewportFraction: 1,

                  //     autoPlay: true,

                  //     enlargeCenterPage: false,

                  //     autoPlayInterval: const Duration(seconds: 5),

                  //     height: isMobile
                  //         ? 470
                  //         : itemsPerPage == 4
                  //         ? 500
                  //         : 520,

                  //     onPageChanged: (index, reason) {
                  //       setState(() {
                  //         _currentIndex = index;
                  //       });
                  //     },
                  //   ),
                  //   itemBuilder: (context, index, realIndex) {
                  //     final int start = index * itemsPerPage;

                  //     final int end = (index + 1) * itemsPerPage;

                  //     final pageDeals = dailyDeals.sublist(
                  //       start,
                  //       end > dailyDeals.length ? dailyDeals.length : end,
                  //     );

                  //     return Row(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         for (int i = 0; i < pageDeals.length; i++) ...[
                  //           Expanded(
                  //             child: _modernProductCard(
                  //               product: pageDeals[i],
                  //               isMobile: isMobile,
                  //             ),
                  //           ),

                  //           if (i != pageDeals.length - 1)
                  //             SizedBox(width: isMobile ? 14 : 24),
                  //         ],

                  //         /// FIX EMPTY GAP
                  //         if (pageDeals.length < itemsPerPage)
                  //           for (
                  //             int i = 0;
                  //             i < itemsPerPage - pageDeals.length;
                  //             i++
                  //           ) ...[
                  //             const Expanded(child: SizedBox()),

                  //             if (i != itemsPerPage - pageDeals.length - 1)
                  //               SizedBox(width: isMobile ? 14 : 24),
                  //           ],
                  //       ],
                  //     );
                  //   },
                  // ),

                SizedBox(height: isMobile ? 24 : 40),

                /// DOTS
                if (dailyDeals.length > itemsPerPage)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        (dailyDeals.length / itemsPerPage).ceil(),
                        (index) => _dot(_currentIndex == index, index),
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

  /// MODERN PRODUCT CARD
  Widget _modernProductCard({
    required ProductModel product,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            /// 
            /// 
            
AspectRatio(
  /// FIXED MOBILE IMAGE HEIGHT
  aspectRatio: isMobile ? 1.5 : 1.2,

  child: Stack(
    children: [
      Positioned.fill(
        child: Image.network(
          product.imageUrl ?? '',
          fit: BoxFit.cover,

          errorBuilder:
              (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade100,
              child: const Icon(
                Icons.image_not_supported,
                size: 40,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),

      Positioned(
        top: 16,
        left: 16,
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF01B6B),
            borderRadius:
                BorderRadius.circular(30),
          ),
          child: Text(
            'SALE',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  ),
),

            // AspectRatio(
            //   aspectRatio: isMobile ? 1.1 : 1.2,
            //   child: Stack(
            //     children: [
            //       Positioned.fill(
            //         child: Image.network(
            //           product.imageUrl ?? '',
            //           fit: BoxFit.cover,
            //           errorBuilder: (context, error, stackTrace) {
            //             return Container(
            //               color: Colors.grey.shade100,
            //               child: const Icon(
            //                 Icons.image_not_supported,
            //                 size: 40,
            //                 color: Colors.grey,
            //               ),
            //             );
            //           },
            //         ),
            //       ),

            //       Positioned(
            //         top: 16,
            //         left: 16,
            //         child: Container(
            //           padding: const EdgeInsets.symmetric(
            //             horizontal: 12,
            //             vertical: 6,
            //           ),
            //           decoration: BoxDecoration(
            //             color: const Color(0xFFF01B6B),
            //             borderRadius: BorderRadius.circular(30),
            //           ),
            //           child: Text(
            //             'SALE',
            //             style: GoogleFonts.inter(
            //               color: Colors.white,
            //               fontSize: 11,
            //               fontWeight: FontWeight.w700,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // /// CONTENT
            Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    // product.description ??
                    'Premium quality furniture for modern homes.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 13 : 14,
                      color: const Color(0xFF6B7280),
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: isMobile ? 12 : 18),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '₹${product.price.ceil()}',
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 22 : 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF01B6B),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/product-detail?id=${product.id}', arguments: product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF01B6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Shop',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF111827)),
      ),
    );
  }

  Widget _dot(bool active, int index) {
    return GestureDetector(
      onTap: () => _carouselController.animateToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: active ? 28 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: active ? const Color(0xFFF01B6B) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 44,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Deals Available',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
