import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/sub_type/dht11_sensor_model.dart';
import 'package:extendable_aiot/services/mqtt_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MQTTEnabledDHT11Model extends DHT11SensorModel {
  static const String TYPE = 'dht11_mqtt';

  final String deviceId;
  final String? roomTopic;

  final MQTTService _mqttService = MQTTService();
  StreamSubscription? _mqttSubscription;
  bool _isConnected = false;
  DateTime _lastDataReceived = DateTime.now();
  final List<Function(bool)> _onlineStatusListeners = [];
  final List<Function(double, double)> _dataUpdateListeners = [];
  MQTTEnabledDHT11Model(
    super.id, {
    required super.name,
    required super.roomId,
    required super.lastUpdated,
    required this.deviceId,
    this.roomTopic,
    super.temperature = 25.0,
    super.humidity = 60.0,
    bool autoConnect = true,
  }) {
    if (autoConnect) {
      connectToMQTT();
    }
  }
  bool get isOnline =>
      _isConnected &&
      DateTime.now().difference(_lastDataReceived).inMinutes < 2;
  DateTime get lastUpdatedTime => _lastDataReceived;
  Future<void> connectToMQTT() async {
    // debugPrint('連接至MQTT...');
    if (!_mqttService.isConnected) {
      await _mqttService.connect();
      // debugPrint('MQTT連接狀態: ${_mqttService.isConnected}');
    }
    _mqttService.subscribe('esp32/sensors/$roomId');
    // if (_mqttService.updates == null) {
    //   debugPrint('警告: MQTT更新流为null');
    // } else {
    //   debugPrint('MQTT更新流已就绪');
    // }
    _mqttSubscription = _mqttService.updates?.listen(
      _onMQTTMessage,
      // onError: (error) => debugPrint('MQTT訂閱出現錯誤: $error'),
      // onDone: () => debugPrint('MQTT訂閱已關閉'),
    );
    _isConnected = _mqttService.isConnected;
    // debugPrint('MQTT連接狀態已更新: $_isConnected');
    // _notifyOnlineStatusChanged(_isConnected);
  }

  void _onMQTTMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    // debugPrint('收到 ${messages.length} 條MQTT訊息');
    for (var message in messages) {
      // debugPrint('topic: ${message.topic}');
      final MqttPublishMessage publishMessage =
          message.payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(
        publishMessage.payload.message,
      );

      // debugPrint('訊息內容: $payload');

      if (message.topic.contains('esp32/sensors/$roomId')) {
        // debugPrint('收來自esp32的數據');
        _handleDataMessage(payload);
      }
    }
  }

  void _handleDataMessage(String payload) {
    try {
      Map<String, dynamic> data = jsonDecode(payload);

      if (_isDataForThisDevice(data)) {
        double newTemp =
            data.containsKey('temp') ? _parseDoubleValue(data['temp']) : 0.0;
        double newHumidity =
            data.containsKey('humidity')
                ? _parseDoubleValue(data['humidity'])
                : 0.0;
        updateSensorData(newTemp, newHumidity);
        _lastDataReceived = DateTime.now();
        _notifyDataUpdated(newTemp, newHumidity);
        if (!_isConnected) {
          _isConnected = true;
          _notifyOnlineStatusChanged(true);
        }
      }
    } catch (e) {
      // debugPrint('MQTTEnabledDHT11Model: 數據解析錯誤 - $e');
    }
  }

  bool _isDataForThisDevice(Map<String, dynamic> data) {
    if (roomTopic != null) {
      roomTopic!.contains(roomId);
      return true;
    }
    return data.containsKey('temp') && data.containsKey('humidity');
  }

  double _parseDoubleValue(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return (double.parse(value) * 100).round() / 100;
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  void addOnlineStatusListener(Function(bool) listener) {
    _onlineStatusListeners.add(listener);
  }

  void removeOnlineStatusListener(Function(bool) listener) {
    _onlineStatusListeners.remove(listener);
  }

  void _notifyOnlineStatusChanged(bool status) {
    for (var listener in _onlineStatusListeners) {
      listener(status);
    }
  }

  void addDataUpdateListener(Function(double, double) listener) {
    _dataUpdateListeners.add(listener);
  }

  void removeDataUpdateListener(Function(double, double) listener) {
    _dataUpdateListeners.remove(listener);
  }

  void _notifyDataUpdated(double temp, double humid) {
    for (var listener in _dataUpdateListeners) {
      listener(temp, humid);
    }
  }

  void publishTestData() {
    if (_mqttService.isConnected) {
      final data = {
        'deviceId': deviceId,
        'temp': temperature + (DateTime.now().millisecondsSinceEpoch % 5) - 2,
        'humidity': humidity + (DateTime.now().millisecondsSinceEpoch % 10) - 5,
      };

      _mqttService.publish('esp32/sensors/$roomId', jsonEncode(data));
    }
  }

  void dispose() {
    _mqttSubscription?.cancel();
    _onlineStatusListeners.clear();
    _dataUpdateListeners.clear();
  }

  static Future<MQTTEnabledDHT11Model?> fromDatabase(String deviceId) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('devices')
              .where('type', isEqualTo: 'dht11')
              .get();
      final matchingDevices = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['deviceId'] == deviceId;
      });

      if (matchingDevices.isNotEmpty) {
        final doc = matchingDevices.first;
        final data = doc.data();

        return MQTTEnabledDHT11Model(
          doc.id,
          name: data['name'] ?? 'DHT11 傳感器',
          roomId: data['roomId'] ?? '',
          roomTopic: data['roomId'],
          deviceId: deviceId,
          lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
          temperature: data['temperature'] ?? 25.0,
          humidity: data['humidity'] ?? 60.0,
        );
      }
      return null;
    } catch (e) {
      // debugPrint('從資料庫獲取DHT11設備失敗: $e');
      return null;
    }
  }

  static MQTTEnabledDHT11Model createTemporary(
    String deviceId, [
    String? roomId,
  ]) {
    return MQTTEnabledDHT11Model(
      '',
      name: 'DHT11 $deviceId',
      roomId: roomId ?? '',
      roomTopic: roomId,
      deviceId: deviceId,
      lastUpdated: Timestamp.now(),
      temperature: 0.0,
      humidity: 0.0,
    );
  }
}
