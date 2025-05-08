// filepath: d:\workspace\study\extendable_aiot\lib\models\device_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/sub_type/mqtt_dht11_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:extendable_aiot/models/abstract/general_model.dart';
import 'package:flutter/material.dart';
import 'package:extendable_aiot/models/sub_type/dht11_sensor_model.dart';
import 'package:extendable_aiot/models/sub_type/airconditioner_model.dart';

class DeviceModel {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 獲取當前用戶ID
  static String? get currentUserId => _auth.currentUser?.uid;
  static GeneralModel? fromDocumentSnapshot(
    DocumentSnapshot snapshot, [
    IconData Function(String)? getIconForType,
  ]) {
    try {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return null;

      final String type = data['type'] as String? ?? '未知';
      final String name = data['name'] as String? ?? '未命名設備';
      final Timestamp lastUpdated =
          data['lastUpdated'] as Timestamp? ?? Timestamp.now();
      final bool status = data['status'] as bool? ?? false;

      switch (type) {
        case 'air_conditioner':
          final acDevice = AirConditionerModel(
            snapshot.id,
            name: name,
            roomId: data['roomId'] ?? '',
            lastUpdated: lastUpdated,
          );
          acDevice.fromJson(data);
          return acDevice;
        case DHT11SensorModel.TYPE:
          return DHT11SensorModel(
            snapshot.id,
            name: name,
            roomId: data['roomId'] ?? '',
            lastUpdated: lastUpdated,
            temperature: data['temperature'] ?? 0.0,
            humidity: data['humidity'] ?? 0.0,
          );
        case MQTTEnabledDHT11Model.TYPE:
          return MQTTEnabledDHT11Model(
            snapshot.id,
            name: name,
            roomId: data['roomId'] ?? '',
            lastUpdated: lastUpdated,
            deviceId: data['deviceId'] ?? '',
            roomTopic: data['roomTopic'],
          );
        default:
          throw Exception('未知設備類型: $type');
      }
    } catch (e) {
      print('創建設備模型錯誤: $e');
      return null;
    }
  }

  /// 添加設備到指定房間
  ///
  /// 參數:
  /// - [device]: 設備模型實例，必須繼承自 GeneralModel
  /// - [roomId]: 房間 ID
  ///
  /// 返回:
  /// - 成功添加設備後返回 true，否則返回 false
  static Future<bool> addDeviceToRoom(
    GeneralModel device,
    String roomId,
  ) async {
    if (currentUserId == null) return false;

    try {
      // 首先創建設備
      await device.createData();

      // 然後將設備ID添加到房間中
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('rooms')
          .doc(roomId)
          .update({
            'devices': FieldValue.arrayUnion([device.id]),
          });

      return true;
    } catch (e) {
      print('添加設備到房間錯誤: $e');
      return false;
    }
  }

