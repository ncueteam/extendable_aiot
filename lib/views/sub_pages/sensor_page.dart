import 'dart:convert';
import 'package:extendable_aiot/models/sensor_data.dart';
import 'package:extendable_aiot/services/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  // 添加DHT11特定訂閱主題
  final String _dht11Topic = 'esp32/sensors/dht11';

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
    // 訂閱DHT11特定主題
    _mqttService.subscribe(_dht11Topic);

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
        } else if (c[0].topic == 'esp32/sensors' || c[0].topic == _dht11Topic) {
          try {
            _lastData = SensorData.fromJson(jsonDecode(payload));
            print(
              '接收到DHT11數據: ${_lastData!.temperature}°C, ${_lastData!.humidity}%',
            );

            // 更新與此感測器相關聯的所有DHT11設備
            _updateDHT11DevicesInFirebase();
          } catch (e) {
            print('數據解析錯誤: $e');
          }
        }
      });
    });
  }

  // 更新Firebase中的DHT11傳感器數據
  Future<void> _updateDHT11DevicesInFirebase() async {
    if (_lastData == null) return;

    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // 獲取所有DHT11類型的設備
      final devicesSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('devices')
              .where('type', isEqualTo: 'dht11')
              .get();

      if (devicesSnapshot.docs.isEmpty) {
        print('沒有找到DHT11設備');
        return;
      }

      // 更新每個DHT11設備的溫度和濕度
      for (var doc in devicesSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(doc.id)
            .update({
              'temperature': _lastData!.temperature,
              'humidity': _lastData!.humidity,
              'lastUpdated': Timestamp.now(),
            });

        print('已更新DHT11設備 ${doc.id} 的數據');
      }
    } catch (e) {
      print('更新DHT11設備數據時出錯: $e');
    }
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
