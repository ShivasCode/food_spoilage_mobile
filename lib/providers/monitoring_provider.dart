import 'package:flutter/material.dart';

class MonitoringProvider with ChangeNotifier {
  bool _isMonitoring = false;

  bool get isMonitoring => _isMonitoring;

  void startMonitoring() {
    _isMonitoring = true;
    notifyListeners();
  }

  void stopMonitoring() {
    _isMonitoring = false;
    notifyListeners();
  }
}