  /// 更新設備狀態
  ///
  /// 參數:
  /// - [deviceId]: 設備 ID
  /// - [status]: 新的設備狀態
  ///
  /// 返回:
  /// - 成功更新設備狀態後返回 true，否則返回 false
  static Future<bool> updateDeviceStatus({
    required String deviceId,
    required bool status,
  }) async {
    if (currentUserId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('devices')
          .doc(deviceId)
          .update({
            'status': status,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      print('更新設備狀態錯誤: $e');
      return false;
    }
  }

  /// 從指定房間移除設備
  ///
  /// 參數:
  /// - [deviceId]: 設備 ID
  /// - [roomId]: 房間 ID
  /// - [deleteDevice]: 是否同時刪除設備資料，默認為 true
  ///
  /// 返回:
  /// - 成功移除設備後返回 true，否則返回 false
  static Future<bool> removeDeviceFromRoom({
    required String deviceId,
    required String roomId,
    bool deleteDevice = true,
  }) async {
    if (currentUserId == null) return false;

    try {
      // 從房間中移除設備ID
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('rooms')
          .doc(roomId)
          .update({
            'devices': FieldValue.arrayRemove([deviceId]),
          });

      // 如果需要，同時刪除設備資料
      if (deleteDevice) {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('devices')
            .doc(deviceId)
            .delete();
      }

      return true;
    } catch (e) {
      print('從房間移除設備錯誤: $e');
      return false;
    }
  }

  /// 獲取指定設備的資料快照
  ///
  /// 參數:
  /// - [deviceId]: 設備 ID
  ///
  /// 返回:
  /// - 設備資料的 DocumentSnapshot
  static Future<DocumentSnapshot?> getDeviceSnapshot(String deviceId) async {
    if (currentUserId == null) return null;

    try {
      return await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('devices')
          .doc(deviceId)
          .get();
    } catch (e) {
      print('獲取設備資料錯誤: $e');
      return null;
    }
  }

  /// 獲取指定設備的資料流
  ///
  /// 參數:
  /// - [deviceId]: 設備 ID
  ///
  /// 返回:
  /// - 設備資料的 Stream<DocumentSnapshot>
  static Stream<DocumentSnapshot> getDeviceStream(String deviceId) {
    if (currentUserId == null) {
      throw Exception('用戶未登錄');
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('devices')
        .doc(deviceId)
        .snapshots();
  }

  /// 獲取指定用戶所有設備的資料流
  ///
  /// 返回:
  /// - 用戶所有設備的 Stream<QuerySnapshot>
  static Stream<QuerySnapshot> getAllDevicesStream() {
    if (currentUserId == null) {
      throw Exception('用戶未登錄');
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('devices')
        .snapshots();
  }

  /// 獲取指定設備類型的設備資料流
  ///
  /// 參數:
  /// - [deviceType]: 設備類型
  ///
  /// 返回:
  /// - 指定類型設備的 Stream<QuerySnapshot>
  static Stream<QuerySnapshot> getDevicesByTypeStream(String deviceType) {
    if (currentUserId == null) {
      throw Exception('用戶未登錄');
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('devices')
        .where('type', isEqualTo: deviceType)
        .snapshots();
  }

  /// 通過設備ID獲取設備模型
  ///
  /// 參數:
  /// - [deviceId]: 設備 ID
  /// - [getIconForType]: 可選函數，用於根據設備類型獲取適當的圖標
  ///
  /// 返回:
  /// - 獲取的設備模型，如果不存在或獲取失敗則返回 null
  static Future<GeneralModel?> getDeviceById(
    String deviceId, [
    IconData Function(String)? getIconForType,
  ]) async {
    if (currentUserId == null) return null;

    try {
      final snapshot = await getDeviceSnapshot(deviceId);
      if (snapshot == null || !snapshot.exists) return null;

      return fromDocumentSnapshot(snapshot, getIconForType);
    } catch (e) {
      print('獲取設備模型錯誤: $e');
      return null;
    }
  }

  /// 獲取指定房間的所有設備模型
  ///
  /// 參數:
  /// - [roomId]: 房間 ID
  /// - [deviceIds]: 可選的設備ID列表，如果提供則只獲取這些設備
  /// - [getIconForType]: 可選函數，用於根據設備類型獲取適當的圖標
  ///
  /// 返回:
  /// - 設備模型列表
  static Future<List<GeneralModel>> getDevicesByRoom(
    String roomId, {
    List<String>? deviceIds,
    IconData Function(String)? getIconForType,
  }) async {
    if (currentUserId == null) return [];

    try {
      // 首先獲取房間的設備ID列表
      final roomSnapshot =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('rooms')
              .doc(roomId)
              .get();

      if (!roomSnapshot.exists) return [];

      final roomData = roomSnapshot.data() as Map<String, dynamic>;
      final List<dynamic> roomDevices = roomData['devices'] ?? [];

      // 如果提供了特定設備ID，則過濾只獲取這些設備
      final List<String> devicesToFetch =
          deviceIds != null
              ? roomDevices
                  .cast<String>()
                  .where((id) => deviceIds.contains(id))
                  .toList()
              : roomDevices.cast<String>();

      if (devicesToFetch.isEmpty) return [];

      final List<GeneralModel> result = [];

      // 批量獲取設備（Firebase有查詢大小限制，所以可能需要分批獲取）
      for (int i = 0; i < devicesToFetch.length; i += 10) {
        final int end =
            (i + 10 < devicesToFetch.length) ? i + 10 : devicesToFetch.length;
        final List<String> batch = devicesToFetch.sublist(i, end);

        final QuerySnapshot querySnapshot =
            await _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('devices')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        for (var doc in querySnapshot.docs) {
          final device = fromDocumentSnapshot(doc, getIconForType);
          if (device != null) {
            result.add(device);
          }
        }
      }

      return result;
    } catch (e) {
      print('獲取房間設備錯誤: $e');
      return [];
    }
  }

  /// 獲取指定類型的所有設備模型
  ///
  /// 參數:
  /// - [deviceType]: 設備類型
  /// - [getIconForType]: 可選函數，用於根據設備類型獲取適當的圖標
  ///
  /// 返回:
  /// - 設備模型列表
  static Future<List<GeneralModel>> getDevicesByType(
    String deviceType, [
    IconData Function(String)? getIconForType,
  ]) async {
    if (currentUserId == null) return [];

    try {
      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('devices')
              .where('type', isEqualTo: deviceType)
              .get();

      List<GeneralModel> devices = [];
      for (var doc in querySnapshot.docs) {
        final device = fromDocumentSnapshot(doc, getIconForType);
        if (device != null) {
          devices.add(device);
        }
      }

      return devices;
    } catch (e) {
      print('獲取設備類型錯誤: $e');
      return [];
    }
  }

  /// 獲取用戶所有設備模型
  ///
  /// 參數:
  /// - [getIconForType]: 可選函數，用於根據設備類型獲取適當的圖標
  ///
  /// 返回:
  /// - 設備模型列表
  static Future<List<GeneralModel>> getAllDevices([
    IconData Function(String)? getIconForType,
  ]) async {
    if (currentUserId == null) return [];

    try {
      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('devices')
              .get();

      List<GeneralModel> devices = [];
      for (var doc in querySnapshot.docs) {
        final device = fromDocumentSnapshot(doc, getIconForType);
        if (device != null) {
          devices.add(device);
        }
      }

      return devices;
    } catch (e) {
      print('獲取所有設備錯誤: $e');
      return [];
    }
  }

  /// 批量獲取設備模型
  ///
  /// 參數:
  /// - [deviceIds]: 要獲取的設備ID列表
  /// - [getIconForType]: 可選函數，用於根據設備類型獲取適當的圖標
  ///
  /// 返回:
  /// - 設備模型列表
  static Future<List<GeneralModel>> getDevicesByIds(
    List<String> deviceIds, [
    IconData Function(String)? getIconForType,
  ]) async {
    if (currentUserId == null || deviceIds.isEmpty) return [];

    try {
      List<GeneralModel> result = [];

      // 批量獲取設備（Firebase有查詢大小限制，所以可能需要分批獲取）
      for (int i = 0; i < deviceIds.length; i += 10) {
        final int end = (i + 10 < deviceIds.length) ? i + 10 : deviceIds.length;
        final List<String> batch = deviceIds.sublist(i, end);

        final QuerySnapshot querySnapshot =
            await _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('devices')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        for (var doc in querySnapshot.docs) {
          final device = fromDocumentSnapshot(doc, getIconForType);
          if (device != null) {
            result.add(device);
          }
        }
      }

      return result;
    } catch (e) {
      print('批量獲取設備錯誤: $e');
      return [];
    }
  }

  /// 通過設備類型流獲取設備模型流
  ///
  /// 參數:
  /// - [deviceType]: 設備類型
  /// - [getIconForType]: 可選函數，用於根據設備類型獲取適當的圖標
  ///
  /// 返回:
  /// - 設備模型流
  static Stream<List<GeneralModel>> getDevicesByTypeModelStream(
    String deviceType, [
    IconData Function(String)? getIconForType,
  ]) {
    return getDevicesByTypeStream(deviceType).map((snapshot) {
      List<GeneralModel> devices = [];
      for (var doc in snapshot.docs) {
        final device = fromDocumentSnapshot(doc, getIconForType);
        if (device != null) {
          devices.add(device);
        }
      }
      return devices;
    });
  }

  /// 獲取所有設備模型流
  ///
  /// 參數:
  /// - [getIconForType]: 可選函數，用於根據設備類型獲取適當的圖標
  ///
  /// 返回:
  /// - 設備模型流
  static Stream<List<GeneralModel>> getAllDevicesModelStream([
    IconData Function(String)? getIconForType,
  ]) {
    return getAllDevicesStream().map((snapshot) {
      List<GeneralModel> devices = [];
      for (var doc in snapshot.docs) {
        final device = fromDocumentSnapshot(doc, getIconForType);
        if (device != null) {
          devices.add(device);
        }
      }
      return devices;
    });
  }
}
