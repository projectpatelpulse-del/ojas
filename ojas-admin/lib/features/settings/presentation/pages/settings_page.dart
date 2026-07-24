import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_admin/features/layout/presentation/widgets/admin_layout.dart';
import 'package:ojas_admin/core/services/api_service.dart';
import 'package:ojas_admin/features/settings/presentation/widgets/blog_management.dart';
import 'package:dio/dio.dart';
import 'package:ojas_admin/core/services/favicon_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _footerController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();
  // New: Contact info
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactAddressController = TextEditingController();
  // New: Legal pages
  final TextEditingController _returnRefundController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _privacyController = TextEditingController();
  final TextEditingController _aboutUsController = TextEditingController();
  // New: Social links
  final TextEditingController _fbController = TextEditingController();
  final TextEditingController _instaController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _ytController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  // New: Secure Config
  final TextEditingController _paymentKeyController = TextEditingController();
  final TextEditingController _paymentSaltController = TextEditingController();
  final TextEditingController _delhiveryTokenController = TextEditingController();
  final TextEditingController _emailUserController = TextEditingController();
  final TextEditingController _emailPassController = TextEditingController();
  final TextEditingController _whatsappTokenController = TextEditingController();
  final TextEditingController _whatsappNumberController = TextEditingController();
  final TextEditingController _geminiKeyController = TextEditingController();
  final TextEditingController _navigationMenuItemsController = TextEditingController();
  final TextEditingController _homeSectionsActiveController = TextEditingController();
  
  // Trending Section & Service Cards
  final TextEditingController _trendingCategoriesController = TextEditingController();
  final TextEditingController _card1TitleController = TextEditingController();
  final TextEditingController _card1SubtitleController = TextEditingController();
  final TextEditingController _card1IconController = TextEditingController();
  final TextEditingController _card2TitleController = TextEditingController();
  final TextEditingController _card2SubtitleController = TextEditingController();
  final TextEditingController _card2IconController = TextEditingController();
  final TextEditingController _card3TitleController = TextEditingController();
  final TextEditingController _card3SubtitleController = TextEditingController();
  final TextEditingController _card3IconController = TextEditingController();
  final TextEditingController _card4TitleController = TextEditingController();
  final TextEditingController _card4SubtitleController = TextEditingController();
  final TextEditingController _card4IconController = TextEditingController();
  
  bool _enableAnnouncement = false;
  bool _showTrendingProducts = true;
  bool _showTrendingB2BBanner = true;
  bool _isLoading = true;
  String? _logoUrl;
  String? _faviconUrl;
  bool _isUploadingLogo = false;
  bool _isUploadingFavicon = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService().dio.get('/admin/settings');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        _nameController.text = data['marketplaceName'] ?? '';
        _taglineController.text = data['tagline'] ?? '';
        _emailController.text = data['supportEmail'] ?? '';
        _phoneController.text = data['supportPhone'] ?? '';
        _footerController.text = data['footerMessage'] ?? '';
        _announcementController.text = data['announcementMessage'] ?? '';
        _linkController.text = data['announcementLink'] ?? '';
        _enableAnnouncement = data['enableAnnouncement'] ?? false;
        _commissionController.text = (data['defaultCommission'] ?? 10).toString();
        // New fields
        _contactPhoneController.text = data['contactPhone'] ?? '';
        _contactEmailController.text = data['contactEmail'] ?? '';
        _contactAddressController.text = data['contactAddress'] ?? '';
        _returnRefundController.text = data['returnRefundPolicy'] ?? '';
        _termsController.text = data['termsConditions'] ?? '';
        _privacyController.text = data['privacyPolicy'] ?? '';
        _aboutUsController.text = data['aboutUsContent'] ?? '';
        // New: Social links
        _fbController.text = data['facebookLink'] ?? '';
        _instaController.text = data['instagramLink'] ?? '';
        _twitterController.text = data['twitterLink'] ?? '';
        _ytController.text = data['youtubeLink'] ?? '';
        _linkedinController.text = data['linkedinLink'] ?? '';
        // New: Secure Config
        _paymentKeyController.text = data['paymentGatewayKey'] ?? '';
        _paymentSaltController.text = data['paymentGatewaySalt'] ?? '';
        _delhiveryTokenController.text = data['delhiveryToken'] ?? '';
        _emailUserController.text = data['emailUser'] ?? '';
        _emailPassController.text = data['emailPass'] ?? '';
        _whatsappTokenController.text = data['whatsappToken'] ?? '';
        _whatsappNumberController.text = data['whatsappNumber'] ?? '';
        _geminiKeyController.text = data['geminiApiKey'] ?? '';
        _navigationMenuItemsController.text = data['navigationMenuItems'] ?? '';
        _homeSectionsActiveController.text = data['homeSectionsActive'] ?? '';
        _showTrendingProducts = data['showTrendingProducts'] ?? true;
        _showTrendingB2BBanner = data['showTrendingB2BBanner'] ?? true;
        
        _trendingCategoriesController.text = data['trendingCategories'] ?? '';
        _card1TitleController.text = data['serviceCard1Title'] ?? '';
        _card1SubtitleController.text = data['serviceCard1Subtitle'] ?? '';
        _card1IconController.text = data['serviceCard1Icon'] ?? '';
        _card2TitleController.text = data['serviceCard2Title'] ?? '';
        _card2SubtitleController.text = data['serviceCard2Subtitle'] ?? '';
        _card2IconController.text = data['serviceCard2Icon'] ?? '';
        _card3TitleController.text = data['serviceCard3Title'] ?? '';
        _card3SubtitleController.text = data['serviceCard3Subtitle'] ?? '';
        _card3IconController.text = data['serviceCard3Icon'] ?? '';
        _card4TitleController.text = data['serviceCard4Title'] ?? '';
        _card4SubtitleController.text = data['serviceCard4Subtitle'] ?? '';
        _card4IconController.text = data['serviceCard4Icon'] ?? '';

        _logoUrl = data['logo'];
        _faviconUrl = data['favicon'];
        if (_faviconUrl != null && _faviconUrl!.isNotEmpty) {
          updateFavicon(_faviconUrl!);
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    debugPrint('Saving settings with data: ${_nameController.text}');
    try {
      final response = await ApiService().dio.put('/admin/settings', data: {
        'marketplaceName': _nameController.text,
        'tagline': _taglineController.text,
        'supportEmail': _emailController.text,
        'supportPhone': _phoneController.text,
        'footerMessage': _footerController.text,
        'announcementMessage': _announcementController.text,
        'announcementLink': _linkController.text,
        'enableAnnouncement': _enableAnnouncement,
        'defaultCommission': double.tryParse(_commissionController.text) ?? 10,
        // New fields
        'contactPhone': _contactPhoneController.text,
        'contactEmail': _contactEmailController.text,
        'contactAddress': _contactAddressController.text,
        'returnRefundPolicy': _returnRefundController.text,
        'termsConditions': _termsController.text,
        'privacyPolicy': _privacyController.text,
        'aboutUsContent': _aboutUsController.text,
        // New: Social links
        'facebookLink': _fbController.text,
        'instagramLink': _instaController.text,
        'twitterLink': _twitterController.text,
        'youtubeLink': _ytController.text,
        'linkedinLink': _linkedinController.text,
        // New: Secure Config
        'paymentGatewayKey': _paymentKeyController.text,
        'paymentGatewaySalt': _paymentSaltController.text,
        'delhiveryToken': _delhiveryTokenController.text,
        'emailUser': _emailUserController.text,
        'emailPass': _emailPassController.text,
        'whatsappToken': _whatsappTokenController.text,
        'whatsappNumber': _whatsappNumberController.text,
        'geminiApiKey': _geminiKeyController.text,
        'navigationMenuItems': _navigationMenuItemsController.text,
        'homeSectionsActive': _homeSectionsActiveController.text,
        'showTrendingProducts': _showTrendingProducts,
        'showTrendingB2BBanner': _showTrendingB2BBanner,
        
        'trendingCategories': _trendingCategoriesController.text,
        'serviceCard1Title': _card1TitleController.text,
        'serviceCard1Subtitle': _card1SubtitleController.text,
        'serviceCard1Icon': _card1IconController.text,
        'serviceCard2Title': _card2TitleController.text,
        'serviceCard2Subtitle': _card2SubtitleController.text,
        'serviceCard2Icon': _card2IconController.text,
        'serviceCard3Title': _card3TitleController.text,
        'serviceCard3Subtitle': _card3SubtitleController.text,
        'serviceCard3Icon': _card3IconController.text,
        'serviceCard4Title': _card4TitleController.text,
        'serviceCard4Subtitle': _card4SubtitleController.text,
        'serviceCard4Icon': _card4IconController.text,

        'logo': _logoUrl,
        'favicon': _faviconUrl,
      });

      debugPrint('Save response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully! Updating user website...')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        String errorMessage = 'Failed to save settings';
        if (e is DioException && e.response != null) {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetToDefault() async {
    try {
      final response = await ApiService().dio.post('/admin/settings/reset');
      if (response.statusCode == 200) {
        await _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings reset to defaults')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isLogo) {
            _isUploadingLogo = true;
          } else {
            _isUploadingFavicon = true;
          }
        });

        final bytes = await image.readAsBytes();
        final formData = FormData.fromMap({
          'image': MultipartFile.fromBytes(bytes, filename: image.name),
        });

        final response = await ApiService().dio.post('/upload/image', data: formData);
        
        if (response.statusCode == 200) {
          setState(() {
            if (isLogo) {
              _logoUrl = response.data['url'];
              _isUploadingLogo = false;
            } else {
              _faviconUrl = response.data['url'];
              _isUploadingFavicon = false;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${isLogo ? "Logo" : "Favicon"} uploaded successfully! Remember to save settings.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      setState(() {
        if (isLogo) {
          _isUploadingLogo = false;
        } else {
          _isUploadingFavicon = false;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/settings',
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              color: Colors.white,
              child: Row(
                children: [
                  Text('Master Admin', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  Text('Website Settings', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),

            // Tab Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                indicatorColor: const Color(0xFF8B5CF6),
                labelColor: const Color(0xFF8B5CF6),
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'General Settings'),
                  Tab(text: 'Blogs Management'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: General Settings
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Website Identity & Branding',
                                      style: GoogleFonts.outfit(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage marketplace identity, colors, and contact details shown across the platform.',
                                      style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: Text('Reset Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey.shade700,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: _resetToDefault,
                                    icon: const Icon(Icons.settings_backup_restore, size: 16),
                                    label: Text('Reset to Default', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _saveSettings,
                                    icon: const Icon(Icons.save_outlined, size: 16),
                                    label: Text('Save Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B5CF6), // Purple
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Main Layout (2 Columns)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column: Forms
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _buildBrandBasicsCard(),
                                    const SizedBox(height: 24),
                                    _buildLogoFaviconCard(),
                                    const SizedBox(height: 24),
                                    _buildAnnouncementCard(),
                                    const SizedBox(height: 24),
                                    _buildNavigationSettingsCard(),
                                    const SizedBox(height: 24),
                                    _buildHomeSectionsSettingsCard(),
                                    const SizedBox(height: 24),
                                    _buildContactInfoCard(),
                                    const SizedBox(height: 24),
                                    _buildLegalPagesCard(),
                                    const SizedBox(height: 24),
                                    _buildSocialMediaCard(),
                                    const SizedBox(height: 24),
                                    _buildTrendingSectionSettingsCard(),
                                    const SizedBox(height: 24),
                                    _buildSecureConfigCard(),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right Column: Preview
                              Expanded(
                                flex: 3,
                                child: _buildPreviewCard(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Tab 2: Blogs Management
                  const SingleChildScrollView(
                    padding: EdgeInsets.all(28),
                    child: BlogManagement(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandBasicsCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Brand Basics', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Logo, name, tagline, and primary contact information.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.palette_outlined, color: Color(0xFF8B5CF6), size: 24),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField('Marketplace Name', _nameController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Tagline', _taglineController)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField('Support Email', _emailController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Support Phone', _phoneController)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField('Default Platform Commission (%)', _commissionController)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField('Footer Message', _footerController, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildLogoFaviconCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Logo & Favicon', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Upload your brand logo and favicon images.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.upload_file_outlined, color: Color(0xFF8B5CF6), size: 24),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Logo', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildUploadBox(
                      'Click to upload logo', 
                      'Max 2MB', 
                      height: 120,
                      imageUrl: _logoUrl,
                      isUploading: _isUploadingLogo,
                      onTap: () => _pickImage(true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Favicon', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildUploadBox(
                      'Upload favicon', 
                      'Max 2MB', 
                      height: 120,
                      imageUrl: _faviconUrl,
                      isUploading: _isUploadingFavicon,
                      onTap: () => _pickImage(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Announcement Bar', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Configure top-of-site announcement messages.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.language_outlined, color: Colors.blue, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _enableAnnouncement,
                  onChanged: (v) => setState(() => _enableAnnouncement = v!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 12),
              Text('Enable announcement bar', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField('Announcement Message', _announcementController, maxLines: 2),
          const SizedBox(height: 20),
          _buildTextField('Link', _linkController),
        ],
      ),
    );
  }

  Widget _buildNavigationSettingsCard() {
    final activeItems = _navigationMenuItemsController.text
        .split(',')
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    Widget buildMenuToggle(String title) {
      final isSelected = activeItems.contains(title);
      return SwitchListTile(
        title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        value: isSelected,
        activeColor: const Color(0xFF8B5CF6),
        onChanged: (val) {
          setState(() {
            if (val) {
              activeItems.add(title);
            } else {
              activeItems.remove(title);
            }
            // Preserve the original ordering if possible or just join them
            final List<String> ordered = ['HOME', 'FEATURES', 'DEALS', 'SHOP', 'BLOG']
                .where((item) => activeItems.contains(item))
                .toList();
            _navigationMenuItemsController.text = ordered.join(', ');
          });
        },
      );
    }

    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Navigation Menu Management', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Toggle tabs active/inactive to manage what pages are visible in the navbar.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.navigation_outlined, color: Colors.indigo, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          buildMenuToggle('HOME'),
          buildMenuToggle('FEATURES'),
          buildMenuToggle('DEALS'),
          buildMenuToggle('SHOP'),
          buildMenuToggle('BLOG'),
        ],
      ),
    );
  }

  Widget _buildHomeSectionsSettingsCard() {
    final activeSections = _homeSectionsActiveController.text
        .split(',')
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    Widget buildSectionToggle(String sectionKey, String label) {
      final isSelected = activeSections.contains(sectionKey);
      return SwitchListTile(
        title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        value: isSelected,
        activeColor: const Color(0xFF8B5CF6),
        onChanged: (val) {
          setState(() {
            if (val) {
              activeSections.add(sectionKey);
            } else {
              activeSections.remove(sectionKey);
            }
            final List<String> ordered = [
              'HERO',
              'DAILY_DEALS',
              'SUMMER_SALE',
              'TRENDING',
              'PROMO_GRID',
              'BECOME_VENDOR',
              'JUST_FOR_YOU',
              'LATEST_PRODUCTS',
              'ADS_SUBSCRIBE',
            ].where((sec) => activeSections.contains(sec)).toList();
            _homeSectionsActiveController.text = ordered.join(', ');
          });
        },
      );
    }

    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Home Sections Management', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Toggle sections active/inactive to manage what content areas are displayed on the home page.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.dashboard_customize_outlined, color: Colors.teal, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          buildSectionToggle('HERO', 'Hero Banner (includes Gift Strip)'),
          buildSectionToggle('DAILY_DEALS', 'Daily Deals Section'),
          buildSectionToggle('SUMMER_SALE', 'Summer Sale Banner'),
          buildSectionToggle('TRENDING', 'Trending Items Section'),
          buildSectionToggle('PROMO_GRID', 'Promo Grid Section'),
          buildSectionToggle('BECOME_VENDOR', 'Become Vendor Banner'),
          buildSectionToggle('JUST_FOR_YOU', 'Just For You Section'),
          buildSectionToggle('LATEST_PRODUCTS', 'Latest Products Section'),
          buildSectionToggle('ADS_SUBSCRIBE', 'Ads & Subscribe Section'),
          const Divider(height: 32),
          SwitchListTile(
            title: Text('Show Products in Trending Section', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text('Show/hide actual items grid inside the trending items area', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            value: _showTrendingProducts,
            activeColor: const Color(0xFF8B5CF6),
            onChanged: (val) {
              setState(() {
                _showTrendingProducts = val;
              });
            },
          ),
          SwitchListTile(
            title: Text('Show B2B Gifting Partner Banner in Trending', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text('Show/hide custom B2B gifting banner image layout inside the trending items area', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            value: _showTrendingB2BBanner,
            activeColor: const Color(0xFF8B5CF6),
            onChanged: (val) {
              setState(() {
                _showTrendingB2BBanner = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Get In Touch (Footer)', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Contact details shown in the website footer.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.contact_phone_outlined, color: Colors.teal, size: 24),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField('Phone Number', _contactPhoneController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Email Address', _contactEmailController)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(flex: 2, child: _buildTextField('Address', _contactAddressController)),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: _buildTextField('WhatsApp FAB Number', _whatsappNumberController)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalPagesCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Legal Pages Content', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Manage content for Return & Refund Policy, Terms & Conditions, and Privacy Policy pages.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.gavel_outlined, color: Color(0xFF8B5CF6), size: 24),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField('Return & Refund Policy', _returnRefundController, maxLines: 10),
          const SizedBox(height: 20),
          _buildTextField('Terms & Conditions', _termsController, maxLines: 10),
          const SizedBox(height: 20),
          _buildTextField('Privacy Policy', _privacyController, maxLines: 10),
          const SizedBox(height: 20),
          _buildTextField('About Us Content', _aboutUsController, maxLines: 10),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can use plain text or basic HTML. Changes are reflected instantly on the user website after saving.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Social Media Links', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Configure your platform\'s social media presence.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.share_outlined, color: Colors.blue, size: 24),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField('Facebook URL', _fbController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Instagram URL', _instaController)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField('Twitter (X) URL', _twitterController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('YouTube URL', _ytController)),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField('LinkedIn URL', _linkedinController),
        ],
      ),
    );
  }

  Widget _buildTrendingSectionSettingsCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trending Section & Service Cards',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage categories and service card features displayed on the homepage.',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.trending_up, color: Color(0xFF8B5CF6), size: 24),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            'Trending Categories (Comma Separated)',
            _trendingCategoriesController,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Service Cards (Home Page Header)',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          
          // Card 1
          Text('Service Card 1', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTextField('Title', _card1TitleController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Subtitle', _card1SubtitleController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Icon URL', _card1IconController)),
            ],
          ),
          const SizedBox(height: 20),

          // Card 2
          Text('Service Card 2', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTextField('Title', _card2TitleController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Subtitle', _card2SubtitleController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Icon URL', _card2IconController)),
            ],
          ),
          const SizedBox(height: 20),

          // Card 3
          Text('Service Card 3', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTextField('Title', _card3TitleController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Subtitle', _card3SubtitleController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Icon URL', _card3IconController)),
            ],
          ),
          const SizedBox(height: 20),

          // Card 4
          Text('Service Card 4', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTextField('Title', _card4TitleController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Subtitle', _card4SubtitleController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Icon URL', _card4IconController)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecureConfigCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Secure Configuration', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Manage sensitive keys for Payment Gateway, Delivery, and Email.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.security_outlined, color: Colors.red, size: 24),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField('Payment Gateway Key', _paymentKeyController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Payment Gateway Salt', _paymentSaltController)),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField('Delhivery Token', _delhiveryTokenController),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField('SMTP Email User', _emailUserController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('SMTP Email Pass', _emailPassController)),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField('WhatsApp Token', _whatsappTokenController),
          const SizedBox(height: 20),
          _buildTextField('Gemini API Key', _geminiKeyController),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Preview', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const Icon(Icons.visibility_outlined, color: Color(0xFF8B5CF6), size: 20),
            ],
          ),
          const SizedBox(height: 24),
          // Browser Window Mockup
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar mockup
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Text('/homepage', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                ),
                // Main content mockup
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        _nameController.text,
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _taglineController.text,
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        _footerController.text,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildTextField(String label, TextEditingController? controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
            ),
          ),
          onChanged: (v) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildUploadBox(String title, String subtitle, {required double height, String? imageUrl, bool isUploading = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (imageUrl != null && imageUrl.isNotEmpty && !isUploading)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.red)),
                  ),
                ),
              )
            else if (isUploading)
              const Center(child: CircularProgressIndicator())
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_outlined, color: Colors.grey.shade400, size: 24),
                    const SizedBox(height: 8),
                    Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
