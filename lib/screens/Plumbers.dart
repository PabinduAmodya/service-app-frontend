import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // To handle the JSON response
import 'workerInfo.dart';  // Import the WorkerInfo screen

class PlumberPage extends StatefulWidget {
  @override
  _PlumberPageState createState() => _PlumberPageState();
}

class _PlumberPageState extends State<PlumberPage> {
  bool isLoading = true;
  List<dynamic> plumbers = [];

  // Function to fetch all workers and filter plumbers
  Future<void> fetchPlumbers() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/workers')); // Change the URL if needed
      if (response.statusCode == 200) {
        List<dynamic> workers = json.decode(response.body);

        // Filter out Plumbers
        plumbers = workers.where((worker) => worker['workType'] == 'Plumber').toList();
      } else {
        throw Exception('Failed to load workers');
      }
    } catch (error) {
      print('Error fetching plumbers: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPlumbers(); // Fetch plumbers when the page is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plumbers Available'),
        backgroundColor: Colors.yellow[700],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : plumbers.isEmpty
              ? Center(child: Text('No Plumbers available at the moment'))
              : ListView.builder(
                  itemCount: plumbers.length,
                  itemBuilder: (context, index) {
                    final plumber = plumbers[index];
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text(plumber['name']),
                      subtitle: Text('Location: ${plumber['location']}'),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        // Navigate to the WorkerInfo page when clicked
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkerInfoScreen(workerData: plumber),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
