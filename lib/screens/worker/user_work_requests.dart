import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
            backgroundColor: Colors.green,
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
                                    Text(
                                      _safeGetString(request, 'location', 'Location not specified'),
                                      style: TextStyle(color: Colors.grey),
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
                              // Show dialog with status update options
                              _showStatusUpdateDialog(
                                context, 
                                request['requestId'] ?? request['id'],
                                request['status']
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}