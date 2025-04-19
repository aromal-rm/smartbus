import 'package:flutter/material.dart';
import '../../services/firestore_service.dart'; // Import FirestoreService
import '../../widgets/custom_widgets.dart'; // Import Custom widgets

class EditBusScreen extends StatefulWidget {
  final String busId;
  final String busNumber;
  final String route;
  final int capacity;
  final String? driverId; // Add driverId parameter

  const EditBusScreen({
    super.key,
    required this.busId,
    required this.busNumber,
    required this.route,
    required this.capacity,
    this.driverId, // Initialize with current driver ID if any
  });

  @override
  _EditBusScreenState createState() => _EditBusScreenState();
}

class _EditBusScreenState extends State<EditBusScreen> {
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Add driver related variables
  List<Map<String, dynamic>> _drivers = [];
  String? _selectedDriverId;
  bool _loadingDrivers = true;

  @override
  void initState() {
    super.initState();
    _busNumberController.text = widget.busNumber;
    _routeController.text = widget.route;
    _capacityController.text = widget.capacity.toString();
    _selectedDriverId = widget.driverId;
    _loadDrivers(); // Load drivers when screen initializes
  }

  // Load drivers from Firestore
  Future<void> _loadDrivers() async {
    setState(() => _loadingDrivers = true);
    try {
      final driversData = await _firestoreService.getDrivers();
      setState(() {
        _drivers = driversData;
        _loadingDrivers = false;
      });
    } catch (error) {
      setState(() => _loadingDrivers = false);
      _showErrorDialog('Failed to load drivers: ${error.toString()}');
    }
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _routeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _editBus() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.editBus(
          busId: widget.busId,
          busNumber: _busNumberController.text.trim(),
          route: _routeController.text.trim(),
          capacity: int.parse(_capacityController.text.trim()),
          driverId: _selectedDriverId, // Add driver ID to the bus data
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
        content: 'Bus edited successfully!',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(); // Go back to the previous screen (BusListScreen)
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
      appBar: AppBar(title: const Text('Edit Bus')),
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
              const SizedBox(height: 20),
              // Driver selection dropdown
              _loadingDrivers
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Assign Driver'),
                          value: _selectedDriverId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('No Driver (Unassigned)'),
                            ),
                            ..._drivers.map((driver) {
                              return DropdownMenuItem<String>(
                                value: driver['id'],
                                child: Text('${driver['name']} (${driver['email']})'),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDriverId = value;
                            });
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CustomProgressIndicator(message: 'Editing Bus...')
                  : CustomButton(
                      onPressed: _editBus,
                      text: 'Save Changes',
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

