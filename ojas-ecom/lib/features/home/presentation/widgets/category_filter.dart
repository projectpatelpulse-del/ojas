import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String>? onCategoryChanged;

  const CategoryFilter({
    super.key,
    required this.categories,
    required this.selectedCategory,
    this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: categories.map((cat) {
        final bool isSelected = cat == selectedCategory;
        return Padding(
          padding: const EdgeInsets.only(left: 24),
          child: InkWell(
            onTap: () => onCategoryChanged?.call(cat),
            child: Text(
              cat,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryPink : AppColors.grey[700],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
