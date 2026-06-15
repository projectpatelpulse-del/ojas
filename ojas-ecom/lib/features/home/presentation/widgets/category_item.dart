import 'package:flutter/material.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/features/home/domain/models/category_model.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryItem extends StatefulWidget {
  final CategoryModel category;

  const CategoryItem({super.key, required this.category});

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.primaryBlue.withOpacity(0.1) : AppColors.bgSecondaryLight,
              borderRadius: BorderRadius.circular(_isHovered ? 24 : 16),
              border: Border.all(
                color: _isHovered ? AppColors.primaryBlue : Colors.transparent,
                width: 2,
              ),
            ),
            child: widget.category.icon != null
                ? Center(child: Text(widget.category.icon!, style: const TextStyle(fontSize: 32)))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(widget.category.imageUrl, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.category.title,
            style: GoogleFonts.inter(
              fontWeight: _isHovered ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
