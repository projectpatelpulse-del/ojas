import 'package:flutter/material.dart';
import 'package:ojas_user/features/home/presentation/widgets/ojas_navbar.dart';
import 'package:ojas_user/features/home/presentation/widgets/ojas_footer.dart';
import 'package:ojas_user/features/home/presentation/widgets/cart_drawer.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/controllers/wishlist_controller.dart';

import 'package:ojas_user/core/controllers/settings_controller.dart';

import '../../features/auth/domain/models/user_model.dart';
import '../services/session_service.dart';

class OjasLayout extends StatelessWidget {
  final Widget child;
  final String activeTitle;
  final bool hideNavigation;
  
  const OjasLayout({
    super.key,
    required this.child,
    this.activeTitle = 'HOME',
    this.hideNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isAuthScreen = currentRoute == '/login' || currentRoute == '/register' || activeTitle == 'LOGIN' || activeTitle == 'REGISTER';
    final double navbarHeight = hideNavigation
        ? 0.0
        : (isMobile
            ? (isAuthScreen || SessionService.instance.refCode != null ? 70 : 130)
            : (SessionService.instance.refCode != null ? 110 : 180));

    return Scaffold(
      backgroundColor: AppColors.bgPrimaryLight,
      drawer: (isMobile && !hideNavigation && SessionService.instance.refCode == null) ? const _MobileDrawer() : null,
      endDrawer: hideNavigation ? null : const CartDrawer(),
      body: Stack(
        children: [
          // 1. Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: navbarHeight), // Responsive Navbar height
                  child,
                  if (!hideNavigation && SessionService.instance.refCode == null) const OjasFooter(), // Included here so it scrolls with content
                ],
              ),
            ),
          ),
          
          // 2. Fixed Navbar (Sticky at top)
          if (!hideNavigation)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: navbarHeight,
              child: Builder(
                builder: (context) => OjasNavbar(activeTitle: activeTitle),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 2 / 3,
      backgroundColor: AppColors.primaryIndigo,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryIndigo),
            child: Center(
              child: SettingsController.instance.settings.logo.isNotEmpty
                  ? Image.network(
                      SettingsController.instance.settings.logo,
                      height: 50,
                      fit: BoxFit.contain,
                    )
                  : Text(
                      SettingsController.instance.settings.marketplaceName,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
          _DrawerItem(title: 'HOME', icon: Icons.home_outlined, onTap: () => Navigator.pushNamed(context, '/')),
          _DrawerItem(title: 'FEATURES', icon: Icons.featured_play_list_outlined, onTap: () => Navigator.pushNamed(context, '/features')),
          _DrawerItem(title: 'DEALS', icon: Icons.local_offer_outlined, onTap: () => Navigator.pushNamed(context, '/deals')),
          _DrawerItem(title: 'SHOP', icon: Icons.shopping_bag_outlined, onTap: () => Navigator.pushNamed(context, '/shop')),
          _DrawerItem(title: 'BLOG', icon: Icons.article_outlined, onTap: () => Navigator.pushNamed(context, '/blog')),
          const Divider(color: Colors.white24, indent: 20, endIndent: 20),
          _DrawerItem(title: 'BECOME VENDOR', icon: Icons.storefront_outlined, onTap: () => Navigator.pushNamed(context, '/become-vendor')),
          ValueListenableBuilder<UserModel?>(
            valueListenable: SessionService.instance.userNotifier,
            builder: (context, user, _) {
              if (user != null && user.role == 'reseller') {
                return const SizedBox.shrink();
              }
              return _DrawerItem(title: 'BECOME RESELLER', icon: Icons.people_outline, onTap: () => Navigator.pushNamed(context, '/become-reseller'));
            },
          ),
          _DrawerItem(title: 'MY ORDERS', icon: Icons.local_shipping_outlined, onTap: () => Navigator.pushNamed(context, '/orders')),
          ListenableBuilder(
            listenable: WishlistController.instance,
            builder: (context, _) {
              final count = WishlistController.instance.count;
              return _DrawerItem(
                title: 'WISHLIST ${count > 0 ? "($count)" : ""}', 
                icon: Icons.favorite_border, 
                onTap: () => Navigator.pushNamed(context, '/wishlist')
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DrawerItem({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}


