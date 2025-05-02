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
  List<String> authorizedFriends = []; // 添加授权好友列表

  RoomModel({
    required this.name,
    String? id,
    List<String>? devices,
    Timestamp? createdAt,
    IconData? icon,
    List<String>? authorizedFriends,
  }) : id = id ?? _generateFirebaseId(),
       devices = devices ?? [],
       createdAt = createdAt ?? Timestamp.now(),
       icon = icon ?? Icons.meeting_room,
       authorizedFriends = authorizedFriends ?? [];

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
      authorizedFriends:
          json['authorizedFriends'] != null
              ? List<String>.from(json['authorizedFriends'])
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
      'authorizedFriends': authorizedFriends,
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

  // 添加授权好友
  Future<bool> addAuthorizedFriend(String friendUserId) async {
    try {
      if (authorizedFriends.contains(friendUserId)) {
        return true; // 已经授权
      }

      authorizedFriends.add(friendUserId);
      await updateRoom();
      return true;
    } catch (e) {
      print('Error adding authorized friend: $e');
      return false;
    }
  }

  // 移除授权好友
  Future<bool> removeAuthorizedFriend(String friendUserId) async {
    try {
      authorizedFriends.remove(friendUserId);
      await updateRoom();
      return true;
    } catch (e) {
      print('Error removing authorized friend: $e');
      return false;
    }
  }
}
