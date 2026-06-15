import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/ojas_layout.dart';
import 'package:ojas_user/core/widgets/centered_content.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/features/auth/application/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;

import '../../../auth/domain/models/user_model.dart';

class BecomeResellerPage extends StatefulWidget {
  const BecomeResellerPage({super.key});

  @override
  State<BecomeResellerPage> createState() => _BecomeResellerPageState();
}

class _BecomeResellerPageState extends State<BecomeResellerPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _agreedToTerms = false;

  // Toggle mode between login and application signup
  bool _isLogin = true;

  // Login controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final bool _obscureLoginPassword = true;

  // Registration Controllers (For unexisting/logged-out users)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Reseller Application Controllers
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _upiIdController.dispose();
    _panController.dispose();
    _gstController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loginReseller() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _loginEmailController.text.trim(),
          'password': _loginPasswordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Successful login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful! Redirecting to Reseller Panel...'),
          ),
        );

        final token = data['token'];
        final userMap = data['user'];
        if (userMap != null) {
          final user = UserModel.fromJson(userMap);
          SessionService.instance.setUser(user, token: token);
        }

        final resellerPanelUrl = 'http://localhost:23080/#/?token=$token';
        Future.delayed(const Duration(seconds: 1), () {
          html.window.location.href = resellerPanelUrl;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions to proceed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Register the new user
      final authService = AuthService();
      final regResult = await authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        gender: "other",
        mobile: _mobileController.text.trim(),
      );

      if (!regResult.success) {
        throw Exception(regResult.message);
      }

      // Step 2: Log in the user to obtain session and token
      final loginResult = await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!loginResult.success || loginResult.token == null) {
        throw Exception(loginResult.message);
      }

      final token = loginResult.token;
      SessionService.instance.setUser(loginResult.user, token: token);

      // Step 3: Apply for reseller status with the active session token
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/reseller/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bankDetails': {
            'bankName': _bankNameController.text.trim(),
            'accountNumber': _accountNumberController.text.trim(),
            'ifsc': _ifscController.text.trim().toUpperCase(),
            'accountHolderName': _accountHolderController.text.trim(),
          },
          'upiDetails': {
            'upiId': _upiIdController.text.trim(),
          },
          'panNumber': _panController.text.trim().toUpperCase(),
          'gstNumber': _gstController.text.trim().toUpperCase(),
        }),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw FormatException('Server returned an invalid response (not JSON). Please make sure your local backend server is running. Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Application Submitted'),
            content: const Text(
              'Your reseller registration has been received successfully! Our admin team will verify and approve your account shortly.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to submit reseller application'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleMode(bool login) {
    setState(() {
      _isLogin = login;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return OjasLayout(
      activeTitle: 'BECOME RESELLER',
      child: Container(
        color: const Color(0xFFF8FAFC),
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 80),
        child: CenteredContent(
          horizontalPadding: isMobile ? 16 : 40,
          child: Column(
            children: [
              if (!_isLogin)
                Text(
                  'Become a Reseller',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 32 : 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              if (!_isLogin) const SizedBox(height: 12),
              Text(
                _isLogin
                    ? 'Access your reseller dashboard to manage your products, referrals, and earnings.'
                    : 'Promote high-quality products and earn direct commissions on every purchase.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 15 : 18,
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleMode(false),
                      child: _ToggleButton(
                        title: 'Become a Reseller',
                        isActive: !_isLogin,
                        fullWidth: isMobile,
                      ),
                    ),
                    if (isMobile) const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _toggleMode(true),
                      child: _ToggleButton(
                        title: 'Login',
                        isActive: _isLogin,
                        fullWidth: isMobile,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLogin
                    ? _buildLoginForm(isMobile)
                    : _buildApplicationForm(isMobile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 500,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: isMobile ? 32 : 40,
            backgroundColor: const Color(0xFFEEF2F6),
            child: Icon(
              Icons.person_outline,
              size: isMobile ? 28 : 36,
              color: AppColors.primaryIndigo,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Reseller Login',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextFormField(
            controller: _loginEmailController,
            label: 'Email Address *',
            hint: 'demo@example.com',
            validator: (v) => v == null || v.isEmpty ? 'Please enter email' : null,
          ),
          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _loginPasswordController,
            label: 'Password *',
            hint: '••••••••',
            obscureText: _obscureLoginPassword,
            validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _loginReseller,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Sign In',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => _toggleMode(false),
            child: Text(
              'New here? Become a Reseller',
              style: GoogleFonts.inter(
                color: AppColors.primaryIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationForm(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 650,
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Create Account',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.bgPrimaryDark),
            ),
            const SizedBox(height: 24),
            _buildTextFormField(
              controller: _nameController,
              label: 'Full Name *',
              hint: 'Enter your full name',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your name';
                if (v.trim().length < 3) return 'Name must be at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _emailController,
              label: 'Email Address *',
              hint: 'you@example.com',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _mobileController,
              label: 'Mobile Number *',
              hint: '10-digit number',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter mobile number';
                if (v.length != 10) {
                  return 'Please enter exactly 10 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _passwordController,
              label: 'Password *',
              hint: 'Choose a strong password',
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter password';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              '2. Bank Details & UPI',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.bgPrimaryDark),
            ),
            const SizedBox(height: 24),
            _buildTextFormField(
              controller: _accountHolderController,
              label: 'Account Holder Name *',
              hint: 'Name as in bank records',
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter account holder name' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _bankNameController,
              label: 'Bank Name *',
              hint: 'e.g. HDFC Bank, SBI',
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter bank name' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _accountNumberController,
              label: 'Account Number *',
              hint: 'Enter account number',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(18),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter account number';
                if (v.length < 9 || v.length > 18) {
                  return 'Please enter a valid account number (9 to 18 digits)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _ifscController,
              label: 'IFSC Code *',
              hint: 'e.g. HDFC0001234',
              inputFormatters: [
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter IFSC code';
                if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v.toUpperCase())) {
                  return 'Please enter a valid 11-character IFSC code';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _upiIdController,
              label: 'UPI ID *',
              hint: 'e.g. name@upi',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter UPI ID';
                if (!v.contains('@')) {
                  return 'Please enter a valid UPI ID (e.g. name@upi)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              '3. Tax Information (Optional)',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.bgPrimaryDark),
            ),
            const SizedBox(height: 24),
            _buildTextFormField(
              controller: _panController,
              label: 'PAN Number',
              hint: 'ABCDE1234F',
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(v.toUpperCase())) {
                    return 'Please enter a valid 10-character PAN number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _gstController,
              label: 'GST Number',
              hint: '22AAAAA0000A1Z5',
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(v.toUpperCase())) {
                    return 'Please enter a valid 15-character GST number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  activeColor: AppColors.primaryIndigo,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'I accept the Reseller Agreement Terms & Conditions and authorize Ojas India to process commission payouts to the provided account details.',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryIndigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Apply as Reseller',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryIndigo, width: 2)),
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool fullWidth;
  const _ToggleButton({
    required this.title,
    required this.isActive,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : 200,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryIndigo : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

