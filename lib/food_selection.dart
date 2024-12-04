import 'package:flutter/material.dart';
import 'models/food_data.dart';
import 'food_details.dart';
import 'providers/monitoring_provider.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/mqtt_data_provider.dart'; // Import the data provider
import 'providers/mqtt_connection_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'monitoring_groups_page.dart';
// import 'charts_page.dart';
import 'mqtt_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'dart:async';
import 'notification_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) =>
              MqttConnectionProvider(), // Provide the MQTT connection provider
        ),
        ChangeNotifierProvider(
          create: (context) =>
              MqttDataProvider(), // Provide the MQTT data provider
        ),
        ChangeNotifierProvider(
          create: (context) => MonitoringProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Sensor and Notifications',
      home: FoodSelection(),
    );
  }
}

class FoodSelection extends StatefulWidget {
  const FoodSelection({super.key});

  @override
  _FoodSelectionState createState() => _FoodSelectionState();
}

class _FoodSelectionState extends State<FoodSelection> {
  bool isDataAvailable = false; // Flag to check if data is available
  String notificationMessage = 'Fetching data...';
  String _username = ''; // To store the username

  // List of pages corresponding to each tab

  String token = '${dotenv.env['TOKEN']}';
  StreamSubscription<String>? statusDataSubscription;
  Timer? offlineTimer;

  @override
  void initState() {
    super.initState();

    // Get the MQTT provider instance
    final mqttConnectionProvider =
        Provider.of<MqttConnectionProvider>(context, listen: false);

    statusDataSubscription =
        mqttConnectionProvider.statusStream.listen((payload) {
      handleStatus();
    });

    // Check if already connected before attempting to connect
    if (!mqttConnectionProvider.isConnected) {
      mqttConnectionProvider
          .connectToMqtt(); // Initiate the connection to the MQTT broker
    } else {
      print('Already connected to MQTT broker.');
    }

    // Fetch the latest sensor data regardless of connection status
    fetchLatestSensorData();
    _loadUsername();
    // Optionally listen for connection updates if needed
    // mqttConnectionProvider.addListener(() {
    //   if (mqttConnectionProvider.isConnected) {
    //     fetchUnreadNotifications();
    //   }
    // });
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ??
          'Guest'; // Default to 'Guest' if no username found
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    offlineTimer?.cancel();
    statusDataSubscription?.cancel();
    super.dispose();
  }

  void handleStatus() {
    print('status handled');
    if (mounted) {
      // If payload indicates "true" (online), update the status
      Provider.of<MqttDataProvider>(context, listen: false)
          .updateStatusToOnline();

      resetOfflineTimer();
    }
  }

  void resetOfflineTimer() {
    // Cancel any existing timer
    offlineTimer?.cancel();

    // Start a new 10-second timer
    offlineTimer = Timer(Duration(seconds: 10), () {
      if (mounted) {
        print('No status update received in 10 seconds, setting to offline.');
        Provider.of<MqttDataProvider>(context, listen: false)
            .updateStatusToOffline();
      }
    });
  }

  Future<void> logout() async {
    // Get SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();

    // Remove the token from SharedPreferences
    await prefs.clear(); // Clear all stored data

    // Redirect to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index; // Update the selected index
  //   });
  // }

  Future<void> fetchLatestSensorData() async {
    final String url = '${dotenv.env['CLIENT_IP']}/latest-sensor-data/';
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $authToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        final latestData = data.first;
        // Update sensor data and start monitoring
        Provider.of<MqttDataProvider>(context, listen: false).startMonitoring();
        Provider.of<MqttDataProvider>(context, listen: false).updateSensorData(
          latestData['temperature'] ?? 0.0,
          latestData['methane'] ?? 0.0,
          latestData['spoilage_status'] ?? "",
          latestData['ammonia'] ?? 0.0,
          latestData['methane_status'] ?? "",
          latestData['temperature_status'] ?? "",
          latestData['storage_status'] ?? "",
          latestData['ammonia_status'] ?? "",
        );

        // Check if widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            isDataAvailable = true; // Mark that data is available
            notificationMessage = ""; // Clear notification message
          });

