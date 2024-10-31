import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:provider/provider.dart'; // Import provider
import 'mqtt_data_provider.dart'; // Import the data provider

void main() {
  runApp(MyApp());
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
  final client = MqttServerClient('192.168.55.105', 'flutter_mqtt_client');
  String token = '1b4980f3491893dbff45774c86555c583c987700';
  double temperature = 0.0;
  double humidity = 0.0;
  int methane = 0;
  String? notificationMessage;

  // Food choices
  final List<String> foodChoices = ['menudo', 'adobo', 'mechado'];
  String selectedFood = 'menudo'; // Default selection

  @override
  void initState() {
    super.initState();
    connectToMqtt();
  }

  Future<void> connectToMqtt() async {
    client.port = 1883;
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_mqtt_client')
        .withWillTopic('willtopic')
        .withWillMessage('Connection closed abnormally..')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect('admin', 'admin'); // MQTT broker credentials
    } on Exception catch (e) {
      print('ERROR: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT connected');
      subscribeToTopics();
    } else {
      print('ERROR: MQTT connection failed - ${client.connectionStatus}');
    }
  }

  void subscribeToTopics() {
    final String sensorDataTopic = 'sensor/data/$token';
    final String notificationTopic = 'sensor/notification/$token';
    final String menuTopic =
        'sensor/menu/$token'; // Subscribe to the menu topic

    client.subscribe(sensorDataTopic, MqttQos.atMostOnce);
    client.subscribe(notificationTopic, MqttQos.atMostOnce);
    client.subscribe(
        menuTopic, MqttQos.atMostOnce); // Subscribe to the menu topic

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      for (var message in messages!) {
        final MqttPublishMessage recMessage =
            message.payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(
            recMessage.payload.message);

        if (message.topic == sensorDataTopic) {
          handleSensorData(payload);
        } else if (message.topic == notificationTopic) {
          handleNotification(payload);
        } else if (message.topic == menuTopic) {
          handleMenuData(payload); // Handle menu data
        }
      }
    });
  }

  void handleSensorData(String payload) {
    final data = jsonDecode(payload);
    double temperature = data['temperature'] ?? 0.0;
    double humidity = data['humidity'] ?? 0.0;
    int methane = data['methane'] ?? 0;

    // Update the provider with new sensor data
    Provider.of<MqttDataProvider>(context, listen: false)
        .updateSensorData(temperature, humidity, methane);

    // Update local state (optional)
    setState(() {
      this.temperature = temperature;
      this.humidity = humidity;
      this.methane = methane;
    });
  }

  void handleNotification(String payload) {
    final notificationData = jsonDecode(payload);
    final notificationId = notificationData['id'];

    setState(() {
      notificationMessage = notificationData['message'];
    });

    print('Received notification: $notificationMessage');
    print('Received notification id: $notificationId');

    if (notificationMessage != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('New Notification'),
            content: Text(notificationMessage!),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  markNotificationAsRead(notificationId).then((_) {
                    setState(() {
                      notificationMessage = null;
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
  }

  void handleMenuData(String payload) {
    // Handle the menu data received from the MQTT topic
    print('Received menu data: $payload');
    // Add your logic to handle menu data here
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final String url =
        'http://192.168.55.105:8000/notifications/acknowledge/$notificationId/';
    final response = await http.post(Uri.parse(url));
    print(response);

    if (response.statusCode == 200) {
      print('Notification ID $notificationId marked as read.');
    } else {
      print('Failed to mark notification as read: ${response.body}');
    }
  }

  void onConnected() {
    print('Connected to MQTT broker');
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  Future<void> publishMenuChoice() async {
    final String menuTopic = 'sensor/menu/$token';
    final payload = jsonEncode({'food_type': selectedFood});
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    client.publishMessage(menuTopic, MqttQos.atLeastOnce, builder.payload!);
    print('Published message to $menuTopic: $payload');
  }

  @override
  Widget build(BuildContext context) {
    final mqttData = Provider.of<MqttDataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedFood,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFood = newValue!;
                      });
                    },
                    isExpanded: true,
                    items: foodChoices
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    publishMenuChoice();
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Display the sensor values from the provider
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: mqttData.temperature),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return SensorCard(
                  title: 'Temperature',
                  value: '${value.toStringAsFixed(2)} °C',
                  icon: Icons.thermostat,
                  gaugeValue: value,
                  gaugeMax: 100,
                );
              },
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: mqttData.humidity),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return SensorCard(
                  title: 'Humidity',
                  value: '${value.toStringAsFixed(2)} %',
                  icon: Icons.water_drop,
                  gaugeValue: value,
                  gaugeMax: 100,
                );
              },
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: mqttData.methane.toDouble()),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return MethaneSensorCard(
                  title: 'Methane',
                  value: '$value ppm',
                  icon: Icons.air,
                  gaugeValue: value,
                  gaugeMax: 4095,
                );
              },
            ),
          ],
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

  const SensorCard({
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 300, // Increased width
              height: 250, // Increased height
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: gaugeMax,
                    interval: 10,
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 0,
                        endValue: 10, // Safe (0 to 10°C)
                        color: Colors.green,
                        label: 'Safe',
                      ),
                      GaugeRange(
                        startValue: 10,
                        endValue: 25, // Caution (10 to 25°C)
                        color: Colors.yellow,
                        label: 'Caution',
                      ),
                      GaugeRange(
                        startValue: 25,
                        endValue: gaugeMax, // Danger (Above 25°C)
                        color: Colors.red,
                        label: 'Danger',
                      ),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(value: gaugeValue),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 0), // Spacing between gauge and text
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.blue),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Bar gauge for Methane
            Container(
              width: 300, // Set the width for the bar gauge
              height: 30, // Set the height for the bar gauge
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Container(
                    width: (gaugeValue / gaugeMax) *
                        300, // Set width based on gauge value
                    decoration: BoxDecoration(
                      color: getGaugeColor(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10), // Spacing between gauge and text
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.blue),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color getGaugeColor() {
    if (gaugeValue <= 1024) {
      return Colors.green; // Safe
    } else if (gaugeValue <= 2048) {
      return Colors.yellow; // Caution
    } else {
      return Colors.red; // Danger
    }
  }
}
