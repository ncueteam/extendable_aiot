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
    this.id, {
    required this.name,
    required this.type,
    required this.lastUpdated,
    required this.icon,
  });
  Future<void> createData() async {}
  Future<void> readData() async {}
  Future<void> updateData() async {}
  Future<void> deleteData() async {}
  fromJson(Map<String, dynamic> json) {
    id = json['id'] as String;
    name = json['name'] as String;
    type = json['type'] as String;
    lastUpdated = json['lastUpdated'] as Timestamp;
    icon = IconData(json['icon'] as int, fontFamily: 'MaterialIcons');
  }

  toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'lastUpdated': lastUpdated,
    'icon': icon.codePoint,
  };
}
