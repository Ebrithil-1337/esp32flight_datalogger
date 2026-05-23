import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'home_screen.dart'; // Main navigation layout

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async
  { // Fixed return type and formatting
    // Leave the splash screen on screen for 3 seconds. 
    // This gives AppState time to load settings from the phone's hard drive!
    await Future.delayed(const Duration(seconds: 3), () {});
    
    if (!mounted) return;
    
    // Smoothly fade to your main app screen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background for the logo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your School Logo
            SvgPicture.asset(
              'assets/BSH_Logo_RGB_2025_RZ.svg',
              width: 250, // Adjust this size as needed
            ),
            
            const SizedBox(height: 60), // Spacing
            
            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.blue, // Match this to your app's theme
            ),
            
            const SizedBox(height: 20),
            
            // Optional text
            const Text(
              'Flight Analyzer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}