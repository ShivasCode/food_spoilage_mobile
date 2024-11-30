import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sensor_data_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonitoringGroupsPage extends StatelessWidget {
  const MonitoringGroupsPage({super.key});

  Future<List<dynamic>> fetchMonitoringGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    final response = await http.get(
      Uri.parse('${dotenv.env['CLIENT_IP']}/monitoring-groups/'),
      headers: {'Authorization': 'Token $authToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load monitoring groups');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEE2D0), // Soft background color
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: fetchMonitoringGroups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  // Reverse the list to start the latest data from the top
                  final monitoringGroups = snapshot.data!.reversed.toList();
                  return ListView.builder(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: monitoringGroups.length,
                    itemBuilder: (context, index) {
                      final group = monitoringGroups[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 16.0),
                        elevation: 8, // Slight shadow for depth
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 20.0),
                          title: Row(
                            children: [
                              Text(
                                '${monitoringGroups.length - index}. ${group['food_type']}', // Adjusting count based on reversed index
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(
                                  width: 8), // Space between text and icon
                              Icon(
                                group['is_done'] ? Icons.check : Icons.cancel,
                                color: group['is_done']
                                    ? Colors.green
                                    : Colors.red,
                                size: 25,
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Start: ${group['start_time']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'End: ${group['end_time'] ?? 'Not Yet Ended'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6.0, horizontal: 10.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: group['is_done']
                                        ? [
                                            Colors.green.withOpacity(0.6),
                                            Colors.green.withOpacity(0.3)
                                          ]
                                        : [
                                            Colors.red.withOpacity(0.6),
                                            Colors.red.withOpacity(0.3)
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  group['is_done'] ? 'Completed' : 'Pending',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SensorDataPage(groupId: group['id']),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
