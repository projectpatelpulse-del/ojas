import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/core/controllers/wishlist_controller.dart';
import 'package:ojas_user/features/home/presentation/pages/shop_page.dart';

/// A Premium, Highly Animated Navbar for eCommerce
/// Designed by Ojas Senior UI/UX Expert
class PremiumAnimatedNavbar extends StatefulWidget {
  const PremiumAnimatedNavbar({super.key});

  @override
  State<PremiumAnimatedNavbar> createState() => _PremiumAnimatedNavbarState();
}

class _PremiumAnimatedNavbarState extends State<PremiumAnimatedNavbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _loadController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _loadController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _loadController, curve: Curves.elasticOut),
        );

    _loadController.forward();
  }

  @override
  void dispose() {
    _loadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.midnightIndigo.withOpacity(0.9),
                    AppColors.navyDark.withOpacity(0.95),
                    AppColors.blackDark.withOpacity(0.98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _TopUtilityBar(),
                  const _MainNavbar(),
                  // Subtle divider with glow
                  Divider(
                    color: Colors.pinkAccent.withOpacity(0.15),
                    height: 1,
                  ),
                  const _SearchBarAndVendorSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1. Top Utility Bar: Features minimalist info and contact details
class _TopUtilityBar extends StatelessWidget {
  const _TopUtilityBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.flash_on, color: AppColors.accentYellow, size: 16),
          const SizedBox(width: 8),
          Text(
            'good message ',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Learn More',
            style: GoogleFonts.poppins(
              color: AppColors.accentYellow,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          _TopLink(
            icon: Icons.location_on_outlined,
            text: 'Track Order',
            onTap: () => Navigator.pushReplacementNamed(context, '/orders'),
          ),
          const SizedBox(width: 20),
          _TopLink(icon: Icons.phone_outlined, text: '+91 908754321'),
        ],
      ),
    );
  }
}

class _TopLink extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _TopLink({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 2. Main Navbar: Logo, Menu, and User Actions
class _MainNavbar extends StatelessWidget {
  const _MainNavbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          // Elegant Logo Section
          InkWell(
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.pinkAccent.withOpacity(0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'OJAS',
                style: GoogleFonts.spectral(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 50),
          // Navigation Menu Items
          const _NavMenu(items: ['HOME', 'FEATURES', 'DEALS', 'SHOP', 'BLOG']),
          const Spacer(),
          // User Interactions
          const _UserActionSection(),
        ],
      ),
    );
  }
}

/// Animated Navigation Menu items with slide-underline hover effect & Route recognition
class _NavMenu extends StatelessWidget {
  final List<String> items;
  const _NavMenu({required this.items});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Row(
      children: List.generate(items.length, (index) {
        final item = items[index];
        bool isActive = false;
        if (item == 'HOME' && currentRoute == '/') isActive = true;
        if (item == 'FEATURES' && currentRoute == '/features') isActive = true;
        if (item == 'DEALS' && currentRoute == '/deals') isActive = true;
        if (item == 'SHOP' && currentRoute == '/shop') isActive = true;
        if (item == 'BLOG' && currentRoute == '/blog') isActive = true;
        if (item == 'LOGIN' && currentRoute == '/login') isActive = true;
        if (item == 'REGISTER' && currentRoute == '/register') isActive = true;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _HoverMenuAction(
            title: item,
            index: index,
            isActive: isActive,
            onTap: () {
              if (item == 'HOME') {
                Navigator.of(context).pushReplacementNamed('/');
              } else if (item == 'FEATURES') {
                Navigator.of(context).pushReplacementNamed('/features');
              } else if (item == 'DEALS') {
                Navigator.of(context).pushReplacementNamed('/deals');
              } else if (item == 'SHOP') {
                Navigator.of(context).pushReplacementNamed('/shop');
              } else if (item == 'BLOG') {
                Navigator.of(context).pushReplacementNamed('/blog');
              } else if (item == 'LOGIN') {
                Navigator.of(context).pushReplacementNamed('/login');
              } else if (item == 'REGISTER') {
                Navigator.of(context).pushReplacementNamed('/register');
              }
            },
          ),
        );
      }),
    );
  }
}

