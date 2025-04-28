import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/general_model.dart';
import 'package:flutter/material.dart';

class SensorModel extends GeneralModel {
  List<dynamic> value;
  SensorModel(
    super.id, {
    required this.value,
    required super.name,
    required super.type,
    required super.lastUpdated,
    required super.icon,
  });

  // 把資料存到firebase user 的 device裡面
}
