import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class WorkRequestsPage extends StatefulWidget {
  final String userToken;

  const WorkRequestsPage({super.key, required this.userToken});

  @override
  _WorkRequestsPageState createState() => _WorkRequestsPageState();
}

class _WorkRequestsPageState extends State<WorkRequestsPage> {
  List<dynamic> workRequests = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchWorkRequests();
  }

  Future<void> fetchWorkRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      var response = await Dio().get(
        'http://10.0.2.2:5000/api/requests/user',
        options: Options(headers: {'Authorization': 'Bearer ${widget.userToken}'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          workRequests = response.data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.data['error'] ?? "Failed to load work requests.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching work requests: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Work Requests"),
        backgroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: fetchWorkRequests,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
                : workRequests.isEmpty
                    ? Center(child: Text("No work requests found."))
                    : ListView.builder(
                        itemCount: workRequests.length,
                        itemBuilder: (context, index) {
                          var request = workRequests[index];
                          return Card(
                            margin: EdgeInsets.all(10),
                            child: ListTile(
                              title: Text(request['title'] ?? 'No Title', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Description: ${request['description'] ?? 'No Description'}"),
                                  Text("Location: ${request['location'] ?? 'No Location'}"),
                                  Text("Status: ${request['status'] ?? 'Unknown'}", style: TextStyle(color: Colors.blue)),
                                  if (request['deadline'] != null && request['deadline']['_seconds'] != null)
                                  Text(
                                  "Deadline: ${DateTime.fromMillisecondsSinceEpoch(request['deadline']['_seconds'] * 1000)}",
                                   style: TextStyle(color: Colors.red),
                                   )
                                  
                                ],
                              ),
                              onTap: () {
                                // Navigate to detailed request view if needed
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  
}