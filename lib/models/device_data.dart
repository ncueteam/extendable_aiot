import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/general_model.dart';
import 'package:extendable_aiot/models/switchable_model.dart';
import 'package:extendable_aiot/models/airconditioner_model.dart';
import 'package:extendable_aiot/models/dht11_sensor_model.dart';
import 'package:extendable_aiot/temp/sensor_page.dart';
import 'package:extendable_aiot/views/card/airconditioner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// 此类已被弃用，推荐使用 GeneralModel 及其子类
/// @deprecated 使用 SwitchableModel、AirConditionerModel 等代替
class DeviceData {
  /*---------------------------------------*/
  static const String TYPE_AC = '中央空調';
  static const String TYPE_FAN = '風扇';
  static const String TYPE_LIGHT = '燈光';
  static const String TYPE_CURTAIN = '窗簾';
  static const String TYPE_LOCK = '門鎖';
  static const String TYPE_SENSOR = '感測器';
  static const String TYPE_DHT11 = 'dht11';

  static List<String> deviceTypes = [
    TYPE_AC,
    TYPE_FAN,
    TYPE_LIGHT,
    TYPE_CURTAIN,
    TYPE_LOCK,
    TYPE_SENSOR,
    TYPE_DHT11,
  ];
  /*---------------------------------------*/
  final String id;
  String name;
  String type;
  bool status;
  Timestamp? lastUpdated;
  String? roomId;

  DeviceData(
    this.id, {
    required this.name,
    required this.type,
    required this.status,
    this.lastUpdated,
    this.roomId,
  });

  factory DeviceData.fromJson(String id, Map<String, dynamic> json) {
    return DeviceData(
      id,
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as bool,
      lastUpdated: json['lastUpdated'] as Timestamp?,
      roomId: json['roomId'] as String?,
    );
  }

  /// 从 DocumentSnapshot 创建 DeviceData
  factory DeviceData.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return DeviceData.fromJson(snapshot.id, data);
  }

  /// 转换为 GeneralModel 子类
  GeneralModel toModel() {
    switch (type) {
      case TYPE_AC:
        return AirConditionerModel(
          id,
          name: name,
          roomId: roomId ?? '',
          lastUpdated: lastUpdated ?? Timestamp.now(),
          status: status,
        );
      case TYPE_DHT11:
        return DHT11SensorModel(
          id,
          name: name,
          roomId: roomId ?? '',
          lastUpdated: lastUpdated ?? Timestamp.now(),
          temperature: 0.0,
          humidity: 0.0,
        );
      default:
        return SwitchableModel(
          id,
          name: name,
          type: type,
          lastUpdated: lastUpdated ?? Timestamp.now(),
          icon: _getIconForType(type),
          updateValue: [true, false],
          previousValue: [false, true],
          status: status,
        );
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'status': status,
    'lastUpdated': lastUpdated ?? Timestamp.now(),
    'roomId': roomId,
  };

  /// 获取设备对应的页面
  Widget getTargetPage() {
    switch (type) {
      case TYPE_AC:
        return Airconditioner(roomItem: toJson());
      // 使用新的设备模型，但保持向后兼容性
      default:
        return SensorPage(); // 預設頁面
    }
  }

  /// 根据设备类型获取对应图标
  static IconData _getIconForType(String type) {
    switch (type) {
      case TYPE_AC:
        return Icons.ac_unit;
      case TYPE_FAN:
        return Icons.wind_power;
      case TYPE_LIGHT:
        return Icons.lightbulb;
      case TYPE_CURTAIN:
        return Icons.curtains;
      case TYPE_LOCK:
        return Icons.lock;
      case TYPE_SENSOR:
        return Icons.sensors;
      case TYPE_DHT11:
        return Icons.thermostat;
      default:
        return Icons.device_unknown;
    }
  }

  /// 向 Firebase 保存设备数据 (使用新的读取方式)
  Future<void> saveToFirebase() async {
    final model = toModel();
    await model.updateData();
  }

  /// 从 Firebase 读取设备数据 (使用新的读取方式)
  static Future<DeviceData?> loadFromFirebase(String deviceId) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('devices')
              .doc(deviceId)
              .get();

      if (!doc.exists) return null;

      return DeviceData.fromSnapshot(doc);
    } catch (e) {
      print('读取设备错误: $e');
      return null;
    }
  }
}
