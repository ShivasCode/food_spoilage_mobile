import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sensor_data_page.dart';

class MonitoringGroupsPage extends StatelessWidget {
  final String token = '1b4980f3491893dbff45774c86555c583c987700';

  const MonitoringGroupsPage({super.key});

  Future<List<dynamic>> fetchMonitoringGroups() async {
    final response = await http.get(
      Uri.parse('http://192.168.55.105:8000/monitoring-groups/'),
      headers: {
        'Authorization': 'Token $token',
      },
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
      body: FutureBuilder<List<dynamic>>(
        future: fetchMonitoringGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final monitoringGroups = snapshot.data!;
            return ListView.builder(
              itemCount: monitoringGroups.length,
              itemBuilder: (context, index) {
                final group = monitoringGroups[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      group['food_type'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Start: ${group['start_time']}',
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${group['is_done'] ? 'Completed' : 'Pending'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: group['is_done'] ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      group['is_done'] ? Icons.check_circle : Icons.cancel,
                      color: group['is_done'] ? Colors.green : Colors.red,
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
    );
  }
}
