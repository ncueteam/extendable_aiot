import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:extendable_aiot/models/friend_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> createOrUpdateUser({
    required String name,
    required String email,
    String? photoURL,
  }) async {
    if (currentUserId == null) return;

    final userData = {
      'name': name,
      'email': email,
      'lastLogin': FieldValue.serverTimestamp(),
    };

    // 只有當頭像 URL 存在時才添加到用戶數據中
    if (photoURL != null) {
      userData['photoURL'] = photoURL;
    }

    // 當用戶首次創建時，添加 createdAt 字段
    await _firestore.collection('users').doc(currentUserId).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateLastLogin() async {
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> getUserData() {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _firestore.collection('users').doc(currentUserId).snapshots();
  }

  Future<DocumentReference> addRoom({
    required String name,
    required String type,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    return await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('rooms')
        .add({
          'name': name,
          'type': type,
          'devices': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot> getRooms() {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('rooms')
        .snapshots();
  }

  Stream<DocumentSnapshot> getRoomById(String roomId) {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('rooms')
        .doc(roomId)
        .snapshots();
  }

  Future<DocumentReference> addDevice({
    required String name,
    required String type,
    required String roomId,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final deviceRef = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('devices')
        .add({
          'name': name,
          'type': type,
          'status': false,
          'lastUpdate': FieldValue.serverTimestamp(),
        });

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('rooms')
        .doc(roomId)
        .update({
          'devices': FieldValue.arrayUnion([deviceRef.id]),
        });

    return deviceRef;
  }

  Future<void> updateDeviceStatus({
    required String deviceId,
    required bool status,
  }) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('devices')
        .doc(deviceId)
        .update({'status': status, 'lastUpdate': FieldValue.serverTimestamp()});
  }

  Stream<List<DocumentSnapshot>> getRoomDevices(String roomId) async* {
    if (currentUserId == null) throw Exception('User not authenticated');

    final roomDoc =
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('rooms')
            .doc(roomId)
            .get();

    final List<String> deviceIds = List<String>.from(
      roomDoc.data()?['devices'] ?? [],
    );

    if (deviceIds.isEmpty) {
      yield [];
      return;
    }

    yield* _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('devices')
        .where(FieldPath.documentId, whereIn: deviceIds)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // 添加好友
  Future<bool> addFriend(String email) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      // 检查用户是否存在
      final userResult = await FriendModel.findUserByEmail(email);
      if (userResult == null) {
        return false; // 用户不存在
      }

      final friendUserId = userResult['userId'];

      // 检查是否添加自己
      if (friendUserId == currentUserId) {
        return false; // 不能添加自己为好友
      }

      // 检查是否已经是好友
      final existingFriends =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .where('userId', isEqualTo: friendUserId)
              .get();

      if (existingFriends.docs.isNotEmpty) {
        return false; // 已经是好友了
      }

      // 创建新的好友关系
      final friendModel = FriendModel(
        userId: friendUserId,
        name: userResult['name'],
        email: userResult['email'],
        photoURL: userResult['photoURL'], // 添加頭像URL
      );

      return await friendModel.createFriend();
    } catch (e) {
      print('Error adding friend: $e');
      return false;
    }
  }

  // 删除好友
  Future<bool> removeFriend(String friendId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final friendDoc =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .doc(friendId)
              .get();

      if (!friendDoc.exists) {
        return false;
      }

      final friendModel = FriendModel.fromSnapshot(friendDoc);
      return await friendModel.deleteFriend();
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }

  // 获取所有好友
  Stream<List<FriendModel>> getFriends() {
    return FriendModel.getAllFriends();
  }

  // 添加好友到房间
  Future<bool> addFriendToRoom(String friendId, String roomId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final friendDoc =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .doc(friendId)
              .get();

      if (!friendDoc.exists) {
        return false;
      }

      final friendModel = FriendModel.fromSnapshot(friendDoc);
      return await friendModel.addToRoom(roomId);
    } catch (e) {
      print('Error adding friend to room: $e');
      return false;
    }
  }

  // 从房间中移除好友
  Future<bool> removeFriendFromRoom(String friendId, String roomId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final friendDoc =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .doc(friendId)
              .get();

      if (!friendDoc.exists) {
        return false;
      }

      final friendModel = FriendModel.fromSnapshot(friendDoc);
      return await friendModel.removeFromRoom(roomId);
    } catch (e) {
      print('Error removing friend from room: $e');
      return false;
    }
  }

  // 获取有权限访问指定房间的好友
  Future<List<FriendModel>> getFriendsForRoom(String roomId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final friendsSnapshot =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .where('sharedRooms', arrayContains: roomId)
              .get();

      return friendsSnapshot.docs
          .map((doc) => FriendModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error getting friends for room: $e');
      return [];
    }
  }
}
