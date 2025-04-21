import 'package:flutter/material.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/place_search_field.dart';
import '../../widgets/time_picker_field.dart';

class AddBusScreen extends StatefulWidget {
  const AddBusScreen({super.key});

  @override
  _AddBusScreenState createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _endPointController = TextEditingController();
  final TextEditingController _departureTimeController = TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  
  // Location data - updated to use OpenStreetMap
  Place? _startPlace;
  Place? _endPlace;
  
  // Time slot selection
  String _selectedTimeSlot = 'AN'; // Default to Afternoon
  final List<String> _timeSlots = ['AN', 'FN']; // AN = Afternoon, FN = Forenoon

  List<Map<String, dynamic>> _drivers = [];
  String? _selectedDriverId;
  bool _loadingDrivers = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final drivers = await _firestoreService.getDrivers();
      setState(() {
        _drivers = drivers;
        _loadingDrivers = false;
      });
    } catch (error) {
      _showErrorDialog('Failed to load drivers: $error');
      setState(() => _loadingDrivers = false);
    }
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _routeController.dispose();
    _capacityController.dispose();
    _startPointController.dispose();
    _endPointController.dispose();
    _departureTimeController.dispose();
    _arrivalTimeController.dispose();
    super.dispose();
  }

  void _addBus() async {
    if (_formKey.currentState!.validate()) {
      if (_startPlace == null || _endPlace == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select valid locations for starting and ending points')),
        );
        return;
      }
      
      setState(() => _isLoading = true);
      try {
        await _firestoreService.addBus(
          busNumber: _busNumberController.text.trim(),
          route: _routeController.text.trim(),
          capacity: int.parse(_capacityController.text.trim()),
          startingPoint: _startPointController.text.trim(),
          endPoint: _endPointController.text.trim(),
          startLat: _startPlace!.lat,
          startLng: _startPlace!.lon,
          endLat: _endPlace!.lat,
          endLng: _endPlace!.lon,
          departureTime: _departureTimeController.text.trim(),
          arrivalTime: _arrivalTimeController.text.trim(),
          timeSlot: _selectedTimeSlot,
          driverId: _selectedDriverId,
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
              Navigator.of(context).pop(); // Go back to the previous screen
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
      appBar: AppBar(
        title: const Text('Add New Bus'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
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
                      const SizedBox(height: 16),
                      PlaceSearchField(
                        controller: _startPointController,
                        labelText: 'Starting Point',
                        onPlaceSelected: (place) {
                          setState(() {
                            _startPlace = place;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      PlaceSearchField(
                        controller: _endPointController,
                        labelText: 'Ending Point',
                        onPlaceSelected: (place) {
                          setState(() {
                            _endPlace = place;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _routeController,
                        labelText: 'Route Description',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter route description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _capacityController,
                        labelText: 'Capacity',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter capacity';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TimePickerField(
                        controller: _departureTimeController,
                        labelText: 'Departure Time',
                      ),
                      const SizedBox(height: 16),
                      TimePickerField(
                        controller: _arrivalTimeController,
                        labelText: 'Arrival Time',
                      ),
                      const SizedBox(height: 16),
                      if (_loadingDrivers)
                        const CircularProgressIndicator()
                      else
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Assign Driver',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedDriverId,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No Driver'),
                            ),
                            ..._drivers.map((driver) => DropdownMenuItem(
                              value: driver['id'],
                              child: Text(driver['name']),
                            )),
                          ],
                          onChanged: (value) => setState(() => _selectedDriverId = value),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _addBus,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Bus'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBus,
        child: const Icon(Icons.save),
      ),
    );
  }
}

