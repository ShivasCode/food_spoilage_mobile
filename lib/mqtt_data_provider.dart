import 'package:flutter/foundation.dart';

class MqttDataProvider with ChangeNotifier {
  double _temperature = 0.0;
  double _humidity = 0.0;
  int _methane = 0;

  double get temperature => _temperature;
  double get humidity => _humidity;
  int get methane => _methane;

  void updateSensorData(double temperature, double humidity, int methane) {
    _temperature = temperature;
    _humidity = humidity;
    _methane = methane;
    notifyListeners(); // Notify listeners to update UI
  }
}
