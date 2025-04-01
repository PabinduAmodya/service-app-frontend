import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_service_app/screens/home.dart';
import 'package:flutter_service_app/screens/worker/worker_home.dart';
import 'package:flutter_service_app/screens/admin/admin_home.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_type.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      String? role = prefs.getString('user_role');
      if (role == 'user') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else if (role == 'worker') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WorkerHomeScreen()),
        );
      } else if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomeScreen()),
        );
      }
    }
  }

  Future<void> loginUser(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Email and password cannot be empty");
      return;
    }

    final url = Uri.parse('http://10.0.2.2:5000/api/users/login');

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String token = responseData['token'];
        String role = responseData['user']['role'];
        String userId = responseData['user']['id'];
        String name = responseData['user']['name'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_role', role);
        await prefs.setString('user_id', userId);
        await prefs.setString('name',name);

        _showSnackBar("Login successful!");

        if (role == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else if (role == 'worker') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WorkerHomeScreen()),
          );
        } else if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomeScreen()),
          );
        }
      } else {
        final responseData = json.decode(response.body);
        String errorMessage = responseData['error'] ?? "Invalid email or password";
        _showSnackBar("Login failed: $errorMessage");
      }
    } catch (error) {
      _showSnackBar("An error occurred: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
        title: Text("Login", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.yellow[700],
              ),
            ),
            SizedBox(height: 20),

            buildTextField(emailController, "Email", Icons.email),
            SizedBox(height: 10),

            buildTextField(passwordController, "Password", Icons.lock, obscureText: true),
            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => loginUser(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.black)
                    : Text(
                        "Login",
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
              ),
            ),
            SizedBox(height: 15),

            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserTypeScreen()),
                  );
                },
                child: Text(
                  "Don't have an account? Register",
                  style: TextStyle(color: Colors.yellow[700], fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        filled: true,
        fillColor: Colors.black12,
      ),
      style: TextStyle(color: Colors.white),
    );
  }
}