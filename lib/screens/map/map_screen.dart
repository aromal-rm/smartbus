import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(8.5241, 76.9366); // Default to Thiruvananthapuram
  List<Marker> _busMarkers = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchBusLocations();
    _determinePosition(); //get user location
  }

  // Show route when the bus icon is pressed
  void _showRoute(LatLng destination) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Handle the case when the user denies the location permission.
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      LatLng source = LatLng(position.latitude, position.longitude);
      String url = "https://www.google.com/maps/dir/?api=1&origin=${source.latitude},${source.longitude}&destination=${destination.latitude},${destination.longitude}";
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Google Maps.'))
        );
      }

      print('Showing route from ${source.latitude},${source.longitude} to ${destination.latitude},${destination.longitude}');
    } catch (e) {
      print('Error showing route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open map. Please try again.'))
      );
    }
  }

  //get user location
  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Handle the case when the user denies the location permission.
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error determining position: $e');
      // Handle location error (e.g., show a message to the user)
    }
  }

  Future<void> _fetchBusLocations() async {
    try {
      final QuerySnapshot snapshot =
      await _firestore.collection('buses').get();
      setState(() {
        _busMarkers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final GeoPoint? location = data['currentLocation'];
          if (location != null) {
            return Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(location.latitude, location.longitude),
              child: IconButton(
                icon: const Icon(Icons.bus_alert),
                color: Colors.red,
                onPressed: () {
                  _showRoute(LatLng(location.latitude, location.longitude));
                },
              ),
            );
          } else {
            return Marker(
              width: 40.0,
              height: 40.0,
              point: _center, // show in the center
              child: const IconButton(
                icon: Icon(Icons.bus_alert),
                color: Colors.grey,
                onPressed: null, // replaced empty function with null
              ),
            );
          }
        }).toList();
      });
    } catch (e) {
      print('Error fetching bus locations: $e');
      // Handle error (e.g., show a message to the user)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Locations'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _center,
          zoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _busMarkers,
          ),
        ],
      ),
    );
  }
}

