import 'package:extendable_aiot/models/general_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  Future<void> createData() {
    //在firebase/userid/device collection裡面創建一個新的device document
    return super.createData();
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
