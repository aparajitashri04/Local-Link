import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SignUp.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userIP;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userIP,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _email;
  String? _phone;
  String? _networkId;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // ✅ Load stored info from SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('email') ?? 'Not available';
      _phone = prefs.getString('phone') ?? 'Not available';
      _networkId = prefs.getString('network_id') ?? 'Not available';
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF40444B),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF06B6D4),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF99AAB5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2C2F33),
              const Color(0xFF202225),
              const Color(0xFF23272A),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF06B6D4),
                      const Color(0xFF14B8A6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(widget.userName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // User ID
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2F33),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF40444B),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Section Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACCOUNT INFORMATION',
                    style: TextStyle(
                      color: Color(0xFF72767D),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // ✅ Information Tiles
              _buildInfoTile('Email', _email ?? 'Loading...', Icons.email_outlined),
              _buildInfoTile('Phone', _phone ?? 'Loading...', Icons.phone_outlined),
              _buildInfoTile('IP Address', widget.userIP, Icons.wifi_outlined),
              _buildInfoTile('Network ID', _networkId ?? 'Loading...', Icons.lan_outlined),

              const SizedBox(height: 40),

              // ✅ Logout Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFED4245),
                      const Color(0xFFC0392B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFED4245).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const SignUpScreen(),
                        ),
                            (route) => false,
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}



