import 'dart:convert';
import 'package:extendable_aiot/models/sensor_data.dart';
import 'package:extendable_aiot/services/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:async';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  final MQTTService _mqttService = MQTTService();
  SensorData? _lastData;
  bool _deviceOnline = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _connectToMQTT();
  }

  Future<void> _connectToMQTT() async {
    await _mqttService.connect();

    // 訂閱所需的主題
    _mqttService.subscribe('esp32/sensors');
    _mqttService.subscribe('esp32/status');

    // 直接監聽MQTT訊息流
    _subscription = _mqttService.updates?.listen((
      List<MqttReceivedMessage<MqttMessage>> c,
    ) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        message.payload.message,
      );

      setState(() {
        if (c[0].topic == 'esp32/status') {
          _deviceOnline = payload == 'online';
        } else if (c[0].topic == 'esp32/sensors') {
          try {
            _lastData = SensorData.fromJson(jsonDecode(payload));
          } catch (e) {
            print('數據解析錯誤: $e');
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('感測器數據'),
        actions: [
          // 顯示設備在線狀態
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: _deviceOnline ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(_deviceOnline ? '在線' : '離線'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child:
            _lastData == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _deviceOnline ? '等待數據...' : '設備離線',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                )
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
