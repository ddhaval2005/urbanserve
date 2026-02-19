import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/services/session_manager.dart';
import '../screens/home_screen.dart';
import '../screens/role_selection/role_selection_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? storedRole;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool rememberMe = false;
  bool isLoginSelected = true;
  bool isPressed = false;
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+\-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"
    );
    return emailRegex.hasMatch(email);
  }
  final _formKey = GlobalKey<FormState>();
  final FocusNode nameFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  String selectedRole = "user"; // default role

/// ℹ️ SHOW MESSAGE
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  /// 🔐 HANDLE REGISTER
  Future<void> _handleRegister() async {



    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      _showMessage("Please fill all fields", Colors.red);
      return;
    }

    if (!_isValidEmail(emailController.text.trim())) {
      _showMessage("Invalid email format", Colors.orange);
      return;
    }

    if (passwordController.text.length < 6) {
      _showMessage("Password must be at least 6 characters", Colors.orange);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showMessage("Passwords do not match", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {

        String role = storedRole ?? "user";

// 1️⃣ Store in users collection (common data)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': nameController.text.trim(),
          'email': user.email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

// 2️⃣ If provider → create provider document also
        if (role == "provider") {
          await FirebaseFirestore.instance.collection('providers').doc(user.uid).set({
            'uid': user.uid,
            'name': nameController.text.trim(),
            'email': user.email,
            // 'isApproved': false,   // Admin approval later
            'createdAt': FieldValue.serverTimestamp(),
          });
        }



        _showMessage("Registration successful. login plz :) .", Colors.green);

        await FirebaseAuth.instance.signOut();

        setState(() {
          isLoginSelected = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = "Registration Failed";
      print("Register Error Code: ${e.code}");
      print("Register Error Message: ${e.message}");
      if (e.code == 'email-already-in-use') {
        message = "Email already registered";
      } else if (e.code == 'weak-password') {
        message = "Weak password";
      }

      _showMessage(message, Colors.red);
    }

    setState(() => isLoading = false);

    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();

  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', (route) => false);
  }




  /// 🔐 HANDLE EMAIL LOGIN
  Future<void> _handleEmailLogin() async {
    setState(() => isLoading = true);

    try {
      final userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user == null) {
        _showMessage("Authentication failed.", Colors.red);
        setState(() => isLoading = false);
        return;
      }

      // 🔹 Get user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showMessage("User data not found.", Colors.red);
        setState(() => isLoading = false);
        return;
      }

      final userData = userDoc.data();
      String role = userData?['role'] ?? "user";

      // 🔹 Update last login
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // 💾 Remember Me
      if (rememberMe) {
        await SessionManager.setLogin(true);
      }

      // 🚀 ROLE BASED NAVIGATION
      if (role == "provider") {

        // 🔎 Check if provider document exists
        final providerDoc = await FirebaseFirestore.instance
            .collection('providers')
            .doc(user.uid)
            .get();

        if (!providerDoc.exists) {
          _showMessage("Provider profile not found.", Colors.red);
          setState(() => isLoading = false);
          return;
        }

        Navigator.pushNamedAndRemoveUntil(
            context, '/providerHome', (route) => false);

      } else {

        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (route) => false);
      }

    } on FirebaseAuthException catch (e) {

      String message = "Login failed";

      switch (e.code) {
        case 'user-not-found':
          message = "No user found with this email.";
          break;
        case 'wrong-password':
          message = "Incorrect password.";
          break;
        case 'invalid-email':
          message = "Invalid email format.";
          break;
        case 'user-disabled':
          message = "User account is disabled.";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Try again later.";
          break;
      }

      _showMessage(message, Colors.red);

    } catch (e) {
      print("Login Error: $e");
      _showMessage("Unexpected error occurred.", Colors.red);
    }

    setState(() => isLoading = false);
  }




  @override
  void initState() {
    super.initState();
    emailFocus.addListener(() => setState(() {}));
    passwordFocus.addListener(() => setState(() {}));
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await SessionManager.getRole();
    setState(() {
      storedRole = role;
    });
  }

  @override
  void dispose() {
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
    nameFocus.dispose();
    confirmPasswordFocus.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser =
      await GoogleSignIn().signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance
          .signInWithCredential(credential);






      if (userCredential.user != null) {
        print("✅ Google Login Success");

        final user = userCredential.user!;

        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        final doc = await userRef.get();

        // 🔹 If user document does not exist → create it
        if (!doc.exists) {
          await userRef.set({
            'uid': user.uid,
            'email': user.email,
            'permissions': storedRole == "provider"
                ? ["user", "provider"]
                : ["user"],
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 🔹 If user exists & selected role is provider → upgrade permission
          if (storedRole == "provider") {
            await userRef.update({
              'permissions': FieldValue.arrayUnion(["provider"]),
            });
          }
        }

        // 🔹 Fetch updated user data
        final updatedDoc = await userRef.get();
        final data = updatedDoc.data();

        List permissions = data?['permissions'] ?? [];

        // 🚀 Permission-based navigation
        if (permissions.contains("provider")) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/providerHome', (r) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, '/home', (r) => false);
        }
      }






    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      if (e.toString().contains("network")) {
        _showMessage("No internet connection", Colors.red);
      } else {
        _showMessage("Something went wrong", Colors.red);
      }
    }
  }

