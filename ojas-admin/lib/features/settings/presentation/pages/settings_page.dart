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
  final TextEditingController _geminiKeyController = TextEditingController();
  
  bool _enableAnnouncement = false;
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
        _geminiKeyController.text = data['geminiApiKey'] ?? '';
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
        'geminiApiKey': _geminiKeyController.text,
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
                                    _buildContactInfoCard(),
                                    const SizedBox(height: 24),
                                    _buildLegalPagesCard(),
                                    const SizedBox(height: 24),
                                    _buildSocialMediaCard(),
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
          _buildTextField('Address', _contactAddressController),
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
