import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching notifications.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No new notifications.'));
          }

          final notifications = snapshot.data!;

          return Column(
            children: [
              // Grouped Icon and Text with a Filled Button Style
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: deleteAllReadNotifications, // Call the delete function
                  child: Container(
                    width: double
                        .infinity, // Makes the button stretch across the screen
                    padding: const EdgeInsets.symmetric(
                        vertical: 16), // Padding for height
                    decoration: BoxDecoration(
                      color: Colors.red, // Filled red background color
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    child: Row(
                      children: [
                        // Icon at the start of the row
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Icon(
                            Icons.delete,
                            color:
                                Colors.white, // White icon color for contrast
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Text aligned to the start, next to the icon
                        Text(
                          'Delete All Read',
                          style: TextStyle(
                            color: Colors.white, // White text color
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // List of notifications
              Expanded(
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      title: Text(notification['message'] ?? 'No message'),
                      subtitle: Text(
                          'Timestamp: ${notification['timestamp']} | ID: ${notification['id']}'),
                      trailing: IconButton(
                        icon: Icon(
                          notification['read'] == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: notification['read'] == true
                              ? Colors.green
                              : Colors.grey,
                        ),
                        onPressed: () {
                          // Mark the notification as read
                          markNotificationAsRead(notification['id']);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    // Retrieve the authToken from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('authToken');

    if (authToken == null) {
      throw Exception('Authentication token is not available');
    }

    final url = '${dotenv.env['CLIENT_IP']}/notifications/';
    print('Fetching notifications from: $url');

    // Make the API request to fetch notifications
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $authToken', // Add the token to headers
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List notifications = json.decode(response.body);
        return notifications.map((notification) {
          return {
            'id': notification['id'],
            'message': notification['message'],
            'timestamp': notification['timestamp'],
            'read': notification['read'],
          };
        }).toList();
      } else {
        throw Exception(
            'Failed to load notifications: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error occurred while fetching notifications: $error');
      throw Exception('Error occurred while fetching notifications: $error');
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    // Retrieve the authToken from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('authToken');

    if (authToken == null) {
      throw Exception('Authentication token is not available');
    }

    // Simulate an API call to mark the notification as read
    final response = await http.patch(
      Uri.parse(
        '${dotenv.env['CLIENT_IP']}/notifications/$notificationId/read/',
      ),
      headers: {
        'Authorization': 'Token $authToken', // Add the token to headers
        'Content-Type': 'application/json',
      },
      body: json.encode({'read': true}),
    );

    if (response.statusCode == 200) {
      // Refresh the notifications after marking as read
      setState(() {
        _notificationsFuture = fetchNotifications();
      });
      print('Notification $notificationId marked as read.');
    } else {
      print('Failed to mark notification $notificationId as read.');
    }
  }

  Future<void> deleteAllReadNotifications() async {
    // Retrieve the authToken from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('authToken');

    if (authToken == null) {
      throw Exception('Authentication token is not available');
    }

    // Make the API request to delete all read notifications
    final response = await http.delete(
      Uri.parse(
        '${dotenv.env['CLIENT_IP']}/notifications/read/',
      ),
      headers: {
        'Authorization': 'Token $authToken', // Add the token to headers
      },
    );

    if (response.statusCode == 200) {
      // Refresh the notifications after deleting read ones
      setState(() {
        _notificationsFuture = fetchNotifications();
      });
      print('All read notifications deleted.');
    } else {
      print('Failed to delete read notifications.');
    }
  }
}
