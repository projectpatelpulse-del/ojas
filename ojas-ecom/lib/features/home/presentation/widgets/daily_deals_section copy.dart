import 'package:ojas_user/core/constants/app_colors.dart';
// // import 'package:flutter/material.dart';
// // import 'package:carousel_slider/carousel_slider.dart';
// // import 'package:ojas_user/core/widgets/centered_content.dart';
// // import 'package:ojas_user/core/controllers/home_controller.dart';
// // import 'package:ojas_user/features/home/domain/models/product_model.dart';
// // import 'package:ojas_user/features/home/presentation/widgets/daily_deal_card.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:ojas_user/core/utils/responsive.dart';

// // class DailyDealsSection extends StatefulWidget {
// //   const DailyDealsSection({super.key});

// //   @override
// //   State<DailyDealsSection> createState() => _DailyDealsSectionState();
// // }

// // class _DailyDealsSectionState extends State<DailyDealsSection> {
// //   int _currentIndex = 0;
// //   final CarouselSliderController _carouselController = CarouselSliderController();

// //   @override
// //   Widget build(BuildContext context) {
// //     return ListenableBuilder(
// //       listenable: HomeController.instance,
// //       builder: (context, _) {
// //         final dailyDeals = HomeController.instance.dealProducts.map((p) => ProductModel.fromMap(p)).toList();
// //         final bool isMobile = Responsive.isMobile(context);
// //         final bool isTablet = Responsive.isTablet(context);

// //         // Grouping deals
// //         int maxOnScreen = isMobile ? 1 : (isTablet ? 2 : 3);
// //         int itemsPerPage = dailyDeals.isNotEmpty && dailyDeals.length < maxOnScreen
// //             ? dailyDeals.length
// //             : maxOnScreen;

// //         if (itemsPerPage == 0) itemsPerPage = 1;

// //         return CenteredContent(
// //           horizontalPadding: isMobile ? 16 : 40,
// //           child: Column(
// //             children: [
// //               const SizedBox(height: 40),
// //               // Header with Navigation
// //               Row(
// //                 children: [
// //                   Text(
// //                     'Daily Deals',
// //                     style: GoogleFonts.outfit(
// //                       fontSize: isMobile ? 20 : 24,
// //                       fontWeight: FontWeight.bold,
// //                       color: AppColors.black
// //                     ),
// //                   ),
// //                   const Spacer(),
// //                   if (dailyDeals.length > itemsPerPage) ...[
// //                     _navButton(Icons.chevron_left, () => _carouselController.previousPage()),
// //                     const SizedBox(width: 8),
// //                     _navButton(Icons.chevron_right, () => _carouselController.nextPage()),
// //                   ],
// //                 ],
// //               ),
// //               const SizedBox(height: 32),

// //               if (dailyDeals.isEmpty)
// //                 Container(
// //                   width: double.infinity,
// //                   padding: const EdgeInsets.symmetric(vertical: 60),
// //                   decoration: BoxDecoration(
// //                     color: AppColors.white,
// //                     borderRadius: BorderRadius.circular(12),
// //                     border: Border.all(color: AppColors.grey200),
// //                   ),
// //                   child: Column(
// //                     children: [
// //                       Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.grey300),
// //                       const SizedBox(height: 16),
// //                       Text(
// //                         'Check back later for daily deals!',
// //                         style: GoogleFonts.inter(
// //                           fontSize: 15,
// //                           color: AppColors.grey500,
// //                           fontWeight: FontWeight.w500,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 )
// //               else
// //                 CarouselSlider.builder(
// //                   carouselController: _carouselController,
// //                   itemCount: (dailyDeals.length / itemsPerPage).ceil(),
// //                   options: CarouselOptions(
// //                     height: isMobile ? 480 : 320,
// //                     viewportFraction: 1.0,
// //                     autoPlay: true,
// //                     autoPlayInterval: const Duration(seconds: 7),
// //                     enlargeCenterPage: false,
// //                     onPageChanged: (index, reason) {
// //                       setState(() {
// //                         _currentIndex = index;
// //                       });
// //                     },
// //                   ),
// //                   itemBuilder: (context, index, realIndex) {
// //                     final int start = index * itemsPerPage;
// //                     final int end = (index + 1) * itemsPerPage;
// //                     final List<ProductModel> pageDeals = dailyDeals.sublist(
// //                       start,
// //                       end > dailyDeals.length ? dailyDeals.length : end,
// //                     );

