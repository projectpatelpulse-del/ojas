import 'package:ojas_user/core/constants/app_colors.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ojas_user/features/auth/application/auth_service.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onToggle;
  const RegisterForm({super.key, required this.onToggle});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.pushNamed(context, '/terms');
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.pushNamed(context, '/privacy');
      };
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  final AuthService _authService = AuthService();

  Future<void> _handleRegister() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and privacy policy.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final response = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        gender: "other", // Dummy default value to satisfy API if needed
        mobile: _mobileController.text.trim(),
        role: "user",
        image: _image,
      );
      // setState(() => _isLoading = false);
      if (response.success) {
        final loginResponse = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (loginResponse.success) {
          if (mounted) {
            SessionService.instance.setUser(loginResponse.user, token: loginResponse.token);
            await CartController.instance.loadCart();
            await CartController.instance.processPendingCart();
            Navigator.of(context).pushReplacementNamed('/welcome', arguments: loginResponse.user);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registered successfully! Auto-login failed: ${loginResponse.message}')),
            );
            widget.onToggle();
          }
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message), backgroundColor: AppColors.errorRed),
          );
        }
      }
    }
  }

  ImageProvider _getImageProvider() {
    if (kIsWeb) {
      return NetworkImage(_image!.path);
    } else {
      return FileImage(File(_image!.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Create Account',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Join us and start your shopping journey',
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: _pickImage,
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      image: _image != null
                          ? DecorationImage(
                              image: _getImageProvider(),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _image == null
                        ? const Center(
                            child: Icon(Icons.person_outline, size: 40, color: Color(0xFF94A3B8)),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.accentOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: AppColors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fields
          _buildFieldLabel('Full Name'),
          _buildTextField(
            controller: _nameController,
            hintText: 'Enter your full name',
            icon: Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          _buildFieldLabel('Email Address'),
          _buildTextField(
            controller: _emailController,
            hintText: 'Email... (e.g. demo@example.com)',
            icon: Icons.mail_outline,
            isFocusedFill: true, // as per the image
            validator: (v) => v!.isEmpty || !v.contains('@') ? 'Invalid email' : null,
          ),
          const SizedBox(height: 12),

          _buildFieldLabel('Mobile Number *'),
          _buildTextField(
            controller: _mobileController,
            hintText: 'Enter 10-digit mobile number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Mobile number is required';
              if (v.trim().length != 10) return 'Enter a valid 10-digit mobile number';
              if (!RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) return 'Only digits allowed';
              return null;
            },
          ),
          const SizedBox(height: 12),

          _buildFieldLabel('Password'),
          _buildTextField(
            controller: _passwordController,
            hintText: '*********',
            icon: Icons.lock_outline,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF94A3B8), size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            isFocusedFill: true,
            validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Password must contain uppercase, lowercase, and number',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
              ),
            ),
          ),

          _buildFieldLabel('Confirm Password'),
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm your password',
            icon: Icons.lock_outline,
            obscure: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF94A3B8), size: 18),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 20),

          // Checkbox Terms
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: const BorderSide(color: Color(0xFF94A3B8)),
                  activeColor: AppColors.accentOrange,
                  onChanged: (v) => setState(() => _agreedToTerms = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: 'I agree to the ',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: GoogleFonts.inter(color: AppColors.accentOrange, fontWeight: FontWeight.w600),
                        recognizer: _termsRecognizer,
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: GoogleFonts.inter(color: AppColors.accentOrange, fontWeight: FontWeight.w600),
                        recognizer: _privacyRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Create Account', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Sign In Link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Already have an account? ', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14)),
              InkWell(
                onTap: widget.onToggle,
                child: Text('Sign In', style: GoogleFonts.inter(color: AppColors.accentOrange, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF334155)),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    bool isFocusedFill = false,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
      maxLength: maxLength,
      // Hide the default counter that appears with maxLength
      buildCounter: maxLength != null
          ? (context, {required currentLength, required isFocused, maxLength}) => null
          : null,
      style: GoogleFonts.inter(color: const Color(0xFF334155), fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        suffixIcon: suffixIcon,
        filled: isFocusedFill,
        fillColor: const Color(0xFFEEF2F6), // Match light blueish focus background seen in image
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isFocusedFill ? AppColors.transparent : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentOrange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
