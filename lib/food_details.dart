import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/food_data.dart';
import 'mqtt_page.dart'; // Make sure to import your MqttClient setup or provider
import 'providers/mqtt_connection_provider.dart';
import 'package:provider/provider.dart'; // Import provider
import 'providers/mqtt_data_provider.dart';

class FoodDetailsPage extends StatelessWidget {
  final Food food; // Receive the Food object

  const FoodDetailsPage({Key? key, required this.food}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(food.name)),
      body: Stack(
        children: [
          // Solid Background
          Container(
            color: const Color(0xFFEEE2D0), // Background color
          ),
          // Wavy Background at the top
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(),
            ),
          ),
          // Scrollable Content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align content to the left
                children: [
                  // Food Name (Larger Text)
                  const SizedBox(height: 16), // Space between name and image
                  // Centered Image with Black Outline (Larger Image)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black, // Outline color
                          width: 4.0,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 80, // Larger radius for a bigger image
                        backgroundImage: AssetImage(food.image),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title aligned to the left
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 32, // Larger font size for the name
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left, // Align title to the left
                  ),
                  const SizedBox(height: 8),
                  // Description justified
                  Text(
                    food.description,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.justify, // Justify paragraphs
                  ),
                  const SizedBox(height: 16),
                  const Text("Storage Temperature",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(food.storageTemperature),
                  const SizedBox(height: 16),
                  const Text("Shelf Life",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(food.shelfLife),
                  const SizedBox(height: 16),
                  const Text("Signs of Spoilage",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...food.signsOfSpoilage.map((sign) => Text("- $sign")),
                  const SizedBox(height: 16),
                  // Centered Button
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFFB649), // Button background
                        foregroundColor: Colors.black, // Button text color
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                      ),
                      onPressed: () {
                        // Get the MQTT provider from the context
                        final mqttProvider =
                            Provider.of<MqttConnectionProvider>(context,
                                listen: false);

                        // Get the MqttDataProvider from the context
                        final mqttDataProvider = Provider.of<MqttDataProvider>(
                            context,
                            listen: false);

                        // Create the topic and payload
                        final String menuTopic =
                            'sensor/monitoring/${dotenv.env['TOKEN']}';
                        final String payload =
                            jsonEncode({'food_type': food.name.toLowerCase()});

                        // Use the MQTT provider's publishMenuChoice method
                        mqttProvider.publishMenuChoice(menuTopic, payload);

                        // Start monitoring in MqttDataProvider
                        mqttDataProvider.startMonitoring();

                        // Navigate to the next screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MqttExample(),
                          ),
                        );
                      },
                      child: const Text("Start Monitoring"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for wavy background
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBE9494) // Wave color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
          size.width / 8, size.height * 0.4, size.width / 2, size.height * 0.3)
      ..quadraticBezierTo(
          size.width * 4 / 4, size.height * 0.2, size.width, size.height * 0.3)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
