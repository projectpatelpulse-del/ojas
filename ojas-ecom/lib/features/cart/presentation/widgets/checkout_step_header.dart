import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';

class CheckoutStepHeader extends StatelessWidget {
  final int step;
  final String title;
  final Widget content;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onStepTap;
  final VoidCallback? onChangeTap;

  const CheckoutStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.content,
    required this.isActive,
    required this.isCompleted,
    this.onStepTap,
    this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onStepTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryBlue.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryBlue : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${step + 1}',
                      style: GoogleFonts.outfit(
                        color: isActive ? Colors.white : Colors.grey[500],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primaryBlue : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted && !isActive)
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  if (isCompleted && !isActive)
                    TextButton(
                      onPressed: onChangeTap,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        'CHANGE', 
                        style: GoogleFonts.inter(
                          color: AppColors.primaryBlue, 
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        )
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isActive) content,
        ],
      ),
    );
  }
}
