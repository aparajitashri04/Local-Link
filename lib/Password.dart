import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:local_link/NetworkConfirm.dart';
import 'Password_service.dart';

class PasswordScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String phone;

  const PasswordScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.phone,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _validateAndContinue() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = "Please enter and confirm your password.");
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = "Password must be at least 8 characters.");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
        "https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app",
      );

      final userRef = db.ref('USERS/${widget.userId}');

      print('🔵 About to hash password...');
      final hashData = await PasswordService.hashPassword(password);
      print('🟢 Hash data: $hashData');

      await userRef.update({
        'email': widget.email,
        'phone': widget.phone,
        'password_hash': hashData['password_hash'],
        'password_salt': hashData['password_salt'],
      });
      print('✅ Saved to Firebase');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NetworkConfirmScreen(
            userId: widget.userId,
            email: widget.email,
            phone: widget.phone,
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ ERROR: $e');
      print('Stack trace: $stackTrace');
      setState(() => _errorMessage = "Failed to save password: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202225),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Password',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2F33),
              Color(0xFF202225),
              Color(0xFF23272A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Lock Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF06B6D4).withOpacity(0.2),
                            const Color(0xFF14B8A6).withOpacity(0.2),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF06B6D4).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 50,
                        color: Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Secure Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a strong password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF99AAB5),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Password Field
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
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Color(0xFF72767D)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF06B6D4),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF72767D),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
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
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          hintStyle: const TextStyle(color: Color(0xFF72767D)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF06B6D4),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF72767D),
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                        onPressed: _isLoading ? null : _validateAndContinue,
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

                    // Password Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2F33).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF40444B).withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF06B6D4),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Password Tips',
                                style: TextStyle(
                                  color: Color(0xFF06B6D4),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordTip('At least 8 characters long'),
                          _buildPasswordTip('Mix of letters and numbers'),
                          _buildPasswordTip('Include special characters'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline,
              color: Color(0xFF72767D),
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                color: Color(0xFF99AAB5),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}