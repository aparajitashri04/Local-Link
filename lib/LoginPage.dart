import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
//import 'package:local_link/Password_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_link/HomePage.dart';
import 'Password_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
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
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please fill out both fields.");
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
      final database = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL:
        'https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      final event = await database
          .ref('USERS')
          .orderByChild('phone')
          .equalTo(phone)
          .once();

      if (event.snapshot.value == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No account found with this phone number.";
        });
        return;
      }

      final usersMap =
      Map<String, dynamic>.from(event.snapshot.value as Map);
      final userEntry = usersMap.entries.first;

      final userId = userEntry.key.toString();
      final userData = Map<String, dynamic>.from(
          json.decode(json.encode(userEntry.value))
      );

      print('🔑 userData keys: ${userData.keys.toList()}');
      print('🔑 storedSalt: ${userData['password_salt']}');
      print('🔑 storedHash: ${userData['password_hash']}');

      final storedSalt = userData['password_salt']?.toString();
      final storedHash = userData['password_hash']?.toString();

      if (storedSalt == null || storedHash == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Account data corrupted. Please sign up again.";
        });
        return;
      }

      final isValid = await PasswordService.verifyPassword(
        password,
        storedSalt,
        storedHash,
      );

      if (!isValid) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Incorrect password.";
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('user_name', userData['name']?.toString() ?? '');
      await prefs.setString('user_ip', userData['ip_address']?.toString() ?? '');
      await prefs.setString('email', userData['email']?.toString() ?? '');
      await prefs.setString('phone', phone);
      await prefs.setString(
          'network_id', userData['network_id']?.toString() ?? '');

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomePage(
            userId: userId,
            userName: userData['name']?.toString() ?? '',
            userIP: userData['ip_address']?.toString() ?? '',
          ),
        ),
            (_) => false,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Login failed.";
      });
    }
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
              padding: const EdgeInsets.all(32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 40),

                    // Logo
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
                            color: const Color(0xFF06B6D4).withOpacity(0.3),
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
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Login to your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF99AAB5),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Phone Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F33),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF40444B),
                        ),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(color: Color(0xFF72767D)),
                          border: InputBorder.none,
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          prefixIcon:
                          Icon(Icons.phone_outlined, color: Color(0xFF06B6D4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F33),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF40444B),
                        ),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Color(0xFF72767D)),
                          border: InputBorder.none,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          prefixIcon:
                          const Icon(Icons.lock_outline, color: Color(0xFF06B6D4)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF72767D),
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFED4245).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                          Border.all(color: const Color(0xFFED4245).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFED4245), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: Color(0xFFED4245), fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Login Button
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF14B8A6)],
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
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
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

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Color(0xFF99AAB5),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            "Sign Up",
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