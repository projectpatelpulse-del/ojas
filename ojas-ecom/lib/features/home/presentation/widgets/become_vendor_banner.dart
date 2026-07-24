import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/features/home/data/models/banner_model.dart';

class BecomeVendorBanner extends StatelessWidget {
  const BecomeVendorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) {
        final allBanners = HomeController.instance.banners;
        final becomeVendorBanners = allBanners
            .where((b) => b.type == 'become_vendor')
            .toList();
        final banner = becomeVendorBanners.isNotEmpty
            ? becomeVendorBanners[0]
            : HomeController.instance.becomeVendorBanner;

        final bool isTablet = Responsive.isTablet(context);

        if (banner.imageUrl.isNotEmpty) {
          return CenteredContent(
            horizontalPadding: isMobile ? 16 : 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    final targetLink = banner.link.isEmpty ? '/become-vendor' : banner.link;
                    Navigator.pushNamed(context, targetLink);
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxHeight: isMobile ? 180 : (isTablet ? 280 : 360),
                    ),
                    decoration:  BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),

                      color: Colors.transparent,
                       boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: banner.imageUrl.startsWith('http')
                        ? Image.network(
                            banner.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          )
                        : Image.asset(
                            banner.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();

        /*
        return CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Container(
              width: double.infinity,
              height: isMobile ? null : 420,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
                gradient: LinearGradient(
                  colors: [
                    AppColors.white,
                    const Color(0xFFFDE8F1).withOpacity(0.5),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: isMobile
                  ? _buildMobileView(context, banner)
                  : _buildDesktopView(context, banner, becomeVendorBanners),
            ),
          ),
        );
        */
      },
    );
  }

  Widget _buildMobileView(BuildContext context, BannerModel banner) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner.tag.isNotEmpty) _buildTag(banner),
          if (banner.tag.isNotEmpty) const SizedBox(height: 16),
          Text(
            banner.title,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            banner.subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  final targetLink = banner.link.isEmpty
                      ? '/become-vendor'
                      : banner.link;
                  Navigator.pushNamed(context, targetLink);
                },
                icon: const Icon(Icons.storefront, size: 18),
                label: const Text('Become a Vendor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/shop'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: AppColors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Explore now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopView(
    BuildContext context,
    BannerModel banner,
    List<BannerModel> becomeVendorBanners,
  ) {
    String img1 =
        'https://ik.imagekit.io/xgdosezi9/banners/banner_1781869135292__XRIzd1zQ.png';
    String img2 =
        'https://ik.imagekit.io/xgdosezi9/banners/banner_1781869135292__XRIzd1zQ.png';

    if (becomeVendorBanners.isNotEmpty) {
      final b1 = becomeVendorBanners[0];
      if (b1.imageUrl.isNotEmpty) {
        final images1 = b1.imageUrl.split(',');
        img1 = images1[0].trim();
        img2 = images1.length > 1 ? images1[1].trim() : img1;
      }
    }

    if (becomeVendorBanners.length > 1) {
      final b2 = becomeVendorBanners[1];
      if (b2.imageUrl.isNotEmpty) {
        final images2 = b2.imageUrl.split(',');
        img2 = images2[0].trim();
      }
    }

    return Stack(
      children: [
        // Content Left Side
        Padding(
          padding: const EdgeInsets.only(left: 48.0, top: 40.0, bottom: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (banner.tag.isNotEmpty) _buildTag(banner),
              if (banner.tag.isNotEmpty) const SizedBox(height: 24),
              Text(
                banner.title,
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 500,
                child: Text(
                  banner.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  // ElevatedButton.icon(
                  //   onPressed: () {
                  //     final targetLink = banner.link.isEmpty
                  //         ? '/become-vendor'
                  //         : banner.link;
                  //     Navigator.pushNamed(context, targetLink);
                  //   },
                  //   icon: const Icon(Icons.storefront, size: 18),
                  //   label: const Text('Become a Vendor hjkhkjh'),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: const Color(0xFF0F172A),
                  //     foregroundColor: AppColors.white,
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 24,
                  //       vertical: 20,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  //   ),
                  // ),
                  // const SizedBox(width: 16),
                 
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/shop'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: AppColors.grey),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Explore now',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Images Right Side (Hidden if width is too small)
        Positioned(
          right: 80,
          top: 20,
          bottom: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildImageCard(img1, -0.1, const Offset(40, -20)),
              const SizedBox(width: 20),
              _buildImageCard(img2, 0.1, const Offset(0, 40), isXbox: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(BannerModel banner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.discount_outlined, size: 16, color: AppColors.grey[700]),
          const SizedBox(width: 8),
          Text(
            banner.tag,
            style: GoogleFonts.inter(
              color: AppColors.grey[800],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(
    String url,
    double angle,
    Offset offset, {
    bool isXbox = false,
  }) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: isXbox ? 220 : 200,
          height: isXbox ? 160 : 240,
          decoration: BoxDecoration(
            color: AppColors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: isXbox
                ? Border.all(color: AppColors.white, width: 8)
                : null,
            image: DecorationImage(
              image: url.startsWith('http')
                  ? NetworkImage(url) as ImageProvider
                  : AssetImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
