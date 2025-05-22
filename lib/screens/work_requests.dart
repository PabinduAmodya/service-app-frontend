import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'payment.dart';

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
        // Properly handle the response depending on what the API returns
        if (response.data is List) {
          setState(() {
            workRequests = response.data;
            isLoading = false;
          });
        } else if (response.data is Map) {
          // If the API returns a map with a data field containing the array
          if (response.data['data'] != null && response.data['data'] is List) {
            setState(() {
              workRequests = response.data['data'];
              isLoading = false;
            });
          } else {
            // If there's a message in the response, use it
            setState(() {
              errorMessage = response.data['message'] ?? response.data['error'] ?? "No work requests available.";
              isLoading = false;
            });
          }
        } else {
          setState(() {
            workRequests = []; // Empty list if format is unexpected
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = response.data['error'] ?? "Failed to load work requests.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  // Function to submit a review
  Future<void> submitReview(String workerId, double rating, String comment) async {
    try {
      var response = await Dio().post(
        'http://10.0.2.2:5000/api/reviews/$workerId',
        data: {
          'rating': rating,
          'comment': comment,
        },
        options: Options(headers: {'Authorization': 'Bearer ${widget.userToken}'}),
      );

      if (response.statusCode == 201) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review submitted successfully!')),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['error'] ?? 'Failed to submit review')),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: ${e.toString()}')),
      );
    }
  }

  // Navigate to payment page
  void navigateToPayment(dynamic request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          userToken: widget.userToken,
          requestId: request['id'],
          workerName: request['workerName'] ?? 'Worker',
          requestTitle: request['title'] ?? 'Work Request',
        ),
      ),
    ).then((_) {
      // Refresh work requests when returning from payment page
      fetchWorkRequests();
    });
  }

  // Show review dialog
  void showReviewDialog(String workerId, String workerName) {
    double selectedRating = 3.0;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate $workerName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: selectedRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  selectedRating = rating;
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Comments',
                  hintText: 'Tell us about your experience...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              submitReview(workerId, selectedRating, commentController.text);
              Navigator.pop(context);
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 70,
                            color: Colors.red[300],
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Error",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 30),
                          ElevatedButton.icon(
                            icon: Icon(Icons.refresh),
                            label: Text("Try Again"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: fetchWorkRequests,
                          ),
                        ],
                      ),
                    ),
                  )
                : workRequests.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 70,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "No Work Requests Found",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "You don't have any work requests yet. Pull down to refresh or create a new request.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 30),
                              ElevatedButton.icon(
                                icon: Icon(Icons.add),
                                label: Text("Create New Request"),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onPressed: () {
                                  // Navigate to create request page
                                  // You'll need to implement this navigation
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: workRequests.length,
                        itemBuilder: (context, index) {
                          var request = workRequests[index];
                          bool isCompleted = request['status'] == 'completed';
                          
                          return Card(
                            margin: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(request['title'] ?? 'No Title', style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Description: ${request['description'] ?? 'No Description'}"),
                                      Text("Location: ${request['location'] ?? 'No Location'}"),
                                      Text(
                                        "Status: ${request['status'] ?? 'Unknown'}", 
                                        style: TextStyle(
                                          color: isCompleted ? Colors.green : Colors.blue,
                                          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                                        )
                                      ),
                                      if (request['deadline'] != null && request['deadline']['_seconds'] != null)
                                        Text(
                                          "Deadline: ${DateTime.fromMillisecondsSinceEpoch(request['deadline']['_seconds'] * 1000)}",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      if (request['workerName'] != null)
                                        Text("Worker: ${request['workerName']}"),
                                    ],
                                  ),
                                  onTap: () {
                                    // Navigate to detailed request view if needed
                                  },
                                ),
                                // Only show review and pay buttons if the request is completed and has a worker assigned
                                if (isCompleted && request['workerId'] != null)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: Icon(Icons.payments),
                                            label: Text("Pay Now"),
                                            style: ElevatedButton.styleFrom(
                                              iconColor: const Color.fromARGB(255, 8, 8, 8),
                                              foregroundColor: const Color.fromARGB(255, 6, 6, 6),
                                              backgroundColor: Colors.yellow[700],
                                            ),
                                            onPressed: () {
                                              navigateToPayment(request);
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: Icon(Icons.rate_review),
                                            label: Text("Review Worker"),
                                            style: ElevatedButton.styleFrom(
                                              iconColor: Colors.black,
                                              foregroundColor: Colors.black,
                                              backgroundColor: Colors.yellow[700],
                                            ),
                                            onPressed: () {
                                              showReviewDialog(
                                                request['workerId'],
                                                request['workerName'] ?? 'Worker'
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}