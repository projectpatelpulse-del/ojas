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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OjasLayout(
      activeTitle: 'HOME',
      child: Column(

        children: [
          // 2. Hero Section (includes Gift Strip)
          HeroSection(),
          
          // 2a. Daily Deals Section
          DailyDealsSection(),
          
          // 2b. Summer Sale Banner
          SummerSaleBanner(),
          
          // 2c. Trending Items Section
          TrendingItemsSection(),
          
          // 2d. Promo Grid Section
          PromoGridSection(),
          
          // 2e. Become Vendor Banner
          BecomeVendorBanner(),
          
          // 2f. Just For You Section
          JustForYouSection(),
          
          // 2g. Latest Products Section
          LatestProductsSection(),
          
          // 9. Ads and Subscribe Section
          AdsAndSubscribeSection(),
        ],
      ),
    );
  }
}

