import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';

class AdsAndSubscribeSection extends StatelessWidget {
  const AdsAndSubscribeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      color: AppColors.bgPrimaryLight,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 32 : 60.0,
        horizontal: isMobile ? 12 : 24.0,
      ),
      child: CenteredContent(
        horizontalPadding: isMobile ? 0 : 40,
        child: Column(
          children: [
            if (isMobile)
              Column(
                children: [
                  const _OfferCard(),
                  const SizedBox(height: 24),
                  const _SubscribeCard(),
                ],
              )
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Expanded(child: _OfferCard()),
                    SizedBox(width: 24),
                    Expanded(child: _SubscribeCard()),
                  ],
                ),
              ),
            const SizedBox(height: 48),
            // Bottom guarantees row
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 32,
              runSpacing: 16,
              children: [
                _buildGuarantee(
                  Icons.check_circle_outline,
                  '10,000+ Happy Customers',
                ),
                _buildGuarantee(
                  Icons.check_circle_outline,
                  'No Spam Guarantee',
                ),
                _buildGuarantee(
                  Icons.check_circle_outline,
                  'Unsubscribe Anytime',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuarantee(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.grey400),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            color: AppColors.grey500,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final homeController = HomeController.instance;

    return ListenableBuilder(
      listenable: homeController,
      builder: (context, _) {
        final offer = homeController.offerBanner;

        final bool hasLink = offer.link.isNotEmpty && offer.link != '/' && offer.link != '#';

        Widget mainContent = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: offer.imageUrl.isEmpty 
                ? const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            image: offer.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(offer.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: (offer.imageUrl.isEmpty ? const Color(0xFFE91E63) : AppColors.black).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: offer.imageUrl.isNotEmpty
                  ? LinearGradient(
                      colors: [AppColors.black.withOpacity(0.7), AppColors.transparent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard, color: AppColors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    if (offer.tag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          offer.tag.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  offer.title,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 28 : 40,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    offer.subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.white.withOpacity(0.9),
                      fontSize: isMobile ? 14 : 16,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildValidityText(),
              ],
            ),
          ),
        );

        if (hasLink) {
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (offer.link.isNotEmpty) {
                  Navigator.pushNamed(context, '/shop', arguments: {'search': offer.link});
                } else {
                  Navigator.pushNamed(context, '/shop');
                }
              },
              child: mainContent,
            ),
          );
        }

        return mainContent;
      },
    );
  }

  Widget _buildClaimButton(BuildContext context, String link) {
    return ElevatedButton(
      onPressed: () {
        if (link.isNotEmpty) {
          Navigator.pushNamed(context, '/shop', arguments: {'search': link});
        } else {
          Navigator.pushNamed(context, '/shop');
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.accentOrange,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_on, size: 18),
          const SizedBox(width: 8),
          Text(
            'Claim Offer',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );
  }

  Widget _buildValidityText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_awesome,
          color: AppColors.white.withOpacity(0.8),
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          'Valid for a limited time',
          style: GoogleFonts.inter(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SubscribeCard extends StatefulWidget {
  const _SubscribeCard();

  @override
  State<_SubscribeCard> createState() => _SubscribeCardState();
}

class _SubscribeCardState extends State<_SubscribeCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryIndigo, AppColors.primaryBlue], // Bronze/Gold
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.mail_outline,
              color: AppColors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Stay in the Loop',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Subscribe to our newsletter and be the first to know about exclusive deals, new arrivals, and special promotions.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Input field
          TextFormField(
            controller: _emailController,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 14,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }

              final emailRegex = RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              );

              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email';
              }

              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: TextStyle(
                color: AppColors.grey400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.white,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.mail_outline,
                  color: AppColors.grey400,
                  size: 20,
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.grey200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accentOrange, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully subscribed to newsletter!'),
                      backgroundColor: AppColors.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _emailController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrangeHover,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Subscribe Now',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Divider
          Divider(color: AppColors.grey100, thickness: 1),
          const SizedBox(height: 16),

          // Perks
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'What you\'ll get:',
              style: GoogleFonts.inter(
                color: AppColors.grey600,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPerk(AppColors.red400, 'Exclusive discounts'),
                const SizedBox(height: 10),
                _buildPerk(AppColors.green400, 'New product alerts'),
                const SizedBox(height: 10),
                _buildPerk(AppColors.blue400, 'Early access to sales'),
                const SizedBox(height: 10),
                _buildPerk(Colors.purple.shade400, 'Weekly style tips'),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPerk(AppColors.red400, 'Exclusive discounts'),
                      const SizedBox(height: 12),
                      _buildPerk(AppColors.green400, 'New product alerts'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPerk(AppColors.blue400, 'Early access to sales'),
                      const SizedBox(height: 12),
                      _buildPerk(Colors.purple.shade400, 'Weekly style tips'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      )
    );
  }

  Widget _buildPerk(Color dotColor, String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.inter(color: AppColors.grey600, fontSize: 12),
        ),
      ],
    );
  }
}
