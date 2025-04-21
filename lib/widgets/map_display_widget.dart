import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

class MapDisplayWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String? title;
  final List<MapMarker>? markers;
  final bool showCurrentLocation;
  final double initialZoom;

  const MapDisplayWidget({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.title,
    this.markers,
    this.showCurrentLocation = false,
    this.initialZoom = 13.0,
  });

  @override
  State<MapDisplayWidget> createState() => _MapDisplayWidgetState();
}

class _MapDisplayWidgetState extends State<MapDisplayWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    // Validate coordinates
    final validLat = widget.initialLat.isFinite && widget.initialLat != 0.0;
    final validLng = widget.initialLng.isFinite && widget.initialLng != 0.0;
    
    // Use default coordinates if invalid
    final initialCenter = (validLat && validLng) 
        ? LatLng(widget.initialLat, widget.initialLng)
        : LatLng(10.8505, 76.2711); // Default to Kerala center
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: widget.initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.smartbus',
          maxZoom: 19,
          // Add attribution as required by OpenStreetMap license
          additionalOptions: const {
            'attribution': '© OpenStreetMap contributors',
          },
        ),
        if (widget.showCurrentLocation)
          CurrentLocationLayer(
            style: const LocationMarkerStyle(
              marker: DefaultLocationMarker(
                color: Colors.blue,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              accuracyCircleColor: Colors.blue,
            ),
          ),
        if (widget.markers != null && widget.markers!.isNotEmpty)
          MarkerLayer(
            markers: widget.markers!
                .map(
                  (marker) => Marker(
                    point: LatLng(marker.latitude, marker.longitude),
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Icon(
                          marker.icon ?? Icons.location_on,
                          color: marker.color ?? Colors.red,
                          size: 30,
                        ),
                        if (marker.label != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            color: Colors.white.withOpacity(0.8),
                            child: Text(
                              marker.label!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class MapMarker {
  final double latitude;
  final double longitude;
  final String? label;
  final IconData? icon;
  final Color? color;

  MapMarker({
    required this.latitude,
    required this.longitude,
    this.label,
    this.icon,
    this.color,
  });
}
