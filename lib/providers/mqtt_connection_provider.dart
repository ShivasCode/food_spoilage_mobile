import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
// import 'package:provider/provider.dart'; // Import provider
// import 'mqtt_data_provider.dart';
// import 'dart:convert';

class MqttConnectionProvider with ChangeNotifier {
  late MqttClient client;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  int _reconnectAttempts = 0; // Retry counter

  MqttClient get mqttClient => client;

  // DateTime _lastStatusReceived = DateTime.now();
  // late Timer _statusCheckTimer;

  // Create StreamControllers to handle different topics
  final _sensorDataController = StreamController<String>.broadcast();
  final _notificationController = StreamController<String>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get sensorDataStream => _sensorDataController.stream;
  Stream<String> get notificationStream => _notificationController.stream;

  MqttConnectionProvider() {
    client =
        MqttServerClient('${dotenv.env['MQTT_SERVER']}', 'flutter_mqtt_client');
    client.port = 1883;
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  // Connect to the MQTT broker with automatic retries
  Future<void> connectToMqtt() async {
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
      _isConnected = true;
      _reconnectAttempts =
          0; // Reset retry attempts after successful connection
      subscribeToTopics();
      notifyListeners(); // Notify listeners that the connection is established
    } else {
      print('ERROR: MQTT connection failed - ${client.connectionStatus}');
      _isConnected = false;
      _reconnectAttempts++;
      notifyListeners();
      // _attemptReconnect(); // Try to reconnect if the connection fails
    }
  }

  // Attempt to reconnect if the connection fails
  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts < 5) {
      // Limit the number of retry attempts to 5
      print('Retrying connection... Attempt $_reconnectAttempts');
      await Future.delayed(Duration(seconds: 5)); // Wait before retrying
      connectToMqtt(); // Try reconnecting
    } else {
      print('Max reconnect attempts reached. Giving up.');
    }
  }

  void subscribeToTopics() {
    final String statusTopic = 'device/status/${dotenv.env['TOKEN']}';
    final String sensorDataTopic = 'sensor/data/${dotenv.env['TOKEN']}';
    final String notificationTopic =
        'sensor/notification/${dotenv.env['TOKEN']}';
    final String menuTopic = 'sensor/menu/${dotenv.env['TOKEN']}';

    client.subscribe(sensorDataTopic, MqttQos.atMostOnce);
    client.subscribe(notificationTopic, MqttQos.atMostOnce);
    client.subscribe(menuTopic, MqttQos.atMostOnce);
    client.subscribe(statusTopic, MqttQos.atMostOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      for (var message in messages!) {
        final MqttPublishMessage recMessage =
            message.payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(
            recMessage.payload.message);

        if (message.topic == sensorDataTopic) {
          // Push data to the StreamController for the relevant topic
          _sensorDataController.add(payload);
          print(_sensorDataController);
          print('received controller');
        } else if (message.topic == notificationTopic) {
          // Push notification data to its StreamController
          _notificationController.add(payload);
        } else if (message.topic == statusTopic) {
          _statusController
              .add("true"); // Assume receiving message means online
        }
      }
    });
  }

  // Callback when the connection is lost
  void _onDisconnected() {
    _isConnected = false;
    print('Disconnected from MQTT broker');
    notifyListeners();
    // Automatically attempt to reconnect when disconnected
    _attemptReconnect();
  }

  // Callback when connected to the MQTT broker
  void _onConnected() {
    _isConnected = true;
    print('Connected to MQTT broker');

    subscribeToTopics();
    notifyListeners();
  }

  // Callback when a topic is successfully subscribed
  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void disconnect() {
    client.disconnect();
    _isConnected = false;
    _sensorDataController
        .close(); // Close the StreamController when disconnecting
    _notificationController.close();
    notifyListeners();
  }

  Future<void> publishMenuChoice(String menuTopic, String payload) async {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload); // Add your payload as string

      // Publish the message to the given topic
      client.publishMessage(menuTopic, MqttQos.atLeastOnce, builder.payload!);
      print('Published message to $menuTopic: $payload');
    } else {
      print('Cannot publish message, MQTT client is not connected.');
    }
  }
}
