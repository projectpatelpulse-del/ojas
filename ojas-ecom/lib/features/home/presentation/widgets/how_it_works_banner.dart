// import 'package:flutter/material.dart';
// import 'package:ojas_user/core/constants/app_colors.dart';
// import 'package:ojas_user/core/widgets/centered_content.dart';
// import 'package:ojas_user/core/utils/responsive.dart';
// import 'package:ojas_user/core/controllers/home_controller.dart';

// class HowItWorksBanner extends StatelessWidget {
//   const HowItWorksBanner({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final bool isMobile = Responsive.isMobile(context);

//     return ListenableBuilder(
//       listenable: HomeController.instance,
//       builder: (context, _) {
//         final banner = HomeController.instance.howItWorksBanner;
//         final bool isTablet = Responsive.isTablet(context);
//         final String imageUrl = banner.imageUrl;

//         if (imageUrl.isNotEmpty) {
//           final targetLink = banner.link.isEmpty ? '/' : banner.link;
//           final bool hasLink = banner.link.isNotEmpty && banner.link != '/' && banner.link != '#';

//           Widget mainContent = Container(
//             width: double.infinity,
//             constraints: BoxConstraints(
//               maxHeight: isMobile ? 180 : (isTablet ? 280 : 360),
//             ),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppColors.black.withOpacity(0.04),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             clipBehavior: Clip.antiAlias,
//             child: imageUrl.startsWith('http')
//                 ? Image.network(
//                     imageUrl,
//                     width: double.infinity,
//                     fit: BoxFit.fill,
//                     errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
//                   )
//                 : Image.asset(
//                     imageUrl,
//                     width: double.infinity,
//                     fit: BoxFit.fill,
//                     errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
//                   ),
//           );
//           if (hasLink) {
//             return MouseRegion(
//               cursor: SystemMouseCursors.click,
//               child: GestureDetector(
//                 onTap: () => Navigator.pushNamed(context, targetLink),
//                 child: mainContent,
//               ),
//             );
//           }

//           return mainContent;
//         }

//         return const SizedBox.shrink();
//       },
//     );
//   }
// }
