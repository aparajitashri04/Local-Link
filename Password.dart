import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:local_link/NetworkConfirm.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateAndContinue() async {
    setState(() => _errorMessage = null);

    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = "Please enter and confirm your password.");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = "Passwords do not match. Please re-enter.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = widget.userId;

      // Firebase DB instance
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
        "https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app",
      );

      // Save password in NETWORK_INFO node
      await database.ref('NETWORK_INFO/$userId').set({
        'password': password,
        'network_id': '',
        'ip_address': '',
        'user_id': userId,
      });

      // ✅ Save password locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('password', password);

      // Navigate to NetworkConfirmScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NetworkConfirmScreen(
              userId: widget.userId,
              email: widget.email,
              phone: widget.phone,
              password: password,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save password: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Set Password"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 100),
              const Text(
                'Create Password',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _validateAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


