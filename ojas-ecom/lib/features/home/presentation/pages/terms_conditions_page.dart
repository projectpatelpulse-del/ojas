import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/settings_controller.dart';
import 'package:ojas_user/core/models/app_settings.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final settings = SettingsController.instance.settings;
    final String customContent = settings.termsConditions.trim();

    return OjasLayout(
      activeTitle: 'TERMS & CONDITIONS',
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

              // Dynamic content from admin
              if (customContent.trim().isNotEmpty) ...[
                _buildSectionCard(
                  'Policy Update',
                  customContent,
                  isMobile: isMobile,
                  icon: Icons.gavel_outlined,
                ),
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 48),
                Text(
                  'General Terms & Conditions',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryIndigo,
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // 2. Table of Contents
              _buildTableOfContents(isMobile),
              const SizedBox(height: 48),

              // 3. Introduction
              _buildSectionCard('Introduction', 'Welcome to Ojas! These Terms and Conditions ("Terms", "Terms and Conditions") govern your relationship with Ojas website (the "Service") operated by Ojas ("us", "we", or "our").\n\nYour access to and use of the Service is conditioned on your acceptance of and compliance with these Terms. These Terms apply to all visitors, users and others who access or use the Service.', isMobile: isMobile, icon: Icons.info_outline),
              const SizedBox(height: 24),

              // 4. Detailed Sections
              _buildSectionCard('Acceptance of Terms', 'By accessing and using Ojas\'s website and services, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.', isMobile: isMobile, icon: Icons.check_circle_outline),
              const SizedBox(height: 24),
              _buildSectionCard('Definitions', 'In these Terms and Conditions, \'Company\' refers to Ojas, \'Service\' refers to our website and related services, \'User\' refers to anyone who accesses or uses our Service, and \'Content\' refers to all information, data, text, software, music, sound, photographs, graphics, video, messages, or other materials.', isMobile: isMobile, icon: Icons.description_outlined),
              const SizedBox(height: 24),
              _buildSectionCard('User Accounts', 'To access certain features of our Service, you may be required to create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.', isMobile: isMobile, icon: Icons.person_outline),
              const SizedBox(height: 24),
              _buildSectionCard('Acceptable Use Policy', 'You agree to use our Service only for lawful purposes and in accordance with these Terms. You may not use our Service to transmit, distribute, store or destroy material that could constitute or encourage conduct that would be considered a criminal offense, give rise to civil liability, or otherwise violate any law or regulation.', isMobile: isMobile, icon: Icons.security_outlined),
              const SizedBox(height: 24),
              _buildSectionCard('Intellectual Property Rights', 'The Service and its original content, features, and functionality are and will remain the exclusive property of Ojas and its licensors. The Service is protected by copyright, trademark, and other laws. Our trademarks and trade dress may not be used in connection with any product or service without our prior written consent.', isMobile: isMobile, icon: Icons.gavel_outlined),
              const SizedBox(height: 24),
              _buildSectionCard('Privacy Policy', 'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the Service, to understand our practices regarding the collection, use, and disclosure of your personal information.', isMobile: isMobile, icon: Icons.lock_outline),
              const SizedBox(height: 48),

              // 5. Prohibited Activities
              _buildProhibitedActivities(isMobile),
              const SizedBox(height: 48),

              // 6. Rights & Responsibilities
              _buildRightsAndResponsibilities(isMobile),
              const SizedBox(height: 48),

              // 7. Additional Terms
              _buildAdditionalTerms(isMobile),
              const SizedBox(height: 48),

              // 8. Contact Info
              _buildContactInfo(isMobile, settings),
              const SizedBox(height: 60),

              // 9. Footer Banner
              _buildAgreementAcknowledgment(context, isMobile),
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
          child: Icon(Icons.description, color: AppColors.primaryPink, size: isMobile ? 32 : 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Terms & Conditions',
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
            'Please read these terms and conditions carefully before using our Service.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: isMobile ? 15 : 18, color: AppColors.grey[600], height: 1.6),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Last updated: November 6, 2024',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildTableOfContents(bool isMobile) {
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
          Text('Table of Contents', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _tocItem(Icons.check_circle_outline, 'Acceptance of Terms', isMobile),
              _tocItem(Icons.description_outlined, 'Definitions', isMobile),
              _tocItem(Icons.person_outline, 'User Accounts', isMobile, isSelected: true),
              _tocItem(Icons.security_outlined, 'Acceptable Use Policy', isMobile),
              _tocItem(Icons.gavel_outlined, 'Intellectual Property Rights', isMobile),
              _tocItem(Icons.lock_outline, 'Privacy Policy', isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tocItem(IconData icon, String text, bool isMobile, {bool isSelected = false}) {
    return Container(
      width: isMobile ? double.infinity : 280,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFEBEE) : AppColors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryPink),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(fontSize: 14, color: AppColors.primaryPink, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, String content, {IconData? icon, required bool isMobile}) {
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
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: AppColors.primaryPink, size: 24),
                ),
                const SizedBox(width: 20),
              ],
              Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo))),
            ],
          ),
          const SizedBox(height: 24),
          Text(content, style: GoogleFonts.inter(fontSize: 16, color: AppColors.grey[700], height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildProhibitedActivities(bool isMobile) {
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
                child: const Icon(Icons.cancel_outlined, color: AppColors.primaryPink, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text('Prohibited Activities', style: GoogleFonts.outfit(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo))),
            ],
          ),
          const SizedBox(height: 24),
          Text('Prohibited activities include, but are not limited to:', style: GoogleFonts.inter(fontSize: 16, color: AppColors.grey[700], height: 1.6)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 16,
            children: [
              _prohibitedItem('Violating any applicable laws or regulations', isMobile),
              _prohibitedItem('Infringing on intellectual property rights', isMobile),
              _prohibitedItem('Transmitting harmful code', isMobile),
              _prohibitedItem('Unauthorized access to our systems', isMobile),
              _prohibitedItem('Interfering with Service functioning', isMobile),
              _prohibitedItem('Engaging in fraudulent activities', isMobile),
              _prohibitedItem('Harassing or threatening other users', isMobile),
              _prohibitedItem('Posting false information', isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prohibitedItem(String text, bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 300,
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.errorRed, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey[700]))),
        ],
      ),
    );
  }

  Widget _buildRightsAndResponsibilities(bool isMobile) {
    final List<Widget> children = [
      _columnCard(
        'Your Rights',
        'As a user, you have the following rights:',
        Icons.check_circle_outline,
        AppColors.successGreen,
        [
          'Access and use our Service in accordance with Terms',
          'Create an account and maintain your profile',
          'Purchase products offered on our platform',
          'Receive customer support and assistance',
          'Request deletion of your personal data',
          'Opt-out of marketing communications',
        ],
        isMobile,
      ),
      if (isMobile) const SizedBox(height: 24) else const SizedBox(width: 40),
      _columnCard(
        'Your Responsibilities',
        'As a user, you are responsible for:',
        Icons.person_search_outlined,
        AppColors.blue500,
        [
          'Provide accurate and complete information',
          'Maintain the security of your account credentials',
          'Comply with all applicable laws and regulations',
          'Respect the rights of other users',
          'Use the Service only for its intended purposes',
          'Report any violations or security issues',
        ],
        isMobile,
      ),
    ];

    if (isMobile) return Column(children: children);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: children.map((c) => c is SizedBox ? c : Expanded(child: c)).toList(),
    );
  }

  Widget _columnCard(String title, String subtitle, IconData icon, Color color, List<String> items, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo))),
            ],
          ),
          const SizedBox(height: 24),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey[600])),
          const SizedBox(height: 32),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(title == 'Your Rights' ? Icons.check_circle_outline : Icons.info_outline, color: color.withOpacity(0.8), size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item, style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey[700]))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAdditionalTerms(bool isMobile) {
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
          Text('Additional Important Terms', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo)),
          const SizedBox(height: 32),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _subSection('Limitation of Liability', 'In no event shall Ojas be liable for any indirect, incidental, special, or consequential damages.'),
                const SizedBox(height: 32),
                _subSection('Disclaimer', 'The information on this website is provided on an "as is" basis.'),
                const SizedBox(height: 32),
                _subSection('Governing Law', 'These Terms shall be interpreted and governed by the laws of the State of New York.'),
                const SizedBox(height: 32),
                _subSection('Changes to Terms', 'We reserve the right, at our sole discretion, to modify or replace these Terms at any time.'),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _subSection('Limitation of Liability', 'In no event shall Ojas be liable for any indirect, incidental, special, or consequential damages.'),
                      const SizedBox(height: 32),
                      _subSection('Disclaimer', 'The information on this website is provided on an "as is" basis.'),
                    ],
                  ),
                ),
                const SizedBox(width: 60),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _subSection('Governing Law', 'These Terms shall be interpreted and governed by the laws of the State of New York.'),
                      const SizedBox(height: 32),
                      _subSection('Changes to Terms', 'We reserve the right, at our sole discretion, to modify or replace these Terms at any time.'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _subSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black87)),
        const SizedBox(height: 12),
        Text(content, style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey[600], height: 1.6)),
      ],
    );
  }

  Widget _buildContactInfo(bool isMobile, AppSettings settings) {
    return Column(
      children: [
        Text('Contact Information', style: GoogleFonts.outfit(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo)),
        const SizedBox(height: 16),
        Text('If you have questions, please contact us:', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, color: AppColors.grey[600])),
        const SizedBox(height: 48),
        if (isMobile)
          Column(
            children: [
              _contactCard(Icons.email_outlined, 'Email', settings.contactEmail, isMobile),
              const SizedBox(height: 16),
              _contactCard(Icons.phone_outlined, 'Phone', settings.contactPhone, isMobile),
              const SizedBox(height: 16),
              _contactCard(Icons.location_on_outlined, 'Address', settings.contactAddress, isMobile),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _contactCard(Icons.email_outlined, 'Email', settings.contactEmail, isMobile)),
              const SizedBox(width: 20),
              Expanded(child: _contactCard(Icons.phone_outlined, 'Phone', settings.contactPhone, isMobile)),
              const SizedBox(width: 20),
              Expanded(child: _contactCard(Icons.location_on_outlined, 'Address', settings.contactAddress, isMobile)),
            ],
          ),
      ],
    );
  }

  Widget _contactCard(IconData icon, String title, String value, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryPink, size: 32),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black87)),
          const SizedBox(height: 12),
          Text(value, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey[600], height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildAgreementAcknowledgment(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: isMobile ? 20 : 40),
      decoration: BoxDecoration(
        color: AppColors.primaryPink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Agreement Acknowledgment',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 800,
            child: Text(
              'By using our Service, you acknowledge that you have read and understood these Terms.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.white.withOpacity(0.9),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _ackButton('Privacy Policy', onPressed: () => Navigator.pushNamed(context, '/privacy')),
              _ackButton('Returns', onPressed: () => Navigator.pushNamed(context, '/returns')),
              _ackButton('Contact', onPressed: () => Navigator.pushNamed(context, '/contact')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ackButton(String label, {required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white.withOpacity(0.15),
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}
