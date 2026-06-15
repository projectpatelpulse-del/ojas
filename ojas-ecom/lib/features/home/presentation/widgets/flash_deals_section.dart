import 'package:flutter/material.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';
import 'package:ojas_user/features/home/presentation/widgets/product_card.dart';
import 'package:ojas_user/features/home/presentation/widgets/section_title.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';

class FlashDealsSection extends StatelessWidget {
  const FlashDealsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final flashProducts = ProductModel.getFlashDeals();

    return Container(
      color: AppColors.bgSecondaryLight,
      child: CenteredContent(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Row(
                children: [
                  SectionTitle(title: 'Flash Deals', onSeeAll: () {}),
                  const SizedBox(width: 24),
                  _TimerWidget(),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 32),
              if (flashProducts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.bolt_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No flash deals at the moment.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 480,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: flashProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 24),
                    itemBuilder: (context, index) {
                      final product = flashProducts[index];
                      return SizedBox(
                        width: 300,
                        child: ProductCard(
                          product: product,
                          onAddToCart: () async {
                            final success = await CartController.instance.addToCart(product.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success ? 'Added to cart' : 'Failed to add to cart. Please login.',
                                  ),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TimeBox(label: '02'),
        _TimerDivider(),
        _TimeBox(label: '14'),
        _TimerDivider(),
        _TimeBox(label: '52'),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  const _TimeBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accentOrange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TimerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
