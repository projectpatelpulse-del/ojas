import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:ojas_user/core/models/app_settings.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final settings = context.watch<SettingsController>().settings;
    final String customContent = settings.privacyPolicy;

    return OjasLayout(
      activeTitle: 'PRIVACY POLICY',
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 60),
        color: const Color(0xFFF8F9FA),
        child: CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Column(
            children: [
              // 1. Header
              _buildHeader(isMobile),
              SizedBox(height: isMobile ? 32 : 60),

              // If dynamic content exists, show it at the top
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
                  'General Privacy Clauses',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // 2. Table of Contents
              _buildTableOfContents(isMobile),
              const SizedBox(height: 48),

              // 3. Introduction
              _buildSectionCard(
                'Introduction',
                'At Ojas, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our services.',
                isMobile,
              ),
              const SizedBox(height: 24),

              // 4. Information We Collect
              _buildDetailedSectionCard(
                'Information We Collect',
                icon: Icons.storage_outlined,
                isMobile: isMobile,
                subsections: [
                  _Subsection('Personal Information', 'We collect information you provide directly to us, such as when you create an account, make a purchase, or contact us for support.'),
                  _Subsection('Automatically Collected Information', 'We automatically collect certain information about your device and how you interact with our services.'),
                  _Subsection('Cookies and Tracking', 'We use cookies and similar technologies to collect information about your browsing activities to improve our services.'),
                ],
              ),
              const SizedBox(height: 24),

              // 5. How We Use Your Information
              _buildDetailedSectionCard(
                'How We Use Your Information',
                icon: Icons.remove_red_eye_outlined,
                isMobile: isMobile,
                subsections: [
                  _Subsection('Service Provision', 'We use your information to provide, maintain, and improve our services, process transactions, and provide customer support.'),
                  _Subsection('Communication', 'We may use your information to send you promotional materials and other communications.'),
                ],
              ),
              const SizedBox(height: 24),

              // 6. Information Sharing
              _buildDetailedSectionCard(
                'Information Sharing',
                icon: Icons.group_outlined,
                isMobile: isMobile,
                subsections: [
                  _Subsection('Service Providers', 'We may share your information with third-party providers who perform services on our behalf.'),
                  _Subsection('Legal Requirements', 'We may disclose your information if required by law or to protect our rights.'),
                ],
              ),
              const SizedBox(height: 24),

              // 7. Your Rights
              _buildDetailedSectionCard(
                'Your Rights and Choices',
                icon: Icons.security_outlined,
                isMobile: isMobile,
                subsections: [
                  _Subsection('Account Information', 'You can update or delete your account information at any time in your settings.'),
                  _Subsection('Marketing Opt-out', 'You can opt out of promotional emails by following unsubscribe instructions.'),
                ],
              ),
              const SizedBox(height: 48),

              // 8. Contact Us
              _buildPrivacyContact(isMobile, settings),
              const SizedBox(height: 48),

              // 9. Related Info
              _buildRelatedInformation(context, isMobile),
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
          child: Icon(Icons.security, color: const Color(0xFFF01B6B), size: isMobile ? 32 : 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Privacy Policy',
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
            'Your privacy is important to us. This policy explains how we collect and protect your information.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: isMobile ? 15 : 18, color: Colors.grey[600], height: 1.6),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Last updated: November 6, 2024',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildTableOfContents(bool isMobile) {
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
          Text('Table of Contents', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B))),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _tocItem(Icons.storage_outlined, 'Information Collect', isMobile),
              _tocItem(Icons.remove_red_eye_outlined, 'How We Use Info', isMobile),
              _tocItem(Icons.group_outlined, 'Sharing Info', isMobile),
              _tocItem(Icons.lock_outline, 'Data Security', isMobile),
              _tocItem(Icons.security_outlined, 'Your Rights', isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tocItem(IconData icon, String text, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 280,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFF01B6B)),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF01B6B))),
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

  Widget _buildDetailedSectionCard(String title, {required IconData icon, required List<_Subsection> subsections, required bool isMobile}) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: const Color(0xFFF01B6B), size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B)))),
            ],
          ),
          const SizedBox(height: 32),
          ...subsections.map((sub) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Text(sub.content, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], height: 1.6)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPrivacyContact(bool isMobile, AppSettings settings) {
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
          Text(
            'Contact Us About Privacy',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 16),
          Text(
            'If you have questions about our privacy practices, contact us below:',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], height: 1.6),
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
          Icon(icon, color: const Color(0xFFF01B6B), size: 24),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(value, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildRelatedInformation(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: isMobile ? 20 : 40),
      decoration: BoxDecoration(
        color: const Color(0xFFF01B6B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Related Information',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Learn more about our policies',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 18, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _relatedButton(Icons.email_outlined, 'Contact', onPressed: () => Navigator.pushNamed(context, '/contact')),
              _relatedButton(Icons.description_outlined, 'Terms', onPressed: () => Navigator.pushNamed(context, '/terms')),
              _relatedButton(Icons.refresh_outlined, 'Returns', onPressed: () => Navigator.pushNamed(context, '/returns')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _relatedButton(IconData icon, String label, {required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.15),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}

class _Subsection {
  final String title;
  final String content;
  _Subsection(this.title, this.content);
}