class _HoverMenuAction extends StatefulWidget {
  final String title;
  final int index;
  final bool isActive;
  final VoidCallback onTap;
  const _HoverMenuAction({
    required this.title,
    required this.index,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_HoverMenuAction> createState() => _HoverMenuActionState();
}

class _HoverMenuActionState extends State<_HoverMenuAction>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
        );

    Future.delayed(Duration(milliseconds: 400 + (widget.index * 100)), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEffectiveActive = _isHovered || widget.isActive;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedScale(
              scale: isEffectiveActive ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      color: isEffectiveActive ? Colors.white : Colors.white70,
                      fontSize: 14,
                      shadows: isEffectiveActive
                          ? [
                              Shadow(
                                color: Colors.pinkAccent.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                      fontWeight: isEffectiveActive
                          ? FontWeight.bold
                          : FontWeight.w500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 2,
                    width: isEffectiveActive ? 20 : 0,
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      boxShadow: [
                        if (isEffectiveActive)
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.8),
                            blurRadius: 4,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Right section of Navbar: Wishlist, Cart, Login, Register
class _UserActionSection extends StatelessWidget {
  const _UserActionSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Wishlist
        ListenableBuilder(
          listenable: WishlistController.instance,
          builder: (context, _) {
            final count = WishlistController.instance.count;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _HoverIconAction(
                  icon: Icons.favorite_border, 
                  label: 'Wishlist',
                  onTap: () => Navigator.of(context).pushReplacementNamed('/wishlist'),
                ),
                if (count > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF01B6B),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 20),
        // Cart Button (Highlighted Animation)
        const _PulseCartButton(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: VerticalDivider(
            color: Colors.white24,
            indent: 20,
            endIndent: 20,
          ),
        ),
        // Auth Buttons
        ListenableBuilder(
          listenable: SessionService.instance,
          builder: (context, _) {
            if (SessionService.instance.isLoggedIn) {
              return Row(
                children: [
                  _HoverIconAction(
                    icon: Icons.person_outline,
                    label: SessionService.instance.currentUser?.name ?? 'Profile',
                    onTap: () => Navigator.of(context).pushReplacementNamed('/profile'),
                  ),
                  const SizedBox(width: 15),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                    onPressed: () async {
                       await SessionService.instance.logout();
                       if (context.mounted) {
                         Navigator.of(context).pushReplacementNamed('/login');
                       }
                    },
                  ),
                ],
              );
            }
            return Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: Text(
                    'Login',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/register');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Register',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HoverIconAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _HoverIconAction({required this.icon, required this.label, this.onTap});

  @override
  State<_HoverIconAction> createState() => _HoverIconActionState();
}

class _HoverIconActionState extends State<_HoverIconAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: _isHovered ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: GoogleFonts.poppins(
                color: _isHovered ? Colors.white : Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseCartButton extends StatefulWidget {
  const _PulseCartButton();

  @override
  State<_PulseCartButton> createState() => _PulseCartButtonState();
}

class _PulseCartButtonState extends State<_PulseCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartController.instance,
      builder: (context, _) {
        final count = CartController.instance.itemCount;
        return ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/cart'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.pinkGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'My Cart ($count)',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
}

/// 3. Search Bar and "Become Vendor" CTA Section
class _SearchBarAndVendorSection extends StatelessWidget {
  const _SearchBarAndVendorSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // BECOME VENDOR CTA
          const _BecomeVendorButton(),
          const SizedBox(width: 20),
          // Expanded Search Bar
          const Expanded(child: _AnimatedSearchBar()),
        ],
      ),
    );
  }
}

class _BecomeVendorButton extends StatefulWidget {
  const _BecomeVendorButton();

  @override
  State<_BecomeVendorButton> createState() => _BecomeVendorButtonState();
}

class _BecomeVendorButtonState extends State<_BecomeVendorButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.orangeGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.store_outlined, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'BECOME VENDOR',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSearchBar extends StatefulWidget {
  const _AnimatedSearchBar();

  @override
  State<_AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<_AnimatedSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isFocused ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (_isFocused)
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.3),
                blurRadius: 25,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your keyword...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            // Search Icon Button
            Container(
              margin: const EdgeInsets.all(4),
              height: 52,
              width: 70,
              decoration: BoxDecoration(
                gradient: AppColors.pinkGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}
