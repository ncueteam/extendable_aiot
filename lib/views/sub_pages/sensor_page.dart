import 'dart:convert';
import 'package:extendable_aiot/models/sensor_data.dart';
import 'package:extendable_aiot/services/mqtt_service.dart';
import 'package:flutter/material.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  final MQTTService _mqttService = MQTTService();
  SensorData? _lastData;

  @override
  void initState() {
    super.initState();
    _connectToMQTT();
  }

  Future<void> _connectToMQTT() async {
    await _mqttService.connect();
    _mqttService.subscribe('esp32/sensors', (payload) {
      final data = SensorData.fromJson(jsonDecode(payload));
      setState(() {
        _lastData = data;
      });
    });
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('感測器數據')),
      body: Center(
        child:
            _lastData == null
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSensorCard(
                      icon: Icons.thermostat,
                      title: '溫度',
                      value: '${_lastData!.temperature}°C',
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    _buildSensorCard(
                      icon: Icons.water_drop,
                      title: '濕度',
                      value: '${_lastData!.humidity}%',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '最後更新: ${_lastData!.timestamp}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
