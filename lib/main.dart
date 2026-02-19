import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:service_provider_booking/screens/providerHome.dart';
import 'core/theme/app_colors.dart';
import 'splash/splash_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'screens/role_selection/role_selection_screen.dart';
import 'auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';

/// ⚡️ INITIALIZATION
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print("🔥 Firebase Connected Successfully");

  User? user = FirebaseAuth.instance.currentUser;

  runApp(const UrbanServeApp());

  try {
    await Firebase.initializeApp();
    print("🔥 Firebase Connected Successfully");
  } catch (e) {
    print("❌ Firebase Connection Failed: $e");
  }

  home: StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (snapshot.hasData) {
        return const HomeScreen();
      }

      return const LoginScreen();
    },
  );

  StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }

      if (snapshot.hasData) {
        return const HomeScreen();
      }

      return const LoginScreen();
    },
  );

}




class UrbanServeApp extends StatelessWidget {
  const UrbanServeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UrbanServe',

      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.darkBg,
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),

      home: FirebaseAuth.instance.currentUser != null
          ? const HomeScreen()
          : const SplashScreen(),


      routes: {
       // '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/providerHome': (context) => const ProviderHomeScreen(), // ✅ ADD THIS

      },
    );
  }
}
