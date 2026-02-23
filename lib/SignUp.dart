import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:local_link/Password.dart';
import 'package:local_link/LoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _continueToPassword() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || phone.isEmpty) {
      setState(() => _errorMessage = "Please fill out both fields.");
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage = "Please enter a valid email address.");
      return;
    }
    if (phone.length != 10) {
      setState(() => _errorMessage = "Phone number must be 10 digits.");
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final FirebaseDatabase database = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL:
        "https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app",
      );

      final DatabaseReference newUserRef = database.ref('USERS').push();
      final String userId = newUserRef.key!;

      await newUserRef.set({
        "email": email,
        "phone": phone,
        "name": "",
        "created_at": DateTime.now().toIso8601String(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('email', email);
      await prefs.setString('phone', phone);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PasswordScreen(
            userId: userId,
            email: email,
            phone: phone,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error: ${e.toString()}";
      });
    }
  }

  void _continueWithGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Google Sign-In not implemented yet"),
        backgroundColor: const Color(0xFF06B6D4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202225),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF202225),
              Color(0xFF2C2F33),
              Color(0xFF23272A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Logo/Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF06B6D4),
                            Color(0xFF14B8A6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.link,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF06B6D4),
                          Color(0xFF14B8A6),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        "LocalLink",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Create your account",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF99AAB5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F33),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF40444B),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(color: Color(0xFF72767D)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F33),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF40444B),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(color: Color(0xFF72767D)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFED4245).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFED4245).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFED4245),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFED4245),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Continue Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF06B6D4),
                            Color(0xFF14B8A6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _continueToPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider with OR
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Color(0xFF40444B),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "OR",
                            style: TextStyle(
                              color: Color(0xFF72767D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Color(0xFF40444B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Continue with Google Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F33),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF40444B),
                          width: 1.5,
                        ),
                      ),
                      child: OutlinedButton(
                        onPressed: _continueWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.g_mobiledata,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(
                            color: Color(0xFF99AAB5),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Color(0xFF06B6D4),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}