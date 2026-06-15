import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/features/home/presentation/widgets/category_sidebar.dart';
import 'package:ojas_user/features/home/presentation/widgets/hero_main_banner.dart';
import 'package:ojas_user/features/home/presentation/widgets/hero_side_banner.dart';
import 'package:ojas_user/features/home/presentation/widgets/gift_promo_strip.dart';
import 'package:ojas_user/core/utils/responsive.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  int _currentBannerIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final homeController = HomeController.instance;

    return ListenableBuilder(
      listenable: homeController,
      builder: (context, _) {
        final mainBanners = homeController.mainBanners;
        final sideTop = homeController.sideTopBanner;
        final sideBottom = homeController.sideBottomBanner;
        final bool isTablet = Responsive.isTablet(context);

        // Default banners if empty
        final displayBanners = mainBanners.isEmpty
            ? [
                const HeroMainBanner(
                  title: 'SALE UP TO 50% OFF',
                  subtitle: "They're built to save energy, they help to clean up every door.",
                  imageUrl: 'assets/images/modern_furniture_hero.png',
                ),
                const HeroMainBanner(
                  title: 'NEW ARRIVALS',
                  subtitle: "Explore our latest collection of premium office furniture.",
                  imageUrl: 'assets/images/modern_furniture_hero.png',
                  badgeText: 'New ✨',
                ),
              ]
            : mainBanners.map((banner) => HeroMainBanner(
                title: banner.title,
                subtitle: banner.subtitle,
                imageUrl: banner.imageUrl,
                badgeText: banner.tag,
              )).toList();

        return CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 32),
            child: Column(
              children: [
                if (isMobile || isTablet)
                  Column(
                    children: [
                      _buildCarousel(displayBanners, isMobile ? 300 : 400),
                      const SizedBox(height: 16),
                      if (isMobile)
                        Column(
                          children: [
                            SizedBox(
                              height: 180, // Increased for better impact
                              child: HeroSideBanner(
                                title: sideTop.title,
                                subtitle: sideTop.subtitle,
                                imageUrl: sideTop.imageUrl,
                                badgeText: sideTop.tag.isEmpty ? 'Trending' : sideTop.tag,
                                badgeColor: const Color(0xFFF01B6B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180, // Increased for better impact
                              child: HeroSideBanner(
                                title: sideBottom.title,
                                subtitle: sideBottom.subtitle,
                                imageUrl: sideBottom.imageUrl,
                                badgeText: sideBottom.tag.isEmpty ? 'Premium' : sideBottom.tag,
                                badgeColor: const Color(0xFF00B4D8),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 200,
                                child: HeroSideBanner(
                                  title: sideTop.title,
                                  subtitle: sideTop.subtitle,
                                  imageUrl: sideTop.imageUrl,
                                  badgeText: sideTop.tag.isEmpty ? 'Trending' : sideTop.tag,
                                  badgeColor: const Color(0xFFF01B6B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 200,
                                child: HeroSideBanner(
                                  title: sideBottom.title,
                                  subtitle: sideBottom.subtitle,
                                  imageUrl: sideBottom.imageUrl,
                                  badgeText: sideBottom.tag.isEmpty ? 'Premium' : sideBottom.tag,
                                  badgeColor: const Color(0xFF00B4D8),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                else
                  SizedBox(
                    height: 420,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CategorySidebar(),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: _buildCarousel(displayBanners, 420),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              Expanded(
                                child: HeroSideBanner(
                                  title: sideTop.title,
                                  subtitle: sideTop.subtitle,
                                  imageUrl: sideTop.imageUrl,
                                  badgeText: sideTop.tag.isEmpty ? 'Trending' : sideTop.tag,
                                  badgeColor: const Color(0xFFF01B6B),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: HeroSideBanner(
                                  title: sideBottom.title,
                                  subtitle: sideBottom.subtitle,
                                  imageUrl: sideBottom.imageUrl,
                                  badgeText: sideBottom.tag.isEmpty ? 'Premium' : sideBottom.tag,
                                  badgeColor: const Color(0xFF00B4D8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 32),
                const GiftPromoStrip(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarousel(List<Widget> items, double height) {
    return Stack(
      children: [
        CarouselSlider(
          items: items,
          carouselController: _carouselController,
          options: CarouselOptions(
            height: height,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
          ),
        ),
        // Dots indicator
        Positioned(
          bottom: 15, // Reduced from 40 to avoid overlapping text
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.asMap().entries.map((entry) {
              bool isActive = _currentBannerIndex == entry.key;
              return GestureDetector(
                onTap: () => _carouselController.animateToPage(entry.key),
                child: Container(
                  width: isActive ? 24.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withOpacity(isActive ? 0.9 : 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
