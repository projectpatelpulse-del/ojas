import 'package:flutter/material.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/features/home/domain/models/category_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/utils/responsive.dart';

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
    final bool isMobile = Responsive.isMobile(context);
    final double itemWidth = isMobile ? 74 : 88;
    final double boxSize = isMobile ? 70 : 80;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/shop',
          arguments: {'category': widget.category.title},
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: SizedBox(
          width: itemWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                // width: 80,
                // height: 80,
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? AppColors.primaryBlue.withValues(alpha: 0.1)
                      : AppColors.bgSecondaryLight,
                  borderRadius: BorderRadius.circular(_isHovered ? 24 : 16),
                  border: Border.all(
                    color: _isHovered
                        ? AppColors.primaryBlue
                        : AppColors.transparent,
                    width: 2,
                  ),
                ),
                child: widget.category.icon != null
                    ? Center(
                        child: Text(
                          widget.category.icon!,
                          style: TextStyle(fontSize: isMobile ? 28 : 32),
                        ),
                      )
                    : (widget.category.imageUrl.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              widget.category.imageUrl,
                              width: boxSize,
                              height: boxSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.category_outlined,
                                size: isMobile ? 28 : 32,
                                color: AppColors.primaryPink,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.category_outlined,
                            size: isMobile ? 28 : 32,
                            color: AppColors.primaryPink,
                          ),
              ),
              // const SizedBox(height: 8),
              // Text(
              //   widget.category.title,
              //   textAlign: TextAlign.center,
              //   maxLines: 1,
              //   overflow: TextOverflow.ellipsis,
              //   style: GoogleFonts.inter(
              //     fontWeight: _isHovered ? FontWeight.bold : FontWeight.w500,
              //     fontSize: 13,
              //     color: AppColors.textPrimary,
              //   ),
              // ),
              SizedBox(height: isMobile ? 6 : 8),
              SizedBox(
                width: itemWidth,
                child: Text(
                  widget.category.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.w500,
                    fontSize: isMobile ? 11 : 13,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
