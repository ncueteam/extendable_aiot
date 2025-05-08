import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/abstract/device_model.dart';
import 'package:extendable_aiot/models/sub_type/airconditioner_model.dart';
import 'package:extendable_aiot/models/abstract/switchable_model.dart';
import 'package:extendable_aiot/models/sub_type/mqtt_dht11_model.dart';
import 'package:extendable_aiot/utils/util.dart';
import 'package:extendable_aiot/views/card/device_cards/air_conditioner_card.dart';
import 'package:extendable_aiot/views/card/device_cards/dht11_card.dart';
import 'package:extendable_aiot/views/card/device_cards/general_card.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class DeviceCard extends StatefulWidget {
  final device;

  const DeviceCard({super.key, required this.device});

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  StreamSubscription? _deviceSubscription;

  @override
  void initState() {
    super.initState();
    _startDeviceListener();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    super.dispose();
  }

  void _startDeviceListener() {
    try {
      _deviceSubscription = DeviceModel.getDeviceStream(
        widget.device.id,
      ).listen(
        (snapshot) {
          if (snapshot.exists) {
            final updatedData = snapshot.data() as Map<String, dynamic>?;
            if (updatedData != null) {
              setState(() {
                if (widget.device is AirConditionerModel) {
                  final airConditioner = widget.device as AirConditionerModel;
                  airConditioner.fromJson(updatedData);
                } else if (widget.device is SwitchableModel) {
                  final switchable = widget.device as SwitchableModel;
                  // 安全地更新属性
                  switchable.status =
                      updatedData['status'] ?? switchable.status;
                  switchable.lastUpdated =
                      updatedData['lastUpdated'] as Timestamp? ??
                      switchable.lastUpdated;
                }
              });
            }
          }
        },
        onError: (error) {
          debugPrint('設備資料監聽錯誤: $error');
        },
      );
    } catch (e) {
      debugPrint('啟動設備資料監聽失敗: $e');
    }
  }

  // 更新設備狀態
  Future<void> _toggleDeviceStatus(bool currentStatus) async {
    try {
      // 先更新本地狀態以提供即時反饋
      setState(() {
        if (widget.device is SwitchableModel) {
          (widget.device as SwitchableModel).status = !currentStatus;
        }
      });

      // 使用 DeviceModel 的靜態方法更新設備狀態
      await DeviceModel.updateDeviceStatus(
        deviceId: widget.device.id,
        status: !currentStatus,
      );

      // 此處無需再次 setState，因為 Firestore 監聽會觸發更新
    } catch (e) {
      // 如果更新失敗，恢復原來的狀態
      setState(() {
        if (widget.device is SwitchableModel) {
          (widget.device as SwitchableModel).status = currentStatus;
        }
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新設備狀態失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根據設備類型選擇不同的顯示方式
    switch (widget.device.type) {
      case AirConditionerModel.TYPE:
        return AirConditionerCard(
          device: widget.device as AirConditionerModel,
          onStatusChange: (newStatus) {
            // 在父組件中處理狀態更新
            setState(() {
              (widget.device as AirConditionerModel).status = newStatus;
            });
          },
        );
      case MQTTEnabledDHT11Model.TYPE:
        return Dht11Card(device: widget.device);
      default:
        return GeneralCard(device: widget.device, detailedPage: Container());
    }
  }

  // 可切換設備卡片
  Widget _buildSwitchableCard(SwitchableModel device) {
    Color cardColor = device.status ? Colors.blue.shade50 : Colors.grey[100]!;
    Color iconColor = device.status ? Colors.blue : Colors.grey;

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(device.icon, size: 24, color: iconColor),
            const SizedBox(height: 8),
            Text(
              truncateString(device.name, 12),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              truncateString(device.type, 12),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.status ? '開啟' : '關閉',
                  style: TextStyle(
                    color: device.status ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: device.status,
                  onChanged: (_) => _toggleDeviceStatus(device.status),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 風扇設備卡片
  Widget _buildFanCard(SwitchableModel device) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: device.status ? Colors.blue.shade50 : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.toys, size: 24, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              truncateString(device.name, 12),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.status ? '開啟' : '關閉',
                  style: TextStyle(
                    color: device.status ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: device.status,
                  onChanged: (_) => _toggleDeviceStatus(device.status),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 燈光設備卡片
  Widget _buildLightCard(SwitchableModel device) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: device.status ? Colors.yellow.shade50 : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb, size: 24, color: Colors.yellow),
            const SizedBox(height: 8),
            Text(
              truncateString(device.name, 12),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.status ? '開啟' : '關閉',
                  style: TextStyle(
                    color: device.status ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: device.status,
                  onChanged: (_) => _toggleDeviceStatus(device.status),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 窗簾設備卡片
  Widget _buildCurtainCard(SwitchableModel device) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: device.status ? Colors.green.shade50 : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.window, size: 24, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              truncateString(device.name, 12),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.status ? '開啟' : '關閉',
                  style: TextStyle(
                    color: device.status ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: device.status,
                  onChanged: (_) => _toggleDeviceStatus(device.status),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 門設備卡片
  Widget _buildDoorCard(SwitchableModel device) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: device.status ? Colors.brown.shade50 : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.door_front_door, size: 24, color: Colors.brown),
            const SizedBox(height: 8),
            Text(
              truncateString(device.name, 12),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.status ? '開啟' : '關閉',
                  style: TextStyle(
                    color: device.status ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: device.status,
                  onChanged: (_) => _toggleDeviceStatus(device.status),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 傳感器設備卡片
  Widget _buildSensorCard(SwitchableModel device) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: device.status ? Colors.purple.shade50 : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sensors, size: 24, color: Colors.purple),
            const SizedBox(height: 8),
            Text(
              truncateString(device.name, 12),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.status ? '開啟' : '關閉',
                  style: TextStyle(
                    color: device.status ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: device.status,
                  onChanged: (_) => _toggleDeviceStatus(device.status),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
