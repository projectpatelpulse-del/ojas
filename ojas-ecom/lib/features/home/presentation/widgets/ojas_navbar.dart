import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:ojas_user/core/controllers/settings_controller.dart';
import 'package:ojas_user/features/auth/domain/models/user_model.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/core/controllers/wishlist_controller.dart';
import 'package:ojas_user/features/home/presentation/pages/shop_page.dart';

class OjasNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String activeTitle;
  const OjasNavbar({super.key, this.activeTitle = 'HOME'});

  @override
  Size get preferredSize => Size.fromHeight(SessionService.instance.refCode != null ? 0 : 0);
  
  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      final String? currentRoute = ModalRoute.of(context)?.settings.name;
      final bool isAuthScreen = currentRoute == '/login' || currentRoute == '/register' || activeTitle == 'LOGIN' || activeTitle == 'REGISTER';
      final bool isRefLocked = SessionService.instance.refCode != null;
      return PreferredSize(
        preferredSize: Size.fromHeight(isAuthScreen || isRefLocked ? 70 : 130),
        child: _MobileNavbar(activeTitle: activeTitle),
      );
    }

    if (SessionService.instance.refCode != null) {
      return Column(
        children: [
          // 1. Top Info Bar
          // Container(
          //   height: 40,
          //   color: AppColors.primaryIndigo.withOpacity(0.95),
          //   child: const CenteredContent(
          //     horizontalPadding: 40,
          //     child: _TopInfoBarContent(),
          //   ),
          // ),
          
          // 2. Main Navigation Bar
          Container(
            height: 70,
            color: AppColors.primaryIndigo,
            child: CenteredContent(
              horizontalPadding: 40,
              child: _MainNavBarContent(activeTitle: activeTitle),
            ),
          ),
        ],
      );
    }

    return Column(
        children: [
          // 1. Top Info Bar
          // Container(
          //   height: 40,
          //   color: AppColors.primaryIndigo.withOpacity(0.95),
          //   child: const CenteredContent(
          //     horizontalPadding: 40,
          //     child: _TopInfoBarContent(),
          //   ),
          // ),
          
          // 2. Main Navigation Bar
          Container(
            height: 70,
            color: AppColors.primaryIndigo,
            child: CenteredContent(
              horizontalPadding: 40,
              child: _MainNavBarContent(activeTitle: activeTitle),
            ),
          ),
          
          // 3. Search & Vendor Bar
          Container(
            height: 70,
            color: AppColors.primaryIndigo.withOpacity(0.98),
            child: const CenteredContent(
              horizontalPadding: 40,
              child: _SearchBarRowContent(),
            ),
          ),
        ],
    );
  }
}

class _MobileNavbar extends StatefulWidget {
  final String activeTitle;
  const _MobileNavbar({required this.activeTitle});

  @override
  State<_MobileNavbar> createState() => _MobileNavbarState();
}

class _MobileNavbarState extends State<_MobileNavbar> {
  final TextEditingController _searchController = TextEditingController();

