import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_link/Profile.dart';
import 'package:local_link/ChatScreen.dart';

class LocalUser {
  final String userId;
  final String name;
  final String ipAddress;

  LocalUser({
    required this.userId,
    required this.name,
    required this.ipAddress,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.userIP,
    required this.userName,
    required this.userId,
  });

  final String userIP;
  final String userName;
  final String userId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final List<LocalUser> _networkUsers = [];
  bool _isLoading = true;
  String _networkId = '';
  DatabaseReference? _networkRef;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadNetworkAndFetchUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNetworkAndFetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    _networkId = prefs.getString('network_id') ?? '';

    print('🟩 Network ID: $_networkId');

    if (_networkId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    _networkRef = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('NETWORK_FRIENDS/$_networkId');

    _networkRef!.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      final List<LocalUser> tempUsers = [];

      print('🔥 Firebase NETWORK_FRIENDS data: $data');

      if (data != null && data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            final userId = value['user_id']?.toString() ?? '';
            final userName = value['name']?.toString() ?? '';
            final ipAddress = value['ip_address']?.toString() ?? '';

            if (userId.isNotEmpty && userName.isNotEmpty && userId != widget.userId) {
              tempUsers.add(LocalUser(
                userId: userId,
                name: userName,
                ipAddress: ipAddress,
              ));
            }
          }
        });
      }

      setState(() {
        _networkUsers
          ..clear()
          ..addAll(tempUsers);
        _isLoading = false;
      });
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String userId) {
    final colors = [
      const Color(0xFF06B6D4),
      const Color(0xFF14B8A6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    final hash = userId.hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202225),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF06B6D4),
                    Color(0xFF14B8A6),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.link,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'LocalLink',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF06B6D4).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_networkUsers.length}',
                  style: const TextStyle(
                    color: Color(0xFF06B6D4),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF2C2F33),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF06B6D4),
                    Color(0xFF14B8A6),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(widget.userName),
                        style: const TextStyle(
                          color: Color(0xFF06B6D4),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'IP: ${widget.userIP}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFF2C2F33),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF06B6D4),
                  ),
                ),
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        userId: widget.userId,
                        userName: widget.userName,
                        userIP: widget.userIP,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF202225),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF40444B),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF06B6D4),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Network ID',
                          style: TextStyle(
                            color: Color(0xFF99AAB5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Connected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF06B6D4),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Finding users...',
                style: TextStyle(
                  color: Color(0xFF99AAB5),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
            : _networkUsers.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2C2F33),
                  border: Border.all(
                    color: const Color(0xFF40444B),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.people_outline,
                  size: 60,
                  color: Color(0xFF72767D),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No users found yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Waiting for others to join your network...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF99AAB5),
                  ),
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: _networkUsers.length,
          itemBuilder: (context, index) {
            final user = _networkUsers[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2F33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF40444B),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getAvatarColor(user.userId),
                          _getAvatarColor(user.userId).withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getAvatarColor(user.userId).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(user.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF06B6D4),
                          Color(0xFF14B8A6),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          currentUserId: widget.userId,
                          currentUserName: widget.userName,
                          peerUserId: user.userId,
                          peerName: user.name,
                          networkId: _networkId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}