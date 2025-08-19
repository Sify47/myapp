import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB2B3B8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              'https://i.ibb.co/3mKCxgGf/Picsart-25-08-12-10-36-14-613.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
