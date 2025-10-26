import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SignUp.dart'; // Make sure this import matches your file path

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

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              widget.userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'User ID: ${widget.userId}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // ✅ Information Tiles
            _buildInfoTile('Email', _email ?? 'Loading...', Icons.email),
            _buildInfoTile('Phone', _phone ?? 'Loading...', Icons.phone),
            _buildInfoTile('IP Address', widget.userIP, Icons.wifi),
            _buildInfoTile(
                'Network ID', _networkId ?? 'Loading...', Icons.network_wifi),

            const SizedBox(height: 30),

            // ✅ Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const SignUpScreen()),
                        (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}



