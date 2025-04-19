import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart'; // Import AuthService
import 'welcome_screen.dart'; // Import WelcomeScreen
import 'dashboard/passenger_dashboard.dart'; // Import PassengerDashboard
import 'dashboard/driver_dashboard.dart';   // Import DriverDashboard
import 'dashboard/admin_dashboard.dart';     // Import AdminDashboard
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }
  
  // Use AuthService to check the current user and navigate
  void _checkLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _navigateTo(const WelcomeScreen());
    } else {
      final String? role = await _authService.getUserRole(user.uid);
      if (role == 'passenger') {
        _navigateTo(const PassengerDashboard());
      } else if (role == 'driver') {
        _navigateTo(const DriverDashboard());
      } else if (role == 'admin') {
        _navigateTo(const AdminDashboard());
      } else {
        print('Invalid user role detected: $role');
        await _authService.signOut();
        _navigateTo(const WelcomeScreen());
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: Duration.zero,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Build method content
    return const Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        // Splash screen content
      ),
    );
  }
}

