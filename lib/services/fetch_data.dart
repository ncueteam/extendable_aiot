import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FetchData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // 獲取所有房間
  Stream<QuerySnapshot> getRooms() {
    if (currentUserId == null) throw Exception('User not authenticated');

    print(
      "獲取所有房間: " +
          _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('rooms')
              .snapshots()
              .toString(),
    );

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
}
