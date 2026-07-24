import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
 
class OjasLayout extends StatefulWidget {
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
  State<OjasLayout> createState() => _OjasLayoutState();
}

class _OjasLayoutState extends State<OjasLayout> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isAuthScreen = currentRoute == '/login' || currentRoute == '/register' || widget.activeTitle == 'LOGIN' || widget.activeTitle == 'REGISTER';
    final double navbarHeight = widget.hideNavigation
        ? 0.0
        : (isMobile
            ? (isAuthScreen || SessionService.instance.refCode != null ? 70 : 130)
            : (SessionService.instance.refCode != null ? 110 : 140));

    // Request focus once layout is built to capture keyboard events immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimaryLight,
      drawer: (isMobile && !widget.hideNavigation && SessionService.instance.refCode == null) ? const _MobileDrawer() : null,
      endDrawer: widget.hideNavigation ? null : const CartDrawer(),
      floatingActionButton: ListenableBuilder(
        listenable: SettingsController.instance,
        builder: (context, _) {
          final settings = SettingsController.instance.settings;
          if (settings.whatsappNumber.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () async {
              final number = settings.whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
              final url = Uri.parse("https://wa.me/$number");
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Could not launch WhatsApp: $e');
              }
            },
            backgroundColor: const Color(0xFF25D366),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            child: const FaIcon(
              FontAwesomeIcons.whatsapp,
              color: AppColors.white,
              size: 28,
            ),
          );
        },
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _scrollController.animateTo(
                (_scrollController.offset + 80.0).clamp(0.0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _scrollController.animateTo(
                (_scrollController.offset - 80.0).clamp(0.0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      SizedBox(height: navbarHeight), // Responsive Navbar height
                      widget.child,
                      if (!widget.hideNavigation && SessionService.instance.refCode == null) const OjasFooter(), // Included here so it scrolls with content
                    ],
                  ),
                ),
              ),
            ),
            
            // 2. Fixed Navbar (Sticky at top)
            if (!widget.hideNavigation)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: navbarHeight,
                child: Builder(
                  builder: (context) => OjasNavbar(activeTitle: widget.activeTitle),
                ),
              ),
          ],
        ),
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
                        color: AppColors.white,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
          ListenableBuilder(
            listenable: SettingsController.instance,
            builder: (context, _) {
              final itemsString = SettingsController.instance.settings.navigationMenuItems;
              final items = itemsString
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              final routeMap = {
                'HOME': '/',
                'FEATURES': '/features',
                'DEALS': '/deals',
                'SHOP': '/shop',
                'BLOG': '/blog',
              };

              final iconMap = {
                'HOME': Icons.home_outlined,
                'FEATURES': Icons.featured_play_list_outlined,
                'DEALS': Icons.local_offer_outlined,
                'SHOP': Icons.shopping_bag_outlined,
                'BLOG': Icons.article_outlined,
              };

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) {
                  final upperItem = item.toUpperCase();
                  final route = routeMap[upperItem] ?? '/';
                  final icon = iconMap[upperItem] ?? Icons.link;
                  return _DrawerItem(
                    title: item,
                    icon: icon,
                    onTap: () => Navigator.pushNamed(context, route),
                  );
                }).toList(),
              );
            },
          ),
          const Divider(color: AppColors.white24, indent: 20, endIndent: 20),
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
      leading: Icon(icon, color: AppColors.white70),
      title: Text(
        title,
        style: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}


