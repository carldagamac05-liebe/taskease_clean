import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:flutter/foundation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: initState called');
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    debugPrint('SplashScreen: Checking login status...');
    await Future.delayed(const Duration(seconds: 1));

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      debugPrint('SplashScreen: userId = $userId');

      if (mounted) {
        if (userId != null && userId.isNotEmpty) {
          debugPrint('SplashScreen: Navigating to HomeScreen');
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          debugPrint('SplashScreen: Navigating to LoginScreen');
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      debugPrint('SplashScreen: Error - $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SplashScreen: Building...');
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity( 0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity( 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.task_alt,
                  size: 60,
                  color: Color(0xFF6200EE),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'TaskEase',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart Task Manager',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity( 0.8),
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
