import 'package:flutter/material.dart';
import '../../services/firestore_service.dart'; // Import FirestoreService
import '../../widgets/custom_widgets.dart'; // Import Custom widgets

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  _BookingListScreenState createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      _bookings = await _firestoreService.getAllBookings();
    } catch (error) {
      _showErrorDialog(error.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Error',
        content: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Bookings')),
      body: _isLoading
          ? const CustomProgressIndicator(message: 'Loading Bookings...')
          : _bookings.isEmpty
          ? const Center(child: Text('No bookings found.'))
          : ListView.builder(
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 10),
            child: ListTile(
              title: Text(
                  'Booking ID: ${booking['id']}'), //show booking id
              subtitle: Text(
                  'User ID: ${booking['userId'] ?? 'N/A'}, Bus ID: ${booking['busId'] ?? 'N/A'}, Source: ${booking['source'] ?? 'N/A'}, Destination: ${booking['destination'] ?? 'N/A'}, Seats: ${booking['seats'] ?? 'N/A'}, Time: ${booking['time'] ?? 'N/A'}, Status: ${booking['status'] ?? 'N/A'}'), //show details
            ),
          );
        },
      ),
    );
  }
}

