import 'package:flutter/material.dart';
import 'package:flutter_service_app/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  // Function to retrieve token from SharedPreferences
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Function to log out the user
  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Remove the token
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate back to login screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Colors.yellow[700],
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "Please log in to continue.",
                style: TextStyle(color: Colors.yellow[700], fontSize: 18),
              ),
            );
          }

          return Center(
            child: Text(
              "Welcome, Admin!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.yellow[700],
              ),
            ),
          );
        },
      ),
    );
  }
}
