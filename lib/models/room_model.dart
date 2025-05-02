import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// 房间模型类
class RoomModel {
  String id; // 房间ID（Firestore文档ID）
  String name; // 房间名称
  List<String> devices = []; // 设备ID列表
  Timestamp createdAt; // 创建时间
  IconData icon; // 房间图标

  /// 构造函数
  RoomModel({
    required this.id,
    required this.name,
    List<String>? devices,
    Timestamp? createdAt,
    IconData? icon,
  }) : this.devices = devices ?? [],
       this.createdAt = createdAt ?? Timestamp.now(),
       this.icon = icon ?? Icons.meeting_room;

  /// 从Json数据创建RoomModel对象
  factory RoomModel.fromJson(String docId, Map<String, dynamic> json) {
    return RoomModel(
      id: docId,
      name: json['name'] as String? ?? '未命名房間',
      devices:
          json['devices'] != null ? List<String>.from(json['devices']) : [],
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
      icon:
          json['icon'] != null
              ? IconData(json['icon'] as int, fontFamily: 'MaterialIcons')
              : Icons.meeting_room,
    );
  }

  /// 从Firestore文档创建RoomModel对象
  factory RoomModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      return RoomModel(id: snapshot.id, name: '未命名房間');
    }
    return RoomModel.fromJson(snapshot.id, data);
  }

  /// 转换为Json数据
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'devices': devices,
      'createdAt': createdAt,
      'icon': icon.codePoint,
    };
  }

  /// 从Firestore加载房间数据
  static Future<RoomModel?> getRoom(String roomId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('rooms')
              .doc(roomId)
              .get();

      if (!doc.exists) {
        return null;
      }

      return RoomModel.fromSnapshot(doc);
    } catch (e) {
      print('Error loading room: $e');
      return null;
    }
  }

  /// 获取所有房间的流
  static Stream<List<RoomModel>> getAllRooms() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RoomModel.fromSnapshot(doc))
              .toList();
        });
  }

  /// 创建新房间
  Future<bool> createRoom() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      // 创建新房间文档
      final roomRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('rooms')
              .doc();

      // 更新ID
      id = roomRef.id;

      // 保存房间数据
      await roomRef.set(toJson());
      return true;
    } catch (e) {
      print('Error creating room: $e');
      return false;
    }
  }

  /// 更新房间信息
  Future<bool> updateRoom() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('rooms')
          .doc(id)
          .update(toJson());
      return true;
    } catch (e) {
      print('Error updating room: $e');
      return false;
    }
  }

  /// 删除房间
  Future<bool> deleteRoom() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('rooms')
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting room: $e');
      return false;
    }
  }

  /// 添加设备到房间
  Future<bool> addDevice(String deviceId) async {
    try {
      if (devices.contains(deviceId)) {
        return true; // 设备已在房间中
      }

      devices.add(deviceId);
      await updateRoom();
      return true;
    } catch (e) {
      print('Error adding device to room: $e');
      return false;
    }
  }

  /// 从房间移除设备
  Future<bool> removeDevice(String deviceId) async {
    try {
      devices.remove(deviceId);
      await updateRoom();
      return true;
    } catch (e) {
      print('Error removing device from room: $e');
      return false;
    }
  }

  /// 加载房间内的所有设备
  Future<List<DocumentSnapshot>> loadDevices() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      if (devices.isEmpty) {
        return [];
      }

      // 检查设备列表长度，Firestore的whereIn查询限制为10个元素
      List<DocumentSnapshot> result = [];

      // 分批处理，每批最多10个设备ID
      for (int i = 0; i < devices.length; i += 10) {
        final int end = (i + 10 < devices.length) ? i + 10 : devices.length;
        final List<String> batch = devices.sublist(i, end);

        final QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('devices')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        result.addAll(querySnapshot.docs);
      }

      return result;
    } catch (e) {
      print('Error loading devices for room: $e');
      return [];
    }
  }

  /// 获取房间内所有设备的实时流
  Stream<List<DocumentSnapshot>> devicesStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || devices.isEmpty) {
      return Stream.value([]);
    }

    // 由于Firestore的whereIn查询限制，我们需要处理设备ID超过10个的情况
    // 创建多个查询并合并结果
    if (devices.length <= 10) {
      // 如果设备少于10个，直接返回查询结果
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .where(FieldPath.documentId, whereIn: devices)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    } else {
      // 对于超过10个设备的情况，我们需要手动合并多个流
      // 这是一个简化的实现，实际应用中可能需要更复杂的逻辑

      // 创建一个可广播的控制器
      final controller = StreamController<List<DocumentSnapshot>>.broadcast();

      // 分批处理设备ID
      List<Stream<List<DocumentSnapshot>>> streams = [];

      for (int i = 0; i < devices.length; i += 10) {
        final int end = (i + 10 < devices.length) ? i + 10 : devices.length;
        final List<String> batch = devices.sublist(i, end);

        // 创建查询流
        final stream = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .where(FieldPath.documentId, whereIn: batch)
            .snapshots()
            .map((snapshot) => snapshot.docs);

        streams.add(stream);
      }

      // 合并所有流的结果
      int completedStreams = 0;
      List<List<DocumentSnapshot>> results = List.filled(streams.length, []);

      for (int i = 0; i < streams.length; i++) {
        final int index = i;
        streams[i].listen(
          (data) {
            results[index] = data;
            // 合并所有结果并发送
            List<DocumentSnapshot> combined = [];
            for (var result in results) {
              combined.addAll(result);
            }
            controller.add(combined);
          },
          onError: (error) {
            controller.addError(error);
          },
          onDone: () {
            completedStreams++;
            if (completedStreams == streams.length) {
              controller.close();
            }
          },
        );
      }

      return controller.stream;
    }
  }
}
