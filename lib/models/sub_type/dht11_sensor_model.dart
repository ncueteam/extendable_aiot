import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/abstract/sensor_model.dart';
import 'package:extendable_aiot/models/sub_type/mqtt_dht11_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DHT11SensorModel extends SensorModel {
  static const String TYPE = 'dht11'; // 設備類型

  double temperature;
  double humidity;
  String roomId;
  static const double MIN_TEMPERATURE = 0.0;
  static const double MAX_TEMPERATURE = 50.0;
  static const double MIN_HUMIDITY = 20.0;
  static const double MAX_HUMIDITY = 90.0;

  DHT11SensorModel(
    super.id, {
    required super.name,
    required this.roomId,
    required super.lastUpdated,
    this.temperature = 25.0,
    this.humidity = 60.0,
    bool status = false,
  }) : super(
         value: [temperature, humidity],
         type: MQTTEnabledDHT11Model.TYPE,
         icon: Icons.thermostat,
       );

  @override
  Future<void> createData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('使用者未登入');

    // 如果未指定ID，Firebase會自動生成
    final docRef =
        id.isEmpty
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('devices')
                .doc()
            : FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('devices')
                .doc(id);

    // 更新ID（如果是自動生成的）
    if (id.isEmpty) {
      id = docRef.id;
    }

    // 儲存設備資料
    await docRef.set(toJson());

    // 更新房間的設備列表
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .update({
          'devices': FieldValue.arrayUnion([id]),
        });
  }

  @override
  Future<void> readData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('使用者未登入');
    if (id.isEmpty) throw Exception('設備ID不能為空');

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(id)
            .get();

    if (!doc.exists) {
      throw Exception('設備不存在');
    }

    // 從文檔中讀取數據
    final data = doc.data()!;
    fromJson(data);
  }

  @override
  Future<void> updateData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('使用者未登入');
    if (id.isEmpty) throw Exception('設備ID不能為空');

    // 更新值數組
    value = [temperature, humidity];

    // 更新文檔
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(id)
        .update(toJson());
  }

  @override
  Future<void> deleteData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('使用者未登入');
    if (id.isEmpty) throw Exception('設備ID不能為空');

    // 從房間中移除設備引用
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .update({
          'devices': FieldValue.arrayRemove([id]),
        });

    // 刪除設備文檔
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(id)
        .delete();
  }

  @override
  fromJson(Map<String, dynamic> json) {
    super.fromJson(json);
    temperature = (json['temperature'] as num?)?.toDouble() ?? 25.0;
    humidity = (json['humidity'] as num?)?.toDouble() ?? 60.0;
    roomId = json['roomId'] as String? ?? '';
    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'temperature': temperature,
      'humidity': humidity,
      'roomId': roomId,
    });
    return json;
  }

  // 更新感測器資料
  void updateSensorData(double newTemp, double newHumidity) {
    if (newTemp >= MIN_TEMPERATURE && newTemp <= MAX_TEMPERATURE) {
      temperature = newTemp;
    }
    if (newHumidity >= MIN_HUMIDITY && newHumidity <= MAX_HUMIDITY) {
      humidity = newHumidity;
    }
    value = [temperature, humidity];
  }
}
