import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SensorDataPage extends StatefulWidget {
  final int groupId;

  const SensorDataPage({super.key, required this.groupId});

  @override
  _SensorDataPageState createState() => _SensorDataPageState();
}

class _SensorDataPageState extends State<SensorDataPage> {
  List<dynamic> sensorData = [];
  Timer? _timer;

  Future<void> fetchSensorData() async {
    final url =
        '${dotenv.env['CLIENT_IP']}/monitoring-groups/${widget.groupId}/';
    print('Fetching data from: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token ${dotenv.env['TOKEN']}',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        setState(() {
          sensorData = jsonDecode(response.body)['sensor_data'];
        });
      } else {
        print('Failed to load sensor data: ${response.reasonPhrase}');
        throw Exception('Failed to load sensor data');
      }
    } catch (error) {
      print('Error occurred while fetching sensor data: $error');
    }
  }

  Future<void> exportCsv() async {
    final url =
        '${dotenv.env['CLIENT_IP']}/monitoring-groups/${widget.groupId}/export-csv/';
    print('Exporting CSV from: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token ${dotenv.env['TOKEN']}',
        },
      );

      print('Export response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message']),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        print('Failed to export CSV: ${response.reasonPhrase}');
        throw Exception('Failed to export CSV');
      }
    } catch (error) {
      print('Error occurred while exporting CSV: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error occurred while exporting CSV.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSensorData();
    _timer =
        Timer.periodic(const Duration(seconds: 60), (_) => fetchSensorData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await fetchSensorData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: exportCsv,
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: DataTable(
            columnSpacing: 0,
            dataRowHeight: 24,
            headingRowHeight: 24,
            columns: const [
              DataColumn(
                label: Text(
                  'Timestamp',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Temp',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Humidity',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Methane',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: sensorData.map((data) {
              return DataRow(cells: [
                DataCell(Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    data['formatted_timestamp'] ?? 'N/A',
                    style: const TextStyle(fontSize: 10),
                  ),
                )),
                DataCell(Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    '${data['temperature'] ?? 'N/A'} °C',
                    style: const TextStyle(fontSize: 10),
                  ),
                )),
                DataCell(Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    '${data['humidity'] ?? 'N/A'} %',
                    style: const TextStyle(fontSize: 10),
                  ),
                )),
                DataCell(Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    '${data['methane'] ?? 'N/A'} ppm',
                    style: const TextStyle(fontSize: 10),
                  ),
                )),
                DataCell(Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    children: [
                      Icon(
                        data['spoilage_status'] == 'food_is_spoiled'
                            ? Icons.cancel
                            : Icons.check_circle,
                        color: data['spoilage_status'] == 'food_is_spoiled'
                            ? Colors.red
                            : Colors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        data['spoilage_status'] == 'food_is_spoiled'
                            ? 'Spoiled'
                            : 'Fresh',
                        style: TextStyle(
                          fontSize: 10,
                          color: data['spoilage_status'] == 'food_is_spoiled'
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
