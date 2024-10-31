import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SensorDataPage extends StatefulWidget {
  final int groupId;

  const SensorDataPage({super.key, required this.groupId});

  @override
  _SensorDataPageState createState() => _SensorDataPageState();
}

class _SensorDataPageState extends State<SensorDataPage> {
  List<dynamic> sensorData = [];
  Timer? _timer; // Make timer nullable

  Future<void> fetchSensorData() async {
    const String token =
        '1b4980f3491893dbff45774c86555c583c987700'; // Your token
    final url =
        'http://192.168.55.105:8000/monitoring-groups/${widget.groupId}/';
    print('Fetching data from: $url'); // Print the URL

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token', // Add the token to the headers
        },
      );

      print('Response status: ${response.statusCode}'); // Print response status

      if (response.statusCode == 200) {
        print('Response body: ${response.body}'); // Print the response body
        setState(() {
          sensorData = jsonDecode(response.body)['sensor_data'];
        });
      } else {
        // Print an error message if the request fails
        print('Failed to load sensor data: ${response.reasonPhrase}');
        throw Exception('Failed to load sensor data');
      }
    } catch (error) {
      print(
          'Error occurred while fetching sensor data: $error'); // Print error details
    }
  }

  Future<void> exportCsv() async {
    const String token =
        '1b4980f3491893dbff45774c86555c583c987700'; // Your token
    final url =
        'http://192.168.55.105:8000/monitoring-groups/${widget.groupId}/export-csv/';
    print('Exporting CSV from: $url'); // Print the URL

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token', // Add the token to the headers
        },
      );

      print(
          'Export response status: ${response.statusCode}'); // Print response status

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Display success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message']),
            duration: const Duration(seconds: 3), // Show for 3 seconds
          ),
        );
      } else {
        print('Failed to export CSV: ${response.reasonPhrase}');
        throw Exception('Failed to export CSV');
      }
    } catch (error) {
      print(
          'Error occurred while exporting CSV: $error'); // Print error details
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error occurred while exporting CSV.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSensorData();
    _timer =
        Timer.periodic(const Duration(seconds: 60), (_) => fetchSensorData());
  }

  @override
  void dispose() {
    _timer?.cancel(); // Properly cancel the timer
    super.dispose();
  }

  // Method to handle the refresh action
  Future<void> _refreshData() async {
    await fetchSensorData(); // Fetch the latest data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _timer?.cancel(); // Cancel timer before going back
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData, // Call _refreshData on pull to refresh
        child: Column(
          children: [
            // Button to export CSV
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: exportCsv, // Call exportCsv on button press
                child: const Text('Export CSV'),
              ),
            ),
            // ListView to display sensor data
            Expanded(
              child: ListView.builder(
                itemCount: sensorData.length,
                itemBuilder: (context, index) {
                  final data = sensorData[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        'Temperature: ${data['temperature']} °C',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Humidity: ${data['humidity']} %',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Methane: ${data['methane']} ppm',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Timestamp: ${data['timestamp']}',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                'Spoilage Status: ',
                                style: TextStyle(fontSize: 16),
                              ),
                              Icon(
                                data['spoilage_status'] == 'food_is_spoiled'
                                    ? Icons.cancel
                                    : Icons.check_circle,
                                color:
                                    data['spoilage_status'] == 'food_is_spoiled'
                                        ? Colors.red
                                        : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data['spoilage_status'] == 'food_is_spoiled'
                                    ? 'Spoiled'
                                    : 'Fresh',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: data['spoilage_status'] ==
                                          'food_is_spoiled'
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      isThreeLine: true, // Allow three lines in the ListTile
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
