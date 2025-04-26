import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // 創建新設備
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
          "icon":"0xe037",
          "num":28,
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
}