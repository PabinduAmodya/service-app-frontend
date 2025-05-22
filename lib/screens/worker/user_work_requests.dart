import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UserWorkRequestsPage extends StatefulWidget {
  final String workerId;

  const UserWorkRequestsPage({Key? key, required this.workerId}) : super(key: key);

  @override
  _UserWorkRequestsPageState createState() => _UserWorkRequestsPageState();
}

class _UserWorkRequestsPageState extends State<UserWorkRequestsPage> {
  List<dynamic> _workRequests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWorkRequests();
  }

  Future<void> _fetchWorkRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/requests/worker/${widget.workerId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        // Ensure we have a list of work requests
        setState(() {
          _workRequests = responseBody is List 
              ? responseBody 
              : (responseBody['requests'] is List 
                  ? responseBody['requests'] 
                  : []);
          _isLoading = false;
        });
      } else {
        final errorBody = json.decode(response.body);
        setState(() {
          _errorMessage = errorBody['error'] ?? 'Failed to load work requests';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Fetch Work Requests Error: $e');
    }
  }

  Future<void> _updateWorkRequestStatus(String requestId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.patch(
        Uri.parse('http://10.0.2.2:5000/api/requests/$requestId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        // Update the local state to reflect the status change
        setState(() {
          final index = _workRequests.indexWhere((request) => 
            request['requestId'] == requestId || request['id'] == requestId);
          
          if (index != -1) {
            _workRequests[index]['status'] = status;
          }
        });

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Work request status updated to $status'),
            backgroundColor: Colors.yellow[700],
          ),
        );
      } else {
        // Parse error message from the response
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to update status');
      }
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusUpdateDialog(BuildContext context, String requestId, String currentStatus) {
    // Determine available status options based on current status and user role
    List<String> availableStatuses = [];
    
    // For workers or requesters
    if (currentStatus == 'pending') {
      availableStatuses = ['accepted', 'rejected'];
    } else if (currentStatus == 'accepted') {
      availableStatuses = ['completed'];
    } else if (currentStatus == 'pending' || currentStatus == 'accepted') {
      availableStatuses = ['cancelled'];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Work Request Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableStatuses.map((status) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateWorkRequestStatus(requestId, status);
                    },
                    child: Text(status.toUpperCase()),
                  ),
                )
              ).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Show detailed view with map
  void _showRequestDetailsWithMap(BuildContext context, dynamic request) {
    // Parse location coordinates from the request
    LatLng locationCoords;
    
    try {
      // First try to parse coordinates from the request
      if (request['coordinates'] != null) {
        // If coordinates are stored in a nested object
        if (request['coordinates'] is Map) {
          double lat = double.parse(request['coordinates']['latitude'].toString());
          double lng = double.parse(request['coordinates']['longitude'].toString());
          locationCoords = LatLng(lat, lng);
        } 
        // If coordinates are stored as a string like "lat, lng"
        else if (request['coordinates'] is String) {
          List<String> parts = request['coordinates'].toString().split(',');
          if (parts.length == 2) {
            double lat = double.parse(parts[0].trim());
            double lng = double.parse(parts[1].trim());
            locationCoords = LatLng(lat, lng);
          } else {
            // Default fallback location if parsing fails
            locationCoords = LatLng(37.7749, -122.4194); // San Francisco as default
          }
        } else {
          // Default fallback location if coordinates format is unknown
          locationCoords = LatLng(37.7749, -122.4194);
        }
      } 
      // Try to parse from location field if it might contain coordinates
      else if (request['location'] != null && request['location'].toString().contains(',')) {
        try {
          List<String> parts = request['location'].toString().split(',');
          if (parts.length == 2) {
            double lat = double.parse(parts[0].trim());
            double lng = double.parse(parts[1].trim());
            locationCoords = LatLng(lat, lng);
          } else {
            // Default fallback location
            locationCoords = LatLng(37.7749, -122.4194);
          }
        } catch (e) {
          // Default fallback location if parsing fails
          locationCoords = LatLng(37.7749, -122.4194);
        }
      } else {
        // Default fallback location if no location data
        locationCoords = LatLng(37.7749, -122.4194);
      }
    } catch (e) {
      print('Location parsing error: $e');
      // Default fallback location
      locationCoords = LatLng(37.7749, -122.4194);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _safeGetString(request, 'title', 'Work Request Details'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_safeGetString(request, 'status', '')),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _safeGetString(request, 'status', 'Unknown').toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_safeGetString(request, 'description', 'No description provided')),
                  SizedBox(height: 15),
                  Text(
                    'Client:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_safeGetString(request, 'userName', 'Unknown client')),
                  SizedBox(height: 5),
                  Text(_safeGetString(request, 'userPhone', 'No phone provided')),
                  SizedBox(height: 15),
                  Text(
                    'Deadline:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_formatDeadline(request['deadline'])),
                  SizedBox(height: 15),
                  Text(
                    'Location:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_safeGetString(request, 'location', 'Location not specified')),
                  SizedBox(height: 15),
                  
                  // Map display section
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              center: locationCoords,
                              zoom: 14.0,
                              interactiveFlags: InteractiveFlag.all,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: locationCoords,
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Attribution
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                '© OpenStreetMap contributors',
                                style: TextStyle(fontSize: 8, color: Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  // Actions section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Update status button - only show if status allows updates
                      if (_safeGetString(request, 'status', '') == 'pending' || 
                          _safeGetString(request, 'status', '') == 'accepted')
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[700],
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showStatusUpdateDialog(
                              context, 
                              request['requestId'] ?? request['id'],
                              request['status']
                            );
                          },
                          child: Text('Update Status'),
                        ),
                      
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Updated color method with default return
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey; // Default fallback
    }
  }

  // Safe string retrieval method with default return
  String _safeGetString(dynamic data, String key, [String defaultValue = '']) {
    if (data is Map && data.containsKey(key)) {
      return data[key]?.toString() ?? defaultValue;
    }
    return defaultValue;
  }

  // Updated deadline formatting with more robust error handling
  String _formatDeadline(dynamic deadlineInput) {
    if (deadlineInput == null) return 'No deadline';
    
    try {
      String? deadlineString;
      if (deadlineInput is String) {
        deadlineString = deadlineInput;
      } else if (deadlineInput is Map) {
        deadlineString = deadlineInput['deadline']?.toString();
      }

      if (deadlineString == null) return 'No deadline';

      final DateTime deadline = DateTime.parse(deadlineString);
      return '${deadline.day}/${deadline.month}/${deadline.year}';
    } catch (e) {
      print('Deadline parsing error: $e');
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work Requests'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : _workRequests.isEmpty
                  ? Center(
                      child: Text(
                        'No work requests found',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _workRequests.length,
                      itemBuilder: (context, index) {
                        final request = _workRequests[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(
                              _safeGetString(request, 'title', 'Untitled Request'),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _safeGetString(request, 'description', 'No description'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _safeGetString(request, 'location', 'Location not specified'),
                                        style: TextStyle(color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'Status: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _safeGetString(request, 'status', 'Unknown'),
                                      style: TextStyle(
                                        color: _getStatusColor(_safeGetString(request, 'status', '')),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: request['deadline'] != null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      Text(
                                        _formatDeadline(request['deadline']),
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  )
                                : null,
                            onTap: () {
                              // Show detailed view with map instead of just status update dialog
                              _showRequestDetailsWithMap(context, request);
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}