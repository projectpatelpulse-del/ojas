import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/features/auth/application/address_controller.dart';
import 'package:ojas_user/core/services/session_service.dart';
// New Widget Imports
import 'package:ojas_user/features/cart/presentation/widgets/checkout_step_header.dart';
import 'package:ojas_user/features/cart/presentation/widgets/address_item_tile.dart';
import 'package:ojas_user/features/cart/presentation/widgets/price_details_card.dart';
import 'package:ojas_user/features/cart/presentation/widgets/address_form_dialog.dart';
import 'package:ojas_user/features/cart/presentation/widgets/order_success_dialog.dart';
import 'package:ojas_user/features/cart/presentation/widgets/payment_option_tile.dart';

import '../../../../core/services/payment_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _activeStep = 0; // 0: Address, 1: Order Summary, 2: Payment
  final AddressController _addressController = AddressController.instance;
  final CartController _cartController = CartController.instance;

  @override
  void initState() {
    super.initState();
    _addressController.loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondaryLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;
          
          Widget stepsColumn = SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CheckoutStepHeader(
                  step: 0,
                  title: 'DELIVERY ADDRESS',
                  content: _buildAddressStep(),
                  isActive: _activeStep == 0,
                  isCompleted: _activeStep > 0,
                  onChangeTap: () => setState(() => _activeStep = 0),
                  onStepTap: _activeStep > 0 ? () => setState(() => _activeStep = 0) : null,
                ),
                const SizedBox(height: 16),
                CheckoutStepHeader(
                  step: 1,
                  title: 'ORDER SUMMARY',
                  content: _buildOrderSummaryStep(),
                  isActive: _activeStep == 1,
                  isCompleted: _activeStep > 1,
                  onChangeTap: () => setState(() => _activeStep = 1),
                  onStepTap: _activeStep > 1 ? () => setState(() => _activeStep = 1) : null,
                ),
                const SizedBox(height: 16),
                CheckoutStepHeader(
                  step: 2,
                  title: 'PAYMENT OPTIONS',
                  content: _buildPaymentStep(),
                  isActive: _activeStep == 2,
                  isCompleted: false,
                ),
                if (isMobile) const SizedBox(height: 16),
                if (isMobile) PriceDetailsCard(cartController: _cartController),
              ],
            ),
          );

          if (isMobile) return stepsColumn;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: stepsColumn,
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16.0, right: 16.0, bottom: 16.0),
                  child: PriceDetailsCard(cartController: _cartController),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressStep() {
    return ListenableBuilder(
      listenable: _addressController,
      builder: (context, _) {
        if (_addressController.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (_addressController.addresses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            child: Column(
              children: [
                Icon(Icons.location_off_outlined, size: 64, color: AppColors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No saved addresses found',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                _buildAddNewAddressButton(),
              ],
            ),
          );
        }

        return Column(
          children: [
            ..._addressController.addresses.map((address) => AddressItemTile(
              address: address,
              isSelected: _addressController.selectedAddress?.id == address.id,
              addressController: _addressController,
              onSelect: () => _addressController.selectAddress(address),
            )),
            _buildAddNewAddressButton(),
            if (_addressController.selectedAddress != null)
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.grey[100]!)),
                ),
                child: ElevatedButton(
                  onPressed: () => setState(() => _activeStep = 1),
                  style: ElevatedButton.styleFrom(
backgroundColor: AppColors.primaryPink,                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DELIVER TO THIS ADDRESS',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAddNewAddressButton() {
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (context) => const AddressFormDialog(),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Text(
              'ADD A NEW ADDRESS',
              style: GoogleFonts.inter(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryStep() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._cartController.items.map((item) => _buildSummaryItem(item)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order confirmation email will be sent to ${SessionService.instance.currentUser?.email ?? 'your email'}',
                style: TextStyle(color: AppColors.grey[600], fontSize: 12),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _activeStep = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(dynamic item) {
    final product = item['product'];
    if (product == null) return const SizedBox();

    double price =
        (product['discountPrice'] != null && product['discountPrice'] > 0
                ? product['discountPrice']
                : (product['price'] ?? 0))
            .toDouble();
    final double oldPrice = (product['price'] ?? 0).toDouble();
    final int quantity = item['quantity'] ?? 1;

    final int moq = product['moq'] ?? 1;
    final double moqDiscount = (product['moqDiscount'] ?? 0).toDouble();
    final String moqTiers = product['moqTiers']?.toString() ?? '';

    double appliedDiscount = moqDiscount;
    if (moqTiers.isNotEmpty) {
      double matchedDiscount = 0.0;
      int highestQty = 0;
      final parts = moqTiers.split(',');
      for (var part in parts) {
        final subParts = part.trim().split(':');
        if (subParts.length == 2) {
          final q = int.tryParse(subParts[0].trim()) ?? 0;
          final d = double.tryParse(subParts[1].replaceAll('%', '').trim()) ?? 0.0;
          if (quantity >= q && q > highestQty) {
            highestQty = q;
            matchedDiscount = d;
          }
        }
      }
      if (highestQty > 0) {
        appliedDiscount = matchedDiscount;
      }
    }

    if ((quantity >= moq && appliedDiscount > 0) || (moqTiers.isNotEmpty && appliedDiscount > 0)) {
      price = price - (price * (appliedDiscount / 100));
    }
    price = price.roundToDouble();

    final variation = item['variation'];
    String name = product['name'] ?? 'Product';
    if (variation != null && variation['title'] != null && variation['title'].toString().trim().isNotEmpty) {
      name = "$name - ${variation['title']}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.grey[100]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product['image'] ?? 'https://via.placeholder.com/150',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Seller: ${product['vendor'] ?? 'Ojas'}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '\u20b9${price.ceil()}',
                      style: GoogleFonts.hind(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (oldPrice > price)
                      Text(
                        '\u20b9${oldPrice.ceil()}',
                        style: GoogleFonts.hind(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'Qty: $quantity',
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _selectedPaymentMethod = 'COD';
  final PaymentService _paymentService = PaymentService();

  Widget _buildPaymentStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PaymentOptionTile(
            title: 'Online Payment (PayU)',
            subtitle: 'Cards, UPI, NetBanking, Wallets',
            icon: Icons.credit_card_rounded,
            isSelected: _selectedPaymentMethod == 'ONLINE',
            onTap: () => setState(() => _selectedPaymentMethod = 'ONLINE'),
          ),
          PaymentOptionTile(
            title: 'Cash on Delivery',
            subtitle: 'Pay at the time of delivery',
            icon: Icons.money_outlined,
            isSelected: _selectedPaymentMethod == 'COD',
            onTap: () => setState(() => _selectedPaymentMethod = 'COD'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'PLACE ORDER • \u20b9${_cartController.totalAmount.round()}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isLoading = false;

  Future<void> _handlePlaceOrder() async {
    if (_addressController.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await _cartController.checkout(
      paymentMethod: _selectedPaymentMethod,
      shippingAddress: {
        'street': _addressController.selectedAddress!.street,
        'city': _addressController.selectedAddress!.city,
        'state': _addressController.selectedAddress!.state,
        'zipCode': _addressController.selectedAddress!.zipCode,
        'name': _addressController.selectedAddress!.name,
        'mobile': _addressController.selectedAddress!.mobile,
        'gstNumber': _addressController.selectedAddress!.gstNumber,
        'panNumber': _addressController.selectedAddress!.panNumber,
      },
    );

    if (mounted) {
      if (response['success'] == true) {
        if (_selectedPaymentMethod == 'COD') {
          final String? referralCode = SessionService.instance.refCode;
          final String? refProductId = SessionService.instance.referredProductId;
          SessionService.instance.setReferral(null, null);
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => OrderSuccessDialog(
              referralCode: referralCode,
              referredProductId: refProductId,
            ),
          );
        } else {
          // Handle Online Payment
          final paymentPayload = response['paymentPayload'];
          await _paymentService.startPayment(
            context: context,
            paymentPayload: paymentPayload,
            onSuccess: (res) async {
              // Verify with backend
              final verifyRes = await _paymentService.verifyPayment(res);
              if (verifyRes['success'] == true) {
                final String? referralCode = SessionService.instance.refCode;
                final String? refProductId = SessionService.instance.referredProductId;
                SessionService.instance.setReferral(null, null);
                _cartController.clear(); // Clear cart after success
                if (mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => OrderSuccessDialog(
                      referralCode: referralCode,
                      referredProductId: refProductId,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment verification failed. Please contact support.')),
                  );
                }
              }
              setState(() => _isLoading = false);
            },
            onFailure: (res) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment Failed: ${res['error'] ?? 'Unknown error'}')),
              );
            },
            onCancel: (res) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment Cancelled')),
              );
            },
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to place order. Please try again.')),
        );
      }
    }
  }
}
