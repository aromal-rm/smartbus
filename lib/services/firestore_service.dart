import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartbus/services/auth_service.dart';
import '../models/user_model.dart'; // Import the user model
import 'package:geolocator/geolocator.dart'; // Import for location
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import for Timer

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';
  final String _busesCollection = 'buses';
  final String _bookingsCollection = 'bookings';
  final AuthService _authService = AuthService(); // Use AuthService

  // Add a new bus
  Future<void> addBus({
    required String busNumber,
    required String route,
    required int capacity,
  }) async {
    try {
      await _firestore.collection(_busesCollection).doc().set({
        'busNumber': busNumber,
        'route': route,
        'capacity': capacity,
        'currentLocation': const GeoPoint(0, 0), // Initial location
        'driverId': null, // Initially no driver assigned
        'crowdLevel': 'Low',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding bus: $e');
      throw 'Failed to add bus: $e';
    }
  }

  // Edit an existing bus
  Future<void> editBus({
    required String busId,
    required String busNumber,
    required String route,
    required int capacity,
    String? driverId, // Add driverId parameter
  }) async {
    try {
      // Create bus data map
      final Map<String, dynamic> busData = {
        'busNumber': busNumber,
        'route': route,
        'capacity': capacity,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add driverId if it's not null
      if (driverId != null) {
        busData['driverId'] = driverId;
      } else {
        // Remove driver assignment if null
        busData['driverId'] = FieldValue.delete();
      }

      // Update the bus document
      await _firestore.collection('buses').doc(busId).update(busData);
    } catch (e) {
      throw 'Failed to edit bus: $e';
    }
  }

  // Delete a bus
  Future<void> deleteBus({required String busId}) async {
    try {
      await _firestore.collection(_busesCollection).doc(busId).delete();
    } catch (e) {
      print('Error deleting bus: $e');
      throw 'Failed to delete bus: $e';
    }
  }

  // Get all buses
  Future<List<Map<String, dynamic>>> getAllBuses() async {
    final snapshot = await FirebaseFirestore.instance.collection('buses').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'id': doc.id, // Add the document ID as 'id'
      };
    }).toList();
  }

  // Get a single bus
  Future<Map<String, dynamic>?> getBusById(String busId) async {
    try {
      final DocumentSnapshot snapshot =
      await _firestore.collection(_busesCollection).doc(busId).get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching bus: $e');
      throw 'Failed to fetch bus: $e';
    }
  }

  // Assign a driver to a bus
  Future<void> assignDriverToBus({
    required String busId,
    required String driverId,
  }) async {
    try {
      // Update the bus document with the driver's ID
      await _firestore.collection(_busesCollection).doc(busId).update({
        'driverId': driverId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the user document with the assigned bus ID
      await _firestore.collection(_usersCollection).doc(driverId).update({
        'assignedBusId': busId,
      });
    } catch (e) {
      print('Error assigning driver: $e');
      throw 'Failed to assign driver: $e';
    }
  }

  // Get bookings for a bus
  Future<List<Map<String, dynamic>>> getBookingsForBus(String busId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_bookingsCollection)
          .where('busId', isEqualTo: busId)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching bookings for bus: $e');
      throw 'Failed to fetch bookings for bus: $e';
    }
  }

  // Get all bookings
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_bookingsCollection).get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching all bookings: $e');
      throw 'Failed to fetch all bookings: $e';
    }
  }

  // Get user details
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      final DocumentSnapshot documentSnapshot =
      await _firestore.collection(_usersCollection).doc(uid).get();
      if (documentSnapshot.exists) {
        return UserModel.fromFirestore(documentSnapshot);
      }
      return null;
    } catch (e) {
      print('Error fetching user details: $e');
      throw 'Failed to fetch user details: $e';
    }
  }

  // Book a ticket
  Future<void> bookTicket({
    required String userId,
    required String busId,
    required String source,
    required String destination,
    required int seats,
    required String time, // Added time
  }) async {
    try {
      await _firestore.collection(_bookingsCollection).doc().set({
        'userId': userId,
        'busId': busId,
        'source': source,
        'destination': destination,
        'seats': seats,
        'time': time, // Save the time
        'status': 'confirmed', // Initial status
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Optionally update bus capacity here
      await _updateBusCapacity(busId, seats);

    } catch (e) {
      print('Error booking ticket: $e');
      throw 'Failed to book ticket: $e';
    }
  }

  // Update bus capacity after booking
  Future<void> _updateBusCapacity(String busId, int bookedSeats) async {
    try {
      final DocumentSnapshot busSnapshot =
      await _firestore.collection(_busesCollection).doc(busId).get();
      if (busSnapshot.exists) {
        final data = busSnapshot.data() as Map<String, dynamic>;
        final int currentCapacity = data['capacity'] as int;
        final int newCapacity = currentCapacity - bookedSeats;
        if (newCapacity >= 0) {
          await _firestore.collection(_busesCollection).doc(busId).update({
            'capacity': newCapacity,
          });
        } else {
          throw 'Not enough seats available on this bus.'; // rollback
        }
      }
    } catch (e) {
      print('Error updating bus capacity: $e');
      throw 'Failed to update bus capacity: $e';
    }
  }

  // Get bookings for a user
  Future<List<Map<String, dynamic>>> getBookingsForUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching bookings for user: $e');
      throw 'Failed to fetch bookings for user: $e';
    }
  }

  // Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      final DocumentSnapshot bookingSnapshot = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      if(!bookingSnapshot.exists){
        throw "Booking does not exist";
      }
      final data = bookingSnapshot.data() as Map<String, dynamic>;
      final String busId = data['busId'];
      final int seats = data['seats'];

      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': 'cancelled',
      });
      //update bus capacity
      await _increaseBusCapacity(busId, seats);
    } catch (e) {
      print('Error cancelling booking: $e');
      throw 'Failed to cancel booking: $e';
    }
  }

  // Increase bus capacity after cancellation
  Future<void> _increaseBusCapacity(String busId, int cancelledSeats) async {
    try {
      final DocumentSnapshot busSnapshot =
      await _firestore.collection(_busesCollection).doc(busId).get();
      if (busSnapshot.exists) {
        final data = busSnapshot.data() as Map<String, dynamic>;
        final int currentCapacity = data['capacity'] as int;
        final int newCapacity = currentCapacity + cancelledSeats;
        await _firestore.collection(_busesCollection).doc(busId).update({
          'capacity': newCapacity,
        });
      }
    } catch (e) {
      print('Error increasing bus capacity: $e');
      throw 'Failed to increase bus capacity: $e';
    }
  }

  // Update bus location
  Future<void> updateBusLocation({
    required String busId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore.collection(_busesCollection).doc(busId).update({
        'currentLocation': GeoPoint(latitude, longitude),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating bus location: $e');
      throw 'Failed to update bus location: $e';
    }
  }

  //update crowd level
  Future<void> updateCrowdLevel({
    required String busId,
    required String crowdLevel,
  }) async {
    try {
      await _firestore.collection(_busesCollection).doc(busId).update({
        'crowdLevel': crowdLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating crowd level: $e');
      throw 'Failed to update crowd level: $e';
    }
  }

  // Function to simulate crowd level (optional, as you mentioned)
  String estimateCrowdLevel(int currentHour, String busStop) {
    if ((currentHour >= 8 && currentHour <= 9) && busStop == "Chinnakkada") {
      return "High";
    } else if (currentHour >= 10 && currentHour <= 11) {
      return "Medium";
    } else {
      return "Low";
    }
  }

  // Get all drivers
  Future<List<Map<String, dynamic>>> getAllDrivers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
      };
    }).toList();
  }

  // Method to get all drivers from Firestore
  Future<List<Map<String, dynamic>>> getDrivers() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? 'No email',
        };
      }).toList();
    } catch (e) {
      throw 'Failed to load drivers: $e';
    }
  }

  // Get all buses assigned to a specific driver
  Future<List<Map<String, dynamic>>> getBusesForDriver(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('buses')
          .where('driverId', isEqualTo: driverId)
          .get();
          
      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error getting buses for driver: $e');
      return [];
    }
  }
}

