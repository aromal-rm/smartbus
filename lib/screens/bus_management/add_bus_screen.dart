import 'package:flutter/material.dart';
import '../../services/firestore_service.dart'; // Import FirestoreService
import '../../widgets/custom_widgets.dart'; // Import Custom widgets

class AddBusScreen extends StatefulWidget {
  const AddBusScreen({super.key});

  @override
  _AddBusScreenState createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _busNumberController.dispose();
    _routeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _addBus() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.addBus(
          busNumber: _busNumberController.text.trim(),
          route: _routeController.text.trim(),
          capacity: int.parse(_capacityController.text.trim()),
        );
        // Show success message
        _showSuccessDialog();
      } catch (error) {
        // Show error message
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
        content: 'Bus added successfully!',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(); // Go back to the previous screen (AdminDashboard)
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
      appBar: AppBar(title: const Text('Add New Bus')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CustomTextField(
                controller: _busNumberController,
                labelText: 'Bus Number',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bus number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _routeController,
                labelText: 'Route',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter route';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _capacityController,
                labelText: 'Capacity',
                keyboardType: TextInputType.numberWithOptions(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter capacity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Capacity must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CustomProgressIndicator(message: 'Adding Bus...')
                  : CustomButton(
                onPressed: _addBus,
                text: 'Add Bus',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

