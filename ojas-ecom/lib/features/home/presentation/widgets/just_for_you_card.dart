import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JustForYouCard extends StatefulWidget {
  final String imageUrl;
  final String brand;
  final String title;
  final double price;
  final double oldPrice;
  final int discount;
  final bool hasBestSellerBadge;
  final VoidCallback? onAddToCart;

  const JustForYouCard({
    super.key,
    required this.imageUrl,
    required this.brand,
    required this.title,
    required this.price,
    required this.oldPrice,
    required this.discount,
    this.hasBestSellerBadge = false,
    this.onAddToCart,
  });

  @override
  State<JustForYouCard> createState() => _JustForYouCardState();
}

class _JustForYouCardState extends State<JustForYouCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.network(widget.imageUrl, fit: BoxFit.contain),
                    ),
                  ),
                  // Badges
                  if (widget.discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryPink, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          '--${widget.discount}%',
                          style: GoogleFonts.inter(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (widget.hasBestSellerBadge)
                    Positioned(
                      top: 8,
                      left: widget.discount > 0 ? 50 : 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          'BEST\nSELLER',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.bold, height: 1.1),
                        ),
                      ),
                    ),
                  
                  // Hover Actions
                  if (_isHovered)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Column(
                        children: [
                          _hoverActionButton(Icons.favorite_border),
                          const SizedBox(height: 8),
                          _hoverActionButton(Icons.shopping_cart_outlined),
                        ],
                      ),
                    )
                ],
              ),
            ),
            
            // Details Area
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.brand,
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.grey600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15, 
                      fontWeight: FontWeight.bold, 
                      color: const Color(0xFF0F172A)
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '₹${widget.price.ceil()}',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.black87),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${widget.oldPrice.ceil()}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grey500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onAddToCart,
                      icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                      label: Text(
                        'Add to Cart',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _hoverActionButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: AppColors.black87),
        onPressed: () {},
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
}
