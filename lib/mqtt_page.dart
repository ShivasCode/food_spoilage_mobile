import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:provider/provider.dart'; // Import provider
import 'providers/mqtt_data_provider.dart'; // Import the data provider
import 'providers/monitoring_provider.dart';
import 'providers/mqtt_connection_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
// import 'food_selection.dart';
// import 'main.dart';
import 'food_selection.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MonitoringProvider(),
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
      home: MqttExample(),
    );
  }
}

class MqttExample extends StatefulWidget {
  const MqttExample({super.key});

  @override
  _MqttExampleState createState() => _MqttExampleState();
}

class _MqttExampleState extends State<MqttExample> {
  String token = '${dotenv.env['TOKEN']}';
  double temperature = 0.0;
  double methane = 0.0;
  double ammonia = 0.0;

  String? notificationMessage;
  String? spoilage_status;
  String? methane_status;
  String? temperature_status;
  String? storage_status;

  // Food choices
  final List<String> foodChoices = ['menudo', 'adobo', 'mechado'];
  String selectedFood = 'menudo'; // Default selection
  late MqttDataProvider mqttDataProvider;
  StreamSubscription<String>? sensorDataSubscription;
  StreamSubscription<String>? notificationSubscription;
  @override
  void initState() {
    super.initState();

    final mqttProvider =
        Provider.of<MqttConnectionProvider>(context, listen: false);

    sensorDataSubscription = mqttProvider.sensorDataStream.listen((payload) {
      handleSensorData(payload);
    });

    notificationSubscription =
        mqttProvider.notificationStream.listen((payload) {
      handleNotification(payload);
    });
  }

  @override
  void dispose() {
    sensorDataSubscription?.cancel();
    notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store reference to MqttDataProvider
    mqttDataProvider = Provider.of<MqttDataProvider>(context, listen: false);
  }

  Future<void> handleSensorData(String payload) async {
    print(payload + 'yes');
    final data = jsonDecode(payload);

    double temperature = data['temperature'] ?? 0.0;
    double methane = data['methane'] ?? 0.0;
    String spoilage_status = data['spoilage_status'] ?? '';
    double ammonia = data['ammonia'] ?? 0.0;
    String methane_status = data['methane_status_message'] ?? '';
    String temperature_status = data['temperature_status_message'] ?? '';
    String storage_status = data['storage_status_message'] ?? '';
    String ammonia_status = data['ammonia_status_message'] ?? '';

    // Start monitoring if it hasn't started yet
    if (!mqttDataProvider.isMonitoring) {
      mqttDataProvider.startMonitoring();
    }

    // Update the provider with new sensor data
    mqttDataProvider.updateSensorData(
        temperature,
        methane,
        spoilage_status,
        ammonia,
        methane_status,
        temperature_status,
        storage_status,
        ammonia_status);

    // Stop monitoring if the spoilage status indicates spoiled food
    if (spoilage_status == 'Food is Spoiled' && mounted) {
      mqttDataProvider.stopMonitoring();

      if (ModalRoute.of(context)?.settings.name != '/') {
        // Navigate to MainPage and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => FoodSelection()),
          (route) => false, // Remove all routes from the stack
        );
      }
    }

