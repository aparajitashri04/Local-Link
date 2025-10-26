import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_link/Profile.dart';
import 'ChatScreen.dart';

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
  final String userId;     // Current logged-in user ID
  final String userName;   // Current user's name
  final String userIP;     // Current user's IP

  const HomePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userIP,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<LocalUser> _discoveredUsers;

  @override
  void initState() {
    super.initState();
    _discoveredUsers = [];

    // Add self to the list
    _discoveredUsers.add(LocalUser(
      userId: widget.userId,
      name: widget.userName,
      ipAddress: widget.userIP,
    ));

    // Start dummy discovery
    _discoverLocalUsers();
  }

  void _discoverLocalUsers() async {
    // Simulate discovery (replace later with UDP scan)
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _discoveredUsers.addAll([
        LocalUser(userId: 'user_1', name: 'Alice', ipAddress: '192.168.1.101'),
        LocalUser(userId: 'user_2', name: 'Bob', ipAddress: '192.168.1.102'),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Link'),
        backgroundColor: Colors.blue,
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.userName),
              accountEmail: Text('IP: ${widget.userIP}'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.blue, size: 48),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),

            // ✅ PROFILE NAVIGATION
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close drawer first
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

            // Placeholder for settings
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // TODO: Add settings screen
              },
            ),
          ],
        ),
      ),

      // ✅ USER LIST
      body: ListView.builder(
        itemCount: _discoveredUsers.length,
        itemBuilder: (context, index) {
          final user = _discoveredUsers[index];
          final isSelf = user.userId == widget.userId;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isSelf ? Colors.blue : Colors.grey[300],
                child: Icon(
                  isSelf ? Icons.person : Icons.person_outline,
                  color: isSelf ? Colors.white : Colors.black,
                ),
              ),
              title: Text(
                user.name + (isSelf ? " (You)" : ""),
                style: TextStyle(
                  fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text('IP: ${user.ipAddress}'),
              trailing: isSelf ? null : const Icon(Icons.chat_bubble_outline),
              onTap: isSelf
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      currentUserId: widget.userId,
                      currentUserName: widget.userName,
                      currentUserIP: widget.userIP,
                      peerUserId: user.userId,
                      peerName: user.name,
                      peerIP: user.ipAddress,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}







