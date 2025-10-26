import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // This SizedBox creates the space to push the content down
            const SizedBox(height: 250.0),
            // The "Login" text at the top
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32.0),
            // Text box for phone number entry
            TextField(
              decoration: InputDecoration(
                hintText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (text) {
                print('Phone number entered: $text');
              },
            ),
            const SizedBox(height: 16.0),
            // Text box for password entry
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: (text) {
                print('Password entered: $text');
              },
            ),
            const SizedBox(height: 32.0),
            // "Continue" button
            ElevatedButton(
              onPressed: () {
                print('Continue button pressed!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18.0, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}