/// 🎯 BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              Color(0xFF6F6AF8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              /// 🔷 HEADER
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// ✅ WORKING BACK BUTTON
                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RoleSelectionScreen(),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Go ahead and set up\nyour account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Sign in to enjoy the best managing experience",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),


              /// ⚪ CARD
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, -6),
                      )
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [

                        /// 🔄 TOGGLE
                        _buildToggle(),

                        const SizedBox(height: 35),

                        if (isLoginSelected) ...[

                          /// 🔐 LOGIN MODE

                          _buildInputField(
                            hint: "E-mail ID",
                            icon: Icons.email_outlined,
                            focusNode: emailFocus,
                            controller: emailController,
                          ),

                          const SizedBox(height: 20),

                          _buildInputField(
                            hint: "Password",
                            icon: Icons.lock_outline,
                            focusNode: passwordFocus,
                            isPassword: true,
                            controller: passwordController,
                          ),

                          const SizedBox(height: 15),

                          /// Remember + Forgot
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                activeColor: AppColors.primary,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.grey.shade600,
                                  width: 1.4,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    rememberMe = value!;
                                  });
                                },
                              ),
                              const Text(
                                "Remember me",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () async {
                                  if (emailController.text.trim().isEmpty) {
                                    _showMessage("Enter email to reset password", Colors.orange);
                                    return;
                                  }

                                  await FirebaseAuth.instance.sendPasswordResetEmail(
                                    email: emailController.text.trim(),
                                  );

                                  _showMessage("Password reset email sent", Colors.green);
                                },
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          _buildAnimatedButton(),

                        ] else ...[

                          /// 📝 REGISTER MODE

                          _buildInputField(
                            hint: "Full Name",
                            icon: Icons.person_outline,
                            focusNode: nameFocus,
                            controller: nameController,
                          ),

                          const SizedBox(height: 20),

                          _buildInputField(
                            hint: "E-mail ID",
                            icon: Icons.email_outlined,
                            focusNode: emailFocus,
                            controller: emailController,
                          ),

                          const SizedBox(height: 20),

                          _buildInputField(
                            hint: "Password",
                            icon: Icons.lock_outline,
                            focusNode: passwordFocus,
                            isPassword: true,
                            controller: passwordController,
                          ),

                          const SizedBox(height: 20),

                          _buildInputField(
                            hint: "Confirm Password",
                            icon: Icons.lock_outline,
                            focusNode: confirmPasswordFocus,
                            isPassword: true,
                            controller: confirmPasswordController,
                          ),

                          const SizedBox(height: 20),

                          /// Role Selection
                          // Row(
                          //   children: [
                          //
                          //     /// USER BUTTON
                          //     Expanded(
                          //       child: GestureDetector(
                          //         onTap: () {
                          //           setState(() {
                          //             selectedRole = "user";
                          //           });
                          //         },
                          //         child: AnimatedContainer(
                          //           duration: const Duration(milliseconds: 200),
                          //           padding: const EdgeInsets.symmetric(vertical: 14),
                          //           decoration: BoxDecoration(
                          //             color: selectedRole == "user"
                          //                 ? AppColors.primary
                          //                 : Colors.grey.shade200,
                          //             borderRadius: BorderRadius.circular(14),
                          //             border: Border.all(
                          //               color: selectedRole == "user"
                          //                   ? AppColors.primary
                          //                   : Colors.grey.shade400,
                          //               width: 1.5,
                          //             ),
                          //           ),
                          //           child: Center(
                          //             child: Text(
                          //               "User",
                          //               style: TextStyle(
                          //                 fontWeight: FontWeight.w600,
                          //                 color: selectedRole == "user"
                          //                     ? Colors.white
                          //                     : Colors.black87,
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //
                          //     const SizedBox(width: 15),
                          //
                          //     /// PROVIDER BUTTON
                          //     Expanded(
                          //       child: GestureDetector(
                          //         onTap: () {
                          //           setState(() {
                          //             selectedRole = "provider";
                          //           });
                          //         },
                          //         child: AnimatedContainer(
                          //           duration: const Duration(milliseconds: 200),
                          //           padding: const EdgeInsets.symmetric(vertical: 14),
                          //           decoration: BoxDecoration(
                          //             color: selectedRole == "provider"
                          //                 ? AppColors.primary
                          //                 : Colors.grey.shade200,
                          //             borderRadius: BorderRadius.circular(14),
                          //             border: Border.all(
                          //               color: selectedRole == "provider"
                          //                   ? AppColors.primary
                          //                   : Colors.grey.shade400,
                          //               width: 1.5,
                          //             ),
                          //           ),
                          //           child: Center(
                          //             child: Text(
                          //               "Provider",
                          //               style: TextStyle(
                          //                 fontWeight: FontWeight.w600,
                          //                 color: selectedRole == "provider"
                          //                     ? Colors.white
                          //                     : Colors.black87,
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
//////hello

                          const SizedBox(height: 28),

                          GestureDetector(
                            onTap: _handleRegister,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              height: 58,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    Color(0xFF6F6AF8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 35),

                        /// Social Login
                        if (isLoginSelected) ...[

                          const SizedBox(height: 35),

                          const Text(
                            "Or login with",
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: _handleGoogleSignIn,
                                child: _socialButton(Icons.g_mobiledata, "Google"),
                              ),
                              _socialButton(Icons.apple, "Apple"),
                            ],
                          ),
                        ]
                      ],
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

  /// 🔄 TOGGLE
  Widget _buildToggle() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEF3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: isLoginSelected
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width / 2 - 36,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => isLoginSelected = true),
                  child: Center(
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isLoginSelected
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => isLoginSelected = false),
                  child: Center(
                    child: Text(
                      "Register",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: !isLoginSelected
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✨ INPUT FIELD
  Widget _buildInputField({
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    required TextEditingController controller,
    bool isPassword = false,
  })
  {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: focusNode.hasFocus
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ]
            : [],
      ),
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        obscureText: isPassword
            ? (controller == confirmPasswordController
            ? obscureConfirmPassword
            : obscurePassword)
            : false,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black45),
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
                onPressed: () {
                  setState(() {
                    if (controller == confirmPasswordController) {
                      obscureConfirmPassword = !obscureConfirmPassword;
                    } else {
                      obscurePassword = !obscurePassword;
                    }
                  });
                },
            )
                : null,
      ),
    ),
    );
  }

  /// 🎯 BUTTON
  Widget _buildAnimatedButton() {
    return GestureDetector(
      onTapDown: (_) =>
          setState(() => isPressed = true),
      onTapUp: (_) async {
        setState(() => isPressed = false);

        await Future.delayed(
            const Duration(milliseconds: 100));

        if (emailController.text.trim().isEmpty ||
            passwordController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please fill all required fields"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (!_isValidEmail(emailController.text.trim())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter a valid email address"),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        if (passwordController.text.trim().length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Password must be at least 6 characters"),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        await _handleEmailLogin();

      },
      onTapCancel: () =>
          setState(() => isPressed = false),
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 120),
        height: 58,
        width: double.infinity,
        transform: Matrix4.identity()
          ..scale(isPressed ? 0.97 : 1.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              Color(0xFF6F6AF8),
            ],
          ),
          borderRadius:
          BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary
                  .withOpacity(
                  isPressed ? 0.25 : 0.45),
              blurRadius:
              isPressed ? 10 : 22,
              offset:
              const Offset(0, 8),
            )
          ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          "Login",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _socialButton(
      IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(28),
        border: Border.all(
            color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 24,
              color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
