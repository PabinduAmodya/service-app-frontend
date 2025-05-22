import 'package:flutter/material.dart';
import 'package:flutter_service_app/screens/login.dart';
import 'package:flutter_service_app/screens/worker/update_profile.dart';
import 'package:flutter_service_app/screens/worker/user_work_requests.dart';
import 'package:flutter_service_app/screens/worker/worker_chats_list.dart';
import 'package:flutter_service_app/screens/worker/worker_notifications_page.dart'; // Added import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  _WorkerHomeScreenState createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  bool isAvailable = true;
  String? authToken;
  String? workerId;
  String? workerName;
  bool _isLoading = true;
  
  // Add these variables for reviews and ratings
  double workerRating = 0.0;
  int reviewsCount = 0;
  List<dynamic> reviews = [];
  bool _isLoadingReviews = true;
  String reviewError = "";
  
  // Add notification count variable
  int notificationCount = 2; // Mock count, replace with actual count from API

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      authToken = prefs.getString('auth_token');
      workerId = prefs.getString('user_id');
      workerName = prefs.getString('username');
      _isLoading = false;

      // Debug prints
      print('Auth Token: $authToken');
      print('Worker ID: $workerId');
      print('Worker Name: $workerName');
    });
    
    // After loading user data, fetch reviews
    if (workerId != null && authToken != null) {
      fetchWorkerReviews();
      // In a real app, you would also fetch notification count here
      // fetchNotificationCount();
    }
  }
  
  // Add method to fetch worker's reviews
  Future<void> fetchWorkerReviews() async {
    if (workerId == null) return;
    
    setState(() {
      _isLoadingReviews = true;
      reviewError = "";
    });
    
    try {
      var response = await Dio().get(
        'http://10.0.2.2:5000/api/reviews/$workerId',
        options: Options(headers: {
          'Authorization': 'Bearer $authToken'
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          reviews = response.data;
          _isLoadingReviews = false;
          
          // Calculate average rating (in case it's not returned from API)
          if (reviews.isNotEmpty) {
            double totalRating = 0;
            for (var review in reviews) {
              totalRating += review['rating'] ?? 0;
            }
            workerRating = totalRating / reviews.length;
            reviewsCount = reviews.length;
          }
        });
      } else {
        setState(() {
          reviewError = "Failed to load reviews.";
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      setState(() {
        reviewError = "Error fetching reviews: ${e.toString()}";
        _isLoadingReviews = false;
      });
    }
  }

  // Add method to navigate to notifications page
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPage(),
      ),
    );
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToWorkRequests() {
    if (workerId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserWorkRequestsPage(workerId: workerId!),
        ),
      );
    } else {
      _showErrorMessage('Unable to load work requests. Please log in again.');
    }
  }

  void _navigateToWorkerChats() {
    if (_isLoading) {
      _showErrorMessage('Loading user data. Please wait.');
      return;
    }

    print('Navigation Data Check:');
    print('Worker ID: $workerId');
    print('Worker Name: $workerName');
    print('Auth Token: $authToken');

    if (workerId != null && authToken != null) {
      // Use a default name if workerName is null
      final displayName = workerName ?? "Worker";
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkerChatsList(
            workerId: workerId!, 
            workerName: displayName,
            userToken: authToken!
          ),
        ),
      );
    } else {
      _showErrorMessage('Unable to load chats. Details missing.');
      print('Navigation failed: workerId=$workerId, workerName=$workerName, authToken=$authToken');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildDashboardButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onPressed,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.9),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAvailable ? 'Available for Work' : 'Not Available',
                style: TextStyle(
                  color: isAvailable ? Colors.green : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAvailable 
                    ? 'You are visible to customers' 
                    : 'You are hidden from new requests',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Switch(
            value: isAvailable,
            onChanged: (bool value) {
              setState(() {
                isAvailable = value;
              });
              // TODO: Implement backend update for worker availability
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value ? 'You are now available' : 'You are now unavailable'),
                  backgroundColor: Colors.yellow[700],
                ),
              );
            },
            activeColor: Colors.green,
            activeTrackColor: Colors.green.withOpacity(0.3),
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow[700]!, Colors.amber[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  workerName != null && workerName!.isNotEmpty 
                      ? workerName![0].toUpperCase() 
                      : 'W',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[800],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workerName ?? 'Worker',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.star, 
                label: _isLoadingReviews ? "..." : workerRating.toStringAsFixed(1),
                sublabel: 'Rating'
              ),
              _buildStatItem(
                icon: Icons.rate_review, 
                label: _isLoadingReviews ? "..." : reviewsCount.toString(),
                sublabel: 'Reviews'
              ),
              _buildStatItem(
                icon: Icons.access_time,
                label: '100%',
                sublabel: 'On time'
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String sublabel,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.black.withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // Method to show all reviews dialog
  void _showAllReviewsDialog(BuildContext context, List<dynamic> allReviews) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Your Reviews (${allReviews.length})",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allReviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewItem(allReviews[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Review item widget
  Widget _buildReviewItem(Map<String, dynamic> review) {
    // Format timestamp if available
    String formattedDate = "Recently";
    if (review['timestamp'] != null) {
      try {
        DateTime date = DateTime.parse(review['timestamp']);
        formattedDate = "${date.day}/${date.month}/${date.year}";
      } catch (e) {
        // Keep default "Recently" if parsing fails
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client name and date
          Row(
            children: [
              Text(
                review['userName'] ?? "Client",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Star rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < (review['rating'] ?? 0) ? Icons.star : Icons.star_outline,
                color: Colors.amber,
                size: 18,
              );
            }),
          ),
          const SizedBox(height: 10),
          // Review comment
          Text(
            review['comment'] ?? "No comment provided.",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Method to build reviews section
  Widget _buildReviewsSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.yellow[700]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Reviews",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (reviews.isNotEmpty)
                TextButton(
                  onPressed: () => _showAllReviewsDialog(context, reviews),
                  child: Text(
                    "See All",
                    style: TextStyle(
                      color: Colors.yellow[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Reviews content
          if (_isLoadingReviews)
            Center(
              child: CircularProgressIndicator(
                color: Colors.yellow[700],
              ),
            )
          else if (reviewError.isNotEmpty)
            Center(
              child: Text(
                reviewError,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (reviews.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    color: Colors.grey[600],
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No reviews yet",
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: List.generate(
                reviews.length > 2 ? 2 : reviews.length,
                (index) => _buildReviewItem(reviews[index]),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        title: const Text(
          'Worker Dashboard', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Add notification icon with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: _navigateToNotifications,
              ),
              if (notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: logout,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
              color: Colors.yellow[700],
            ),
          )
        : RefreshIndicator(
            onRefresh: () async {
              await _loadUserData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileCard(),
                  _buildAvailabilityToggle(),
                  const SizedBox(height: 16),
                  // Add reviews section here
                  _buildReviewsSection(),
                  const SizedBox(height: 16),
                  _buildDashboardButton(
                    icon: Icons.work_outline,
                    label: 'Work Requests',
                    subtitle: 'View and manage customer requests',
                    onPressed: _navigateToWorkRequests,
                    color: Colors.blue[700]!,
                  ),
                  _buildDashboardButton(
                    icon: Icons.message_outlined,
                    label: 'My Chats',
                    subtitle: 'Communicate with customers',
                    onPressed: _navigateToWorkerChats,
                    color: Colors.green[700]!,
                  ),
                  // Add a new button for notifications
                  _buildDashboardButton(
                    icon: Icons.notifications_active,
                    label: 'Notifications',
                    subtitle: 'View your latest notifications',
                    onPressed: _navigateToNotifications,
                    color: Colors.red[700]!,
                  ),
                  _buildDashboardButton(
                    icon: Icons.calendar_today,
                    label: 'My Schedule',
                    subtitle: 'View your upcoming appointments',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Schedule feature coming soon!'),
                          backgroundColor: Colors.yellow[700],
                        ),
                      );
                    },
                    color: Colors.purple[700]!,
                  ),
                  _buildDashboardButton(
                    icon: Icons.account_circle,
                    label: 'Profile',
                    subtitle: 'Update your profile information',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UpdateProfileScreen(),
                        ),
                      ).then((updated) {
                        // If profile was updated, refresh the data
                        if (updated == true) {
                          _loadUserData();
                        }
                      });
                    },
                    color: Colors.orange[700]!,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }
}