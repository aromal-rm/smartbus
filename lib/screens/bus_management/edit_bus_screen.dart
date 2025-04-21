import 'package:flutter/material.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/place_search_field.dart';
import '../../widgets/time_picker_field.dart';

class EditBusScreen extends StatefulWidget {
  final String busId;
  final String busNumber;
  final String route;
  final int capacity;
  final String? driverId;
  final String? startingPoint;
  final String? endPoint;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final String? departureTime;
  final String? arrivalTime;
  final String? timeSlot;

  const EditBusScreen({
    super.key,
    required this.busId,
    required this.busNumber,
    required this.route,
    required this.capacity,
    this.driverId,
    this.startingPoint,
    this.endPoint,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.departureTime,
    this.arrivalTime,
    this.timeSlot,
  });

  @override
  _EditBusScreenState createState() => _EditBusScreenState();
}

class _EditBusScreenState extends State<EditBusScreen> {
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
  
  // Location data
  Place? _startPlace;
  Place? _endPlace;
  
  // Time slot selection
  String _selectedTimeSlot = 'AN';
  final List<String> _timeSlots = ['AN', 'FN'];

  // Driver related variables
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
    
    // Initialize new fields
    _startPointController.text = widget.startingPoint ?? '';
    _endPointController.text = widget.endPoint ?? '';
    _departureTimeController.text = widget.departureTime ?? '';
    _arrivalTimeController.text = widget.arrivalTime ?? '';
    _selectedTimeSlot = widget.timeSlot ?? 'AN';
    
    _loadDrivers();
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
    _startPointController.dispose();
    _endPointController.dispose();
    _departureTimeController.dispose();
    _arrivalTimeController.dispose();
    super.dispose();
  }

  // Update the bus data in Firestore
  Future<void> _updateBus() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Check if locations have changed and validate coordinates
        final bool hasStartLocationChanged = _startPointController.text != widget.startingPoint;
        final bool hasEndLocationChanged = _endPointController.text != widget.endPoint;

        // Validate start location
        if (hasStartLocationChanged && _startPlace == null) {
          throw 'Please select a valid starting point';
        }

        // Validate end location 
        if (hasEndLocationChanged && _endPlace == null) {
          throw 'Please select a valid ending point';
        }

        // Use updated or existing coordinates
        final startLatitude = hasStartLocationChanged ? _startPlace!.lat : widget.startLat;
        final startLongitude = hasStartLocationChanged ? _startPlace!.lon : widget.startLng;
        final endLatitude = hasEndLocationChanged ? _endPlace!.lat : widget.endLat;
        final endLongitude = hasEndLocationChanged ? _endPlace!.lon : widget.endLng;

        // Validate all coordinates are non-null
        if (startLatitude == null || startLongitude == null || 
            endLatitude == null || endLongitude == null) {
          throw 'Invalid location coordinates';
        }

        await _firestoreService.editBus(
          busId: widget.busId,
          busNumber: _busNumberController.text.trim(),
          route: _routeController.text.trim(),
          capacity: int.parse(_capacityController.text.trim()),
          driverId: _selectedDriverId,
          startingPoint: _startPointController.text.trim(),
          endPoint: _endPointController.text.trim(),
          startLat: startLatitude,
          startLng: startLongitude,
          endLat: endLatitude, 
          endLng: endLongitude,
          departureTime: _departureTimeController.text.trim(),
          arrivalTime: _arrivalTimeController.text.trim(),
          timeSlot: _selectedTimeSlot,
        );
        
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus updated successfully!')),
        );
      } catch (error) {
        _showErrorDialog(error.toString());
      } finally {
        setState(() => _isLoading = false);
      }
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
      appBar: AppBar(
        title: const Text('Edit Bus'),
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
                        initialValue: widget.startingPoint,
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
                        initialValue: widget.endPoint,
                        onPlaceSelected: (place) {
                          setState(() {
                            _endPlace = place;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Time Slot',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedTimeSlot,
                        items: _timeSlots.map((slot) {
                          return DropdownMenuItem(
                            value: slot,
                            child: Text(slot == 'AN' ? 'Afternoon' : 'Forenoon'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTimeSlot = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _updateBus,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

