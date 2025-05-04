import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  // 屬性
  String id;
  String name;
  String email;
  String? photoURL;
  Timestamp? createdAt;
  Timestamp? lastLogin;
  List<String> friends;

  // 靜態實例
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 靜態獲取當前用戶ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // 構造函數
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoURL,
    this.createdAt,
    this.lastLogin,
    this.friends = const [],
  });

  // 從 Firebase 文檔創建 UserModel 實例
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '未命名使用者',
      email: data['email'] ?? '',
      photoURL: data['photoURL'],
      createdAt: data['createdAt'],
      lastLogin: data['lastLogin'],
      friends: List<String>.from(data['friends'] ?? []),
    );
  }

  // 轉換為 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      if (photoURL != null) 'photoURL': photoURL,
      'friends': friends,
    };
  }

  // 創建或更新用戶
  Future<void> createOrUpdate() async {
    if (currentUserId == null) return;

    final userData = {
      'name': name,
      'email': email,
      if (photoURL != null) 'photoURL': photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
    };

    // 當用戶首次創建時，添加 createdAt 字段和空的好友列表
    await _firestore.collection('users').doc(currentUserId).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'friends': friends,
    }, SetOptions(merge: true));
  }

  // 更新最後登入時間
  static Future<void> updateLastLogin() async {
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // 獲取當前用戶數據流
  static Stream<UserModel?> getCurrentUser() {
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore.collection('users').doc(currentUserId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return UserModel.fromFirestore(snapshot);
      } else {
        return null;
      }
    });
  }

  // 通過 ID 獲取用戶
  static Future<UserModel?> getById(String userId) async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // 通過 Email 查找用戶
  static Future<UserModel?> getByEmail(String email) async {
    QuerySnapshot query =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromFirestore(query.docs.first);
    }
    return null;
  }

  // 添加好友
  Future<bool> addFriend(String friendEmail) async {
    try {
      // 獲取當前用戶ID
      if (currentUserId == null) return false;

      // 查找要添加的好友
      UserModel? friendUser = await UserModel.getByEmail(friendEmail);
      if (friendUser == null) {
        return false; // 找不到使用者
      }

      // 不能添加自己為好友
      if (friendUser.id == id) {
        return false;
      }

      // 將好友ID添加到使用者的好友列表中
      if (!friends.contains(friendUser.id)) {
        friends.add(friendUser.id);
        await _firestore.collection('users').doc(id).update({
          'friends': friends,
        });
      }

      return true;
    } catch (e) {
      print('添加好友錯誤: $e');
      return false;
    }
  }

  // 刪除好友
  Future<bool> removeFriend(String friendId) async {
    try {
      if (currentUserId == null) return false;

      // 從好友列表中移除
      if (friends.contains(friendId)) {
        friends.remove(friendId);
        await _firestore.collection('users').doc(id).update({
          'friends': friends,
        });
      }

      return true;
    } catch (e) {
      print('刪除好友錯誤: $e');
      return false;
    }
  }

  // 獲取好友資料
  Future<List<UserModel>> getFriends() async {
    if (friends.isEmpty) {
      return [];
    }

    List<UserModel> friendModels = [];
    for (String friendId in friends) {
      UserModel? friendUser = await UserModel.getById(friendId);
      if (friendUser != null) {
        friendModels.add(friendUser);
      }
    }

    return friendModels;
  }

  // 獲取好友資料流
  Stream<List<UserModel>> getFriendsStream() async* {
    if (currentUserId == null) {
      yield [];
      return;
    }

    yield* _firestore
        .collection('users')
        .doc(currentUserId)
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
          List<UserModel> friendModels = [];

          for (String friendId in friendIds) {
            UserModel? friend = await UserModel.getById(friendId);
            if (friend != null) {
              friendModels.add(friend);
            }
          }

          return friendModels;
        });
  }

  // 获取有权限访问指定房间的好友
  Future<List<UserModel>> getFriendsForRoom(String roomId) async {
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

      List<UserModel> friendModels = [];

      for (String friendId in friendIds) {
        UserModel? friend = await UserModel.getById(friendId);
        if (friend != null) {
          friendModels.add(friend);
        }
      }

      return friendModels;
    } catch (e) {
      print('Error getting friends for room: $e');
      return [];
    }
  }

  // 刪除用戶
  Future<void> delete() async {
    await _firestore.collection('users').doc(id).delete();
  }
}
