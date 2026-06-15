import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:ojas_user/core/models/app_settings.dart';

class ReturnsRefundsPage extends StatelessWidget {
  const ReturnsRefundsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final settings = context.watch<SettingsController>().settings;
    final String customContent = settings.returnRefundPolicy;

    return OjasLayout(
      activeTitle: 'RETURNS & REFUNDS',
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 60),
        color: const Color(0xFFF8F9FA),
        child: CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Column(
            children: [
              // 1. Header Section
              _buildHeader(isMobile),
              SizedBox(height: isMobile ? 32 : 60),

              // Dynamic content from admin
              if (customContent.trim().isNotEmpty) ...[
                _buildSectionCard(
                  'Policy Update',
                  customContent,
                  isMobile,
                ),
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 48),
                Text(
                  'General Returns & Refunds Info',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // 2. Highlights
              _buildHighlights(isMobile),
              SizedBox(height: isMobile ? 48 : 80),

              // 3. How to Return
              _buildHowToReturn(isMobile),
              SizedBox(height: isMobile ? 48 : 80),

              // 4. Return Policies by Category
              _buildPoliciesByCategory(isMobile),
              SizedBox(height: isMobile ? 48 : 80),

              // 5. Refund Options
              _buildRefundOptions(isMobile),
              SizedBox(height: isMobile ? 48 : 80),

              // 6. Non-Returnable & Important Notes
              _buildNotesSection(isMobile),
              SizedBox(height: isMobile ? 48 : 80),

              // 7. FAQ
              _buildFAQ(isMobile),
              SizedBox(height: isMobile ? 48 : 80),

              // 8. Help Banner
              _buildHelpBanner(isMobile, settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.refresh, color: const Color(0xFFF01B6B), size: isMobile ? 32 : 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Returns & Refunds',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 700,
          child: Text(
            'We want you to be completely satisfied with your purchase. If you\'re not happy, we\'ll make it right.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 15 : 18,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlights(bool isMobile) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: [
        _highlightCard('60', 'Days to Return', isMobile),
        _highlightCard('Free', 'Return Shipping', isMobile),
        _highlightCard('3-5', 'Days for Refund', isMobile),
        _highlightCard('100%', 'Money Back', isMobile),
      ],
    );
  }

  Widget _highlightCard(String title, String subtitle, bool isMobile) {
    return Container(
      width: isMobile ? 160 : 250,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 32, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF01B6B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToReturn(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'How to Return an Item',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B)),
          ),
          SizedBox(height: isMobile ? 32 : 48),
          if (isMobile)
            Column(
              children: [
                _stepItem('1', Icons.inventory_2_outlined, 'Initiate Return', 'Log in and select the item to return', isMobile),
                _separator(isMobile),
                _stepItem('2', Icons.local_shipping_outlined, 'Print Label', 'Print the prepaid shipping label', isMobile),
                _separator(isMobile),
                _stepItem('3', Icons.refresh_outlined, 'Pack & Ship', 'Deliver package to any shipping point', isMobile),
                _separator(isMobile),
                _stepItem('4', Icons.payments_outlined, 'Get Refund', 'Refunded within 3-5 business days', isMobile),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _stepItem('1', Icons.inventory_2_outlined, 'Initiate Return', 'Log in and select the item to return', isMobile)),
                Expanded(child: _stepItem('2', Icons.local_shipping_outlined, 'Print Label', 'Print the prepaid shipping label', isMobile)),
                Expanded(child: _stepItem('3', Icons.refresh_outlined, 'Pack & Ship', 'Deliver package to any shipping point', isMobile)),
                Expanded(child: _stepItem('4', Icons.payments_outlined, 'Get Refund', 'Refunded within 3-5 business days', isMobile)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _separator(bool isMobile) {
    return Container(
      height: 30,
      width: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFFFFEBEE),
    );
  }

  Widget _stepItem(String step, IconData icon, String title, String desc, bool isMobile) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFFF01B6B), size: isMobile ? 24 : 32),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFF01B6B), shape: BoxShape.circle),
                child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        Text(desc, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], height: 1.5)),
      ],
    );
  }

  Widget _buildPoliciesByCategory(bool isMobile) {
    return Column(
      children: [
        Text(
          'Return Policies',
          style: GoogleFonts.outfit(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B)),
        ),
        SizedBox(height: isMobile ? 32 : 48),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _policyCard(Icons.smartphone, 'Electronics', '30 days', '15%', 'Must be in original packaging', isMobile),
            _policyCard(Icons.checkroom, 'Clothing', '60 days', 'None', 'Tags must be intact and unworn', isMobile),
            _policyCard(Icons.home, 'Home & Garden', '45 days', '10%', 'Must be unused in original condition', isMobile),
            _policyCard(Icons.menu_book, 'Books & Media', '30 days', 'None', 'Must be in original condition', isMobile),
          ],
        ),
      ],
    );
  }

  Widget _policyCard(IconData icon, String category, String window, String fee, String conditions, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 530,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(category, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
            ],
          ),
          const SizedBox(height: 20),
          _policyRow('Return Window:', window),
          _policyRow('Restocking Fee:', fee),
          const SizedBox(height: 16),
          Text('Conditions:', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(conditions, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _policyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRefundOptions(bool isMobile) {
    return Column(
      children: [
        Text(
          'Refund Options',
          style: GoogleFonts.outfit(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B)),
        ),
        SizedBox(height: isMobile ? 32 : 48),
        if (isMobile)
          Column(
            children: [
              _refundOptionCard(Icons.credit_card, 'Original Payment', '3-5 Days', 'Refund to your original payment method', isMobile),
              const SizedBox(height: 16),
              _refundOptionCard(Icons.inventory_2_outlined, 'Store Credit', 'Instant', 'Instant credit for future purchases', isMobile),
              const SizedBox(height: 16),
              _refundOptionCard(Icons.refresh, 'Exchange', '5-7 Days', 'Exchange for a different size or color', isMobile),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _refundOptionCard(Icons.credit_card, 'Original Payment', '3-5 Days', 'Refund to your original payment method', isMobile)),
              const SizedBox(width: 20),
              Expanded(child: _refundOptionCard(Icons.inventory_2_outlined, 'Store Credit', 'Instant', 'Instant credit for future purchases', isMobile)),
              const SizedBox(width: 20),
              Expanded(child: _refundOptionCard(Icons.refresh, 'Exchange', '5-7 Days', 'Exchange for a different size or color', isMobile)),
            ],
          ),
      ],
    );
  }

  Widget _refundOptionCard(IconData icon, String title, String time, String desc, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFFF01B6B), size: 28),
          ),
          const SizedBox(height: 24),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(time, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFFF01B6B))),
          const SizedBox(height: 16),
          Text(desc, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildNotesSection(bool isMobile) {
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Non-Returnable Items
        Expanded(
          flex: isMobile ? 0 : 1,
          child: Container(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 24),
                    const SizedBox(width: 16),
                    Expanded(child: Text('Non-Returnable Items', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B)))),
                  ],
                ),
                const SizedBox(height: 32),
                _noteItem(Icons.cancel_outlined, 'Personalized items', Colors.red),
                _noteItem(Icons.cancel_outlined, 'Perishable goods', Colors.red),
                _noteItem(Icons.cancel_outlined, 'Intimate items', Colors.red),
                _noteItem(Icons.cancel_outlined, 'Digital downloads', Colors.red),
              ],
            ),
          ),
        ),
        SizedBox(width: isMobile ? 0 : 40, height: isMobile ? 24 : 0),
        // Important Notes
        Expanded(
          flex: isMobile ? 0 : 1,
          child: Container(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 24),
                    const SizedBox(width: 16),
                    Expanded(child: Text('Important Notes', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B)))),
                  ],
                ),
                const SizedBox(height: 32),
                _noteItemWithDesc(Icons.check_circle_outline, 'Free Shipping', 'We provide prepaid labels for all eligible returns.', Colors.green),
                _noteItemWithDesc(Icons.access_time, 'Processing', 'Refunds processed within 3-5 days after receipt.', Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _noteItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _noteItemWithDesc(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Text('FAQ', style: GoogleFonts.outfit(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B))),
          SizedBox(height: isMobile ? 32 : 48),
          if (isMobile)
            Column(
              children: [
                _faqItem('Damaged item?', 'Contact us with photos. We\'ll arrange a replacement or full refund.'),
                _faqItem('Return shipping fee?', 'Free for all eligible returns. We provide prepaid labels.'),
                _faqItem('Exchanges?', 'Yes! Initiate a return or contact support for assistance.'),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _faqItem('Damaged item?', 'Contact us with photos. We\'ll arrange a replacement or full refund.'),
                      _faqItem('Return shipping fee?', 'Free for all eligible returns. We provide prepaid labels.'),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    children: [
                      _faqItem('Exchanges?', 'Yes! Initiate a return or contact support for assistance.'),
                      _faqItem('Refund window?', 'Processed within 3-5 business days after receipt.'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          Text(answer, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildHelpBanner(bool isMobile, AppSettings settings) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF01B6B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text('Need Help?', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Text('Our team is here to help with any questions.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 40),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFF01B6B),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Start Return', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 12 : 0),
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, String content, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B))),
          const SizedBox(height: 24),
          Text(content, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700], height: 1.6)),
        ],
      ),
    );
  }
}
