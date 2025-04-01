import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_service_app/screens/login.dart'; // Update import for login screen

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  _UserRegisterScreenState createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false; // Track loading state

  // Function to handle user registration
Future<void> registerUser(BuildContext context) async {
  final name = nameController.text.trim();
  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  if (name.isEmpty || email.isEmpty || password.isEmpty) {
    _showSnackBar("All fields are required");
    return;
  }

  final url = Uri.parse('http://10.0.2.2:5000/api/users/register');

  setState(() {
    isLoading = true;
  });

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 201 && responseData['error'] == null) {
      _showSnackBar(responseData['message']); // Show success message
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      String errorMessage = responseData['error'] ?? "Unknown error occurred";
      _showSnackBar("Registration failed: $errorMessage");
    }
  } catch (error) {
    _showSnackBar("An error occurred: $error");
  } finally {
    setState(() {
      isLoading = false;
    });
  }
  
}


  // Function to show snackbar messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "User Registration",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black, // AppBar color
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // Back button color
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Create a User Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20), // Space after title

              // Name TextField
              buildTextField(nameController, "Name", Icons.person),
              SizedBox(height: 15), // Space between fields

              // Email TextField
              buildTextField(emailController, "Email", Icons.email),
              SizedBox(height: 15), // Space between fields

              // Password TextField
              buildTextField(passwordController, "Password", Icons.lock, obscureText: true),
              SizedBox(height: 30), // Space before button

              // Register Button
              SizedBox(
                width: double.infinity, // Make button full width
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => registerUser(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700], // Button color
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.black)
                      : Text(
                          "Register as User",
                          style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                        ),

                        
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black, // Set background to black
    );
    
  }

  // Reusable TextField widget
  Widget buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white), // White text input
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.yellow[700]), // Yellow icons
        labelText: label,
        labelStyle: TextStyle(color: Colors.white), // White label
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.yellow), // Yellow border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.yellow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.yellow, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.black12, // Light black fill color
      ),
    );
  }
}
