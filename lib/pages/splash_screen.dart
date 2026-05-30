// ============================================================
// pages/splash_screen.dart
// ============================================================
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAEEDA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFEF9F27),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.volunteer_activism,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'DonateConnect',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF412402),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Give. Receive. Impact.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF854F0B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}