import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_widgets.dart';
import 'edit_bus_screen.dart'; // Import EditBusScreen
// import 'package:cloud_firestore/cloud_firestore.dart';

class BusListScreen extends StatefulWidget {
  const BusListScreen({super.key});

  @override
  _BusListScreenState createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _buses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _buses = await _firestoreService.getAllBuses();
    } catch (e) {
      // Handle error
      print('Error loading buses: $e');
      _showErrorDialog('Failed to load buses: $e'); // Show error to user
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      appBar: AppBar(title: const Text('Bus List')),
      body: _isLoading
          ? const CustomProgressIndicator(message: 'Loading buses...')
          : _buses.isEmpty
              ? const Center(child: Text('No buses available.'))
              : ListView.builder(
                  itemCount: _buses.length,
                  itemBuilder: (context, index) {
                    final bus = _buses[index];
                    return BusListItem(
                      bus: bus,
                      onEdit: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditBusScreen(
                              busId: bus['id'],
                              busNumber: bus['busNumber'] ?? '',
                              route: bus['route'] ?? '',
                              capacity: bus['capacity'] ?? 0,
                            ),
                          ),
                        ).then((_) {
                          // Refresh the list after editing
                          _loadBuses();
                        });
                      },
                      onDelete: () {
                        _showDeleteConfirmationDialog(bus['id']);
                      },
                    );
                  },
                ),
    );
  }

  void _showDeleteConfirmationDialog(String busId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus'),
        content: const Text('Are you sure you want to delete this bus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog
              setState(() {
                _isLoading = true;
              });
              try {
                await _firestoreService.deleteBus(busId: busId);
                // Refresh the list after deletion
                await _loadBuses();
              } catch (e) {
                _showErrorDialog('Failed to delete bus: $e');
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class BusListItem extends StatelessWidget {
  final Map<String, dynamic> bus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BusListItem({super.key, 
    required this.bus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
     String busId = bus['id'] ?? '';
    String busNumber = bus['busNumber'] ?? 'N/A';
    String route = bus['route'] ?? 'N/A';
    int capacity = bus['capacity'] ?? 0;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Bus ID: $busId', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Number: $busNumber'),
                Text('Route: $route'),
                Text('Capacity: $capacity'),
              ],
            ),
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

