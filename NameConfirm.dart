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

class _NameConfirmState extends State<NameConfirm> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
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
      // ✅ Save to Firebase
      final database = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL:
        'https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      await database.ref('USERS/${widget.userId}').update({
        'name': name,
        'email': widget.email ?? '',
        'phone': widget.phone ?? '',
        'password': widget.password ?? '',
        'ip': widget.userIP,
        'network_id': widget.networkId ?? '',
      });

      // ✅ Save everything locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', widget.userId);
      await prefs.setString('userName', name);
      await prefs.setString('userIP', widget.userIP);
      await prefs.setString('email', widget.email ?? '');
      await prefs.setString('phone', widget.phone ?? '');
      await prefs.setString('password', widget.password ?? '');
      await prefs.setString('network_id', widget.networkId ?? '');

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
      appBar: AppBar(
        title: const Text('Set Your Name'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the name your friends will see:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20.0),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                )
                    : const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}











