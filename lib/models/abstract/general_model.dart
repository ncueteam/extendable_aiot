import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

abstract class GeneralModel {
  String id;
  String name;
  String type;
  Timestamp lastUpdated; // Timestamp for the last update
  IconData icon; // Icon for the device

  GeneralModel(
    String? id, {
    required this.name,
    required this.type,
    required this.lastUpdated,
    required this.icon,
  }) : id = id ?? _generateFirebaseId();
  Future<void> createData() async {}
  Future<void> readData() async {}
  Future<void> updateData() async {}
  Future<void> deleteData() async {}
  fromJson(Map<String, dynamic> json) {
    id = json['id'] as String? ?? id;
    name = json['name'] as String? ?? name;
    type = json['type'] as String? ?? type;
    lastUpdated = json['lastUpdated'] as Timestamp? ?? Timestamp.now();
    icon =
        json['icon'] != null
            ? IconData(json['icon'] as int, fontFamily: 'MaterialIcons')
            : icon;
  }

  toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'lastUpdated': lastUpdated,
    'icon': icon.codePoint,
  };

  static String _generateFirebaseId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        20,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
