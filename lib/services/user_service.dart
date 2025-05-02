import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

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
}
