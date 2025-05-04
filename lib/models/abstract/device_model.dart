// filepath: d:\workspace\study\extendable_aiot\lib\models\device_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:extendable_aiot/models/abstract/general_model.dart';

/// DeviceModel 提供設備通用操作的靜態方法
/// 實際的設備實例應該使用特定的子類如 SwitchModel, AirConditionerModel 等
class DeviceModel {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 獲取當前用戶ID
  static String? get currentUserId => _auth.currentUser?.uid;

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
}