  void _handleSearch() {
    if (_searchController.text.trim().isNotEmpty) {
      Navigator.pushNamed(
        context, 
        '/shop', 
        arguments: {'search': _searchController.text.trim()}
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isAuthScreen = currentRoute == '/login' || currentRoute == '/register' || widget.activeTitle == 'LOGIN' || widget.activeTitle == 'REGISTER';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryIndigo,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SessionService.instance.refCode != null
                    ? const SizedBox(width: 48)
                    : IconButton(
                        icon: const Icon(Icons.menu, color: AppColors.black),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (SessionService.instance.refCode != null && SessionService.instance.referredProductId != null) {
                        Navigator.pushNamed(
                          context,
                          '/product-detail',
                          arguments: {'id': SessionService.instance.referredProductId, 'ref': SessionService.instance.refCode},
                        );
                      } else {
                        Navigator.pushNamed(context, '/');
                      }
                    },
                    child: Center(
                      child: SettingsController.instance.settings.logo.isNotEmpty
                          ? Image.network(
                              SettingsController.instance.settings.logo,
                              // height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Text(
                                SettingsController.instance.settings.marketplaceName,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            )
                          : Text(
                              SettingsController.instance.settings.marketplaceName,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.black, size: 22),
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                    ),
                    ValueListenableBuilder<UserModel?>(
                      valueListenable: SessionService.instance.userNotifier,
                      builder: (context, user, _) {
                        return IconButton(
                          icon: const Icon(Icons.person_outline, color: AppColors.black, size: 22),
                          onPressed: () {
                            if (user != null) {
                              Navigator.pushNamed(context, '/profile', arguments: user);
                            } else {
                              Navigator.pushNamed(context, '/login');
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (!isAuthScreen && SessionService.instance.refCode == null)
            // Mobile Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _handleSearch(),
                          style: const TextStyle(color: AppColors.black, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: TextStyle(color: AppColors.grey[500], fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _handleSearch,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: AppColors.white,
                          size: 20,
                        ),
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
}


class _TopInfoBarContent extends StatelessWidget {
  const _TopInfoBarContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, color: AppColors.accentOrange, size: 16),
            const SizedBox(width: 8),
            Text(
              'Good Deals Every Day!',
              style: GoogleFonts.inter(color: AppColors.black, fontSize: 12),
            ),
            const SizedBox(width: 16),
            Text(
              'Learn More',
              style: GoogleFonts.inter(
                color: AppColors.accentOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _TopInfoItem(
              icon: Icons.location_on_outlined, 
              label: 'Track Order',
              onTap: () => Navigator.pushNamed(context, '/orders'),
            ),
            const SizedBox(width: 24),
            _TopInfoItem(icon: Icons.phone_outlined, label: SettingsController.instance.settings.supportPhone),
          ],
        ),
      ],
    );
  }
}

class _TopInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _TopInfoItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.black, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(color: AppColors.black, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MainNavBarContent extends StatelessWidget {
  final String activeTitle;
  const _MainNavBarContent({required this.activeTitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logo
        InkWell(
          onTap: () {
            if (SessionService.instance.refCode != null && SessionService.instance.referredProductId != null) {
              Navigator.pushNamed(
                context,
                '/product-detail',
                arguments: {'id': SessionService.instance.referredProductId, 'ref': SessionService.instance.refCode},
              );
            } else {
              Navigator.pushNamed(context, '/');
            }
          },
          child: SettingsController.instance.settings.logo.isNotEmpty
              ? Image.network(
                  SettingsController.instance.settings.logo,
                  // height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Text(
                    SettingsController.instance.settings.marketplaceName,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                )
              : Text(
                  SettingsController.instance.settings.marketplaceName,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
        const SizedBox(width: 20), // Reduced width
        
        Expanded(
          child: SessionService.instance.refCode != null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ListenableBuilder(
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

                      return Row(
                        children: items.map((item) {
                          final upperItem = item.toUpperCase();
                          final route = routeMap[upperItem] ?? '/';
                          return _NavItem(
                            key: ValueKey('nav_${item.toLowerCase()}'),
                            title: item,
                            isActive: activeTitle.toUpperCase() == upperItem,
                            onTap: () => Navigator.pushNamed(context, route),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
        ),
        
        // Actions
        if (SessionService.instance.refCode == null) ...[
          ListenableBuilder(
            listenable: WishlistController.instance,
            builder: (context, _) {
              return _IconAction(
                key: const ValueKey('nav_wishlist'),
                icon: Icons.favorite_border, 
                label: 'Wishlist', 
                count: WishlistController.instance.count.toString(), 
                onTap: () => Navigator.pushNamed(context, '/wishlist')
              );
            },
          ),
          const SizedBox(width: 16),
        ],
        
        // Cart Button
        ListenableBuilder(
          listenable: CartController.instance,
          builder: (context, _) {
            return ElevatedButton.icon(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Badge(
                label: Text(CartController.instance.itemCount.toString()),
                isLabelVisible: CartController.instance.itemCount > 0,
                child: const Icon(Icons.shopping_cart_outlined, size: 18),
              ),
              label: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            );
          },
        ),
        
        const SizedBox(width: 16),
        
        ValueListenableBuilder<UserModel?>(
          valueListenable: SessionService.instance.userNotifier,
          builder: (context, user, _) {
            if (user != null) {
              return _UserInfo(user: user, isActive: activeTitle == 'PROFILE');
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _AuthLink(key: ValueKey('nav_login'), title: 'User Login'),
                const SizedBox(width: 8),
                _RegisterButton(key: const ValueKey('nav_register')),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UserInfo extends StatelessWidget {
  final UserModel user;
  final bool isActive;
  const _UserInfo({required this.user, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/profile', arguments: user),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.blue500.withOpacity(0.5), width: 1.5),
              ),
              child: ClipOval(
                child: user.photo != null && user.photo!.isNotEmpty
                  ? Image.network(
                      user.photo!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.black, size: 16),
                    )
                  : const Icon(Icons.person, color: AppColors.black, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: isActive ? AppColors.accentOrange : AppColors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.role.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: isActive ? AppColors.accentOrange.withOpacity(0.8) : AppColors.black87,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SearchBarRowContent extends StatefulWidget {
  const _SearchBarRowContent();

  @override
  State<_SearchBarRowContent> createState() => _SearchBarRowContentState();
}

class _SearchBarRowContentState extends State<_SearchBarRowContent> {
  final TextEditingController _searchController = TextEditingController();

  void _handleSearch() {
    if (_searchController.text.trim().isNotEmpty) {
      Navigator.pushNamed(
        context, 
        '/shop', 
        arguments: {'search': _searchController.text.trim()}
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Become Vendor Button
        Flexible(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/become-vendor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const FittedBox(child: Text('BECOME VENDOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ),
        ),
        
        const SizedBox(width: 12),

        // Become Reseller Button
        ValueListenableBuilder<UserModel?>(
          valueListenable: SessionService.instance.userNotifier,
          builder: (context, user, _) {
            if (user != null && user.role == 'reseller') {
              return const SizedBox.shrink();
            }
            return Flexible(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/become-reseller'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.people_outline, size: 18),
                label: const FittedBox(child: Text('BECOME RESELLER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ),
            );
          },
        ),
        
        const SizedBox(width: 16),
        

        // Search Field
Expanded(
  flex: 5,
  child: Container(
    height: 45,
    decoration: BoxDecoration(
      color: AppColors.grey[300],
      borderRadius: BorderRadius.circular(8),
      border: Border.all( // Added border
        color: AppColors.primaryBlue,
        width: 1.2,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _handleSearch(),
              style: const TextStyle(color: AppColors.black, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Enter your keyword...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: _handleSearch,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: const Icon(
              Icons.search,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    ),
  ),
),
        // // Search Field
        // Expanded(
        //   flex: 5,
        //   child: Container(
        //     height: 45,
        //     decoration: BoxDecoration(
        //       color: AppColors.grey[300],
        //       borderRadius: BorderRadius.circular(8),
        //     ),
        //     child: Row(
        //       children: [
        //         Expanded(
        //           child: Padding(
        //             padding: const EdgeInsets.symmetric(horizontal: 16),
        //             child: TextField(
        //               controller: _searchController,
        //               onSubmitted: (_) => _handleSearch(),
        //               decoration: const InputDecoration(
        //                 hintText: 'Enter your keyword...',
        //                 border: InputBorder.none,
        //                 hintStyle: TextStyle(color: AppColors.grey, fontSize: 14),
        //               ),
        //             ),
        //           ),
        //         ),
        //         InkWell(
        //           onTap: _handleSearch,
        //           child: Container(
        //             width: 45,
        //             height: 45,
        //             decoration: BoxDecoration(
        //               color: AppColors.primaryBlue,
        //               borderRadius: const BorderRadius.only(
        //                 topRight: Radius.circular(8),
        //                 bottomRight: Radius.circular(8),
        //               ),
        //             ),
        //             child: const Icon(Icons.search, color: AppColors.black),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
     
     
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback? onTap;
  const _NavItem({super.key, required this.title, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.accentOrange : AppColors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: isActive ? AppColors.accentOrange : AppColors.black,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final VoidCallback? onTap;
  
  const _IconAction({
    super.key,
    required this.icon, 
    required this.label, 
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.black, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$label $count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: AppColors.black, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthLink extends StatelessWidget {
  final String title;
  const _AuthLink({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/login'),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          title,
          style: GoogleFonts.inter(color: AppColors.black, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({super.key});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/register'),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Register',
          style: GoogleFonts.inter(
            color: AppColors.charcoal,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
