import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_link/NameConfirm.dart';
import 'package:network_info_plus/network_info_plus.dart';


class NetworkConfirmScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String phone;

  const NetworkConfirmScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.phone,
  });

  @override
  State<NetworkConfirmScreen> createState() => _NetworkConfirmScreenState();
}

class _NetworkConfirmScreenState extends State<NetworkConfirmScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String _calculatedNetworkPrefix = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _loadSavedNetworkData();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _ssidController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedNetworkData() async {
    final prefs = await SharedPreferences.getInstance();

    // Try to auto-detect IP address
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      final wifiName = await info.getWifiName();

      if (wifiIP != null) {
        setState(() {
          _ipController.text = wifiIP;
          _calculatedNetworkPrefix = _calculateNetworkPrefix(wifiIP);
        });
      }

      if (wifiName != null) {
        setState(() {
          // Remove quotes from SSID if present
          _ssidController.text = wifiName.replaceAll('"', '');
        });
      }
    } catch (e) {
      print('❌ Could not auto-detect network: $e');
    }

    // Fallback to saved data
    final savedIp = prefs.getString('ip_address') ?? '';
    final savedSsid = prefs.getString('ssid') ?? '';

    if (_ipController.text.isEmpty && savedIp.isNotEmpty) {
      setState(() {
        _ipController.text = savedIp;
        _calculatedNetworkPrefix = _calculateNetworkPrefix(savedIp);
      });
    }

    if (_ssidController.text.isEmpty && savedSsid.isNotEmpty) {
      setState(() {
        _ssidController.text = savedSsid;
      });
    }
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
      final rawNetworkId = _calculateNetworkPrefix(ipAddress);
      if (rawNetworkId.isEmpty) throw Exception("Invalid IP format.");

      final safeNetworkId = rawNetworkId.replaceAll('.', '_');
      final userId = widget.userId;

      final database = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL:
        'https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      await database
          .ref('NETWORK_FRIENDS/$safeNetworkId/$userId')
          .set({
        'user_id': userId,
        'ip_address': ipAddress,
      });

      await database.ref('USERS/$userId').update({
        'ip_address': ipAddress,
        'network_id': safeNetworkId,
        'ssid': ssid,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ip_address', ipAddress);
      await prefs.setString('ssid', ssid);
      await prefs.setString('network_id', safeNetworkId);
      await prefs.setString('user_id', userId);
      await prefs.setString('email', widget.email);
      await prefs.setString('phone', widget.phone);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NameConfirm(
              userId: userId,
              userIP: ipAddress,
              email: widget.email,
              phone: widget.phone,
              networkId: safeNetworkId,
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
      backgroundColor: const Color(0xFF202225),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Network Setup',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Icon
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
                      Icons.wifi,
                      size: 50,
                      color: Color(0xFF06B6D4),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Network Setup',
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
                    'Connect to your local network',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF99AAB5),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // SSID Field
                  const Text(
                    'Wi-Fi Network',
                    style: TextStyle(
                      color: Color(0xFF99AAB5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      controller: _ssidController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Network name (SSID)',
                        hintStyle: TextStyle(color: Color(0xFF72767D)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.wifi,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // IP Field
                  const Text(
                    'Local IP Address',
                    style: TextStyle(
                      color: Color(0xFF99AAB5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      controller: _ipController,
                      onChanged: _onIpChanged,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'e.g., 192.168.1.100',
                        hintStyle: TextStyle(color: Color(0xFF72767D)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.device_hub,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Calculated prefix
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF06B6D4).withOpacity(0.1),
                          const Color(0xFF14B8A6).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF06B6D4).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.lan_outlined,
                              color: Color(0xFF06B6D4),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Network ID (Prefix)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF06B6D4),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2F33),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _calculatedNetworkPrefix.isNotEmpty
                                ? _calculatedNetworkPrefix
                                : 'Enter IP to compute prefix',
                            style: TextStyle(
                              color: _calculatedNetworkPrefix.isNotEmpty
                                  ? const Color(0xFF06B6D4)
                                  : const Color(0xFF72767D),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
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

                  // Save & Continue Button
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
                      onPressed: _isLoading ? null : _saveNetworkDetails,
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
                        'Save & Continue',
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

                  // Help text
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
                              Icons.help_outline,
                              color: Color(0xFF06B6D4),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'How to find your IP',
                              style: TextStyle(
                                color: Color(0xFF06B6D4),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildHelpTip('Go to Settings > Wi-Fi'),
                        _buildHelpTip('Tap on your connected network'),
                        _buildHelpTip('Look for "IP Address"'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.arrow_right,
              color: Color(0xFF72767D),
              size: 16,
            ),
          ),
          const SizedBox(width: 4),
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
