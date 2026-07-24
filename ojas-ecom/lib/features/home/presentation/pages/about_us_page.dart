import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:ojas_user/core/models/app_settings.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final settings = context.watch<SettingsController>().settings;
    final String customContent = settings.aboutUsContent;

    return OjasLayout(
      activeTitle: 'ABOUT US',
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 60),
        color: const Color(0xFFF8F9FA),
        child: CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Column(
            children: [
              // 1. Header
              _buildHeader(isMobile, settings),
              SizedBox(height: isMobile ? 32 : 60),

              // 2. Custom Admin Content
              if (customContent.trim().isNotEmpty) ...[
                _buildSectionCard(
                  'Our Mission & Story',
                  customContent,
                  isMobile,
                ),
                const SizedBox(height: 24),
              ] else ...[
                // Default fallback content if Admin hasn't set it yet
                _buildSectionCard(
                  'Our Story',
                  'Welcome to ${settings.marketplaceName}, your premier destination for exceptional products and outstanding customer service. Established with a passion for quality and innovation, we strive to bring you a handpicked selection of top-tier products across multiple categories.\n\nWe believe in building lasting relationships with our customers by providing an unmatched shopping experience, secure payments, and dedicated 24/7 support. Our goal is to connect premium products with happy customers worldwide.',
                  isMobile,
                ),
                const SizedBox(height: 24),
                _buildDetailedSectionCard(
                  'Our Core Values',
                  icon: Icons.favorite_border,
                  isMobile: isMobile,
                  subsections: [
                    _Subsection('Quality First', 'We meticulously source and verify every vendor to ensure that our customers only receive the finest quality products.'),
                    _Subsection('Customer-Centric', 'Your satisfaction is our ultimate goal. From browsing to unboxing, we are here to make your shopping smooth and pleasant.'),
                    _Subsection('Integrity & Trust', 'We prioritize safe payment channels, clear policies, and transparent communications in everything we do.'),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // 3. Contact information
              _buildContactInfo(isMobile, settings),
              const SizedBox(height: 48),

              // 4. Back to Shop button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/shop'),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Start Shopping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, AppSettings settings) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.info_outline, color: AppColors.primaryPink, size: isMobile ? 32 : 40),
        ),
        const SizedBox(height: 24),
        Text(
          'About Us',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryIndigo,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 700,
          child: Text(
            settings.tagline.isNotEmpty ? settings.tagline : 'Discover our journey, our values, and our commitment to bringing you the best.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: isMobile ? 15 : 18, color: AppColors.grey[600], height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, String content, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo)),
          const SizedBox(height: 24),
          Text(content, style: GoogleFonts.inter(fontSize: 16, color: AppColors.grey[700], height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildDetailedSectionCard(String title, {required IconData icon, required List<_Subsection> subsections, required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.primaryPink, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo))),
            ],
          ),
          const SizedBox(height: 32),
          ...subsections.map((sub) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black87)),
                    const SizedBox(height: 12),
                    Text(sub.content, style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey[600], height: 1.6)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildContactInfo(bool isMobile, AppSettings settings) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get In Touch',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo),
          ),
          const SizedBox(height: 16),
          Text(
            'Have questions or want to partner with us? We are always here to help!',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey[600], height: 1.6),
          ),
          const SizedBox(height: 48),
          if (isMobile)
            Column(
              children: [
                _contactSubCard(Icons.email_outlined, 'Email', settings.contactEmail, isMobile),
                const SizedBox(height: 16),
                _contactSubCard(Icons.phone_outlined, 'Phone', settings.contactPhone, isMobile),
                const SizedBox(height: 16),
                _contactSubCard(Icons.location_on_outlined, 'Address', settings.contactAddress, isMobile),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _contactSubCard(Icons.email_outlined, 'Email', settings.contactEmail, isMobile),
                _contactSubCard(Icons.phone_outlined, 'Phone', settings.contactPhone, isMobile),
                _contactSubCard(Icons.location_on_outlined, 'Address', settings.contactAddress, isMobile),
              ],
            ),
        ],
      ),
    );
  }

  Widget _contactSubCard(IconData icon, String title, String value, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryPink, size: 24),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.black87)),
          const SizedBox(height: 8),
          Text(value, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey[600], height: 1.4)),
        ],
      ),
    );
  }
}

class _Subsection {
  final String title;
  final String content;
  _Subsection(this.title, this.content);
}
