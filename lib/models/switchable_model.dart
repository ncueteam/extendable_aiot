import 'package:extendable_aiot/models/general_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwitchableModel extends GeneralModel {
  List<dynamic> updateValue;
  List<dynamic> previousValue;
  bool status;

  SwitchableModel(
    super.id, {
    required super.name,
    required super.type,
    required super.lastUpdated,
    required super.icon,
    required this.updateValue,
    required this.previousValue,
    required this.status,
  });

  @override
  Future<void> createData() async {
    // 在firebase/userid/device collection裡面創建一個新的device document
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(id)
            .set(toJson());
      }
    } catch (e) {
      print('Error creating switchable device: $e');
      rethrow;
    }
  }

  @override
  Future<void> readData() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('devices')
                .doc(id)
                .get();

        if (docSnapshot.exists) {
          fromJson(docSnapshot.data()!);
        }
      }
    } catch (e) {
      print('Error reading switchable device: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateData() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Update the lastUpdated timestamp
        lastUpdated = Timestamp.now();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(id)
            .update(toJson());
      }
    } catch (e) {
      print('Error updating switchable device: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteData() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(id)
            .delete();
      }
    } catch (e) {
      print('Error deleting switchable device: $e');
      rethrow;
    }
  }

  @override
  fromJson(Map<String, dynamic> json) {
    updateValue = json['updateValue'] as List<dynamic>;
    previousValue = json['previousValue'] as List<dynamic>;
    status = json['status'] as bool;
    return super.fromJson(json);
  }

  @override
  toJson() {
    return {
      'updateValue': updateValue,
      'previousValue': previousValue,
      'status': status,
    }..addAll(super.toJson());
  }
}
