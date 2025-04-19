import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? uid;
  String? name;
  String? email;
  String? role;
  String? assignedBusId;
  Timestamp? createdAt;

  UserModel({
    this.uid,
    this.name,
    this.email,
    this.role,
    this.assignedBusId,
    this.createdAt,
  });

  // Factory constructor to create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Add null check
    if (data == null) {
      // Handle the case where the document data is null
      return UserModel(); // Or throw an exception, or return null, depending on your needs
    }
    return UserModel(
      uid: doc.id,
      name: data['name'],
      email: data['email'],
      role: data['role'],
      assignedBusId: data['assignedBusId'],
      createdAt: data['createdAt'],
    );
  }

  // Convert UserModel to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'assignedBusId': assignedBusId,
      'createdAt': createdAt,
    };
  }
}
