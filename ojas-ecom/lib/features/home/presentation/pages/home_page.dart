import 'package:flutter/material.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/features/home/presentation/widgets/hero_section.dart';

import 'package:ojas_user/features/home/presentation/widgets/daily_deals_section.dart';
import 'package:ojas_user/features/home/presentation/widgets/summer_sale_banner.dart';
import 'package:ojas_user/features/home/presentation/widgets/trending_items_section.dart';
import 'package:ojas_user/features/home/presentation/widgets/promo_grid_section.dart';
import 'package:ojas_user/features/home/presentation/widgets/become_vendor_banner.dart';
import 'package:ojas_user/features/home/presentation/widgets/just_for_you_section.dart';
import 'package:ojas_user/features/home/presentation/widgets/latest_products_section.dart';
import 'package:ojas_user/features/home/presentation/widgets/ads_and_subscribe_section.dart';

import '../../../../core/controllers/settings_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OjasLayout(
      activeTitle: 'HOME',
      child: ListenableBuilder(
        listenable: SettingsController.instance,
        builder: (context, _) {
          final activeSectionsString = SettingsController.instance.settings.homeSectionsActive;
          final activeSections = activeSectionsString
              .split(',')
              .map((e) => e.trim().toUpperCase())
              .where((e) => e.isNotEmpty)
              .toSet();

          return Column(
            children: [
              // 2. Hero Section (includes Gift Strip)
              if (activeSections.contains('HERO')) const HeroSection(),
              
              // 2a. Daily Deals Section
              if (activeSections.contains('DAILY_DEALS')) const DailyDealsSection(),
              
              // 2b. Summer Sale Banner
              if (activeSections.contains('SUMMER_SALE')) const SummerSaleBanner(),
              
              // 2c. Trending Items Section
              if (activeSections.contains('TRENDING')) const TrendingItemsSection(),
              
              // 2d. Promo Grid Section
              if (activeSections.contains('PROMO_GRID')) const PromoGridSection(),
              
              // 2e. Become Vendor Banner
              if (activeSections.contains('BECOME_VENDOR')) const BecomeVendorBanner(),
              
              // 2f. Just For You Section
              if (activeSections.contains('JUST_FOR_YOU')) const JustForYouSection(),
              
              // 2g. Latest Products Section
              if (activeSections.contains('LATEST_PRODUCTS')) const LatestProductsSection(),
              
              // 9. Ads and Subscribe Section
              if (activeSections.contains('ADS_SUBSCRIBE')) const AdsAndSubscribeSection(),
            ],
          );
        },
      ),
    );
  }
}

