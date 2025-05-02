import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/sensor_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DHT11SensorModel extends SensorModel {
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
         type: 'dht11',
         icon: Icons.thermostat,
       );

  @override
  Future<void> createData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('用户未登录');

    // 如果未指定ID，Firebase会自动生成
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

    // 更新ID（如果是自动生成的）
    if (id.isEmpty) {
      id = docRef.id;
    }

    // 保存设备数据
    await docRef.set(toJson());

    // 更新房间的设备列表
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
    if (userId == null) throw Exception('用户未登录');
    if (id.isEmpty) throw Exception('设备ID不能为空');

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(id)
            .get();

    if (!doc.exists) {
      throw Exception('设备不存在');
    }

    // 从文档中读取数据
    final data = doc.data()!;
    fromJson(data);
  }

  @override
  Future<void> updateData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('用户未登录');
    if (id.isEmpty) throw Exception('设备ID不能为空');

    // 更新值数组
    value = [temperature, humidity];

    // 更新文档
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
    if (userId == null) throw Exception('用户未登录');
    if (id.isEmpty) throw Exception('设备ID不能为空');

    // 从房间中移除设备引用
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .update({
          'devices': FieldValue.arrayRemove([id]),
        });

    // 删除设备文档
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

  // 更新传感器数据
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
