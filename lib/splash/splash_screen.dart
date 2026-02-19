import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return; // ✅ SAFETY FIX

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ keeps content centered tightly
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/urbanserve_logo.png',
              height: 120,
            ),

            const SizedBox(height: 16),

            const Text(
              'UrbanServe',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 6),

            // ✨ TAGLINE (kept as-is)
            Text(
              'Smart Local Services',
              style: TextStyle(
                color: AppColors.neutral,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
