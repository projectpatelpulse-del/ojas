import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/widgets/shell_screen.dart';
import 'package:ojas_user/core/utils/responsive.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';
import '../widgets/forgot_password_form.dart';

class AuthScreen extends StatefulWidget {
  final bool isInitialLogin;
  const AuthScreen({super.key, required this.isInitialLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum AuthMode { login, register, forgotPassword }

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _authMode;

  @override
  void initState() {
    super.initState();
    _authMode = widget.isInitialLogin ? AuthMode.login : AuthMode.register;
  }

  void _toggleAuth() {
    setState(() {
      if (_authMode == AuthMode.login) {
        _authMode = AuthMode.register;
      } else {
        _authMode = AuthMode.login;
      }
    });
  }

  void _showForgotPassword() {
    setState(() {
      _authMode = AuthMode.forgotPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return ShellScreen(
      child: Container(
        color: const Color(0xFFFEF6F9),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Logo Area
                _buildLogo(),
                const SizedBox(height: 24),

                // Card Container
                Container(
                  width: isMobile ? double.infinity : 480,
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentForm(),
                  ),
                ),
                
                const SizedBox(height: 40),
                Text(
                  'By creating an account, you agree to our terms and conditions',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentForm() {
    switch (_authMode) {
      case AuthMode.login:
        return LoginForm(
          key: const ValueKey('login'),
          onToggle: _toggleAuth,
          onForgotPassword: _showForgotPassword,
        );
      case AuthMode.register:
        return RegisterForm(
          key: const ValueKey('register'),
          onToggle: _toggleAuth,
        );
      case AuthMode.forgotPassword:
        return ForgotPasswordForm(
          key: const ValueKey('forgot_password'),
          onBackToLogin: () {
            setState(() {
              _authMode = AuthMode.login;
            });
          },
        );
    }
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              'O',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ojas',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              'SHOP SMART',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
