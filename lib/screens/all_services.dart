import 'package:flutter/material.dart';
import 'Plumbers.dart'; // Import the Plumber page

class AllServicesScreen extends StatelessWidget {
  const AllServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> services = [
      {"icon": Icons.plumbing, "title": "Plumber"},
      {"icon": Icons.electrical_services, "title": "Electrician"},
      {"icon": Icons.carpenter, "title": "Carpenter"},
      {"icon": Icons.car_repair, "title": "Mechanic"},     
      {"icon": Icons.brush, "title": "Painter"},
      {"icon": Icons.home_repair_service, "title": "Mason"},
      {"icon": Icons.build_circle, "title": "Welder"},
      {"icon": Icons.cleaning_services, "title": "Cleaner"}
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("All Services", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.yellow[700],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 columns
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            return _buildServiceTile(
              context, 
              services[index]["icon"], 
              services[index]["title"]
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceTile(BuildContext context, IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        // Navigate to PlumberPage when the Plumber tile is tapped
        if (title == 'Plumber') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlumberPage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.yellow[700],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.black),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
