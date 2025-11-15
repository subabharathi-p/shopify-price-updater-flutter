// File: services/auto_logout_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shopify_pricesync_v2/screen/login_screen.dart';
 // Make sure this path matches your project

/// AutoLogoutService handles automatic logout after user inactivity.
class AutoLogoutService {
  // Singleton pattern
  static final AutoLogoutService _instance = AutoLogoutService._internal();
  factory AutoLogoutService() => _instance;
  AutoLogoutService._internal();

  Timer? _timer;
  Duration _timeout = const Duration(minutes: 5); // Default auto-logout duration

  /// Start or reset inactivity timer
  void startTimer(BuildContext context, {Duration? timeout}) {
    _timeout = timeout ?? _timeout;
    _timer?.cancel();
    _timer = Timer(_timeout, () {
      _logout(context);
    });
  }

  /// Call this on user activity (tap, scroll, input) to reset timer
  void userActivityDetected(BuildContext context) {
    startTimer(context);
  }

  /// Cancel the timer manually (optional)
  void cancelTimer() {
    _timer?.cancel();
  }

  /// Private method to logout user
  void _logout(BuildContext context) {
    _timer?.cancel();

    // Navigate to LoginScreen and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    // Show notification to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logged out due to inactivity"),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
