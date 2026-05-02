import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class LogoutHandler {
  static Future<void> handleAppExit() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) {
      // Cancel background tasks when not logged in
      await Workmanager().cancelAll();
    }
  }

  static Future<bool> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final userId = prefs.getString('user_id');

    return isLoggedIn && userId != null && userId.isNotEmpty;
  }
}