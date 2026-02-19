import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/session_manager.dart';
import '../../auth/login_screen.dart';

enum UserRole { user, provider }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? selectedRole;

  Future<void> handleGetStarted() async {
    if (selectedRole == null) return;

    // Save role
    await SessionManager.saveRole(selectedRole!.name);

    // Navigate to Login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 40),

              /// 🟣 LOGO
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/urbanserve_logo.png',
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// 🟣 TITLE
              const Text(
                "Choose your role below",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 50),

              /// 👤 USER CARD
              roleCard(
                role: UserRole.user,
                title: "User",
                subtitle: "Book trusted local services",
                icon: Icons.handshake_outlined,
              ),

              const SizedBox(height: 22),

              /// OR
              Text(
                "or",
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 22),

              /// 🧰 PROVIDER CARD
              roleCard(
                role: UserRole.provider,
                title: "Service Provider",
                subtitle: "Offer services & earn money",
                icon: Icons.build_circle_outlined,
              ),

              const Spacer(),

              /// 🚀 GET STARTED BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedRole == null ? null : handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.4),
                    elevation: 10,
                    shadowColor:
                    AppColors.primaryDark.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Get started",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎴 ROLE CARD
  Widget roleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() => selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.darkBg
              : AppColors.darkBg.withOpacity(0.92),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.selectionGlow
                  : AppColors.cardShadow,
              blurRadius: isSelected ? 26 : 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [

            /// ICON CIRCLE
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: AppColors.lightBg.withOpacity(0.95),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.darkBg,
                size: 30,
              ),
            ),

            const SizedBox(width: 18),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),

            /// CHECK ICON
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.accent,
                size: 26,
              ),
          ],
        ),
      ),
    );
  }
}
