import 'package:flutter/material.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/controllers/wishlist_controller.dart';
import 'package:ojas_user/core/utils/url_helper.dart';

class FeaturedProductCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final double price;
  final double? oldPrice;
  final int discount;
  final String brand;
  final String category;
  // final double rating;
  // final int ratingCount;
  final String description;
  final List<String> tags;
  final String badge; // e.g. "Premium", "New"
  final Color badgeColor;
  final String? productId;
  final VoidCallback? onAddToCart;

  const FeaturedProductCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.oldPrice,
    this.discount = 0,
    required this.brand,
    required this.category,
    // this.rating = 4.5,
    // this.ratingCount = 100,
    required this.description,
    this.tags = const ["Premium quality", "Fast shipping",],
    this.badge = "Premium",
    this.badgeColor = const Color(0xFFE0E7FF),
    this.productId,
    this.onAddToCart,
  });

  @override
  State<FeaturedProductCard> createState() => _FeaturedProductCardState();
}

class _FeaturedProductCardState extends State<FeaturedProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WishlistController.instance,
      builder: (context, _) {
        final bool isWishlisted = widget.productId != null && WishlistController.instance.isWishlisted(widget.productId!);
        
        return MouseRegion(
          cursor: widget.productId != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.productId != null
                ? () {
                    final route = UrlHelper.productUrl({
                      'id': widget.productId,
                      'name': widget.name,
                      'category': widget.category,
                    });
                    Navigator.pushNamed(
                      context,
                      route,
                    );
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? AppColors.primaryBlue.withOpacity(0.5) : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with Badges
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Image.network(
                          widget.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.grey[100],
                            child: const Icon(Icons.image_outlined, color: AppColors.grey, size: 40),
                          ),
                        ),
                      ),
                    ),
                    
                    // Top Left Badge (e.g. Premium)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.badgeColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_outlined, size: 12, color: _getBadgeTextColor(widget.badge)),
                            const SizedBox(width: 4),
                            Text(
                              widget.badge,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getBadgeTextColor(widget.badge),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top Right Discount Badge
                    if (widget.discount > 0)
                      Positioned(
                        top: 12,
                        right: 45,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${widget.discount}%',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Wishlist Icon
                  //   if (widget.productId != null)
                  //     Positioned(
                  //       top: 10,
                  //       right: 10,
                  //       child: GestureDetector(
                  //         onTap: () {
                  //           final productMap = {
                  //             '_id': widget.productId,
                  //             'name': widget.name,
                  //             'price': widget.price,
                  //             'images': [widget.imageUrl],
                  //           };
                  //           WishlistController.instance.toggleWishlist(productMap);
                  //         },
                  //         child: Container(
                  //           decoration: BoxDecoration(
                  //             color: AppColors.white,
                  //             shape: BoxShape.circle,
                  //             boxShadow: [
                  //               BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 4),
                  //             ],
                  //           ),
                  //           padding: const EdgeInsets.all(8),
                  //           child: Icon(
                  //             isWishlisted ? Icons.favorite : Icons.favorite_border, 
                  //             size: 18, 
                  //             color: isWishlisted ? AppColors.primaryPink : AppColors.grey,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  ],
                ),

                // Content Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Brand & Category
                        Text(
                          '${widget.brand} • ${widget.category}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Description Snippet
                        if (widget.description.isNotEmpty) ...[
                          Text(
                            widget.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.grey[600],
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Tags
                        if (widget.tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: widget.tags.map((tag) => _buildTag(tag)).toList(),
                          ),
                        ],

                        const Spacer(),

                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${widget.price.ceil()}',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.black,
                              ),
                            ),
                            if (widget.oldPrice != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '₹${widget.oldPrice!.ceil()}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.mrpBrown,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: widget.onAddToCart,
                            icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                            label: Text('Add to Cart', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPink,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: AppColors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getBadgeTextColor(String badge) {
    if (badge == "Premium") return const Color(0xFF4338CA);
    if (badge == "New") return const Color(0xFF0D9488);
    return AppColors.black87;
  }
}
