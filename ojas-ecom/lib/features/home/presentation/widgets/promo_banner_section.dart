import 'package:flutter/material.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/features/home/presentation/widgets/banner_widget.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/features/home/data/models/banner_model.dart';

class PromoBannerSection extends StatelessWidget {
  const PromoBannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HomeController.instance,
      builder: (context, _) {
        final banners = HomeController.instance.promoBanners;
        
        if (banners.isEmpty) {
          // Default static banners if none uploaded
          return CenteredContent(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Row(
                children: [
                  Expanded(
                    child: BannerWidget(
                      banner: BannerModel(
                        id: 'default_p1',
                        title: 'Fashion Sale',
                        subtitle: 'Up to 60% off on all clothing.',
                        imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800',
                        link: '/',
                        tag: '60% OFF',
                        type: 'promo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: BannerWidget(
                      banner: BannerModel(
                        id: 'default_p2',
                        title: 'Tech Deals',
                        subtitle: 'Latest gadgets at best prices.',
                        imageUrl: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=800',
                        link: '/',
                        tag: 'LATEST',
                        type: 'promo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return CenteredContent(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Row(
              children: [
                Expanded(child: BannerWidget(banner: banners[0])),
                if (banners.length > 1) ...[
                  const SizedBox(width: 24),
                  Expanded(child: BannerWidget(banner: banners[1])),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
