import 'package:flutter/material.dart';

class BedRoomList {
  final List<BedRoomItem> list;

  BedRoomList(this.list);

  /// 循環後台返回的數組，將每一項組裝成 UserItem
  factory BedRoomList.fromJson(List<dynamic> list) {
    return BedRoomList(list.map((item) => BedRoomItem.fromJson(item)).toList());
  }
}

class BedRoomItem {
  final IconData icon;
  final int num;
  final String name;
  bool isOn;

  void toggle() {
    isOn = !isOn;
  }

  BedRoomItem({
    required this.icon,
    required this.num,
    required this.name,
    this.isOn = false,
  });

  /// 將 Json 數據轉換為實體模型
  factory BedRoomItem.fromJson(dynamic item) {
    return BedRoomItem(
      icon: IconData(item['icon'], fontFamily: 'MaterialIcons'),
      num: item['num'], // 強制轉換為整數
      name: item['name'],
      isOn: item['isOn'] ?? false,
    );
  }
}
