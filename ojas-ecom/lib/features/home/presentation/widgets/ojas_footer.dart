import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/settings_controller.dart';
import 'package:ojas_user/core/models/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/services/session_service.dart';
import '../../../auth/domain/models/user_model.dart';
import 'package:ojas_user/core/routes/app_router.dart';

class OjasFooter extends StatelessWidget {
  const OjasFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final settings = SettingsController.instance.settings;

    return Container(
      // color: AppColors.primaryIndigo, // Premium Dark Indigo matching navbar
      decoration: const BoxDecoration(
        color: AppColors.headerFooterBg,
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorderTint,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(top: isMobile ? 40 : 80, bottom: 40),
      child: CenteredContent(
        horizontalPadding: isMobile ? 16 : 40,
        child: Column(
          children: [
            // TOP ROW: Responsive Grid
            Wrap(
              spacing: isMobile ? 18 : 40,
              runSpacing: isMobile ? 25 : 40,
              children: [
                // Col 1: Branding
                SizedBox(
                  width: isMobile ? double.infinity : 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLogo(settings.marketplaceName),
                      const SizedBox(height: 20),
                      Text(
                        settings.tagline.isNotEmpty 
                          ? settings.tagline 
                          : 'Your trusted marketplace for quality products from verified vendors worldwide. Discover amazing deals and exceptional service.',
                        style: GoogleFonts.inter(
                          // color: AppColors.black87,
                          color: AppColors.charcoal.withOpacity(0.85),
                          height: 1.6,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (settings.gmbLink.isNotEmpty)
                            _socialIcon(
                              FontAwesomeIcons.google, 
                              onTap: () => _launchURL(settings.gmbLink),
                            ),
                          if (settings.facebookLink.isNotEmpty)
                            _socialIcon(
                              FontAwesomeIcons.facebook, 
                              onTap: () => _launchURL(settings.facebookLink),
                            ),
                          if (settings.instagramLink.isNotEmpty)
                            _socialIcon(
                              FontAwesomeIcons.instagram, 
                              onTap: () => _launchURL(settings.instagramLink),
                            ),
                          if (settings.twitterLink.isNotEmpty)
                            _socialIcon(
                              FontAwesomeIcons.xTwitter, 
                              onTap: () => _launchURL(settings.twitterLink),
                            ),
                          if (settings.youtubeLink.isNotEmpty)
                            _socialIcon(
                              FontAwesomeIcons.youtube, 
                              onTap: () => _launchURL(settings.youtubeLink),
                            ),
                          if (settings.linkedinLink.isNotEmpty)
                            _socialIcon(
                              FontAwesomeIcons.linkedin, 
                              onTap: () => _launchURL(settings.linkedinLink),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        settings.footerMessage,
                        // style: GoogleFonts.inter(color: AppColors.black38, fontSize: 11),
                        style: GoogleFonts.inter(color: AppColors.charcoal.withOpacity(0.6), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                
                // Col 2: Quick Links
                SizedBox(
                  width: isMobile ? (MediaQuery.of(context).size.width - 52) / 2 : 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _columnTitle('QUICK LINKS'),
                      _footerLink(context, 'Home', route: '/'),
                      _footerLink(context, 'About Us', route: '/about-us'),
                      _footerLink(context, 'Shop', route: '/shop'),
                      _footerLink(context, 'Offers', route: '/deals'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => AppRouter.push(context, '/become-vendor'),
                        child: _vendorBadge(),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<UserModel?>(
                        valueListenable: SessionService.instance.userNotifier,
                        builder: (context, user, _) {
                          if (user != null && user.role == 'reseller') {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => AppRouter.push(context, '/become-reseller'),
                                child: _resellerBadge(),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Col 3: Customer Service
                SizedBox(
                  width: isMobile ? (MediaQuery.of(context).size.width - 52) / 2 : 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _columnTitle('CUSTOMER SERVICE'),
                      _footerLink(context, 'Returns & Refunds', route: '/returns'),
                      _footerLink(context, 'Track Orders', route: '/orders'),
                      _footerLink(context, 'Help Center', route: '/contact'),
                    ],
                  ),
                ),
                
                // Col 4: Get In Touch
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _columnTitle('GET IN TOUCH'),
                      _contactInfo(Icons.phone_outlined, settings.contactPhone),
                      _contactInfo(Icons.email_outlined, settings.contactEmail),
                      _contactInfo(Icons.location_on_outlined, settings.contactAddress, settings.gmbLink),
                    ],
                  ),
                ),

                // Col 5: Legal
                SizedBox(
                  width: isMobile ? double.infinity : 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _columnTitle('LEGAL'),
                      _footerLink(context, 'Terms & Conditions', route: '/terms'),
                      _footerLink(context, 'Privacy Policy', route: '/privacy'),
                    ],
                  ),
                ),
              ],
            ),
            
            // PAYMENT MODES BADGES ROW
            _buildPaymentBadges(isMobile, settings),
            
            // const SizedBox(height: 48),
            // Divider(color: AppColors.black12, thickness: 1),

            
            /*
            // BOTTOM ROW: Brands
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 24,
              children: List.generate(isMobile ? 3 : 5, (index) {
                bool isBoat = index % 2 == 0;
                return _brandCard(isBoat);
              }),
            ),
            */
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  Widget _buildLogo(String name) {
    final settings = SettingsController.instance.settings;
    if (settings.logo.isNotEmpty) {
      return Image.network(
        settings.logo,
        height: 55,
        fit: BoxFit.cover,
      );
    }
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // color: AppColors.primaryPink,
            color: AppColors.goldAccent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(name.isNotEmpty ? name[0] : 'O', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        const SizedBox(width: 8),
        Text(
          name.isNotEmpty ? name : 'OJAS',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            // color: AppColors.black,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _vendorBadge() {
    return Row(
      children: [
        // const Icon(Icons.storefront, color: Colors.deepOrange, size: 16),
        const Icon(Icons.storefront, color: AppColors.goldAccent, size: 16),
        const SizedBox(width: 8),
        Text(
          'Become Vendor',
          style: GoogleFonts.inter(
            // color: Colors.deepOrange,
            color: AppColors.charcoal,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _resellerBadge() {
    return Row(
      children: [
        // const Icon(Icons.people, color: Colors.blueAccent, size: 16),
        const Icon(Icons.people, color: AppColors.goldAccent, size: 16),
        const SizedBox(width: 8),
        Text(
          'Become Reseller',
          style: GoogleFonts.inter(
            // color: Colors.blueAccent,
            color: AppColors.charcoal,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _brandCard(bool isBoat) {
    return Container(
      width: 140,
      height: 80,
      decoration: BoxDecoration(
        // color: AppColors.black,
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          // BoxShadow(color: AppColors.black.withOpacity(0.02), blurRadius: 4),
          BoxShadow(color: AppColors.black.withOpacity(0.04), blurRadius: 4),
        ],
      ),
      child: Center(
        child: isBoat
            ? RichText(
                text: TextSpan(
                  // style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal, color: AppColors.black87),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal, color: AppColors.charcoal),
                  children: [
                    const TextSpan(text: 'bo'),
                    TextSpan(text: 'A', style: TextStyle(color: AppColors.errorRed[600], fontWeight: FontWeight.bold)),
                    const TextSpan(text: 't'),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const Icon(Icons.shopping_cart, color: AppColors.black87, size: 20),
                  const Icon(Icons.shopping_cart, color: AppColors.charcoal, size: 20),
                  // Text('SHOP SMART', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.pink, fontSize: 11)),
                  Text('SHOP SMART', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppColors.goldAccent, fontSize: 11)),
                ],
              ),
      ),
    );
  }

  Widget _columnTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          // fontSize: 12,
          // color: AppColors.black,
          fontSize: 13,
          color: AppColors.charcoal,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _footerLink(BuildContext context, String text, {String? route, VoidCallback? onTap}) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isActive = route != null && currentRoute == route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _FooterLinkItem(
        text: text,
        isActive: isActive,
        onTap: onTap ?? (route != null ? () => AppRouter.push(context, route) : null),
      ),
    );
  }

  Widget _contactInfo(IconData icon, String text, [String? customUrl]) {
    VoidCallback? onTap;
    if (icon == Icons.phone_outlined) {
      final cleanPhone = text.replaceAll(RegExp(r'[^0-9+]'), '');
      onTap = () => _launchURL('tel:$cleanPhone');
    } else if (icon == Icons.email_outlined) {
      onTap = () => _launchURL('mailto:$text');
    } else if (icon == Icons.location_on_outlined) {
      final String targetUrl = (customUrl != null && customUrl.isNotEmpty)
          ? customUrl
          : 'https://maps.app.goo.gl/o5DBPxAU2hb2sVqs7';
      onTap = () => _launchURL(targetUrl);
    }

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.goldAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.charcoal.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: content,
    );
  }

  Widget _buildPaymentBadges(bool isMobile, AppSettings settings) {
    final String activeStr = settings.activePaymentModes.toUpperCase();
    final bool showAll = activeStr.isEmpty;

    final List<Widget> badges = [];

    // 1. UPI Badge
    if (showAll || activeStr.contains('UPI')) {
      badges.add(_paymentBadge(
        label: 'UPI',
        icon: Icons.qr_code_2_rounded,
        iconColor: const Color(0xFF097939),
        subtext: 'GPay • PhonePe • Paytm',
      ));
    }

    // 2. VISA Badge
    if (showAll || activeStr.contains('VISA')) {
      badges.add(_paymentBadge(
        label: 'VISA',
        customText: 'VISA',
        textColor: const Color(0xFF1A1F71),
        isTextLogo: true,
      ));
    }

    // 3. Mastercard Badge
    if (showAll || activeStr.contains('MASTERCARD')) {
      badges.add(_mastercardBadge());
    }

    // 4. RuPay Badge
    if (showAll || activeStr.contains('RUPAY')) {
      badges.add(_paymentBadge(
        label: 'RuPay',
        customText: 'RuPay❯',
        textColor: const Color(0xFFE35205),
        isTextLogo: true,
      ));
    }

    // 5. Net Banking
    if (showAll || activeStr.contains('NET_BANKING') || activeStr.contains('NETBANKING') || activeStr.contains('BANK')) {
      badges.add(_paymentBadge(
        label: 'Net Banking',
        icon: Icons.account_balance_outlined,
        iconColor: const Color(0xFF1E3A8A),
      ));
    }

    // 6. Wallets
    if (showAll || activeStr.contains('WALLET')) {
      badges.add(_paymentBadge(
        label: 'Wallets',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: const Color(0xFF0284C7),
      ));
    }

    // 7. Cash on Delivery
    if ((showAll || activeStr.contains('COD')) && settings.enableCOD) {
      badges.add(_paymentBadge(
        label: 'Cash on Delivery',
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xFFD97706),
      ));
    }

    // 8. 100% Safe & Secure Badge
    badges.add(_paymentBadge(
      label: '100% Safe & Secure',
      icon: Icons.verified_user_outlined,
      iconColor: const Color(0xFF059669),
      isHighlight: true,
    ));

    return Column(
      children: [
        const SizedBox(height: 36),
        Container(
          height: 1,
          color: AppColors.cardBorderTint,
        ),
        const SizedBox(height: 24),
        isMobile
            ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.charcoal),
                      const SizedBox(width: 6),
                      Text(
                        '100% SECURE PAYMENT MODES ACCEPTED',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.charcoal.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: badges,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.charcoal),
                      const SizedBox(width: 8),
                      Text(
                        '100% SECURE PAYMENT MODES:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.charcoal.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: badges,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _mastercardBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorderTint),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 16,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEB001B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF79E1B).withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Mastercard',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBadge({
    required String label,
    IconData? icon,
    Color? iconColor,
    String? customText,
    Color? textColor,
    String? subtext,
    bool isTextLogo = false,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFF0FDF4) : AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlight ? const Color(0xFF86EFAC) : AppColors.cardBorderTint,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: iconColor ?? AppColors.charcoal),
            const SizedBox(width: 6),
          ],
          if (isTextLogo && customText != null)
            Text(
              customText,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: textColor ?? const Color(0xFF1E293B),
                letterSpacing: 0.5,
              ),
            )
          else
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isHighlight ? const Color(0xFF166534) : const Color(0xFF1E293B),
              ),
            ),
          if (subtext != null) ...[
            const SizedBox(width: 4),
            Text(
              '($subtext)',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _socialIcon(dynamic icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      onHover: (hovering) {}, // Optional: Add hover effect if needed
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // color: AppColors.black.withOpacity(0.05),
          color: AppColors.charcoal.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: icon is FaIconData
            ? FaIcon(icon, color: AppColors.charcoal, size: 18)
            : Icon(icon as IconData, color: AppColors.charcoal, size: 18),
      ),
    );
  }
  
  Widget _dot(Color color) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FooterLinkItem extends StatefulWidget {
  final String text;
  final bool isActive;
  final VoidCallback? onTap;

  const _FooterLinkItem({
    required this.text,
    required this.isActive,
    this.onTap,
  });

  @override
  State<_FooterLinkItem> createState() => _FooterLinkItemState();
}

class _FooterLinkItemState extends State<_FooterLinkItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // const Color activeColor = AppColors.primaryPink;
    // const Color normalColor = AppColors.black87;
    // const Color hoverColor = AppColors.black;
    const Color activeColor = AppColors.goldAccent;
    final Color normalColor = AppColors.charcoal.withOpacity(0.85);
    const Color hoverColor = AppColors.goldAccent;

    return InkWell(
      onTap: widget.onTap,
      onHover: (value) => setState(() => _isHovered = value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: GoogleFonts.inter(
              color: widget.isActive ? activeColor : (_isHovered ? hoverColor : normalColor),
              fontSize: 13,
              // fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
              fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (widget.isActive)
            Container(
              margin: const EdgeInsets.only(top: 2),
              // height: 1.5,
              // width: 15,
              height: 2,
              width: 16,
              color: activeColor,
            ),
        ],
      ),
    );
  }
}
