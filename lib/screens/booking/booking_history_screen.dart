import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart'; // Import FirestoreService
import '../../widgets/custom_widgets.dart'; // Import Custom widgets

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;
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
      final user = _auth.currentUser;
      if (user != null) {
        _bookings =
        await _firestoreService.getBookingsForUser(user.uid); //get user
      }
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

  // Function to show cancel booking confirmation
  void _showCancelBookingDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cancel
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              // Perform cancellation
              Navigator.of(context).pop(); // Close the dialog
              setState(() => _isLoading = true);
              try {
                await _firestoreService.cancelBooking(
                    bookingId); //cancel using booking id
                await _loadBookings(); // Refresh the list
              } catch (error) {
                _showErrorDialog(error.toString());
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking History')),
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
                  'Bus: ${booking['busId'] ?? 'N/A'}'), //show bus id
              subtitle: Text(
                  'Source: ${booking['source'] ?? 'N/A'}, Destination: ${booking['destination'] ?? 'N/A'}, Seats: ${booking['seats'] ?? 'N/A'}, Time: ${booking['time'] ?? 'N/A'}, Status: ${booking['status'] ?? 'N/A'}'), //show details
              trailing: booking['status'] == 'confirmed'
                  ? ElevatedButton(
                onPressed: () =>
                    _showCancelBookingDialog(booking['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Cancel'),
              )
                  : const Text(
                'Cancelled',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      ),
    );
  }
}

