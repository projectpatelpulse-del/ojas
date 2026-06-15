import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ojas_user/core/widgets/shell_screen.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:ojas_user/features/auth/domain/models/user_model.dart';
import 'package:ojas_user/features/auth/data/services/profile_service.dart';
import 'package:ojas_user/core/utils/responsive.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel? _initialUser;
  const ProfileScreen({super.key, UserModel? user}) : _initialUser = user;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionService.instance,
      builder: (context, _) {
        final user = SessionService.instance.currentUser ?? _initialUser;
        if (user == null) return const SizedBox();

        final bool isMobile = Responsive.isMobile(context);

        return ShellScreen(
          activeTitle: 'PROFILE',
          child: Container(
            color: const Color(0xFFF8FAFC),
            padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 40, horizontal: isMobile ? 12 : 24),
            child: Center(
              child: SizedBox(
                width: isMobile ? double.infinity : 1000,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 32),
                      if (isMobile)
                        Column(
                          children: [
                            _buildProfileCard(context, user),
                            const SizedBox(height: 24),
                            _buildPersonalInfoCard(isMobile, user),
                            const SizedBox(height: 24),
                            _buildAccountInfoCard(isMobile),
                            const SizedBox(height: 24),
                            _buildQuickActionsCard(context, isMobile),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 280, child: _buildProfileCard(context, user)),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildPersonalInfoCard(isMobile, user),
                                  const SizedBox(height: 24),
                                  _buildAccountInfoCard(isMobile),
                                  const SizedBox(height: 24),
                                  _buildQuickActionsCard(context, isMobile),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pushReplacementNamed('/'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text('Back', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'My Profile',
          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your account information and preferences',
          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: user.photo != null ? NetworkImage(user.photo!) : null,
            child: user.photo == null ? const Icon(Icons.person, size: 50, color: Color(0xFF94A3B8)) : null,
          ),
          const SizedBox(height: 20),
          Text(
            user.name,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user.role == 'reseller' ? 'RESELLER' : user.role.toUpperCase(), 
            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14)
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _showEditProfileDialog(context, user),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () async {
                await SessionService.instance.logout();
                Navigator.of(context).pushReplacementNamed('/');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(color: const Color(0xFFE11D48), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(bool isMobile, UserModel user) {
    final nameField = _buildInfoField('Full Name', Icons.person_outline, user.name);
    final emailField = _buildInfoField('Email Address', Icons.mail_outline, user.email);
    final phoneField = _buildInfoField('Phone Number', Icons.phone_outlined, user.mobile);
    final accountTypeField = _buildInfoField('Account Type', Icons.shield_outlined, user.role == 'reseller' ? 'RESELLER' : user.role.toUpperCase());

    return _buildSectionCard(
      title: 'Personal Information',
      isMobile: isMobile,
      child: isMobile 
        ? Column(children: [nameField, const SizedBox(height: 16), emailField, const SizedBox(height: 16), phoneField, const SizedBox(height: 16), accountTypeField])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [nameField, const SizedBox(height: 20), emailField])),
              const SizedBox(width: 24),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [phoneField, const SizedBox(height: 20), accountTypeField])),
            ],
          ),
    );
  }

  Widget _buildAccountInfoCard(bool isMobile) {
    final memberSinceField = _buildInfoField('Member Since', Icons.calendar_today_outlined, 'November 8, 2025');
    final accountStatusField = _buildInfoField('Account Status', Icons.shield_outlined, 'Unverified', valueColor: const Color(0xFFD97706));

    return _buildSectionCard(
      title: 'Account Information',
      isMobile: isMobile,
      child: isMobile 
        ? Column(children: [memberSinceField, const SizedBox(height: 16), accountStatusField])
        : Row(children: [Expanded(child: memberSinceField), const SizedBox(width: 24), Expanded(child: accountStatusField)]),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, bool isMobile) {
    final ordersAction = _buildQuickActionItem(
      icon: Icons.receipt_long_outlined,
      iconBgColor: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF3B82F6),
      title: 'My Orders',
      subtitle: 'View order history',
      onTap: () => Navigator.of(context).pushNamed('/orders'),
    );
    final wishlistAction = _buildQuickActionItem(
      icon: Icons.favorite_border_outlined,
      iconBgColor: const Color(0xFFFCE7F3),
      iconColor: const Color(0xFFEC4899),
      title: 'Wishlist',
      subtitle: 'Saved items',
      onTap: () {},
    );

    return _buildSectionCard(
      title: 'Quick Actions',
      isMobile: isMobile,
      child: isMobile 
        ? Column(children: [ordersAction, const SizedBox(height: 16), wishlistAction])
        : Row(children: [Expanded(child: ordersAction), const SizedBox(width: 24), Expanded(child: wishlistAction)]),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, IconData icon, String value, {Color valueColor = const Color(0xFF1E293B)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 12),
              Expanded(child: Text(value, style: GoogleFonts.inter(color: valueColor, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserModel user) {
    showDialog(context: context, builder: (context) => _EditProfileDialog(user: user));
  }
}

class _EditProfileDialog extends StatefulWidget {
  final UserModel user;
  const _EditProfileDialog({required this.user});
  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _mobileController;
  String _gender = 'male';
  XFile? _selectedImage;
  Uint8List? _webImageBytes;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _mobileController = TextEditingController(text: widget.user.mobile);
    _gender = widget.user.gender.isEmpty ? 'male' : widget.user.gender.toLowerCase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = pickedFile;
          _webImageBytes = bytes;
        });
      } else {
        setState(() => _selectedImage = pickedFile);
      }
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);
    final updated = await ProfileService().updateProfile(
      name: _nameController.text, bio: _bioController.text, mobile: _mobileController.text, gender: _gender, photo: _selectedImage,
    );
    if (mounted) {
      setState(() => _isUpdating = false);
      if (updated != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Profile', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: _selectedImage != null 
                          ? (kIsWeb && _webImageBytes != null 
                              ? MemoryImage(_webImageBytes!) 
                              : FileImage(File(_selectedImage!.path))) as ImageProvider
                          : (widget.user.photo != null ? NetworkImage(widget.user.photo!) : null) as ImageProvider?,
                        child: _selectedImage == null && widget.user.photo == null ? const Icon(Icons.person, size: 50, color: Color(0xFF94A3B8)) : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFE91E63), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildField('Full Name', _nameController),
                const SizedBox(height: 16),
                _buildField('Bio', _bioController),
                const SizedBox(height: 16),
                _buildField('Mobile', _mobileController),
                const SizedBox(height: 16),
                Text('Gender', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                const SizedBox(height: 8),
                Row(children: [_buildGenderRadio('male'), const SizedBox(width: 16), _buildGenderRadio('female')]),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _isUpdating ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white60)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(color: const Color(0xFF0F172A)),
          decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildGenderRadio(String value) {
    return InkWell(
      onTap: () => setState(() => _gender = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(value: value, groupValue: _gender, onChanged: (v) => setState(() => _gender = v!), activeColor: const Color(0xFFE91E63)),
          Text(value[0].toUpperCase() + value.substring(1), style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }
}
