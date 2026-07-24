import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:ojas_user/core/constants/app_colors.dart';

class OrderSuccessDialog extends StatefulWidget {
  final String? referralCode;
  final String? referredProductId;

  const OrderSuccessDialog({
    super.key,
    this.referralCode,
    this.referredProductId,
  });

  @override
  State<OrderSuccessDialog> createState() => _OrderSuccessDialogState();
}

class _OrderSuccessDialogState extends State<OrderSuccessDialog> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    if (widget.referredProductId != null) {
      _redirectTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _navigateToProduct();
        }
      });
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _navigateToProduct() {
    _redirectTimer?.cancel();
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (widget.referredProductId != null) {
      Navigator.of(context).pushNamed(
        '/product-detail?id=${widget.referredProductId}&ref=${widget.referralCode}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReferral = widget.referredProductId != null;

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        padding: const EdgeInsets.all(40),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successGreen[50],
                shape: BoxShape.circle,
              ),
              child: isReferral
                  ? Lottie.network(
                      'https://lottie.host/8e20257e-39cf-4cb5-aa5c-15a0cf079c6d/P4Xzlyj4tE.json',
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 80);
                      },
                    )
                  : const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 80),
            ),
            const SizedBox(height: 32),
            Text(
              'Order Placed!',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isReferral
                  ? 'Your order has been successfully placed. Redirecting you back to the product details page...'
                  : 'Your order has been successfully placed. You can track its status in the orders section.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isReferral) {
                    _navigateToProduct();
                  } else {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  isReferral ? 'BACK TO PRODUCT' : 'CONTINUE SHOPPING',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
