import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartbus/screens/welcome_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_widgets.dart';
import '../bus_management/add_bus_screen.dart'; // Import AddBusScreen
import '../bus_management/bus_list_screen.dart'; // Import BusListScreen
import '../booking/booking_list_screen.dart';  // Import BookingListScreen
import 'package:flutter_map/flutter_map.dart'; // Import Flutter Map
import 'package:latlong2/latlong.dart'; // Import LatLng

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  String? _userName;
  List<Map<String, dynamic>> _buses =
  []; // To store bus data for the map, now used.
  bool _isLoading = true;
  final MapController _mapController = MapController();
  LatLng _mapCenter = const LatLng(8.5241, 76.9366);  // Default to Thiruvananthapuram

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    _user = _authService.currentUser;
    if (_user != null) {
      final userDetails = await _firestoreService.getUserDetails(_user!.uid);
      if (userDetails != null) {
        setState(() {
          _userName = userDetails.name;
        });
      }
    }
    _buses = await _firestoreService.getAllBuses(); //get all buses
    if (_buses.isNotEmpty) {
      //calculate average
      double totalLatitude = 0;
      double totalLongitude = 0;
      for (var bus in _buses) {
        final GeoPoint? location = bus['currentLocation'];
        if (location != null) {
          totalLatitude += location.latitude;
          totalLongitude += location.longitude;
        }
      }
      if (totalLatitude > 0 && totalLongitude > 0) {
        _mapCenter = LatLng(
            totalLatitude / _buses.length, totalLongitude / _buses.length);
      }
    }
    setState(() => _isLoading = false);
  }

  //show all buses
  Widget _showAllBusesOnMap() {
    if (_buses.isNotEmpty) {
      return SizedBox(
        height: 300,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _mapCenter,
            zoom: 10.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: _buses.map((bus) {
                final GeoPoint? location = bus['currentLocation'];
                if (location != null) {
                  final LatLng busLocation =
                  LatLng(location.latitude, location.longitude);
                  return Marker(
                    width: 40.0,
                    height: 40.0,
                    point: busLocation,
                    child: const Icon(Icons.bus_alert,
                        color: Colors.red, size: 40),
                  );
                }
                return Marker(
                  //show buses without location
                  width: 40.0,
                  height: 40.0,
                  point: _mapCenter,
                  child: const Icon(Icons.bus_alert, color: Colors.grey, size: 40),
                );
              }).toList(),
            ),
          ],
        ),
      );
    } else {
      return const Text('No buses available.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
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
              const Text(
                'Admin Actions:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _showAllBusesOnMap(), //show all buses
              const SizedBox(height: 20),
              CustomButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddBusScreen(),
                    ),
                  );
                },
                text: 'Add New Bus',
              ),
              const SizedBox(height: 15),
              CustomButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BusListScreen(),
                    ),
                  );
                },
                text: 'View/Edit Buses',
              ),
              const SizedBox(height: 15),
              CustomButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BookingListScreen(),
                    ),
                  );
                },
                text: 'View All Bookings',
              ),
              // Add more admin actions here
            ],
          ),
        ),
      ),
    );
  }
}

