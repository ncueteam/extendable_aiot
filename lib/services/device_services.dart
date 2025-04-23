import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../components/temp_data.dart';

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveDevices(List<TempData> devices) async {
    try {
      final batch = _firestore.batch();
      final devicesRef = _firestore.collection('devices');

      for (var device in devices) {
        final docRef = devicesRef.doc(device.title); // Use title as document ID
        batch.set(docRef, device.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error saving devices: $e');
      rethrow;
    }
  }
}
