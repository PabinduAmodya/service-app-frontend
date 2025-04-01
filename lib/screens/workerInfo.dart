import 'package:flutter/material.dart';
import 'package:flutter_service_app/screens/book_worker.dart';
import 'package:flutter_service_app/screens/chat.dart'; // Import the ChatScreen
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerInfoScreen extends StatelessWidget {
  final Map<String, dynamic> workerData;

  const WorkerInfoScreen({super.key, required this.workerData});

  Future<String?> getUserToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Method to launch phone dialer
  Future<void> _launchPhoneDialer(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Show error if phone dialer cannot be launched
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone dialer for $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching phone dialer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () async {
              String? token = await getUserToken();
              
              if (token != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      workerId: workerData['id'], 
                      workerName: workerData['name'],
                      userToken: token,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("You need to be logged in to start a chat"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Future: Add more options
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow[700]!.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.yellow[700],
                        child: Text(
                          workerData['name'].toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 70,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      workerData['name'],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      workerData['specialization'] ?? 'Professional',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.yellow[600],
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Professional Details
              _buildSectionCard(
                title: "Professional Overview",
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerData['about'] ?? "No description available.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[300],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.phone_outlined,
                      label: "Phone",
                      value: workerData['phoneNo'],
                    ),
                    const SizedBox(height: 15),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.location_on_outlined,
                      label: "Location",
                      value: workerData['location'],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Skills and Expertise
              _buildSectionCard(
                title: "Skills & Expertise",
                content: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSkillChip("Plumbing"),
                    _buildSkillChip("Repair"),
                    _buildSkillChip("Installation"),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Book Now Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.yellow[700]!, Colors.yellow[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow[700]!.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    String? token = await getUserToken();
                    
                    if (token != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookWorkerScreen(
                            workerData: workerData,
                            userToken: token,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("You need to be logged in to book a worker"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Book Now",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Section Card Widget
  Widget _buildSectionCard({required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Slightly lighter than background
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.yellow[700]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          content,
        ],
      ),
    );
  }

  // Info Row Widget
  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon, 
    required String label, 
    required String value,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: label == "Phone" 
            ? () => _launchPhoneDialer(context, value) 
            : null,
          child: Icon(
            icon, 
            color: label == "Phone" ? Colors.green : Colors.yellow[700], 
            size: 24
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Skill Chip Widget
  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.yellow[700]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.yellow[700]!,
          width: 1,
        ),
      ),
      child: Text(
        skill,
        style: TextStyle(
          color: Colors.yellow[700],
          fontSize: 14,
        ),
      ),
    );
  }
}




// Error launching phone dialer     PlatformException(Channel-error, unable to establish connection on channel:"dev.flutter.pigeon.url_launcher_android.UrlLauncherApi.canLaunchUrl" , null ,null)                   got this error