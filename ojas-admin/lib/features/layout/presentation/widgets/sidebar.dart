import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;

  const Sidebar({
    super.key,
    required this.currentRoute,
  });

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B21A8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Master Admin',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Platform Governance',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              children: [
                _buildSectionTitle('ADMINISTRATION'),
                _buildMenuItem(context, Icons.dashboard_outlined, 'Admin Overview', '/admin-overview'),
                _buildMenuItem(context, Icons.admin_panel_settings_outlined, 'Admin Management', '/admin-management'),
                _buildMenuItem(context, Icons.account_circle_outlined, 'Profile', '/profile'),
                _buildMenuItem(context, Icons.settings_outlined, 'Website Settings', '/settings'),
                
                const SizedBox(height: 16),
                _buildSectionTitle('MANAGEMENT'),
                _buildMenuItem(context, Icons.inventory_2_outlined, 'Products', '/products'),
                _buildMenuItem(context, Icons.shopping_cart_outlined, 'Orders', '/orders'),
                _buildMenuItem(context, Icons.category_outlined, 'Categories', '/categories'),
                _buildMenuItem(context, Icons.account_tree_outlined, 'Subcategories', '/subcategories'),
                _buildMenuItem(context, Icons.group_outlined, 'Users', '/users'),
                _buildMenuItem(context, Icons.storefront_outlined, 'Vendors', '/vendors'),
                _buildMenuItem(context, Icons.people_outline, 'Resellers', '/resellers'),
                _buildMenuItem(context, Icons.account_balance_wallet_outlined, 'Vendor Payouts', '/payouts'),
                _buildMenuItem(context, Icons.image_outlined, 'Hero Banners', '/banners'),
                
                const SizedBox(height: 16),
                _buildSectionTitle('SUPPORT'),
                _buildMenuItem(context, Icons.help_outline, 'Help Management', '/help'),

                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),
                _buildLogoutItem(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.logout_rounded,
          color: Colors.redAccent,
          size: 20,
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(
            color: Colors.redAccent,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        dense: true,
        horizontalTitleGap: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onTap: () => _logout(context),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String route) {
    final bool isSelected = currentRoute == route || (currentRoute == '/' && route == '/admin-overview');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFAF5FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: const Color(0xFF6B21A8).withOpacity(0.3)) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF6B21A8) : Colors.grey.shade600,
          size: 20,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isSelected ? const Color(0xFF6B21A8) : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        dense: true,
        horizontalTitleGap: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
