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
  List<dynamic> allPlumbers = [];
  List<dynamic> filteredPlumbers = [];
  TextEditingController locationController = TextEditingController();
  bool isFiltering = false;

  // Function to fetch all workers and filter plumbers
  Future<void> fetchPlumbers() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/workers')); // Change the URL if needed
      if (response.statusCode == 200) {
        List<dynamic> workers = json.decode(response.body);

        // Filter out Plumbers
        allPlumbers = workers.where((worker) => worker['workType'] == 'Plumber').toList();
        // Initialize filteredPlumbers with all plumbers by default
        filteredPlumbers = List.from(allPlumbers);
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

  // Function to filter plumbers by location
  void filterPlumbersByLocation(String location) {
    setState(() {
      isFiltering = true;
      if (location.trim().isEmpty) {
        filteredPlumbers = List.from(allPlumbers);
      } else {
        filteredPlumbers = allPlumbers
            .where((plumber) => 
                plumber['location'].toString().toLowerCase()
                .contains(location.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchPlumbers(); // Fetch plumbers when the page is initialized
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plumbers Available'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search for plumbers in your area:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          hintText: 'Enter location to filter',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        filterPlumbersByLocation(locationController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Filter',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredPlumbers.isEmpty
                    ? Center(child: Text(isFiltering 
                        ? 'No plumbers found in this location' 
                        : 'No plumbers available at the moment'))
                    : ListView.builder(
                          itemCount: filteredPlumbers.length,
                          itemBuilder: (context, index) {
                            final plumber = filteredPlumbers[index];
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.yellow[700],
                                  child: Icon(Icons.plumbing, color: Colors.white),
                                ),
                                title: Text(
                                  plumber['name'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Location: ${plumber['location']}'),
                                    if (plumber['rating'] != null)
                                      Row(
                                        children: [
                                          Icon(Icons.star, size: 16, color: Colors.amber),
                                          Text(' ${plumber['rating']}'),
                                        ],
                                      ),
                                  ],
                                ),
                                isThreeLine: plumber['rating'] != null,
                                trailing: Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  // Navigate to the WorkerInfo page when clicked
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WorkerInfoScreen(workerData: plumber),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
          ),
        ],
      ),
    );
  }
}