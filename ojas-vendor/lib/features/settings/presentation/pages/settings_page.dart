import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_vendor/core/constants/app_colors.dart';
import 'package:ojas_vendor/core/widgets/sidebar_layout.dart';
import 'package:ojas_vendor/core/widgets/vendor_topbar.dart';
import 'package:ojas_vendor/core/services/service_locator.dart';
import 'package:ojas_vendor/features/settings/data/services/vendor_settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _activeTab = 'Profile';
  bool _isLoading = true;
  bool _isSaving = false;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _vendor;

  final Map<String, bool> _notificationSettings = {
    'New Orders': true,
    'Order Updates': true,
    'Customer Messages': true,
    'Low Stock Alerts': true,
    'Weekly Reports': true,
  };

  final List<String> _selectedCategories = [];
  final TextEditingController _categoryController = TextEditingController();

  // Profile Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Store Controllers
  final _storeNameCtrl = TextEditingController();
  final _storeDescCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  String _businessType = 'Sole Proprietorship';
  String _avgOrderValue = 'Select range';
  String _monthlyVolume = '0 - 10 orders';

  // Address Controllers
  final _zipCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Docs Controllers
  final _taxIdCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();

  // Security Controllers
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await sl<VendorSettingsService>().getSettings();
      _user = data['user'];
      _vendor = data['vendor'];

      final names = (_user?['name'] ?? '').split(' ');
      _firstNameCtrl.text = names.isNotEmpty ? names.first : '';
      _lastNameCtrl.text = names.length > 1 ? names.sublist(1).join(' ') : '';
      _emailCtrl.text = _user?['email'] ?? '';
      _phoneCtrl.text = _user?['mobile'] ?? '';

      _storeNameCtrl.text = _vendor?['businessName'] ?? '';
      _storeDescCtrl.text = _vendor?['description'] ?? '';
      _websiteCtrl.text = _vendor?['website'] ?? '';

      if (['Sole Proprietorship', 'LLC', 'Corporation', 'Partnership'].contains(_vendor?['businessType'])) {
        _businessType = _vendor?['businessType'];
      }
      if (['Select range', '₹0 - ₹50', '₹50 - ₹100', '₹100+'].contains(_vendor?['avgOrderValue'])) {
        _avgOrderValue = _vendor?['avgOrderValue'];
      }
      if (['0 - 10 orders', '11 - 50 orders', '50+ orders'].contains(_vendor?['monthlyVolume'])) {
        _monthlyVolume = _vendor?['monthlyVolume'];
      }

      _zipCtrl.text = _vendor?['address']?['zipCode'] ?? '';
      _cityCtrl.text = _vendor?['address']?['city'] ?? '';
      _stateCtrl.text = _vendor?['address']?['state'] ?? '';
      _addressCtrl.text = _vendor?['address']?['street'] ?? '';

      _taxIdCtrl.text = _vendor?['documents']?['taxId'] ?? '';
      _bankAccountCtrl.text = _vendor?['documents']?['bankAccount'] ?? '';

      final cats = _vendor?['categories'] ?? [];
      _selectedCategories.clear();
      for (var c in cats) {
        _selectedCategories.add(c.toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      Map<String, dynamic> updateData = {};

      if (_activeTab == 'Profile' || _activeTab == 'Store Settings') {
        updateData = {
          'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
          'mobile': _phoneCtrl.text.trim(),
          'businessName': _storeNameCtrl.text.trim(),
          'description': _storeDescCtrl.text.trim(),
          'businessType': _businessType,
          'website': _websiteCtrl.text.trim(),
          'avgOrderValue': _avgOrderValue,
          'monthlyVolume': _monthlyVolume,
          'address': _addressCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'zipCode': _zipCtrl.text.trim(),
        };

        await sl<VendorSettingsService>().updateSettings(updateData);
      } else if (_activeTab == 'Security') {
        if (_currentPwdCtrl.text.isEmpty || _newPwdCtrl.text.isEmpty) {
          throw Exception('Please fill in current and new password');
        }
        if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
          throw Exception('New passwords do not match');
        }
        await sl<VendorSettingsService>().updatePassword(_currentPwdCtrl.text, _newPwdCtrl.text);
        _currentPwdCtrl.clear();
        _newPwdCtrl.clear();
        _confirmPwdCtrl.clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _storeNameCtrl.dispose();
    _storeDescCtrl.dispose();
    _websiteCtrl.dispose();
    _zipCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _addressCtrl.dispose();
    _taxIdCtrl.dispose();
    _bankAccountCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayout(
      activeRoute: '/settings',
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const VendorTopBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Settings',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your account and store preferences',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Vendor Information Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Vendor Information',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _vendor?['status'] == 'approved' ? const Color(0xFFE1FBF2) : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (_vendor?['status'] ?? 'PENDING').toString().toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _vendor?['status'] == 'approved' ? AppColors.success : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoColumn('Vendor ID', _vendor?['_id'] ?? 'N/A'),
                              ),
                              Expanded(
                                child: _buildInfoColumn('Account Created', _vendor?['createdAt']?.substring(0, 10) ?? 'N/A'),
                              ),
                              Expanded(
                                child: _buildInfoColumn('Last Updated', _vendor?['updatedAt']?.substring(0, 10) ?? 'N/A'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main Settings Area (Sidebar + Content)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Settings Sidebar
                        Container(
                          width: 240,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              _buildSettingsTab('Profile', Icons.person_outline),
                              _buildSettingsTab('Store Settings', Icons.storefront_outlined),
                              _buildSettingsTab('Notifications', Icons.notifications_none_outlined),
                              _buildSettingsTab('Security', Icons.security_outlined),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Settings Content
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _buildActiveContent(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(String title, IconData icon) {
    final bool isActive = _activeTab == title;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContent() {
    switch (_activeTab) {
      case 'Store Settings':
        return _buildStoreSettingsContent();
      case 'Notifications':
        return _buildNotificationsContent();
      case 'Security':
        return _buildSecurityContent();
      case 'Profile':
      default:
        return _buildProfileContent();
    }
  }

  Widget _buildSecurityContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Change Password', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 24),
        _buildPasswordInputField('Current Password *', _currentPwdCtrl, hintText: 'Enter current password'),
        const SizedBox(height: 24),
        _buildPasswordInputField('New Password *', _newPwdCtrl, hintText: 'Enter new password (min 6 characters)'),
        const SizedBox(height: 24),
        _buildPasswordInputField('Confirm New Password *', _confirmPwdCtrl, hintText: 'Confirm new password'),
        const SizedBox(height: 48),

        Text('Two-Factor Authentication', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enable 2FA', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Add an extra layer of security to your account (Coming soon)', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.blueGrey.shade100, borderRadius: BorderRadius.circular(6)),
                child: Text('Coming Soon', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blueGrey.shade700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_outlined, size: 20),
              label: Text('Update Password', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordInputField(String label, TextEditingController controller, {String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: TextFormField(
            controller: controller,
            obscureText: true,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email Notifications', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 24),
        _buildNotificationToggle('New Orders', 'Get notified when you receive new orders'),
        _buildNotificationToggle('Order Updates', 'Updates on order status changes'),
        _buildNotificationToggle('Customer Messages', 'New messages from customers'),
        _buildNotificationToggle('Low Stock Alerts', 'When products are running low'),
        _buildNotificationToggle('Weekly Reports', 'Weekly performance summaries'),
      ],
    );
  }

  Widget _buildNotificationToggle(String title, String subtitle) {
    final bool isActive = _notificationSettings[title] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          Switch(
            value: isActive,
            onChanged: (val) {
              setState(() {
                _notificationSettings[title] = val;
              });
            },
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(child: _buildInputField('First Name *', _firstNameCtrl)),
            const SizedBox(width: 24),
            Expanded(child: _buildInputField('Last Name *', _lastNameCtrl)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildInputField('Email', _emailCtrl, isDisabled: true, subText: 'Email cannot be changed directly')),
            const SizedBox(width: 24),
            Expanded(child: _buildInputField('Phone', _phoneCtrl)),
          ],
        ),
        const SizedBox(height: 48),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_outlined, size: 20),
              label: Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField('Store Name *', _storeNameCtrl),
        const SizedBox(height: 24),
        _buildInputField('Store Description *', _storeDescCtrl, maxLines: 4),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildDropdownField('Business Type', _businessType, ['Sole Proprietorship', 'LLC', 'Corporation', 'Partnership'], (v) {
                if (v != null) setState(() => _businessType = v);
              }),
            ),
            const SizedBox(width: 24),
            Expanded(child: _buildInputField('Website', _websiteCtrl)),
          ],
        ),
        const SizedBox(height: 24),

        Text('Product Categories (Read-Only)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedCategories.map((cat) => _buildCategoryChip(cat)).toList(),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildDropdownField('Average Order Value', _avgOrderValue, ['Select range', '₹0 - ₹50', '₹50 - ₹100', '₹100+'], (v) {
                if (v != null) setState(() => _avgOrderValue = v);
              }),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDropdownField('Monthly Volume', _monthlyVolume, ['0 - 10 orders', '11 - 50 orders', '50+ orders'], (v) {
                if (v != null) setState(() => _monthlyVolume = v);
              }),
            ),
          ],
        ),
        const SizedBox(height: 40),

        Text('Address Information', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 24),

        Row(
           children: [
             Expanded(child: _buildInputField('City *', _cityCtrl)),
             const SizedBox(width: 24),
             Expanded(child: _buildInputField('State *', _stateCtrl)),
             const SizedBox(width: 24),
             Expanded(child: _buildInputField('Zip Code', _zipCtrl)),
           ],
        ),
        const SizedBox(height: 24),

        _buildInputField('Store Address *', _addressCtrl, maxLines: 3),
        const SizedBox(height: 48),

        Text('Business Documents', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('These fields are read-only and were set during registration', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(child: _buildInputField('Tax ID', _taxIdCtrl, isDisabled: true)),
            const SizedBox(width: 24),
            Expanded(child: _buildInputField('Bank Account', _bankAccountCtrl, isDisabled: true)),
          ],
        ),
        const SizedBox(height: 40),
        const Divider(color: Color(0xFFF1F5F9)),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_outlined, size: 20),
              label: Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {int maxLines = 1, bool isDisabled = false, String? subText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          height: maxLines > 1 ? null : 48,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: !isDisabled,
            style: GoogleFonts.inter(fontSize: 14, color: isDisabled ? AppColors.textSecondary : AppColors.textPrimary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
        if (subText != null) ...[
          const SizedBox(height: 6),
          Text(subText, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ]
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              items: items.toSet().map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFFFF4EB), borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
    );
  }
}
