import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_widgets.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'package:permission_handler/permission_handler.dart'; // Import PermissionHandler
import 'dart:async'; // Import Timer
import 'package:flutter_map/flutter_map.dart'; // Import Flutter Map
import 'package:latlong2/latlong.dart'; // Import LatLng
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // Import PolylinePoints
// import '../../../.config.dart'; // Import the config.dart file
import 'package:url_launcher/url_launcher.dart'; // Import for launching maps
// import '../welcome/welcome_screen.dart'; // Import for WelcomeScreen
import '../welcome_screen.dart';

// Define a constant for Google API key - replace with your actual key in production
const String googleApiKey = ''; // Add your Google Maps API key here

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  _DriverDashboardState createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  String? _userName;
  String? _assignedBusId;
  Map<String, dynamic>? _assignedBus;
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _assignedBuses = []; // Added list for all assigned buses
  bool _isLoading = true;
  bool _isUpdatingLocation = false;
  //Location
  LocationPermission? _permission;
  Position? _currentPosition;
  late Timer _locationUpdateTimer;
  final MapController _mapController = MapController();
  LatLng _currentCameraPosition = LatLng(8.5241, 76.9366);
  List<LatLng> _polylineCoordinates = [];
  bool _isCrowdLevelHigh = false; // Track crowd level
  String _crowdLevel = 'Low';

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {});
    _locationUpdateTimer.cancel();
  }

  @override
  void dispose() {
    _locationUpdateTimer.cancel();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    setState(() => _isLoading = true);
    _user = _authService.currentUser;
    if (_user != null) {
      final userDetails = await _firestoreService.getUserDetails(_user!.uid);
      if (userDetails != null) {
        setState(() {
          _userName = userDetails.name;
        });

        final buses = await _firestoreService.getBusesForDriver(_user!.uid);
        setState(() {
          _assignedBuses = buses;

          if (buses.isNotEmpty) {
            if (_assignedBusId != null && buses.any((bus) => bus['id'] == _assignedBusId)) {
              _assignedBus = buses.firstWhere((bus) => bus['id'] == _assignedBusId);
            } else {
              _assignedBusId = buses.first['id'];
              _assignedBus = buses.first;
            }

            _loadBookingsForBus(_assignedBusId!);
          }
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadBookingsForBus(String busId) async {
    _bookings = await _firestoreService.getBookingsForBus(busId);
    setState(() {});
  }

  void _selectBus(Map<String, dynamic> bus) {
    setState(() {
      _assignedBusId = bus['id'];
      _assignedBus = bus;
      _bookings = [];
    });
    _loadBookingsForBus(bus['id']);
  }

  Future<void> _getCurrentLocation() async {
    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
      if (_permission == LocationPermission.denied) {
        _showErrorDialog('Location permissions are denied.');
        return;
      }
    }

    if (_permission == LocationPermission.deniedForever) {
      _showErrorDialog(
          'Location permissions are permanently denied, please enable them in settings.');
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _currentCameraPosition =
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      });
      _mapController.move(
          _currentCameraPosition, 15.0);

      if (_assignedBusId != null) {
        await _firestoreService.updateBusLocation(
          busId: _assignedBusId!,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
      }
    } catch (e) {
      print("Error getting location: $e");
      _showErrorDialog('Error getting location: $e');
    }
  }

  void _startLocationUpdates() {
    setState(() {
      _isUpdatingLocation = true;
    });
    _getCurrentLocation();

    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
          if (_isUpdatingLocation) {
            await _getCurrentLocation();
          }
        });
  }

  void _stopLocationUpdates() {
    setState(() {
      _isUpdatingLocation = false;
    });
    _locationUpdateTimer.cancel();
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

  void _getDirections() async {
    if (_currentPosition != null && _assignedBus != null) {
      final double? destLatitude = _assignedBus!['currentLocation']?.latitude;
      final double? destLongitude = _assignedBus!['currentLocation']?.longitude;

      if (destLatitude != null && destLongitude != null) {
        final String origin =
            '${_currentPosition!.latitude},${_currentPosition!.longitude}';
        final String destination = '$destLatitude,$destLongitude';
        final Uri url =
            Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showErrorDialog('Could not launch maps.');
        }
      } else {
        _showErrorDialog('Bus location is not available.');
      }
    } else {
      _showErrorDialog('Current location or bus location is not available.');
    }
  }

  Widget _showBusLocationOnMap() {
    if (_assignedBus != null) {
      final double? busLatitude = _assignedBus!['currentLocation']?.latitude;
      final double? busLongitude = _assignedBus!['currentLocation']?.longitude;

      if (busLatitude != null && busLongitude != null) {
        final LatLng busLocation = LatLng(busLatitude, busLongitude);
        _getPolyline(source: _currentCameraPosition, destination: busLocation);
        return SizedBox(
          height: 300,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentCameraPosition,
              zoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: _currentCameraPosition,
                    child: const Icon(Icons.person_pin, color: Colors.blue, size: 40),
                  ),
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: busLocation,
                    child: const Icon(Icons.bus_alert, color: Colors.red, size: 40),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _polylineCoordinates,
                    strokeWidth: 5.0,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        return const Text('Bus location not available.');
      }
    } else {
      return const Text('Bus not assigned to driver.');
    }
  }

  Future<void> _getPolyline({required LatLng source, required LatLng destination}) async {
    _polylineCoordinates.clear();

    if (googleApiKey.isEmpty) {
      _polylineCoordinates = [source, destination];
      setState(() {});
      return;
    }

    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(source.latitude, source.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        _polylineCoordinates = [source, destination];
      }
      setState(() {});
    } catch (e) {
      print("Error getting polyline: $e");
      _polylineCoordinates = [source, destination];
      setState(() {});
    }
  }

  void _toggleCrowdLevel() {
    setState(() {
      _isCrowdLevelHigh = !_isCrowdLevelHigh;
      _crowdLevel = _isCrowdLevelHigh ? 'High' : 'Low';
    });
    if (_assignedBusId != null) {
      _firestoreService.updateCrowdLevel(
          busId: _assignedBusId!, crowdLevel: _crowdLevel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _stopLocationUpdates();
              await _authService.signOut();
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Welcome, $_userName!',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Text(
                'Your Assigned Buses:',
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 10),

              if (_assignedBuses.isEmpty)
                const Text('No buses assigned to you.'),

              if (_assignedBuses.isNotEmpty)
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _assignedBuses.length,
                    itemBuilder: (context, index) {
                      final bus = _assignedBuses[index];
                      final isSelected = bus['id'] == _assignedBusId;

                      return GestureDetector(
                        onTap: () => _selectBus(bus),
                        child: Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected 
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bus: ${bus['busNumber'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Route: ${bus['route'] ?? 'N/A'}',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Status: ${bus['status'] ?? 'Active'}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              if (_assignedBus != null) ...[
                Text(
                  'Selected Bus Details:',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bus Number: ${_assignedBus!['busNumber'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  'Route: ${_assignedBus!['route'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                _showBusLocationOnMap(),
                const SizedBox(height: 20),
                Text(
                  'Passenger List for Bus:',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_bookings.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return ListTile(
                        title: Text(
                            'User ID: ${booking['userId'] ?? 'N/A'}'),
                        subtitle: Text(
                            'Seats: ${booking['seats'] ?? 'N/A'}, Time: ${booking['time']}'),
                      );
                    },
                  )
                else
                  const Text('No bookings for this bus.'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isUpdatingLocation
                          ? _stopLocationUpdates
                          : _startLocationUpdates,
                      child: Text(_isUpdatingLocation
                          ? 'Stop Location Updates'
                          : 'Start Location Updates'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _getDirections,
                      child: const Text('Get Directions'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _toggleCrowdLevel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCrowdLevelHigh
                        ? Colors.red
                        : Colors.green,
                  ),
                  child: Text('Crowd Level: $_crowdLevel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