    // Update local state only if the widget is mounted
    if (mounted) {
      setState(() {
        this.temperature = temperature;
        this.methane = methane;
        this.spoilage_status = spoilage_status;
        // Optionally include the new fields if needed in the local state
        this.methane_status = methane_status;
        this.temperature_status = temperature_status;
        this.storage_status = storage_status;
      });
    }
  }

  Future<void> fetchLatestSensorData() async {
    final String url = '${dotenv.env['CLIENT_IP']}/latest-sensor-data/';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token ${dotenv.env['TOKEN']}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        if (data.isNotEmpty) {
          final latestData = data.first;
          Provider.of<MqttDataProvider>(context, listen: false)
              .startMonitoring();
          // Update the provider with new sensor data
          Provider.of<MqttDataProvider>(context, listen: false)
              .updateSensorData(
            latestData['temperature'] ?? 0.0,
            latestData['methane'] ?? 0.0,
            latestData['spoilage_status'] ?? "",
            latestData['ammonia'] ?? 0.0,
            latestData['methane_status'] ?? "",
            latestData['temperature_status'] ?? "",
            latestData['storage_status'] ?? "",
            latestData['ammonia_status'] ?? "",
          );

          // Update local state as well
          setState(() {
            this.temperature = latestData['temperature'] ?? 0.0;
            this.methane = latestData['methane'] ?? 0;
            notificationMessage = null;
          });
        } else {
          Provider.of<MqttDataProvider>(context, listen: false)
              .stopMonitoring();
          setState(() {
            this.temperature = 0.0;
            this.methane = 0;
            notificationMessage = 'No active monitoring.';
          });
        }
      }
    } else {
      print('Failed to fetch sensor data: ${response.body}');
    }
  }

  // Future<void> fetchUnreadNotifications() async {
  //   final String url =
  //       '${dotenv.env['CLIENT_IP']}/notifications/warnings/unread/';
  //   final response = await http.get(
  //     Uri.parse(url),
  //     headers: {'Authorization': 'Token ${dotenv.env['TOKEN']}'},
  //   );

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     if (data is List) {
  //       setState(() {
  //         pendingNotifications = data
  //             .map((notif) => {
  //                   'id': notif['id'],
  //                   'message': notif['message'],
  //                 })
  //             .toList();
  //       });
  //       // Show the first notification, if there are any pending
  //       if (pendingNotifications.isNotEmpty) {
  //         _showNextNotification();
  //       }
  //     }
  //   } else {
  //     print('Failed to fetch unread notifications: ${response.body}');
  //   }
  // }

  List<Map<String, dynamic>> pendingNotifications = [];
  void handleNotification(String payload) {
    print(payload + 'wahahha');
    final notificationData = jsonDecode(payload);
    final notificationId = notificationData['id'];
    final notificationMessage = notificationData['message'];
    final spoilageStatus = notificationData[
        'spoilage_status']; // Ensure this key exists in your payload

    // Check if the spoilage status is "Food is at Risk" or "Food is Fresh"
    if (spoilageStatus == 'Food is at Risk' ||
        spoilageStatus == 'Food is Fresh') {
      // Add the new notification to the pending notifications list
      if (mounted) {
        setState(() {
          pendingNotifications.add({
            'id': notificationId,
            'message': notificationMessage,
          });
        });

        // If there is only one notification, display it immediately
        if (pendingNotifications.length == 1) {
          _showNextNotification();
        }
      }
    } else {
      print('Notification ignored. Spoilage status: $spoilageStatus');
    }
  }

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
                  // No further notifications will be shown, just exit
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

  Future<void> publishEndMonitoring() async {
    final mqttProvider =
        Provider.of<MqttConnectionProvider>(context, listen: false);
    final client = mqttProvider.mqttClient;

    final String endMonitoringTopic = 'sensor/monitoring/$token';
    final payload = jsonEncode({'start_monitoring': false});
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    // Publish the end monitoring message
    client.publishMessage(
        endMonitoringTopic, MqttQos.atLeastOnce, builder.payload!);
    print('Published end monitoring message to $endMonitoringTopic: $payload');

    final response = await http.post(
      Uri.parse('${dotenv.env['CLIENT_IP']}/end-monitoring/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token ${dotenv.env['TOKEN']}',
      },
      body: jsonEncode({'status': 'end'}),
    );
    print(response.body + 'hello');

    if (response.statusCode == 200) {
      print('Successfully marked end monitoring: ${response.body}');

      // Use the stored reference
      mqttDataProvider.updateSensorData(
          0.0, // Temperature
          0, // Methane
          "", // Spoilage status
          0.0,
          "",
          "",
          "",
          "");

      mqttDataProvider.stopMonitoring();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => FoodSelection(), // Go back to MainPage
        ),
        (route) => false,
      );
    } else if (response.statusCode == 400 &&
        jsonDecode(response.body)['message'] ==
            'No active monitoring groups to end.') {
      print('No active monitoring groups to end.');

      // Use the stored reference
      mqttDataProvider.stopMonitoring();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => FoodSelection(), // Go back to MainPage
        ),
        (route) => false,
      );
    } else {
      print(
          'Failed to mark end monitoring: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqttData = Provider.of<MqttDataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back button
        backgroundColor:
            Color(0xFFEEE2D0), // Make AppBar background transparent
        elevation: 0, // Remove the shadow of the AppBar
        flexibleSpace: Container(
          width: double.infinity, // Ensures it captures full width
          height: 100, // AppBar height
          child: Padding(
            padding:
                const EdgeInsets.only(top: 50, left: 20), // Adjusted padding
            child: Text(
              'Food Spoilage',
              style: TextStyle(
                fontSize: 22, // Adjusted text size for better balance
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Roboto', // Clean, modern font
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFEEE2D0), // Light grey background color
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    mqttData.isOnline ? Icons.cloud : Icons.cloud_off,
                    color: mqttData.isOnline ? Colors.green : Colors.red,
                    size: 30,
                  ),
                  SizedBox(width: 10),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      iconColor: Color.fromARGB(255, 255, 255, 255),
                      backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Rounded corners
                      ),
                      elevation: 2, // Subtle shadow for better visibility
                      textStyle: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (mqttData.isMonitoring) {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('End Monitoring'),
                              content: Text(
                                  'Are you sure you want to end monitoring?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    publishEndMonitoring();
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                  child: Text('Yes, End Monitoring'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: Text(
                      'End Monitoring',
                      style: TextStyle(
                        color: mqttData.isMonitoring
                            ? Colors.red
                            : Colors
                                .black, // Change text color based on monitoring state
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Display the 4 statuses
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Methane Status
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                mqttData.methane_status ==
                                        'Methane threshold exceeded. Food at risk.'
                                    ? Icons.warning_amber_rounded
                                    : Icons.info,
                                color: mqttData.methane_status ==
                                        'Methane threshold exceeded. Food at risk.'
                                    ? Colors.red
                                    : Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Methane Status:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            mqttData.methane_status.isNotEmpty
                                ? mqttData.methane_status
                                : 'No data has been received yet.',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                              color: mqttData.methane_status ==
                                      'Methane threshold exceeded. Food at risk.'
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Ammonia Status
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                mqttData.ammonia_status ==
                                        'Ammonia threshold exceeded. Food at risk.'
                                    ? Icons.warning_amber_rounded
                                    : Icons.info,
                                color: mqttData.ammonia_status ==
                                        'Ammonia threshold exceeded. Food at risk.'
                                    ? Colors.red
                                    : Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ammonia Status:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            mqttData.ammonia_status.isNotEmpty
                                ? mqttData.ammonia_status
                                : 'No data has been received yet.',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                              color: mqttData.ammonia_status ==
                                      'Ammonia threshold exceeded. Food at risk.'
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Temperature Status
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                mqttData.temperature_status ==
                                            'Food at Risk Due to High Temperature' ||
                                        mqttData.temperature_status ==
                                            'Food has been exposed to high temperature for over 2 hours. Spoilage risk detected.'
                                    ? Icons.warning_amber_rounded
                                    : Icons.info,
                                color: mqttData.temperature_status ==
                                            'Food at Risk Due to High Temperature' ||
                                        mqttData.temperature_status ==
                                            'Food has been exposed to high temperature for over 2 hours. Spoilage risk detected.'
                                    ? Colors.red
                                    : Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Temperature Status:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            mqttData.temperature_status.isNotEmpty
                                ? mqttData.temperature_status
                                : 'No data has been received yet.',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                              color: mqttData.temperature_status ==
                                          'Food at Risk Due to High Temperature' ||
                                      mqttData.temperature_status ==
                                          'Food has been exposed to high temperature for over 2 hours. Spoilage risk detected.'
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Storage Status
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                mqttData.storage_status ==
                                        'Food is at risk due to being stored for over 3 days.'
                                    ? Icons.warning_amber_rounded
                                    : Icons.info,
                                color: mqttData.storage_status ==
                                        'Food is at risk due to being stored for over 3 days.'
                                    ? Colors.red
                                    : Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Storage Status:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            mqttData.storage_status.isNotEmpty
                                ? mqttData.storage_status
                                : 'No data has been received yet.',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                              color: mqttData.storage_status ==
                                      'Food is at risk due to being stored for over 3 days.'
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SensorCard(
                title: 'Temperature',
                value: '${mqttData.temperature.toStringAsFixed(2)}',
                icon: Icons.thermostat,
                gaugeValue: mqttData.temperature,
                gaugeMax: 50, // Max temperature
                gaugeMin: -50, // Min temperature
                unit: '°C', // Unit for temperature
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              MethaneSensorCard(
                title: 'Methane',
                value: '${mqttData.methane} ppm',
                icon: Icons.air,
                gaugeValue: mqttData.methane.toDouble(),
                gaugeMax: 4095,
              ),
              MethaneSensorCard(
                title: 'Ammonia',
                value: '${mqttData.ammonia} ppm',
                icon: Icons.air,
                gaugeValue: mqttData.ammonia.toDouble(),
                gaugeMax: 4095,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double gaugeValue;
  final double gaugeMax;
  final double gaugeMin; // Add a minimum gauge value
  final String unit; // Add a unit (like °C or %)

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gaugeValue,
    required this.gaugeMax,
    required this.gaugeMin,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    // Define dynamic pointer and range colors
    Color pointerColor = Colors.green; // Default color
    Color needleCircleColor =
        Colors.green; // Default color for the circle at the base of the needle

    // Determine color based on gauge value
    if (gaugeValue >= (gaugeMax / 1.5)) {
      pointerColor = Colors.red; // Danger
      needleCircleColor = Colors.red; // Set the circle to red
    } else if (gaugeValue >= (gaugeMax / 3)) {
      pointerColor = Colors.orange; // Caution
      needleCircleColor = Colors.orange; // Set the circle to orange
    }

    return Card(
      color: Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Icon and title at the top-left of the card
            Row(
              children: [
                // Use ShaderMask with Gradient for the icon
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        Colors.teal,
                        Colors.blue
                      ], // Gradient from teal to blue
                      tileMode: TileMode.mirror,
                    ).createShader(bounds);
                  },
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors
                        .white, // The icon color will be overridden by the gradient
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Use black for better contrast
                  ),
                ),
              ],
            ),
            const SizedBox(
                height:
                    10), // Reduced spacing between the icon/title and the gauge
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 300,
                  height: 250,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: gaugeValue),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, child) {
                      return SfRadialGauge(
                        axes: <RadialAxis>[
                          RadialAxis(
                            minimum: gaugeMin, // Dynamic min value
                            maximum: gaugeMax, // Dynamic max value
                            interval: 10,
                            ranges: <GaugeRange>[
                              GaugeRange(
                                startValue: gaugeMin,
                                endValue:
                                    (gaugeMax / 3), // Adjust range dynamically
                                color: Colors.green,
                                label: 'Safe',
                                labelStyle: GaugeTextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                              GaugeRange(
                                startValue: (gaugeMax / 3),
                                endValue: (gaugeMax / 1.5),
                                color: Colors.orange,
                                label: 'Caution',
                                labelStyle: GaugeTextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                              GaugeRange(
                                startValue: (gaugeMax / 1.5),
                                endValue: gaugeMax,
                                color: Colors.red,
                                label: 'Danger',
                                labelStyle: GaugeTextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                            ],
                            pointers: <GaugePointer>[
                              NeedlePointer(
                                value: value,
                                needleColor:
                                    pointerColor, // Dynamic pointer color
                                knobStyle: KnobStyle(
                                  color:
                                      needleCircleColor, // Color of the circle at the base of the needle
                                ),
                                tailStyle: TailStyle(
                                  color:
                                      pointerColor, // Tail color same as the pointer color
                                ),
                              ),
                            ],
                            axisLabelStyle: GaugeTextStyle(
                                fontSize: 12, color: Colors.black),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Position the value text absolutely
                Positioned(
                  bottom:
                      0, // Adjust this value to move the text closer or farther
                  child: Text(
                    '$value $unit',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Ensure value text is readable
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MethaneSensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double gaugeValue;
  final double gaugeMax;

  const MethaneSensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gaugeValue,
    required this.gaugeMax,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for icon and title on top-left
            Row(
              children: [
                Icon(icon, size: 40, color: Colors.blue),
                const SizedBox(width: 10), // Space between icon and title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
                height: 10), // Spacing between icon/title and bar gauge
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: gaugeValue),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Container(
                  width: 300, // Set the width for the bar gauge
                  height: 30, // Set the height for the bar gauge
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: (value / gaugeMax) *
                            300, // Set width based on gauge value
                        decoration: BoxDecoration(
                          color: getGaugeColor(value),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10), // Spacing between bar and value
            // Centered value text below the gauge
            Align(
              alignment: Alignment.center,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getGaugeColor(double value) {
    if (value <= 1024) {
      return Colors.green; // Safe
    } else if (value <= 2048) {
      return Colors.yellow; // Caution
    } else {
      return Colors.red; // Danger
    }
  }
}
