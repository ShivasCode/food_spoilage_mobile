import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Import provider
import 'providers/mqtt_connection_provider.dart';
import 'providers/mqtt_data_provider.dart'; // Import the data provider
import 'providers/monitoring_provider.dart';

import 'login.dart';
import 'food_selection.dart';
// import 'monitoring_groups_page.dart';
// import 'charts_page.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MqttConnectionProvider()),
        ChangeNotifierProvider(create: (context) => MqttDataProvider()),
        ChangeNotifierProvider(create: (context) => MonitoringProvider()),
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
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEEE2D0),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          bodyMedium: GoogleFonts.roboto(),
          titleMedium: GoogleFonts.roboto(fontSize: 16),
        ),
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          elevation: 2,
          backgroundColor: Color(0xFFEEE2D0),
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token != null) {
      // Token exists, navigate to FoodSelectionPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FoodSelection()),
      );
    } else {
      // No token, navigate to LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Splash loading indicator
      ),
    );
  }
}
