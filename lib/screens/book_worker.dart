import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookWorkerScreen extends StatefulWidget {
  final Map<String, dynamic> workerData;
  final String userToken; // User's JWT Token for authentication

  const BookWorkerScreen({
    super.key,
    required this.workerData,
    required this.userToken,
  });

  @override
  _BookWorkerScreenState createState() => _BookWorkerScreenState();
}

class _BookWorkerScreenState extends State<BookWorkerScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitBookingRequest() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _deadlineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Uri apiUrl = Uri.parse('http://10.0.2.2:5000/api/requests'); // Matches your backend
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.userToken}', // Send JWT Token
    };

    final Map<String, dynamic> requestBody = {
      'workerId': widget.workerData['id'],
      'title': _titleController.text,
      'description': _descriptionController.text,
      'location': _locationController.text,
      'deadline': _deadlineController.text,
    };

    try {
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Work request sent successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${errorData['error']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Worker"),
        backgroundColor: Colors.yellow[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Booking Appointment with ${widget.workerData['name']}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextField(_titleController, "Title"),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, "Description", maxLines: 4),
            const SizedBox(height: 16),
            _buildTextField(_locationController, "Location"),
            const SizedBox(height: 16),
            _buildTextField(_deadlineController, "Deadline (YYYY-MM-DD)", isDate: true),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitBookingRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Submit Booking Request",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isDate = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isDate ? TextInputType.datetime : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      maxLines: maxLines,
    );
  }
}
