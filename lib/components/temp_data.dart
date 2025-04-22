import 'package:flutter/material.dart';

class TempData {
  final String title;
  final String room;
  final IconData icon;
  bool isOn;

  void toogle() {
    isOn = !isOn;
  }

  TempData({
    required this.title,
    required this.room,
    required this.icon,
    this.isOn = false,
  });
}

List<TempData> tempData = [
  TempData(title: "中央空調", room: "客廳", icon: Icons.ac_unit, isOn: true),
  TempData(title: "燈", room: "臥室", icon: Icons.lightbulb),
  TempData(title: "電視機", room: "客廳", icon: Icons.tv),
  TempData(title: "無線路由器", room: "客廳", icon: Icons.router),
];
