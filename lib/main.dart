import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import provider
import 'mqtt_page.dart';
import 'monitoring_groups_page.dart';
import 'charts_page.dart';
import 'mqtt_data_provider.dart'; // Import the data provider

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MqttDataProvider(),
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
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          bodyMedium: GoogleFonts.roboto(), // Set Roboto for general body text
          titleMedium: GoogleFonts.roboto(fontSize: 16), // Roboto for subtitles
        ),
        primarySwatch: Colors.blue, // Set the primary color
        appBarTheme: const AppBarTheme(
          elevation: 2, // Slight elevation for shadow
        ),
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // Track the selected tab

  // List of pages corresponding to each tab
  final List<Widget> _pages = [
    MqttExample(), // First tab
    MonitoringGroupsPage(), // Second tab
    ChartsPage(), // Placeholder for the charts page
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.device_hub, size: 28), // Add an icon to the title
            SizedBox(width: 10), // Space between icon and title
            Text(
              'Food Spoilage Monitoring',
              style: GoogleFonts.poppins(
                // Use Poppins specifically in AppBar title
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent, // Set a distinct background color
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _pages[_selectedIndex], // Display the selected page
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.device_hub),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped, // Handle tab selection
      ),
    );
  }
}
