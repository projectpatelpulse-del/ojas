import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';

class PriceDetailsCard extends StatelessWidget {
  final CartController cartController;
  const PriceDetailsCard({super.key, required this.cartController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'PRICE DETAILS',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildPriceRow('Price (${cartController.itemCount} items)', '\u20b9${cartController.subtotal.ceil()}'),
                const SizedBox(height: 16),
                _buildPriceRow('Delivery Charges', 'FREE', valueColor: AppColors.successGreen[600]),
                const SizedBox(height: 16),
                _buildPriceRow('Taxes', '\u20b9${cartController.tax.ceil()}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, 
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '\u20b9${cartController.totalAmount.ceil()}',
                      style: GoogleFonts.hind(
                        fontWeight: FontWeight.bold, 
                        fontSize: 22,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successGreen[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stars_rounded, color: AppColors.successGreen[700], size: 18),
                const SizedBox(width: 8),
                Text(
                  'You will save \u20b9${cartController.savings.ceil()} on this order',
                  style: GoogleFonts.inter(
                    color: AppColors.successGreen[700], 
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          )
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: valueColor != null ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
