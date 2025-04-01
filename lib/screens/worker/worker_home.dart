import 'package:flutter/material.dart';
import 'package:flutter_service_app/screens/login.dart';
import 'package:flutter_service_app/screens/worker/update_profile.dart';
import 'package:flutter_service_app/screens/worker/user_work_requests.dart';
import 'package:flutter_service_app/screens/worker/worker_chats_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
              _buildStatItem(icon: Icons.star, label: '4.8', sublabel: 'Rating'),
              _buildStatItem(icon: Icons.check_circle, label: '24', sublabel: 'Jobs'),
              _buildStatItem(icon: Icons.access_time, label: '100%', sublabel: 'On time'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        title: Text(
          'Worker Dashboard', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
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
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileCard(),
                _buildAvailabilityToggle(),
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
                _buildDashboardButton(
                  icon: Icons.calendar_today,
                  label: 'My Schedule',
                  subtitle: 'View your upcoming appointments',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Schedule feature coming soon!'),
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
    );
  }
}