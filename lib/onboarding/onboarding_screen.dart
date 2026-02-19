import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int index = 0;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: "Find Local Services",
      subtitle: "Electricians, plumbers & more near you",
      icon: Icons.location_city,
    ),
    OnboardingPage(
      title: "Book Instantly",
      subtitle: "Choose service & time in minutes",
      icon: Icons.calendar_month,
    ),
    OnboardingPage(
      title: "Trusted Professionals",
      subtitle: "Verified providers with ratings",
      icon: Icons.verified,
    ),
  ];

  /// 🔹 Rounded Image / Icon Card (USED IN ALL 3 SCREENS)
  Widget onboardingImageCard(IconData icon) {
    return Container(
      height: 220,
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(28), // ✅ Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 110,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// ⏭️ Skip → Role Selection
  void skipOnboarding() {
    Navigator.pushReplacementNamed(context, '/role-selection');
  }

  /// ➡️ Next / Finish
  void nextPage() {
    if (index < pages.length - 1) {
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/role-selection');
    }
  }

  /// 🔵⚪ Page Indicator
  Widget buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pages.length,
            (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: index == i ? 22 : 8,
          decoration: BoxDecoration(
            color: index == i
                ? AppColors.accent
                : AppColors.textSecondary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔹 PAGE CONTENT
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: pages.length,
                onPageChanged: (i) {
                  setState(() => index = i);
                },
                itemBuilder: (_, i) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      onboardingImageCard(pages[i].icon), // ✅ UPDATED

                      const SizedBox(height: 40),

                      Text(
                        pages[i].title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          pages[i].subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            /// 🔵⚪ DOT INDICATORS
            const SizedBox(height: 12),
            buildPageIndicator(),
            const SizedBox(height: 14),

            /// 🔹 BOTTOM CONTROLS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// ⏭️ SKIP
                  GestureDetector(
                    onTap: skipOnboarding,
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  /// ➡️ NEXT BUTTON
                  GestureDetector(
                    onTap: nextPage,
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppColors.lightBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