          // Navigate to the MQTT page if data is available
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MqttExample()),
          );
        }
      } else {
        // No data available, stop monitoring
        Provider.of<MqttDataProvider>(context, listen: false).stopMonitoring();
        // Ensure widget is still mounted before updating UI
        if (mounted) {
          setState(() {
            isDataAvailable = false; // No data available
            notificationMessage =
                'No active monitoring.'; // Set notification message
          });
        }
      }
    } else {
      print('Failed to fetch sensor data: ${response.body}');

      // Ensure widget is still mounted before showing error message
      if (mounted) {
        setState(() {
          notificationMessage = 'Error fetching data.';
        });
      }
    }
  }

  Future<void> fetchUnreadNotifications() async {
    final String url = '${dotenv.env['CLIENT_IP']}/notifications/unread/';
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $authToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        if (mounted) {
          // Check if the widget is still mounted
          setState(() {
            pendingNotifications = data
                .map((notif) => {
                      'id': notif['id'],
                      'message': notif['message'],
                    })
                .toList();
          });
          // Show the first notification, if there are any pending
          if (pendingNotifications.isNotEmpty) {
            _showNextNotification();
          }
        }
      }
    } else {
      print('Failed to fetch unread notifications: ${response.body}');
    }
  }

  List<Map<String, dynamic>> pendingNotifications = [];

  // void handleNotification(String payload) {
  //   print('testing');
  //   final notificationData = jsonDecode(payload);

  //   // Extract fields
  //   final notificationId = notificationData['id'];
  //   final notificationMessage = notificationData['message'];
  //   final spoilageStatus = notificationMessage['spoilage_status'];

  //   // Trigger only if spoilage_status is "Food is Spoiled"
  //   if (spoilageStatus == "Food is Spoiled") {
  //     // Add the new notification to the pending notifications list
  //     setState(() {
  //       pendingNotifications.add({
  //         'id': notificationId,
  //         'message': notificationMessage,
  //       });
  //     });

  //     // If there is only one notification, display it immediately
  //     if (pendingNotifications.length == 1) {
  //       _showNextNotification();
  //     }
  //   }
  // }

  void _showNextNotification() {
    if (pendingNotifications.isEmpty) return;

    final notification = pendingNotifications.first;
    final notificationId = notification['id'];
    final notificationMessage = notification['message'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Notification'),
          content: Text(notificationMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                markNotificationAsRead(notificationId).then((_) {
                  setState(() {
                    pendingNotifications.removeAt(0);
                  });
                });
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final String url =
        '${dotenv.env['CLIENT_IP']}/notifications/acknowledge/$notificationId/';
    final response = await http.post(Uri.parse(url));
    print(response);

    if (response.statusCode == 200) {
      print('Notification ID $notificationId marked as read.');
    } else {
      print('Failed to mark notification as read: ${response.body}');
    }
  }

  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final mqttProvider = Provider.of<MqttConnectionProvider>(context);
    final mqttData = Provider.of<MqttDataProvider>(context);

    // Pages for Monitoring and History
    final List<Widget> pages = [
      ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: foods.length,
        itemBuilder: (context, index) {
          final food = foods[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodDetailsPage(food: food),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4, // Shadow effect
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Left: Food Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                        image: DecorationImage(
                          image: AssetImage(food.image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right: Food Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Estimated Spoilage: ${food.estimatedSpoilage}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            food.details,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      MonitoringGroupsPage(),
      NotificationPage()
    ];

    if (!mqttProvider.isConnected) {
      return Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(), // Show a loading indicator while connecting
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hi, $_username", // Display Hi, {username} dynamically
          style: const TextStyle(
            fontSize: 20, // Adjust the font size
            color: Colors
                .black, // Use a color that complements the AppBar background
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed:
                logout, // Call the logout function when the logout button is pressed
          ),
        ],
      ),
      backgroundColor: const Color(0xFFEEE2D0), // Set background color here
      body: Column(
        children: [
          // Conditionally hide the MQTT status section if the current page is the NotificationPage
          if (_currentIndex != 2) // 2 corresponds to the Notification tab index
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    mqttData.isOnline ? Icons.cloud : Icons.cloud_off,
                    color: mqttData.isOnline ? Colors.green : Colors.red,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    mqttData.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mqttData.isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          // Main Content Section
          Expanded(child: pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFEEE2D0),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.device_hub),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications', // Notification tab
          ),
        ],
        currentIndex: _currentIndex, // Reflect the selected index
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected index
          });
        },
      ),
    );
  }
}
