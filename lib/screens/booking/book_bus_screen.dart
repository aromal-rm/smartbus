import 'package:flutter/material.dart';
import '../../services/firestore_service.dart'; // Import FirestoreService
import '../../widgets/custom_widgets.dart'; // Import Custom widgets
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class BookBusScreen extends StatefulWidget {
  const BookBusScreen({super.key});

  @override
  _BookBusScreenState createState() => _BookBusScreenState();
}

class _BookBusScreenState extends State<BookBusScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance; // Get the FirebaseAuth instance
  String? _selectedBusId;
  String? _source;
  String? _destination;
  int _seats = 1;
  String? _time; // Added time
  List<Map<String, dynamic>> _buses = [];
  bool _isLoading = true;

  //text editing controllers
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadBuses() async {
    setState(() => _isLoading = true);
    try {
      _buses = await _firestoreService.getAllBuses();
      if (_buses.isNotEmpty) {
        setState(() {
          _selectedBusId = _buses[0]['id']; // Initialize with the first bus
        });
      }
    } catch (error) {
      _showErrorDialog(error.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _bookTicket() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = _auth.currentUser; // Get the current user
        if (user == null) {
          // Handle the case where the user is not logged in
          _showErrorDialog(
              'You must be logged in to book a ticket.'); //improved
          setState(() => _isLoading = false);
          return;
        }

        if (_selectedBusId == null) {
          _showErrorDialog('Please select a bus.');
          setState(() => _isLoading = false);
          return;
        }
        await _firestoreService.bookTicket(
          userId: user.uid,
          busId: _selectedBusId!,
          source: _sourceController.text.trim(),
          destination: _destinationController.text.trim(),
          seats: _seats,
          time: _timeController.text
              .trim(), // Pass the time from the text field
        );
        _showSuccessDialog();
      } catch (error) {
        _showErrorDialog(error.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Success',
        content: 'Ticket booked successfully!',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(); // Go back
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(title: const Text('Book a Bus')),
      body: _isLoading
          ? const CustomProgressIndicator(message: 'Loading Buses...')
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  value: _selectedBusId,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBusId = newValue;
                    });
                  },
                  items: _buses.map<DropdownMenuItem<String>>(
                        (Map<String, dynamic> bus) {
                      return DropdownMenuItem<String>(
                        value: bus['id'],
                        child: Text(
                            '${bus['busNumber']} - ${bus['route']}'), //show route
                      );
                    },
                  ).toList(),
                  validator: (value) => value == null
                      ? 'Please select a bus'
                      : null, //moved validator here
                  decoration:
                  const InputDecoration(labelText: 'Select Bus'),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _sourceController,
                  labelText: 'Source',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter source';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _destinationController,
                  labelText: 'Destination',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter destination';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _timeController,
                  labelText: 'Time',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter time';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: _seats,
                  onChanged: (int? newValue) {
                    setState(() {
                      _seats = newValue!;
                    });
                  },
                  items: <int>[1, 2, 3, 4, 5]
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                  decoration:
                  const InputDecoration(labelText: 'Number of Seats'),
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CustomProgressIndicator(
                    message: 'Booking Ticket...')
                    : CustomButton(
                  onPressed: _bookTicket,
                  text: 'Book Ticket',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

