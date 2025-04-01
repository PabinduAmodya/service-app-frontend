import 'package:flutter/material.dart';
import 'package:flutter_service_app/screens/user_register.dart';
import 'package:flutter_service_app/screens/worker_register.dart';
import 'package:flutter_service_app/screens/login.dart'; // Added import for login page

class UserTypeScreen extends StatelessWidget {
  const UserTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF121212)], // Dark background gradient
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              children: [
                // App logo or icon
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.yellow[700],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.handyman,
                        size: 60,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                
                // Title and subtitle
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        "Welcome!",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Please select how you want to use the app",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Buttons section
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Service Provider Option
                      _buildSelectionCard(
                        context: context,
                        icon: Icons.business_center,
                        title: "Service Provider",
                        subtitle: "Offer your services and manage your bookings",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => WorkerRegisterScreen()),
                          );
                        },
                      ),
                      
                      SizedBox(height: 20),
                      
                      // User Option
                      _buildSelectionCard(
                        context: context,
                        icon: Icons.person,
                        title: "Customer",
                        subtitle: "Find services and book professionals",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UserRegisterScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Footer text - Now navigates to login.dart
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: TextButton(
                    onPressed: () {
                      // Navigate to login screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      "Already have an account? Log in",
                      style: TextStyle(
                        color: Colors.yellow[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E1E), // Dark card background
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade800,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[700]!.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.yellow[600],
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}