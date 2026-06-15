import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/service_locator.dart';

class VendorTopBar extends StatefulWidget implements PreferredSizeWidget {
  const VendorTopBar({super.key});

  @override
  State<VendorTopBar> createState() => _VendorTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _VendorTopBarState extends State<VendorTopBar> {
  String _vendorName = 'Vendor';
  String _vendorEmail = '';

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('vendor_name');
    final email = prefs.getString('vendor_email');

    if (mounted) {
      setState(() {
        _vendorName = name ?? 'Vendor';
        _vendorEmail = email ?? '';
      });
    }

    // If name is default or missing, try to fetch it from the API
    if (name == null || name == 'Vendor' || name.isEmpty) {
      _fetchVendorInfo();
    }
  }

  Future<void> _fetchVendorInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('vendor_token');
      if (token == null) return;

      final response = await sl<ApiService>().dio.get('/vendor/settings');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final userData = response.data['data']['user'];
        if (userData != null) {
          final fetchedName = userData['name'] ?? 'Vendor';
          final fetchedEmail = userData['email'] ?? '';
          
          await prefs.setString('vendor_name', fetchedName);
          await prefs.setString('vendor_email', fetchedEmail);
          
          if (mounted) {
            setState(() {
              _vendorName = fetchedName;
              _vendorEmail = fetchedEmail;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('TopBar: Failed to auto-fetch vendor info: $e');
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vendor_token');
    await prefs.remove('vendor_name');
    await prefs.remove('vendor_email');
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Search Bar
          // Expanded(
          //   child: Container(
          //     height: 40,
          //     decoration: BoxDecoration(
          //       color: Colors.grey.shade50,
          //       borderRadius: BorderRadius.circular(8),
          //       border: Border.all(color: Colors.grey.shade200),
          //     ),
          //     child: TextField(
          //       decoration: InputDecoration(
          //         hintText: 'Sesrewrarch...',
          //         hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
          //         prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          //         suffixIcon: Container(
          //           margin: const EdgeInsets.all(8),
          //           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          //           decoration: BoxDecoration(
          //             color: Colors.grey.shade200,
          //             borderRadius: BorderRadius.circular(4),
          //           ),
          //           child: Text('⌘ K', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
          //         ),
          //         border: InputBorder.none,
          //         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          //       ),
          //     ),
          //   ),
          // ),
          
          // const SizedBox(width: 24),
          
          // Vendor Profile Dropdown
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              } else if (value == 'profile') {
                context.go('/settings');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'header',
                enabled: false,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _vendorName.isNotEmpty ? _vendorName[0].toUpperCase() : 'V',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _vendorName,
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _vendorEmail,
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'profile',
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: Colors.blueGrey.shade700),
                    const SizedBox(width: 12),
                    Text(
                      'Profile Settings',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.blueGrey.shade700),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<String>(
                value: 'logout',
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _vendorName.isNotEmpty ? _vendorName[0].toUpperCase() : 'V',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Row(
                       children: [
                         Text(
                           _vendorName,
                           style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                         ),
                         const SizedBox(width: 8),
                         Container(
                           padding: const EdgeInsets.all(4),
                           decoration: BoxDecoration(
                             color: Colors.grey.shade100,
                             borderRadius: BorderRadius.circular(6),
                           ),
                           child: const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
                         ),
                       ],
                     ),
                     if (_vendorEmail.isNotEmpty)
                       Text(
                         _vendorEmail,
                         style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                       ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
