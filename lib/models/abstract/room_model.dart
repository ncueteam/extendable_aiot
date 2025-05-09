import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoomModel {
  String id;
  String name;
  List<String> devices = [];
  Timestamp createdAt;
  IconData icon;
  List<String> authorizedUsers = []; // 修改為 authorizedUsers

  RoomModel({
    required this.name,
    String? id,
    List<String>? devices,
    Timestamp? createdAt,
    IconData? icon,
    List<String>? authorizedUsers, // 修改參數名
  }) : id = id ?? _generateFirebaseId(),
       devices = devices ?? [],
       createdAt = createdAt ?? Timestamp.now(),
       icon = icon ?? Icons.meeting_room,
       authorizedUsers = authorizedUsers ?? []; // 修改賦值

  static String _generateFirebaseId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        20,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

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
      authorizedUsers: // 修改為 authorizedUsers
          json['authorizedUsers'] != null
              ? List<String>.from(json['authorizedUsers'])
              : [],
    );
  }

  factory RoomModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      return RoomModel(id: snapshot.id, name: '未命名房間');
    }
    return RoomModel.fromJson(snapshot.id, data);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'devices': devices,
      'createdAt': createdAt,
      'icon': icon.codePoint,
      'authorizedUsers': authorizedUsers, // 修改為 authorizedUsers
    };
  }

  static Future<RoomModel> getRoom(String roomId) async {
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
        return RoomModel(name: 'error');
      }

      return RoomModel.fromSnapshot(doc);
    } catch (e) {
      print('Error loading room: $e');
      return RoomModel(name: 'error');
    }
  }

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

  Future<bool> createRoom() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      final roomRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('rooms')
              .doc();

      id = roomRef.id;

      await roomRef.set(toJson());
      return true;
    } catch (e) {
      print('Error creating room: $e');
      return false;
    }
  }

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

  Future<bool> addDevice(String deviceId) async {
    try {
      if (devices.contains(deviceId)) {
        return true;
      }

      devices.add(deviceId);
      await updateRoom();
      return true;
    } catch (e) {
      print('Error adding device to room: $e');
      return false;
    }
  }

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

  Future<List<DocumentSnapshot>> loadDevices() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      if (devices.isEmpty) {
        return [];
      }

      List<DocumentSnapshot> result = [];

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

  Stream<List<DocumentSnapshot>> devicesStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || devices.isEmpty) {
      return Stream.value([]);
    }
    if (devices.length <= 10) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .where(FieldPath.documentId, whereIn: devices)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    } else {
      final controller = StreamController<List<DocumentSnapshot>>.broadcast();
      List<Stream<List<DocumentSnapshot>>> streams = [];

      for (int i = 0; i < devices.length; i += 10) {
        final int end = (i + 10 < devices.length) ? i + 10 : devices.length;
        final List<String> batch = devices.sublist(i, end);
        final stream = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .where(FieldPath.documentId, whereIn: batch)
            .snapshots()
            .map((snapshot) => snapshot.docs);

        streams.add(stream);
      }

      int completedStreams = 0;
      List<List<DocumentSnapshot>> results = List.filled(streams.length, []);

      for (int i = 0; i < streams.length; i++) {
        final int index = i;
        streams[i].listen(
          (data) {
            results[index] = data;
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

  // 添加授權使用者
  static Future<bool> addAuthorizedUser(String roomId, String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('rooms')
          .doc(roomId)
          .update({
            'authorizedUsers': FieldValue.arrayUnion([userId]),
          });
      return true;
    } catch (e) {
      print('添加授權使用者錯誤: $e');
      return false;
    }
  }

  // 移除授權使用者
  static Future<bool> removeAuthorizedUser(String roomId, String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('rooms')
          .doc(roomId)
          .update({
            'authorizedUsers': FieldValue.arrayRemove([userId]),
          });
      return true;
    } catch (e) {
      print('移除授權使用者錯誤: $e');
      return false;
    }
  }

  // 檢查使用者是否有房間授權
  static Future<bool> isUserAuthorized(String roomId, String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      DocumentSnapshot roomDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('rooms')
              .doc(roomId)
              .get();

      if (roomDoc.exists) {
        Map<String, dynamic> data = roomDoc.data() as Map<String, dynamic>;
        List<String> authorizedUsers = List<String>.from(
          data['authorizedUsers'] ?? [],
        );
        return authorizedUsers.contains(userId);
      }
      return false;
    } catch (e) {
      print('檢查使用者授權錯誤: $e');
      return false;
    }
  }
}
