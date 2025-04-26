import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // 創建或更新用戶基本資料
  Future<void> createOrUpdateUser({
    required String name,
    required String email,
  }) async {
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).set({
      'name': name,
      'email': email,
      'lastLogin': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 更新最後登入時間
  Future<void> updateLastLogin() async {
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // 獲取用戶資料
  Stream<DocumentSnapshot> getUserData() {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _firestore.collection('users').doc(currentUserId).snapshots();
  }

  // 創建新房間
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

  // 獲取所有房間
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

  // 創建新設備 O
  Future<DocumentReference> addDevice({
    required String name,
    required String type,
    required String roomId,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // 創建設備文檔
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

    // 更新房間的設備列表
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

  // 更新設備狀態
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

  // 獲取房間的所有設備 O
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
}
