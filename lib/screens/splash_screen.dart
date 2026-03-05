import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  final Future<void> Function() onInit;
  final VoidCallback onReady;
  const SplashScreen({required this.onInit, required this.onReady, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startInit();
  }

  Future<void> _startInit() async {
    final start = DateTime.now();
    await widget.onInit();
    final elapsed = DateTime.now().difference(start);
    final minDuration = Duration(seconds: 2);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }
    setState(() {
      // Initialization complete
    });
    widget.onReady();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your own Lottie animation file
            Lottie.asset(
              'assets/animations/splash.json',
              width: 200,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 32),
            const Text(
              'Vyaya',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Initializing...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
