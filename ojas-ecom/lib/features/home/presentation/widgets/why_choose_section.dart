import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';

import 'package:ojas_user/core/utils/responsive.dart';

class WhyChooseSection extends StatelessWidget {
  const WhyChooseSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isTablet ? 28 : 40),
        vertical: isMobile ? 32 : 50,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Why Choose Our Featured Products?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.black87,
            ),
          ),
          SizedBox(height: isMobile ? 28 : 40),
          if (isMobile)
            const Column(
              children: [
                _FeatureItem(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Premium Quality',
                  description: 'Handpicked products that meet our highest quality standards.',
                ),
                SizedBox(height: 28),
                _FeatureItem(
                  icon: Icons.trending_up,
                  title: 'Trending Items',
                  description: 'Stay ahead with the latest trends and customer favorites.',
                ),
                SizedBox(height: 28),
                _FeatureItem(
                  icon: Icons.military_tech_outlined,
                  title: 'Exclusive Selection',
                  description: 'Curated collection of premium and exclusive products.',
                ),
              ],
            )
          else
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Premium Quality',
                    description: 'Handpicked products that meet our highest quality standards.',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.trending_up,
                    title: 'Trending Items',
                    description: 'Stay ahead with the latest trends and customer favorites.',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.military_tech_outlined,
                    title: 'Exclusive Selection',
                    description: 'Curated collection of premium and exclusive products.',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryPink.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primaryPink,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
