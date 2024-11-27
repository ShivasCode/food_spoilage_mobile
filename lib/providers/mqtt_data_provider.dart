import 'package:flutter/foundation.dart';

class MqttDataProvider with ChangeNotifier {
  // Sensor data
  double _temperature = 0.0;
  double _humidity = 0.0;
  double _methane = 0.0;
  double _ammonia = 0.0;

  String _spoilage_status = "";

  // Monitoring state
  bool _isMonitoring = false;

  // Connection status
  bool _isOnline = false;

  // Getters for sensor data
  double get temperature => _temperature;
  double get humidity => _humidity;
  double get methane => _methane;
  double get ammonia => _ammonia;

  String get spoilage_status => _spoilage_status;

  // Getter for monitoring state
  bool get isMonitoring => _isMonitoring;

  // Getter for online status
  bool get isOnline => _isOnline;

  // Method to update sensor data
  void updateSensorData(double temperature, double humidity, double methane,
      String spoilage_status, double ammonia) {
    _temperature = temperature;
    _humidity = humidity;
    _methane = methane;
    _spoilage_status = spoilage_status;
    _ammonia = ammonia;

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
    _humidity = 0.0;
    _methane = 0.0;
    _spoilage_status = "";
    _ammonia = 0.0;

    // Update online status to false when stopping
    _isOnline = false;

    notifyListeners(); // Notify listeners to update UI
  }
}
