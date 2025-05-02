import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/components/airconditioner_control.dart';
import 'package:extendable_aiot/models/airconditioner_model.dart';
import 'package:extendable_aiot/models/dht11_sensor_model.dart';
import 'package:extendable_aiot/models/general_model.dart';
import 'package:extendable_aiot/models/switchable_model.dart';
import 'package:extendable_aiot/utils/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DeviceCard extends StatefulWidget {
  final GeneralModel device;

  const DeviceCard({super.key, required this.device});

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  // 更新设备状态
  Future<void> _toggleDeviceStatus(bool currentStatus) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // 更新Firebase中的数据
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(widget.device.id)
          .update({
            'status': !currentStatus,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      setState(() {});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新設備狀態失敗: $e')));
      }
    }
  }

  // 根据设备类型导航到相应的控制页面
  void _navigateToDeviceControl() {
    if (widget.device is AirConditionerModel) {
      _openAirConditionerControl(widget.device as AirConditionerModel);
    } else if (widget.device is DHT11SensorModel) {
      _openSensorDetails(widget.device as DHT11SensorModel);
    } else if (widget.device is SwitchableModel) {
      // 可以根据需要为其他类型的设备实现具体的页面导航
      _openGenericDeviceControl(widget.device);
    }
  }

  // 打开空调控制页面
  void _openAirConditionerControl(AirConditionerModel airConditioner) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AirConditionerControl(
              airConditioner: airConditioner,
              onUpdate: () {
                setState(() {});
              },
            ),
      ),
    );
  }

  // 打开DHT11传感器详情页面
  void _openSensorDetails(DHT11SensorModel sensor) {
    // 这里可以替换为具体的传感器详情页面
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('DHT11傳感器: ${sensor.name}')));
  }

  // 打开通用设备控制页面
  void _openGenericDeviceControl(GeneralModel device) {
    // 这里可以替换为通用设备控制页面
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('設備: ${device.name}')));
  }

  @override
  Widget build(BuildContext context) {
    // 根据设备类型选择不同的显示方式
    if (widget.device is AirConditionerModel) {
      return _buildAirConditionerCard(widget.device as AirConditionerModel);
    } else if (widget.device is DHT11SensorModel) {
      return _buildDHT11SensorCard(widget.device as DHT11SensorModel);
    } else if (widget.device is SwitchableModel) {
      return _buildSwitchableCard(widget.device as SwitchableModel);
    } else {
      // 默认卡片
      return _buildDefaultCard(widget.device);
    }
  }

  // 空调设备卡片
  Widget _buildAirConditionerCard(AirConditionerModel device) {
    return GestureDetector(
      onTap: () => _navigateToDeviceControl(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.ac_unit,
                  size: 24,
                  color: device.status ? Colors.blue : Colors.grey,
                ),
                Text(
                  '${device.temperature.toInt()}°C',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: device.status ? Colors.blue[700] : Colors.grey[600],
                  ),
                ),
              ],
            ),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: device.status ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    device.status ? '開啟' : '關閉',
                    style: TextStyle(
                      color:
                          device.status ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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

  // DHT11 温湿度传感器卡片
  Widget _buildDHT11SensorCard(DHT11SensorModel device) {
    return GestureDetector(
      onTap: () => _navigateToDeviceControl(),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade50,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.thermostat, color: Colors.blue),
                Text(
                  'DHT11',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              truncateString(device.name, 12),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.thermostat, size: 20, color: Colors.red),
                    const SizedBox(height: 4),
                    Text(
                      '${device.temperature.toInt()}°C',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.water_drop, size: 20, color: Colors.blue),
                    const SizedBox(height: 4),
                    Text(
                      '${device.humidity.toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 可切换设备卡片
  Widget _buildSwitchableCard(SwitchableModel device) {
    Color cardColor = device.status ? Colors.blue.shade50 : Colors.grey[100]!;
    Color iconColor = device.status ? Colors.blue : Colors.grey;

    return GestureDetector(
      onTap: () => _navigateToDeviceControl(),
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

  // 默认设备卡片
  Widget _buildDefaultCard(GeneralModel device) {
    return GestureDetector(
      onTap: () => _navigateToDeviceControl(),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
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
            const Icon(Icons.device_unknown, size: 24, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              truncateString(device.name, 12),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              truncateString(device.type, 12),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
