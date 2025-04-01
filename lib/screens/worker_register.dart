import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WorkerRegisterScreen extends StatefulWidget {
  const WorkerRegisterScreen({super.key});

  @override
  _WorkerRegisterScreenState createState() => _WorkerRegisterScreenState();
}

class _WorkerRegisterScreenState extends State<WorkerRegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNoController = TextEditingController(); // Added phone number controller
  final TextEditingController locationController = TextEditingController();
  final TextEditingController yearsExperienceController = TextEditingController();

  final List<String> workTypes = ["Plumber", "Electrician", "Carpenter", "Mechanic", "Painter", "Mason", "Welder", "Cleaner"];
  String? selectedWorkType;

  Future<void> registerWorker() async {
    const String apiUrl = 'http://10.0.2.2:5000/api/users/register'; // 🔹 Replace with your actual API URL

    // Construct request body
    Map<String, dynamic> workerData = {
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
      "role": "worker",
      "workType": selectedWorkType,
      "location": locationController.text.trim(),
      "yearsOfExperience": yearsExperienceController.text.trim(),
      "phoneNo": phoneNoController.text.trim(), // Add phone number to request body
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(workerData),
      );

      if (response.statusCode == 201) {
        // 🔹 Successful registration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Successful!')),
        );
        // Clear input fields after successful registration
        nameController.clear();
        emailController.clear();
        passwordController.clear();
        phoneNoController.clear(); // Clear phone number field
        locationController.clear();
        yearsExperienceController.clear();
        setState(() {
          selectedWorkType = null;
        });
      } else {
        // 🔹 Error handling
        Map<String, dynamic> responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${responseData["error"]}')),
        );
      }
    } catch (error) {
      print('Registration Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong! Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Worker Registration", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              buildTextField(nameController, "Name", Icons.person),
              buildTextField(emailController, "Email", Icons.email),
              buildTextField(passwordController, "Password", Icons.lock, obscureText: true),
              buildTextField(phoneNoController, "Phone Number", Icons.phone, keyboardType: TextInputType.phone), // Added phone number input
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Work Type",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
                value: selectedWorkType,
                items: workTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedWorkType = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              buildTextField(locationController, "Location", Icons.location_on),
              buildTextField(yearsExperienceController, "Years of Experience", Icons.accessibility_new, keyboardType: TextInputType.number),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerWorker,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[700]),
                child: Text("Register as Worker", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.yellow[700]),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      ),
    );
  }
}
