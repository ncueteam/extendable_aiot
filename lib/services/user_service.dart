import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    // 當用戶首次創建時，添加 createdAt 字段和空的好友列表
    await _firestore.collection('users').doc(currentUserId).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'friends': [],
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

    // 創建房間時初始化一個空的授權用戶列表
    return await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('rooms')
        .add({
          'name': name,
          'type': type,
          'devices': [],
          'authorizedUsers': [],
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
  Future<bool> addFriend(String friendEmail) async {
    try {
      // 獲取當前用戶ID
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // 查找要添加的好友
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: friendEmail)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // 找不到使用者
      }

      final friendDoc = querySnapshot.docs.first;
      final friendId = friendDoc.id;

      // 不能添加自己為好友
      if (friendId == currentUser.uid) {
        return false;
      }

      // 將好友ID添加到使用者的好友列表中
      await _firestore.collection('users').doc(currentUser.uid).update({
        'friends': FieldValue.arrayUnion([friendId]),
      });

      return true;
    } catch (e) {
      print('添加好友錯誤: $e');
      return false;
    }
  }

  // 刪除好友
  Future<bool> removeFriend(String friendId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // 從好友列表中移除
      await _firestore.collection('users').doc(currentUser.uid).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });

      return true;
    } catch (e) {
      print('刪除好友錯誤: $e');
      return false;
    }
  }

  // 獲取好友資料
  Stream<List<Map<String, dynamic>>> getFriendsData() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // 從使用者文件中獲取好友ID列表，然後獲取每個好友的資料
    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .asyncMap((userDoc) async {
          if (!userDoc.exists) {
            return [];
          }

          // 從使用者文件中讀取好友ID列表
          List<String> friendIds = List<String>.from(
            userDoc.data()?['friends'] ?? [],
          );

          if (friendIds.isEmpty) {
            return [];
          }

          // 獲取所有好友的詳細資料
          List<Map<String, dynamic>> friendsData = [];

          for (String friendId in friendIds) {
            DocumentSnapshot friendDoc =
                await _firestore.collection('users').doc(friendId).get();
            if (friendDoc.exists) {
              Map<String, dynamic> data =
                  friendDoc.data() as Map<String, dynamic>;
              friendsData.add({
                'id': friendId,
                'name': data['name'] ?? '未命名使用者',
                'email': data['email'] ?? '',
                'photoURL': data['photoURL'],
              });
            }
          }

          return friendsData;
        });
  }

  // 添加好友到房間
  Future<bool> addFriendToRoom(String friendId, String roomId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final roomDoc =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('rooms')
              .doc(roomId)
              .get();

      if (!roomDoc.exists) {
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('rooms')
          .doc(roomId)
          .update({
            'authorizedUsers': FieldValue.arrayUnion([friendId]),
          });

      return true;
    } catch (e) {
      print('Error adding friend to room: $e');
      return false;
    }
  }

  // 从房间中移除好友
  Future<bool> removeFriendFromRoom(String friendId, String roomId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final roomDoc =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('rooms')
              .doc(roomId)
              .get();

      if (!roomDoc.exists) {
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('rooms')
          .doc(roomId)
          .update({
            'authorizedUsers': FieldValue.arrayRemove([friendId]),
          });

      return true;
    } catch (e) {
      print('Error removing friend from room: $e');
      return false;
    }
  }

  // 获取有权限访问指定房间的好友
  Future<List<Map<String, dynamic>>> getFriendsForRoom(String roomId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final roomDoc =
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('rooms')
              .doc(roomId)
              .get();

      if (!roomDoc.exists) {
        return [];
      }

      List<String> friendIds = List<String>.from(
        roomDoc.data()?['authorizedUsers'] ?? [],
      );

      if (friendIds.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> friendsData = [];

      for (String friendId in friendIds) {
        DocumentSnapshot friendDoc =
            await _firestore.collection('users').doc(friendId).get();
        if (friendDoc.exists) {
          Map<String, dynamic> data = friendDoc.data() as Map<String, dynamic>;
          friendsData.add({
            'id': friendId,
            'name': data['name'] ?? '未命名使用者',
            'email': data['email'] ?? '',
            'photoURL': data['photoURL'],
          });
        }
      }

      return friendsData;
    } catch (e) {
      print('Error getting friends for room: $e');
      return [];
    }
  }
}
