import 'package:extendable_aiot/temp/sensor_page.dart';
import 'package:extendable_aiot/views/card/airconditioner.dart';
import 'package:flutter/material.dart';

class DeviceData {
  /*---------------------------------------*/
  static const String TYPE_AC = '中央空調';
  static const String TYPE_FAN = '風扇';
  static const String TYPE_LIGHT = '燈光';
  static const String TYPE_CURTAIN = '窗簾';
  static const String TYPE_LOCK = '門鎖';
  static const String TYPE_SENSOR = '感測器';

  static List<String> deviceTypes = [
    TYPE_AC,
    TYPE_FAN,
    TYPE_LIGHT,
    TYPE_CURTAIN,
    TYPE_LOCK,
    TYPE_SENSOR,
  ];
  /*---------------------------------------*/
  final String id;
  String name;
  String type;
  bool status;

  DeviceData(
    this.id, {
    required this.name,
    required this.type,
    required this.status,
  });

  factory DeviceData.fromJson(String id, Map<String, dynamic> json) {
    return DeviceData(
      id,
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'status': status,
  };

  Widget getTargetPage() {
    switch (type) {
      case TYPE_AC:
        return Airconditioner(roomItem: toJson());
      // case TYPE_FAN:
      //   return Page2();
      // case TYPE_LIGHT:
      //   return Page3();
      // case TYPE_CURTAIN:
      //   return Page4();
      default:
        return SensorPage(); // 預設頁面
    }
  }
}
