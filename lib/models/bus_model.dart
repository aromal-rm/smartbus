class BusModel {
  final String id;
  final String busNumber;
  final String startingPoint;
  final String endPoint;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String departureTime;
  final String arrivalTime;
  final String timeSlot; // AN or FN
  final String route;
  final int capacity;
  final String? driverId;

  BusModel({
    required this.id,
    required this.busNumber,
    required this.startingPoint,
    required this.endPoint,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.departureTime,
    required this.arrivalTime,
    required this.timeSlot,
    required this.route,
    required this.capacity,
    this.driverId,
  });

  // Create a Bus from Firestore data
  factory BusModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BusModel(
      id: id,
      busNumber: data['busNumber'] ?? '',
      startingPoint: data['startingPoint'] ?? '',
      endPoint: data['endPoint'] ?? '',
      startLat: data['startLat'] ?? 0.0,
      startLng: data['startLng'] ?? 0.0,
      endLat: data['endLat'] ?? 0.0,
      endLng: data['endLng'] ?? 0.0,
      departureTime: data['departureTime'] ?? '',
      arrivalTime: data['arrivalTime'] ?? '',
      timeSlot: data['timeSlot'] ?? 'AN',
      route: data['route'] ?? '',
      capacity: data['capacity'] ?? 0,
      driverId: data['driverId'],
    );
  }

  // Convert Bus to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'busNumber': busNumber,
      'startingPoint': startingPoint,
      'endPoint': endPoint,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'timeSlot': timeSlot,
      'route': route,
      'capacity': capacity,
      'driverId': driverId,
    };
  }
}
