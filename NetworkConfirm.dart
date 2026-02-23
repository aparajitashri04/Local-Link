import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_link/NameConfirm.dart';

class NetworkConfirmScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String phone;
  final String password;

  const NetworkConfirmScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  State<NetworkConfirmScreen> createState() => _NetworkConfirmScreenState();
}

class _NetworkConfirmScreenState extends State<NetworkConfirmScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String _calculatedNetworkPrefix = '';

  @override
  void initState() {
    super.initState();
    _loadSavedNetworkData();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _ssidController.dispose();
    super.dispose();
  }

  // ✅ Load any previously saved IP/SSID/network_id
  Future<void> _loadSavedNetworkData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('ip_address') ?? '';
    final savedSsid = prefs.getString('ssid') ?? '';
    final savedNetworkId = prefs.getString('network_id') ?? '';

    setState(() {
      _ipController.text = savedIp;
      _ssidController.text = savedSsid;
      _calculatedNetworkPrefix = savedNetworkId;
    });
  }

  String _calculateNetworkPrefix(String ip) {
    final lastDotIndex = ip.lastIndexOf('.');
    return (lastDotIndex != -1 && lastDotIndex < ip.length)
        ? ip.substring(0, lastDotIndex)
        : '';
  }

  void _onIpChanged(String newIp) {
    setState(() {
      _calculatedNetworkPrefix = _calculateNetworkPrefix(newIp);
    });
  }

  Future<void> _saveNetworkDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ipAddress = _ipController.text.trim();
      final ssid = _ssidController.text.trim();

      if (ipAddress.isEmpty) throw Exception("IP Address is required.");

      final networkId = _calculateNetworkPrefix(ipAddress);
      if (networkId.isEmpty) throw Exception("Invalid IP format.");

      final userId = widget.userId;

      final database = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL:
        'https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      // Save to USERS node
      await database.ref('USERS/$userId').update({
        'ip_address': ipAddress,
        'network_id': networkId,
        'ssid': ssid,
      });

      // Save to NETWORK_INFO node
      await database.ref('NETWORK_INFO/$userId').update({
        'network_id': networkId,
        'ip_address': ipAddress,
        'ssid': ssid,
        'user_id': userId,
      });

      // ✅ Save locally in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ip_address', ipAddress);
      await prefs.setString('ssid', ssid);
      await prefs.setString('network_id', networkId);
      await prefs.setString('user_id', userId);
      await prefs.setString('email', widget.email);
      await prefs.setString('phone', widget.phone);
      await prefs.setString('password', widget.password);

      // Navigate to NameConfirm
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NameConfirm(
              userId: userId,
              userIP: ipAddress,
              email: widget.email,
              phone: widget.phone,
              password: widget.password,
              networkId: networkId,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save network details: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Setup'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Network Setup',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                hintText: 'Wi-Fi network name (SSID)',
                labelText: 'Network (SSID)',
                prefixIcon: const Icon(Icons.wifi),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              onChanged: _onIpChanged,
              decoration: InputDecoration(
                hintText: 'Local IP (e.g., 192.168.1.100)',
                labelText: 'Local IP',
                prefixIcon: const Icon(Icons.device_hub),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calculated Network ID (prefix):',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    _calculatedNetworkPrefix.isNotEmpty
                        ? _calculatedNetworkPrefix
                        : 'Enter IP to compute prefix',
                    style: TextStyle(
                      color: _calculatedNetworkPrefix.isNotEmpty
                          ? Colors.blue.shade800
                          : Colors.grey,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveNetworkDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child:
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text('Save & Continue', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}







