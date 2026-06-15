import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/features/cart/presentation/pages/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return OjasLayout(
      activeTitle: 'CART',
      child: Container(
        color: AppColors.bgPrimaryLight,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 250,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.isLoading) {
                  return const SizedBox(
                    height: 400,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFF01B6B)),
                    ),
                  );
                }

                final items = controller.items;

                if (items.isEmpty) {
                  return SizedBox(
                    height: 400,
                    child: _buildEmptyState(context),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF01B6B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Cart',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${items.length} items in your shopping bag',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Items List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildCartItem(items[index]);
                      },
                    ),
                    const Divider(height: 1),

                    // Summary & Checkout
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', '\u20b9${controller.subtotal.ceil()}'),
                          const SizedBox(height: 12),
                          if (controller.savings > 0)
                            _buildSummaryRow(
                              'You saved',
                              '-\u20b9${controller.savings.ceil()}',
                              valueColor: const Color(0xFF2E7D32),
                            ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Shipping',
                            'FREE',
                            valueColor: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Tax',
                            '\u20b9${controller.tax.ceil()}',
                            valueColor: Colors.grey[400]!,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '\u20b9${controller.totalAmount.ceil()}',
                                style: GoogleFonts.hind(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB71C1C),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                for (var item in items) {
                                  final p = item['product'];
                                  if (p == null) continue;
                                  final qty = item['quantity'] ?? 1;
                                  final moq = p['moq'] ?? 1;
                                  if (qty < moq) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${p['name']} requires a minimum order quantity of $moq',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CheckoutPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF01B6B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Proceed to Checkout',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    final product = item['product'];
    if (product == null) return const SizedBox();

    final String name = product['name'] ?? 'Product';
    double price =
        (product['discountPrice'] != null && product['discountPrice'] > 0
                ? product['discountPrice']
                : (product['price'] ?? 0))
            .toDouble();
    final double oldPrice = (product['price'] ?? 0).toDouble();
    final String imageUrl = product['image'] ?? 'https://via.placeholder.com/150';
    final int quantity = item['quantity'] ?? 1;

    final int moq = product['moq'] ?? 1;
    final double moqDiscount = (product['moqDiscount'] ?? 0).toDouble();

    if (quantity >= moq && moqDiscount > 0) {
      price = price - (price * (moqDiscount / 100));
    }
    price = price.roundToDouble();

    final int discount = oldPrice > 0 && oldPrice > price
        ? (((oldPrice - price) / oldPrice) * 100).toInt()
        : 0;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final double paddingVal = isMobile ? 10.0 : 16.0;
    final double imgSize = isMobile ? 65.0 : 80.0;
    final double titleFontSize = isMobile ? 13.0 : 15.0;
    final double priceFontSize = isMobile ? 15.0 : 18.0;
    final double oldPriceFontSize = isMobile ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(paddingVal),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: imgSize,
                  height: imgSize,
                  fit: BoxFit.cover,
                ),
              ),
              if (discount > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFB1B4F),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$discount%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: isMobile ? 10 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      '\u20b9${price.ceil()}',
                      style: GoogleFonts.hind(
                        fontSize: priceFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (oldPrice > price)
                      Text(
                        '\u20b9${oldPrice.ceil()}',
                        style: GoogleFonts.hind(
                          fontSize: oldPriceFontSize,
                          color: Colors.grey[400],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                if (quantity >= moq && moqDiscount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Text(
                      'Includes ${moqDiscount.toInt()}% MOQ Discount',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _quantityButton(Icons.remove, () {
                            final int moq = product['moq'] ?? 1;
                            if (quantity > moq) {
                              CartController.instance.addToCart(
                                product['_id'],
                                quantity: -1,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Minimum order quantity is $moq',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          }),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _quantityButton(Icons.add, () {
                            CartController.instance.addToCart(
                              product['_id'],
                              quantity: 1,
                            );
                          }),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFFB1B4F),
                        size: 20,
                      ),
                      onPressed: () {
                        CartController.instance.removeFromCart(product['_id']);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: label == 'You saved' || label == 'Shipping' ? const Color(0xFF2E7D32) : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: label == 'Total Amount' ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Your cart is empty',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add some products to get started',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF01B6B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Continue Shopping',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}
