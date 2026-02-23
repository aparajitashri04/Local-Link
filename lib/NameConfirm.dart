import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomePage.dart';

class NameConfirm extends StatefulWidget {
  final String userId;
  final String userIP;
  final String? email;
  final String? phone;
  final String? password;
  final String? networkId;

  const NameConfirm({
    super.key,
    required this.userId,
    required this.userIP,
    this.email,
    this.phone,
    this.password,
    this.networkId,
  });

  @override
  State<NameConfirm> createState() => _NameConfirmState();
}

class _NameConfirmState extends State<NameConfirm> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = "Please enter your name");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL:
        'https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      final networkId = widget.networkId ?? '';
      print("🟩 NameConfirm: Saving for userId = ${widget.userId}");
      print("🟦 IP Address: ${widget.userIP}");
      print("🟨 Network ID: $networkId");

      // ✅ USE UPDATE INSTEAD OF SET - this preserves password_hash and password_salt!
      final userPath = 'USERS/${widget.userId}';
      await db.ref(userPath).update({
        'name': name,
      });
      print("✅ Updated user name in USERS node");

      // ✅ Also save under NETWORK_FRIENDS with matching field names
      if (networkId.isNotEmpty) {
        final friendPath = 'NETWORK_FRIENDS/$networkId/${widget.userId}';
        await db.ref(friendPath).set({
          'user_id': widget.userId,
          'name': name,
          'ip_address': widget.userIP,
        });
        print("✅ Added user to NETWORK_FRIENDS/$networkId");
      } else {
        print("⚠️ Skipped adding to NETWORK_FRIENDS: networkId is empty!");
      }

      // ✅ Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', widget.userId);
      await prefs.setString('user_name', name);
      await prefs.setString('user_ip', widget.userIP);
      await prefs.setString('email', widget.email ?? '');
      await prefs.setString('phone', widget.phone ?? '');
      await prefs.setString('network_id', networkId);

      print("💾 Saved all details locally");

      // ✅ Navigate to HomePage
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomePage(
              userId: widget.userId,
              userName: name,
              userIP: widget.userIP,
            ),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      print("❌ Error while saving name: $e");
      setState(() {
        _errorMessage = 'Failed to save name: ${e.toString()}';
      });
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
          'Set Your Name',
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
              padding: const EdgeInsets.all(32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(24),
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
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                      const Text(
                        'Almost There!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter the name your friends will see',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF99AAB5),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Name Field
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
                          controller: _nameController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: 'Your Name',
                            hintStyle: TextStyle(
                              color: Color(0xFF72767D),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

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
                        height: 54,
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
                              color: const Color(0xFF06B6D4).withOpacity(0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveName,
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
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2F33).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF40444B).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF06B6D4),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Setup Complete!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'You\'ll be connected to your local network',
                                    style: TextStyle(
                                      color: Color(0xFF99AAB5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }
}