// //                     return Row(
// //                       children: [
// //                         for (var i = 0; i < pageDeals.length; i++) ...[
// //                           Expanded(child: DailyDealCard(product: pageDeals[i])),
// //                           if (i < pageDeals.length - 1) const SizedBox(width: 24),
// //                         ],
// //                         // Fill remaining space if last page has fewer items
// //                         if (pageDeals.length < itemsPerPage)
// //                           for (var i = 0; i < itemsPerPage - pageDeals.length; i++)
// //                             const Expanded(child: SizedBox()),
// //                       ],
// //                     );
// //                   },
// //                 ),

// //               const SizedBox(height: 32),
// //               // Pagination Dots
// //               if (dailyDeals.length > itemsPerPage)
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: List.generate(
// //                     (dailyDeals.length / itemsPerPage).ceil(),
// //                     (index) => _pageDot(_currentIndex == index, index),
// //                   ),
// //                 ),
// //               const SizedBox(height: 40),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   Widget _navButton(IconData icon, VoidCallback onTap) {
// //     return MouseRegion(
// //       cursor: SystemMouseCursors.click,
// //       child: GestureDetector(
// //         onTap: onTap,
// //         child: Container(
// //           padding: const EdgeInsets.all(8),
// //           decoration: BoxDecoration(
// //             color: AppColors.white,
// //             shape: BoxShape.circle,
// //             border: Border.all(color: AppColors.grey[200]!),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: AppColors.black.withOpacity(0.05),
// //                 blurRadius: 4,
// //                 offset: const Offset(0, 2),
// //               ),
// //             ],
// //           ),
// //           child: Icon(icon, size: 20, color: AppColors.grey[700]),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _pageDot(bool active, int index) {
// //     return GestureDetector(
// //       onTap: () => _carouselController.animateToPage(index),
// //       child: Container(
// //         width: active ? 24 : 8,
// //         height: 8,
// //         margin: const EdgeInsets.symmetric(horizontal: 4),
// //         decoration: BoxDecoration(
// //           color: active ? AppColors.primaryPink : AppColors.grey[300],
// //           borderRadius: BorderRadius.circular(4),
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:google_fonts/google_fonts.dart';

// import 'package:ojas_user/core/controllers/home_controller.dart';
// import 'package:ojas_user/core/utils/responsive.dart';
// import 'package:ojas_user/core/widgets/centered_content.dart';
// import 'package:ojas_user/features/home/domain/models/product_model.dart';

// class DailyDealsSection extends StatefulWidget {
//   const DailyDealsSection({super.key});

//   @override
//   State<DailyDealsSection> createState() => _DailyDealsSectionState();
// }

// class _DailyDealsSectionState extends State<DailyDealsSection> {
//   int _currentIndex = 0;

//   final CarouselSliderController _carouselController =
//       CarouselSliderController();

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: HomeController.instance,
//       builder: (context, _) {
//         final dailyDeals = HomeController.instance.dealProducts
//             .map((p) => ProductModel.fromMap(p))
//             .toList();

//         final screenWidth = MediaQuery.of(context).size.width;

//         final bool isMobile = Responsive.isMobile(context);

//         /// RESPONSIVE ITEMS COUNT
//         int itemsPerPage;

//         if (screenWidth >= 1600) {
//           itemsPerPage = 4;
//         } else if (screenWidth >= 1100) {
//           itemsPerPage = 3;
//         } else if (screenWidth >= 700) {
//           itemsPerPage = 2;
//         } else {
//           itemsPerPage = 1;
//         }

//         if (dailyDeals.length < itemsPerPage) {
//           itemsPerPage = dailyDeals.length;
//         }

//         if (itemsPerPage == 0) {
//           itemsPerPage = 1;
//         }

//         return Container(
//           width: double.infinity,
//           padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 70),
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [Color(0xFFF8FAFC), AppColors.white],
//             ),
//           ),
//           child: CenteredContent(
//             horizontalPadding: isMobile ? 16 : 40,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// HEADER
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Wrap(
//                             spacing: 12,
//                             runSpacing: 8,
//                             crossAxisAlignment: WrapCrossAlignment.center,
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 14,
//                                   vertical: 6,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: AppColors.primaryPink.withOpacity(0.08),
//                                   borderRadius: BorderRadius.circular(30),
//                                 ),
//                                 child: Text(
//                                   'LIMITED TIME DEALS',
//                                   style: GoogleFonts.inter(
//                                     fontSize: 11,
//                                     color: AppColors.primaryPink,
//                                     fontWeight: FontWeight.w700,
//                                     letterSpacing: 1,
//                                   ),
//                                 ),
//                               ),
//                              _CountdownTimerWidget(),
//                             ],
//                           ),

//                           SizedBox(height: isMobile ? 14 : 18),

//                           Text(
//                             'Daily Deals',
//                             style: GoogleFonts.outfit(
//                               fontSize: isMobile ? 30 : 42,
//                               fontWeight: FontWeight.w700,
//                               color: const Color(0xFF111827),
//                               height: 1.1,
//                             ),
//                           ),

//                           const SizedBox(height: 10),

//                           ConstrainedBox(
//                             constraints: BoxConstraints(
//                               maxWidth: isMobile ? 500 : 700,
//                             ),
//                             child: Text(
//                               'Explore premium furniture collections with modern designs crafted for comfort, style and productivity.',
//                               style: GoogleFonts.inter(
//                                 fontSize: isMobile ? 14 : 16,
//                                 color: const Color(0xFF6B7280),
//                                 height: 1.7,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     /// NAV BUTTONS
//                     if (dailyDeals.length > itemsPerPage && !isMobile)
//                       Row(
//                         children: [
//                           _navButton(
//                             Icons.arrow_back_rounded,
//                             () => _carouselController.previousPage(),
//                           ),

//                           const SizedBox(width: 12),

//                           _navButton(
//                             Icons.arrow_forward_rounded,
//                             () => _carouselController.nextPage(),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),

//                 SizedBox(height: isMobile ? 28 : 50),

//                 /// EMPTY STATE
//                 if (dailyDeals.isEmpty)
//                   _emptyState()
//                 /// RESPONSIVE CAROUSEL
//                 else
//                CarouselSlider.builder(
//   carouselController: _carouselController,
//   itemCount: (dailyDeals.length / itemsPerPage).ceil(),

//   options: CarouselOptions(
//     viewportFraction: 1,
//     autoPlay: true,
//     enlargeCenterPage: false,
//     autoPlayInterval: const Duration(seconds: 5),

//     /// FIXED RESPONSIVE HEIGHT
//     height: isMobile
//         ? 390
//         : itemsPerPage == 4
//             ? 540
//             : 560,

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
//       end > dailyDeals.length
//           ? dailyDeals.length
//           : end,
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
//             SizedBox(
//               width: isMobile ? 14 : 24,
//             ),
//         ],

//         /// FIX EMPTY GAP
//         if (pageDeals.length < itemsPerPage)
//           for (
//             int i = 0;
//             i < itemsPerPage - pageDeals.length;
//             i++
//           ) ...[
//             const Expanded(
//               child: SizedBox(),
//             ),

//             if (i !=
//                 itemsPerPage -
//                         pageDeals.length -
//                     1)
//               SizedBox(
//                 width: isMobile ? 14 : 24,
//               ),
//           ],
//       ],
//     );
//   },
// ),
               
//                   // CarouselSlider.builder(
//                   //   carouselController: _carouselController,
//                   //   itemCount: (dailyDeals.length / itemsPerPage).ceil(),
//                   //   options: CarouselOptions(
//                   //     viewportFraction: 1,

//                   //     autoPlay: true,

//                   //     enlargeCenterPage: false,

//                   //     autoPlayInterval: const Duration(seconds: 5),

//                   //     height: isMobile
//                   //         ? 470
//                   //         : itemsPerPage == 4
//                   //         ? 500
//                   //         : 520,

//                   //     onPageChanged: (index, reason) {
//                   //       setState(() {
//                   //         _currentIndex = index;
//                   //       });
//                   //     },
//                   //   ),
//                   //   itemBuilder: (context, index, realIndex) {
//                   //     final int start = index * itemsPerPage;

//                   //     final int end = (index + 1) * itemsPerPage;

//                   //     final pageDeals = dailyDeals.sublist(
//                   //       start,
//                   //       end > dailyDeals.length ? dailyDeals.length : end,
//                   //     );

//                   //     return Row(
//                   //       crossAxisAlignment: CrossAxisAlignment.start,
//                   //       children: [
//                   //         for (int i = 0; i < pageDeals.length; i++) ...[
//                   //           Expanded(
//                   //             child: _modernProductCard(
//                   //               product: pageDeals[i],
//                   //               isMobile: isMobile,
//                   //             ),
//                   //           ),

//                   //           if (i != pageDeals.length - 1)
//                   //             SizedBox(width: isMobile ? 14 : 24),
//                   //         ],

//                   //         /// FIX EMPTY GAP
//                   //         if (pageDeals.length < itemsPerPage)
//                   //           for (
//                   //             int i = 0;
//                   //             i < itemsPerPage - pageDeals.length;
//                   //             i++
//                   //           ) ...[
//                   //             const Expanded(child: SizedBox()),

//                   //             if (i != itemsPerPage - pageDeals.length - 1)
//                   //               SizedBox(width: isMobile ? 14 : 24),
//                   //           ],
//                   //       ],
//                   //     );
//                   //   },
//                   // ),

//                 SizedBox(height: isMobile ? 24 : 40),

//                 /// DOTS
//                 if (dailyDeals.length > itemsPerPage)
//                   Center(
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: List.generate(
//                         (dailyDeals.length / itemsPerPage).ceil(),
//                         (index) => _dot(_currentIndex == index, index),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   /// MODERN PRODUCT CARD
//   Widget _modernProductCard({
//     required ProductModel product,
//     required bool isMobile,
//   }) {
//     final hasDiscount = product.discount > 0 && product.oldPrice != null;
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primaryPink.withOpacity(0.03),
//             blurRadius: 24,
//             offset: const Offset(0, 12),
//           ),
//           BoxShadow(
//             color: AppColors.black.withOpacity(0.01),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(22),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// IMAGE
//             AspectRatio(
//               aspectRatio: isMobile ? 1.8 : 1.6,
//               child: Stack(
//                 children: [
//                   Positioned.fill(
//                     child: Image.network(
//                       product.imageUrl ?? '',
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           color: const Color(0xFFF8FAFC),
//                           child: const Icon(
//                             Icons.image_not_supported_outlined,
//                             size: 32,
//                             color: Color(0xFF94A3B8),
//                           ),
//                         );
//                       },
//                     ),
//                   ),

//                   Positioned.fill(
//                     child: DecoratedBox(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           colors: [
//                             AppColors.black.withOpacity(0.0),
//                             AppColors.black.withOpacity(0.15),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   if (hasDiscount)
//                     Positioned(
//                       top: 14,
//                       left: 14,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 5,
//                         ),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
//                           ),
//                           borderRadius: BorderRadius.circular(8),
//                           boxShadow: [
//                             BoxShadow(
//                               color: AppColors.errorRed.withOpacity(0.2),
//                               blurRadius: 6,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: Text(
//                           '${product.discount}% OFF',
//                           style: GoogleFonts.inter(
//                             color: AppColors.white,
//                             fontSize: 10,
//                             fontWeight: FontWeight.w800,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                       ),
//                     ),
                  
//                   Positioned(
//                     bottom: 12,
//                     left: 12,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: AppColors.black.withOpacity(0.6),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(
//                             Icons.flash_on_rounded,
//                             color: Color(0xFFFBBF24),
//                             size: 12,
//                           ),
//                           const SizedBox(width: 3),
//                           Text(
//                             'DEAL OF THE DAY',
//                             style: GoogleFonts.inter(
//                               color: AppColors.white,
//                               fontSize: 9,
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             /// CONTENT
//             Padding(
//               padding: EdgeInsets.all(isMobile ? 14 : 18),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     (product.brand ?? product.category ?? 'Ojas Collection').toUpperCase(),
//                     style: GoogleFonts.inter(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w700,
//                       color: const Color(0xFF94A3B8),
//                       letterSpacing: 1.2,
//                     ),
//                   ),
//                   const SizedBox(height: 6),

//                   Text(
//                     product.name ?? '',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: GoogleFonts.outfit(
//                       fontSize: isMobile ? 18 : 20,
//                       fontWeight: FontWeight.w700,
//                       color: const Color(0xFF1E293B),
//                     ),
//                   ),
//                   const SizedBox(height: 6),

//                   Text(
//                     product.shortDescription ?? 'Premium quality furniture for modern lifestyle.',
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: GoogleFonts.inter(
//                       fontSize: isMobile ? 12 : 13,
//                       color: const Color(0xFF64748B),
//                       height: 1.5,
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.baseline,
//                             textBaseline: TextBaseline.alphabetic,
//                             children: [
//                               Text(
//                                 '₹${product.price.ceil()}',
//                                 style: GoogleFonts.outfit(
//                                   fontSize: isMobile ? 22 : 24,
//                                   fontWeight: FontWeight.w800,
//                                   color: AppColors.primaryPink,
//                                 ),
//                               ),
//                               if (hasDiscount) ...[
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   '₹${product.oldPrice!.ceil()}',
//                                   style: GoogleFonts.inter(
//                                     fontSize: 12,
//                                     decoration: TextDecoration.lineThrough,
//                                     color: const Color(0xFF94A3B8),
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ],
//                           ),
//                           if (hasDiscount) ...[
//                             const SizedBox(height: 2),
//                             Text(
//                               'Save ₹${(product.oldPrice! - product.price).ceil()}',
//                               style: GoogleFonts.inter(
//                                 fontSize: 10,
//                                 color: const Color(0xFF10B981),
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
                      
//                       ElevatedButton(
//                         onPressed: () => Navigator.pushNamed(
//                           context,
//                           '/product-detail?id=${product.id}',
//                           arguments: product,
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF1E293B),
//                           foregroundColor: AppColors.white,
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 18,
//                             vertical: 12,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text(
//                               'Shop',
//                               style: GoogleFonts.inter(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold,
//                                 color: AppColors.white,
//                               ),
//                             ),
//                             const SizedBox(width: 4),
//                             const Icon(
//                               Icons.arrow_forward_rounded,
//                               size: 13,
//                               color: AppColors.white,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _navButton(IconData icon, VoidCallback onTap) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(18),
//       onTap: onTap,
//       child: Container(
//         height: 52,
//         width: 52,
//         decoration: BoxDecoration(
//           color: AppColors.white,
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(color: AppColors.grey100),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.black.withOpacity(0.04),
//               blurRadius: 20,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Icon(icon, color: const Color(0xFF111827)),
//       ),
//     );
//   }

//   Widget _dot(bool active, int index) {
//     return GestureDetector(
//       onTap: () => _carouselController.animateToPage(index),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         width: active ? 28 : 8,
//         height: 8,
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(30),
//           color: active ? AppColors.primaryPink : AppColors.grey300,
//         ),
//       ),
//     );
//   }

//   Widget _emptyState() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 70),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Column(
//         children: [
//           Icon(
//             Icons.local_offer_outlined,
//             size: 44,
//             color: AppColors.grey400,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No Deals Available',
//             style: GoogleFonts.outfit(
//               fontSize: 22,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CountdownTimerWidget extends StatefulWidget {
//   const _CountdownTimerWidget();

//   @override
//   State<_CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
// }

// class _CountdownTimerWidgetState extends State<_CountdownTimerWidget> {
//   late Duration _duration;
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//     final now = DateTime.now();
//     final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
//     _duration = endOfDay.difference(now);
//     _startTimer();
//   }

//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) {
//         setState(() {
//           if (_duration.inSeconds > 0) {
//             _duration -= const Duration(seconds: 1);
//           } else {
//             _timer?.cancel();
//           }
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   String _twoDigits(int n) => n.toString().padLeft(2, '0');

//   @override
//   Widget build(BuildContext context) {
//     final hours = _twoDigits(_duration.inHours);
//     final minutes = _twoDigits(_duration.inMinutes.remainder(60));
//     final seconds = _twoDigits(_duration.inSeconds.remainder(60));

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Icon(Icons.timer_outlined, color: AppColors.primaryPink, size: 14),
//         const SizedBox(width: 6),
//         _timeBox(hours),
//         _colon(),
//         _timeBox(minutes),
//         _colon(),
//         _timeBox(seconds),
//       ],
//     );
//   }

//   Widget _timeBox(String text) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E293B),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Text(
//         text,
//         style: GoogleFonts.inter(
//           color: AppColors.white,
//           fontSize: 11,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _colon() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 2),
//       child: Text(
//         ':',
//         style: GoogleFonts.inter(
//           color: const Color(0xFF6B7280),
//           fontWeight: FontWeight.bold,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }
// }
