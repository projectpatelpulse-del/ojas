import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ojas_user/core/constants/app_colors.dart';
import 'package:ojas_user/features/auth/domain/models/user_model.dart';

class WelcomeScreen extends StatefulWidget {
  final UserModel user;
  const WelcomeScreen({super.key, required this.user});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    
    // Auto-redirect to Homepage after a few seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkNavbarGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Welcome to Ojas,',
                        style: GoogleFonts.spectral(
                          color: AppColors.white54,
                          fontSize: 24,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.user.name.toUpperCase(),
                        style: GoogleFonts.spectral(
                          color: AppColors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(color: Colors.pinkAccent.withOpacity(0.5), blurRadius: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 2,
                        width: 100,
                        color: Colors.pinkAccent,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your account is ready! Explore our curated collections.',
                        style: GoogleFonts.poppins(
                          color: AppColors.white70,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 36),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                        label: const Text(
                          'CONTINUE SHOPPING',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                          shadowColor: Colors.pinkAccent.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/profile', arguments: widget.user);
                        },
                        child: Text(
                          'Go to My Profile',
                          style: GoogleFonts.inter(
                            color: AppColors.white54,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
