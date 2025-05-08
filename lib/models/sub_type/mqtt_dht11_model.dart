import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/sub_type/dht11_sensor_model.dart';
import 'package:extendable_aiot/services/mqtt_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MQTTEnabledDHT11Model extends DHT11SensorModel {
  static const String TYPE = 'dht11_mqtt'; // 設備類型

  final String deviceId; // 硬體裝置ID
  final String? roomTopic; // 特定房間的主題

  // MQTT 相關字段
  final MQTTService _mqttService = MQTTService();
  StreamSubscription? _mqttSubscription;
  bool _isConnected = false;

  // 保存最後更新時間
  DateTime _lastDataReceived = DateTime.now();

  // 定義狀態監聽器
  final List<Function(bool)> _onlineStatusListeners = [];
  final List<Function(double, double)> _dataUpdateListeners = [];

  /// 建構子 - 創建MQTT啟用的DHT11模型
  MQTTEnabledDHT11Model(
    super.id, {
    required super.name,
    required super.roomId,
    required super.lastUpdated,
    required this.deviceId,
    this.roomTopic,
    super.temperature = 25.0,
    super.humidity = 60.0,
    bool autoConnect = true, // 默認自動連接
  }) {
    if (autoConnect) {
      connectToMQTT();
    }
  }

  /// 獲取設備在線狀態
  bool get isOnline =>
      _isConnected &&
      DateTime.now().difference(_lastDataReceived).inMinutes < 2;

  /// 獲取最後更新時間
  DateTime get lastUpdatedTime => _lastDataReceived;

  /// 連接到MQTT服務並訂閱主題
  Future<void> connectToMQTT() async {
    debugPrint('連接至MQTT...');

    // 先建立MQTT連接
    if (!_mqttService.isConnected) {
      await _mqttService.connect();
      debugPrint('MQTT連接狀態: ${_mqttService.isConnected}');
    }

    // 訂閱房間sensor主題
    _mqttService.subscribe('esp32/sensors/$roomId');

    // 检查更新流是否可用
    if (_mqttService.updates == null) {
      debugPrint('警告: MQTT更新流为null');
    } else {
      debugPrint('MQTT更新流已就绪');
    }

    // topic 訂閱訊息
    _mqttSubscription = _mqttService.updates?.listen(
      _onMQTTMessage,
      onError: (error) => debugPrint('MQTT訂閱出現錯誤: $error'),
      onDone: () => debugPrint('MQTT訂閱已關閉'),
    );

    // 設定mqtt連接狀態
    _isConnected = _mqttService.isConnected;
    debugPrint('MQTT連接狀態已更新: $_isConnected');

    // 通知狀態更新
    _notifyOnlineStatusChanged(_isConnected);
  }

  /// 處理接收到的MQTT訊息
  void _onMQTTMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    debugPrint('收到 ${messages.length} 條MQTT訊息');
    for (var message in messages) {
      debugPrint('topic: ${message.topic}');

      // 将消息载荷解析为字串
      final MqttPublishMessage publishMessage =
          message.payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(
        publishMessage.payload.message,
      );

      debugPrint('訊息內容: $payload');

      if (message.topic.contains('esp32/sensors/$roomId')) {
        debugPrint('收來自esp32的數據');
        _handleDataMessage(payload);
      }
    }
  }

  /// 處理數據訊息
  void _handleDataMessage(String payload) {
    try {
      // 解析JSON數據
      Map<String, dynamic> data = jsonDecode(payload);

      // 檢查此數據是否適用於此設備
      if (_isDataForThisDevice(data)) {
        // 更新溫度和濕度
        double newTemp =
            data.containsKey('temp') ? _parseDoubleValue(data['temp']) : 0.0;

        double newHumidity =
            data.containsKey('humidity')
                ? _parseDoubleValue(data['humidity'])
                : 0.0;

        // 使用溫濕度更新模型數據
        updateSensorData(newTemp, newHumidity);

        // 更新時間戳
        _lastDataReceived = DateTime.now();

        // 通知數據更新
        _notifyDataUpdated(newTemp, newHumidity);

        // 如果設備不在線，更新狀態
        if (!_isConnected) {
          _isConnected = true;
          _notifyOnlineStatusChanged(true);
        }
      }
    } catch (e) {
      debugPrint('MQTTEnabledDHT11Model: 數據解析錯誤 - $e');
    }
  }

  /// 判斷數據是否專屬此設備
  bool _isDataForThisDevice(Map<String, dynamic> data) {
    // 檢查數據是否包含設備ID
    if (roomTopic != null) {
      roomTopic!.contains(roomId);
      return true;
    }

    // 如果沒有明確識別，默認接受所有DHT11數據
    return data.containsKey('temp') && data.containsKey('humidity');
  }

  /// 解析數值，處理不同類型的值
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

  /// 添加在線狀態變化監聽器
  void addOnlineStatusListener(Function(bool) listener) {
    _onlineStatusListeners.add(listener);
  }

  /// 移除在線狀態變化監聽器
  void removeOnlineStatusListener(Function(bool) listener) {
    _onlineStatusListeners.remove(listener);
  }

  /// 通知所有在線狀態監聽器
  void _notifyOnlineStatusChanged(bool status) {
    for (var listener in _onlineStatusListeners) {
      listener(status);
    }
  }

  /// 添加數據更新監聽器
  void addDataUpdateListener(Function(double, double) listener) {
    _dataUpdateListeners.add(listener);
  }

  /// 移除數據更新監聽器
  void removeDataUpdateListener(Function(double, double) listener) {
    _dataUpdateListeners.remove(listener);
  }

  /// 通知所有數據更新監聽器
  void _notifyDataUpdated(double temp, double humid) {
    for (var listener in _dataUpdateListeners) {
      listener(temp, humid);
    }
  }

  /// 發布測試數據到MQTT（用於測試）
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

  /// 斷開MQTT連接
  @override
  void dispose() {
    _mqttSubscription?.cancel();
    // 不要斷開MQTT連接，因為其他部分可能還在使用
    _onlineStatusListeners.clear();
    _dataUpdateListeners.clear();
  }

  /// 從資料庫創建MQTT啟用的DHT11模型
  static Future<MQTTEnabledDHT11Model?> fromDatabase(String deviceId) async {
    // 嘗試從數據庫中獲取DHT11設備信息
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      // 查詢所有設備
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('devices')
              .where('type', isEqualTo: 'dht11')
              .get();

      // 找到與設備ID匹配的設備
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

      // 沒找到匹配的設備
      return null;
    } catch (e) {
      debugPrint('從資料庫獲取DHT11設備失敗: $e');
      return null;
    }
  }

  /// 從字串型的deviceId與roomId創建臨時模型（不存到資料庫）
  static MQTTEnabledDHT11Model createTemporary(
    String deviceId, [
    String? roomId,
  ]) {
    return MQTTEnabledDHT11Model(
      '', // 臨時ID
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
