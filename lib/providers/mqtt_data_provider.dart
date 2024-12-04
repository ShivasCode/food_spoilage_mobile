import 'package:flutter/foundation.dart';

class MqttDataProvider with ChangeNotifier {
  // Sensor data
  double _temperature = 0.0;
  double _methane = 0.0;
  double _ammonia = 0.0;
  String _spoilage_status = "";
  String _methane_status = "";
  String _temperature_status = "";
  String _storage_status = "";
  String _ammonia_status = ""; // Added ammonia status

  // Monitoring state
  bool _isMonitoring = false;

  // Connection status
  bool _isOnline = false;

  // Getters for sensor data
  double get temperature => _temperature;
  double get methane => _methane;
  double get ammonia => _ammonia;

  String get spoilage_status => _spoilage_status;
  String get methane_status => _methane_status;
  String get temperature_status => _temperature_status;
  String get storage_status => _storage_status;
  String get ammonia_status => _ammonia_status; // Getter for ammonia status

  // Getter for monitoring state
  bool get isMonitoring => _isMonitoring;

  // Getter for online status
  bool get isOnline => _isOnline;

  // Method to update sensor data
  void updateSensorData(
    double temperature,
    double methane,
    String spoilage_status,
    double ammonia,
    String methane_status,
    String temperature_status,
    String storage_status,
    String ammonia_status, // Added ammonia status parameter
  ) {
    _temperature = temperature;
    _methane = methane;
    _spoilage_status = spoilage_status;
    _ammonia = ammonia;
    _methane_status = methane_status;
    _temperature_status = temperature_status;
    _storage_status = storage_status;
    _ammonia_status = ammonia_status; // Update ammonia status

    notifyListeners(); // Notify listeners to update UI
  }

  // Method to update online status
  void updateStatusToOnline() {
    _isOnline = true;
    notifyListeners(); // Notify listeners to update UI
  }

  void updateStatusToOffline() {
    _isOnline = false;
    notifyListeners(); // Notify listeners to update UI
  }

  // Method to start monitoring
  void startMonitoring() {
    _isMonitoring = true;
    notifyListeners(); // Notify listeners to update UI
  }

  // Method to stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;

    // Reset sensor data to default values
    _temperature = 0.0;
    _methane = 0.0;
    _spoilage_status = "";
    _ammonia = 0.0;
    _methane_status = "";
    _temperature_status = "";
    _storage_status = "";
    _ammonia_status = ""; // Reset ammonia status

    // Update online status to false when stopping
    _isOnline = false;

    notifyListeners(); // Notify listeners to update UI
  }
}
