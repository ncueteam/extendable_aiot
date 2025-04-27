import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FetchData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // 獲取建立的房間
  Stream<QuerySnapshot> getRooms() {
    if (currentUserId == null) throw Exception('User not authenticated');

    print("獲取建立的房間");

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('rooms')
        .snapshots();
  }

  // 獲取房間的設備
  Stream<List<DocumentSnapshot>> getRoomDevices(String roomId) async* {
    if (currentUserId == null) throw Exception('User not authenticated');

    print("獲取$roomId的設備");

    final roomDoc =
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('rooms')
            .doc(roomId)
            .get();

    final devicesField = roomDoc.data()?['devices'];
    List<String> deviceIds = [];
    if (devicesField is List) {
      deviceIds = List<String>.from(devicesField);
    } else if (devicesField is Map) {
      deviceIds = List<String>.from(devicesField.keys);
    }

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

  // 獲取所有房間的設備
  Stream<List<DocumentSnapshot>> getAllDevices() {
    if (currentUserId == null) throw Exception('User not authenticated');

    print("獲取所有房間的設備");

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('devices')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // 獲取用戶資料
  Stream<DocumentSnapshot> getUserData() {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _firestore.collection('users').doc(currentUserId).snapshots();
  }

}
