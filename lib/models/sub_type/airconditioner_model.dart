import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/abstract/switchable_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 冷氣設備模型
class AirConditionerModel extends SwitchableModel {
  // 溫度設置 (16°C-30°C)
  double temperature;

  // 模式設置 (Auto, Cool, Dry)
  String mode;

  // 風速設置 (Low, Mid, High)
  String fanSpeed;

  // 所屬房間ID
  String roomId;

  // 模式選項
  static const List<String> modes = ['Auto', 'Cool', 'Dry'];

  // 風速選項
  static const List<String> fanSpeeds = ['Low', 'Mid', 'High'];

  AirConditionerModel(
    super.id, {
    required super.name,
    super.type = "air_conditioner", // 將類型統一為 air_conditioner
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
    if (userId == null) throw Exception('使用者未認證');

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
    if (userId == null) throw Exception('使用者未認證');
    if (id.isEmpty) throw Exception('設備ID為必填項');

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(id)
            .get();

    if (!doc.exists) {
      throw Exception('找不到設備');
    }

    // 從文檔中讀取數據
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
    if (userId == null) throw Exception('使用者未認證');
    if (id.isEmpty) throw Exception('設備ID為必填項');

    // 從房間中移除設備引用
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .update({
          'devices': FieldValue.arrayRemove([id]),
        });

    // 刪除設備文檔 - 使用 SwitchableModel 的方法
    await super.deleteData();
  }

  @override
  fromJson(Map<String, dynamic> json) {
    super.fromJson(json); // 調用 SwitchableModel 的 fromJson
    temperature = (json['temperature'] as num?)?.toDouble() ?? temperature;
    mode = json['mode'] as String? ?? mode;
    fanSpeed = json['fanSpeed'] as String? ?? fanSpeed;
    roomId = json['roomId'] as String? ?? roomId;
    // lastUpdated 已经在 GeneralModel 的 fromJson 中处理
    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson(); // 獲取 SwitchableModel 的 json
    json.addAll({
      'temperature': temperature,
      'mode': mode,
      'fanSpeed': fanSpeed,
      'roomId': roomId,
    });
    return json;
  }

  // 設置溫度
  void setTemperature(double value) {
    // 確保溫度在有效範圍內
    if (value >= 16 && value <= 30) {
      temperature = value;
    }
  }

  // 設置模式
  void setMode(String value) {
    if (modes.contains(value)) {
      mode = value;
    }
  }

  // 設置風速
  void setFanSpeed(String value) {
    if (fanSpeeds.contains(value)) {
      fanSpeed = value;
    }
  }

  // 切換電源狀態 - 使用繼承的 status 字段
  void togglePower() {
    status = !status;
  }
}
