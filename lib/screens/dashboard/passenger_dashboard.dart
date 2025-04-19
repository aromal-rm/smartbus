import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartbus/screens/welcome_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_widgets.dart';
import '../booking/book_bus_screen.dart'; // Import BookBusScreen
import '../booking/booking_history_screen.dart';// Import BookingHistoryScreen

class PassengerDashboard extends StatefulWidget {
  const PassengerDashboard({super.key});

  @override
  _PassengerDashboardState createState() => _PassengerDashboardState();
}

class _PassengerDashboardState extends State<PassengerDashboard> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    _user = _authService.currentUser;
    if (_user != null) {
      final userDetails = await _firestoreService.getUserDetails(_user!.uid);
      if (userDetails != null) {
        setState(() {
          _userName = userDetails.name;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: constText('Passenger Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              // Navigate to welcome screen after sign out
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const CustomProgressIndicator(message: 'Loading Dashboard...')
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome, $_userName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'What would you like to do?',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            CustomButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BookBusScreen(),
                  ),
                );
              },
              text: 'Book a Bus',
            ),
            const SizedBox(height: 15),
            CustomButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BookingHistoryScreen(),
                  ),
                );
              },
              text: 'View Booking History',
            ),
            // Add more passenger-specific actions here
          ],
        ),
      ),
    );
  }
}

