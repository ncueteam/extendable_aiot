import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/switchable_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 冷气设备模型
class AirConditionerModel extends SwitchableModel {
  // 温度设置 (16°C-30°C)
  double temperature;

  // 模式设置 (Auto, Cool, Dry)
  String mode;

  // 风速设置 (Low, Mid, High)
  String fanSpeed;

  // 所属房间ID
  String roomId;

  // 模式选项
  static const List<String> modes = ['Auto', 'Cool', 'Dry'];

  // 风速选项
  static const List<String> fanSpeeds = ['Low', 'Mid', 'High'];

  AirConditionerModel(
    super.id, {
    required super.name,
    super.type = "air_conditioner", // 将类型统一为 air_conditioner
    required super.lastUpdated,
    super.icon = Icons.ac_unit,
    this.temperature = 25.0,
    this.mode = 'Auto',
    this.fanSpeed = 'Mid',
    this.roomId = '',
  });

  @override
  Future<void> createData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

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
    if (userId == null) throw Exception('User not authenticated');
    if (id.isEmpty) throw Exception('Device ID is required');

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(id)
            .get();

    if (!doc.exists) {
      throw Exception('Device not found');
    }

    // 从文档中读取数据
    final data = doc.data()!;
    fromJson(data);
  }

  @override
  Future<void> updateData() async {
    // 使用 SwitchableModel 的 updateData 方法
    await super.updateData();
  }

  @override
  Future<void> deleteData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    if (id.isEmpty) throw Exception('Device ID is required');

    // 从房间中移除设备引用
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .update({
          'devices': FieldValue.arrayRemove([id]),
        });

    // 删除设备文档 - 使用 SwitchableModel 的方法
    await super.deleteData();
  }

  @override
  fromJson(Map<String, dynamic> json) {
    super.fromJson(json); // 调用 SwitchableModel 的 fromJson
    temperature = (json['temperature'] as num?)?.toDouble() ?? 25.0;
    mode = json['mode'] as String? ?? 'Auto';
    fanSpeed = json['fanSpeed'] as String? ?? 'Mid';
    roomId = json['roomId'] as String? ?? '';
    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson(); // 获取 SwitchableModel 的 json
    json.addAll({
      'temperature': temperature,
      'mode': mode,
      'fanSpeed': fanSpeed,
      'roomId': roomId,
    });
    return json;
  }

  // 设置温度
  void setTemperature(double value) {
    // 确保温度在有效范围内
    if (value >= 16 && value <= 30) {
      temperature = value;
    }
  }

  // 设置模式
  void setMode(String value) {
    if (modes.contains(value)) {
      mode = value;
    }
  }

  // 设置风速
  void setFanSpeed(String value) {
    if (fanSpeeds.contains(value)) {
      fanSpeed = value;
    }
  }

  // 切换电源状态 - 使用继承的 status 字段
  void togglePower() {
    status = !status;
  }
}
