import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

/// 好友模型类
class FriendModel {
  String id; // 好友关系的唯一ID
  String userId; // 好友用户ID
  String name; // 好友名称
  String email; // 好友邮箱
  Timestamp addedAt; // 添加好友的时间
  List<String> sharedRooms = []; // 该好友可以访问的房间ID列表

  FriendModel({
    String? id,
    required this.userId,
    required this.name,
    required this.email,
    Timestamp? addedAt,
    List<String>? sharedRooms,
  }) : id = id ?? _generateId(),
       addedAt = addedAt ?? Timestamp.now(),
       sharedRooms = sharedRooms ?? [];

  // 从Firebase文档创建模型
  factory FriendModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      return FriendModel(id: snapshot.id, userId: '', name: '未命名好友', email: '');
    }

    return FriendModel(
      id: snapshot.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '未命名好友',
      email: data['email'] as String? ?? '',
      addedAt: data['addedAt'] as Timestamp? ?? Timestamp.now(),
      sharedRooms:
          data['sharedRooms'] != null
              ? List<String>.from(data['sharedRooms'])
              : [],
    );
  }

  // 转换为JSON以存储到Firebase
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'addedAt': addedAt,
      'sharedRooms': sharedRooms,
    };
  }

  // 添加此好友到指定房间
  Future<bool> addToRoom(String roomId) async {
    try {
      if (sharedRooms.contains(roomId)) {
        return true; // 已经在房间中
      }

      sharedRooms.add(roomId);
      await updateFriend();

      // 我们还需要在房间文档中添加该好友的访问权限记录
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('rooms')
            .doc(roomId)
            .update({
              'authorizedFriends': FieldValue.arrayUnion([userId]),
            });
      }

      return true;
    } catch (e) {
      print('Error adding friend to room: $e');
      return false;
    }
  }

  // 将此好友从指定房间中移除
  Future<bool> removeFromRoom(String roomId) async {
    try {
      sharedRooms.remove(roomId);
      await updateFriend();

      // 从房间文档中移除该好友的访问权限
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('rooms')
            .doc(roomId)
            .update({
              'authorizedFriends': FieldValue.arrayRemove([userId]),
            });
      }

      return true;
    } catch (e) {
      print('Error removing friend from room: $e');
      return false;
    }
  }

  // 更新好友数据
  Future<bool> updateFriend() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception('用户未登录');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(id)
          .update(toJson());

      return true;
    } catch (e) {
      print('Error updating friend: $e');
      return false;
    }
  }

  // 删除好友关系
  Future<bool> deleteFriend() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception('用户未登录');

      // 首先从所有已授权房间中移除该好友
      for (var roomId in sharedRooms) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('rooms')
            .doc(roomId)
            .update({
              'authorizedFriends': FieldValue.arrayRemove([userId]),
            });
      }

      // 然后删除好友文档
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting friend: $e');
      return false;
    }
  }

  // 创建一个新的好友关系
  Future<bool> createFriend() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception('用户未登录');

      final friendRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .doc();

      id = friendRef.id;

      await friendRef.set(toJson());
      return true;
    } catch (e) {
      print('Error creating friend: $e');
      return false;
    }
  }

  // 通过邮箱查找用户
  static Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {
          'userId': doc.id,
          'name': (doc.data() as Map<String, dynamic>)['name'] ?? '',
          'email': (doc.data() as Map<String, dynamic>)['email'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Error finding user by email: $e');
      return null;
    }
  }

  // 获取所有好友
  static Stream<List<FriendModel>> getAllFriends() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FriendModel.fromSnapshot(doc))
              .toList();
        });
  }

  // 生成唯一ID的辅助方法
  static String _generateId() {
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
}
