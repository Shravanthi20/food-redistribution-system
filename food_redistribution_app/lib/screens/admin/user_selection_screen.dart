import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // [NEW]
import 'package:google_maps_flutter/google_maps_flutter.dart'; // [NEW] For LatLng
import '../../models/user.dart';
import '../../services/user_service.dart';

class UserSelectionScreen extends StatefulWidget {
  final UserRole role;
  final String title;
  final LatLng? origin; // [NEW]

  const UserSelectionScreen({
    Key? key,
    required this.role,
    required this.title,
    this.origin,
  }) : super(key: key);

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getUsersByRole(widget.role);
      
      // [NEW] Proximity Sorting
      if (widget.origin != null) {
        for (var user in users) {
           // Assume user has 'location' field or we might need to fetch it
           // For this implementation, I'll check if 'location' exists in user map
           // user['location'] might be a GeoPoint from Firestore or Map
           double distance = double.infinity;
           
           if (user['location'] != null) {
              // Handle Firestore GeoPoint or Map
              double uLat = 0, uLng = 0;
              if (user['location'] is Map) {
                uLat = (user['location']['latitude'] as num).toDouble();
                uLng = (user['location']['longitude'] as num).toDouble();
              } 
              // Add other checks if needed
              
              distance = Geolocator.distanceBetween(
                widget.origin!.latitude, 
                widget.origin!.longitude, 
                uLat, 
                uLng
              );
           }
           user['distanceMetrics'] = distance;
        }

        // Sort
        users.sort((a, b) {
          double distA = a['distanceMetrics'] as double;
          double distB = b['distanceMetrics'] as double;
          return distA.compareTo(distB);
        });
      }

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final email = (user['email'] ?? '').toString().toLowerCase();
        final name = (user['name'] ?? user['email'] ?? '').toString().toLowerCase();
        return email.contains(query) || name.contains(query);
      }).toList();
    });
  }

  String _formatDistance(double meters) {
    if (meters == double.infinity) return '';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (widget.origin != null)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16),
               child: Row(
                 children: const [
                   Icon(Icons.sort, size: 16, color: Colors.blue),
                   SizedBox(width: 4),
                   Text('Sorted by proximity', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final id = user['id'];
                          final displayName = user['name'] ?? user['email'] ?? 'Unknown User'; 
                          final subtitle = user['email'] ?? '';
                          
                          final distanceVal = user['distanceMetrics'] as double? ?? double.infinity;
                          final distanceStr = _formatDistance(distanceVal);

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(displayName[0].toUpperCase()),
                            ),
                            title: Text(displayName),
                            subtitle: Text('$subtitle\n$distanceStr'),
                            isThreeLine: distanceStr.isNotEmpty,
                            onTap: () {
                              Navigator.pop(context, id);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
