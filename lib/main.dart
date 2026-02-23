import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'SignUp.dart';
import 'HomePage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Realtime Database
  FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    "https://local-link-63f75-default-rtdb.asia-southeast1.firebasedatabase.app",
  );

  // ✅ Load saved user data from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');
  final userName = prefs.getString('user_name');
  final userIP = prefs.getString('user_ip');

  // ✅ Run app
  runApp(MyApp(
    userId: userId,
    userName: userName,
    userIP: userIP,
  ));
}

class MyApp extends StatelessWidget {
  final String? userId;
  final String? userName;
  final String? userIP;

  const MyApp({
    super.key,
    this.userId,
    this.userName,
    this.userIP,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUserLoggedIn =
        userId != null && userName != null && userIP != null;

    return MaterialApp(
      title: 'Local Link Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // ✅ Navigate correctly
      home: isUserLoggedIn
          ? HomePage(
        userId: userId!,
        userName: userName!,
        userIP: userIP!,
      )
          : const SignUpScreen(),
    );
  }
}