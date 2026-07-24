import 'package:flutter/material.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FeaturedHeader extends StatelessWidget {
  final int productCount;
  const FeaturedHeader({super.key, this.productCount = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        
        // 1. Star Icon
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star, color: Colors.amber, size: 36),
        ),
        const SizedBox(height: 16),
        
        // 2. Title
        Text(
          'Featured Products',
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
            color: AppColors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        // 3. Subtitle
        SizedBox(
          width: 500,
          child: Text(
            'Discover our handpicked selection of premium products, trending items, and customer favorites.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.grey[600],
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 48),
        
        // 4. Info & Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$productCount featured products',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey[700],
                ),
              ),
              Row(
                children: [
                  _ViewToggleButton(icon: Icons.grid_view_rounded, isActive: true),
                  const SizedBox(width: 8),
                  _ViewToggleButton(icon: Icons.format_list_bulleted_rounded, isActive: false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  const _ViewToggleButton({required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryPink : AppColors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? AppColors.primaryPink : AppColors.borderLight,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: isActive ? AppColors.white : AppColors.grey[600],
      ),
    );
  }
}
