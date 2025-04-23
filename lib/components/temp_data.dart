import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TempData {
  final String title;
  final String room;
  final IconData icon;
  bool isOn;

  void toggle() {
    isOn = !isOn;
  }

  TempData({
    required this.title,
    required this.room,
    required this.icon,
    this.isOn = false,
  });

  Map<String, dynamic> toMap() {
    return {'title': title, 'room': room, 'icon': icon.codePoint, 'isOn': isOn};
  }

  static TempData fromMap(Map<String, dynamic> map) {
    return TempData(
      title: map['title'],
      room: map['room'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      isOn: map['isOn'] ?? false,
    );
  }
}

// 取得所有設備資料的 Stream
Stream<List<TempData>> getTempDataStream() {
  return FirebaseFirestore.instance.collection('devices').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs.map((doc) => TempData.fromMap(doc.data())).toList();
  });
}
