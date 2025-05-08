import 'package:extendable_aiot/components/airconditioner_control.dart';
import 'package:extendable_aiot/models/abstract/device_model.dart';
import 'package:extendable_aiot/models/sub_type/airconditioner_model.dart';
import 'package:extendable_aiot/models/sub_type/dht11_sensor_model.dart';
import 'package:extendable_aiot/models/abstract/general_model.dart';
import 'package:extendable_aiot/models/abstract/switchable_model.dart';
import 'package:extendable_aiot/models/sub_type/mqtt_dht11_model.dart';
import 'package:extendable_aiot/utils/util.dart';
import 'package:extendable_aiot/views/card/device_cards/dht11_card.dart';
import 'package:extendable_aiot/views/card/device_cards/general_card.dart';
import 'package:extendable_aiot/views/sub_pages/mqtt_dht11_details_page.dart';
import 'package:flutter/material.dart';

class DeviceCard extends StatefulWidget {
  final device;

  const DeviceCard({super.key, required this.device});

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
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

  // 根據設備類型導航到相應的控制頁面
  void _navigateToDeviceControl() {
    switch (widget.device.type) {
      case 'air_conditioner':
        _openAirConditionerControl(widget.device as AirConditionerModel);
        break;
      case MQTTEnabledDHT11Model.TYPE:
        _openMQTTSensorDetails(widget.device as MQTTEnabledDHT11Model);
        break;
      default:
        _openGenericDeviceControl(widget.device);
    }
  }

  // 打開空調控制頁面
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

  // 打開MQTT啟用的DHT11傳感器詳情頁面
  void _openMQTTSensorDetails(MQTTEnabledDHT11Model sensor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return MQTTDht11DetailsPage(sensor: sensor);
        },
      ),
    );
  }

  // 打開通用設備控制頁面
  void _openGenericDeviceControl(GeneralModel device) {
    // 這裡可以替換為通用設備控制頁面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '未知設備類型: ${device.name} , ${device.type} not in [${MQTTEnabledDHT11Model.TYPE}, air_conditioner]',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 根據設備類型選擇不同的顯示方式
    switch (widget.device.type) {
      case 'air_conditioner':
        return _buildAirConditionerCard(widget.device as AirConditionerModel);
      case MQTTEnabledDHT11Model.TYPE:
        return Dht11Card(device: widget.device);
      // case 'fan':
      //   return _buildFanCard(widget.device as SwitchableModel);
      // case 'light':
      //   return _buildLightCard(widget.device as SwitchableModel);
      // case 'curtain':
      //   return _buildCurtainCard(widget.device as SwitchableModel);
      // case 'door':
      //   return _buildDoorCard(widget.device as SwitchableModel);
      // case 'sensor':
      //   return _buildSensorCard(widget.device as SwitchableModel);
      // case 'switch':
      //   return _buildSwitchableCard(widget.device as SwitchableModel);
      default:
        return GeneralCard(device: widget.device, detailedPage: Container());
    }
  }

  // 空調設備卡片
  Widget _buildAirConditionerCard(AirConditionerModel device) {
    return InkWell(
      onTap: () {
        print("空調卡片被點擊: ${device.name}"); // 調試信息
        _openAirConditionerControl(device);
      },
      borderRadius: BorderRadius.circular(15),
      splashColor: Colors.blue.withOpacity(0.3),
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

  // MQTT DHT11 溫濕度傳感器卡片
  Widget _buildMQTTDHT11SensorCard(MQTTEnabledDHT11Model device) {
    bool isOnline = device.isOnline;

    return GestureDetector(
      onTap: () => _navigateToDeviceControl(),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isOnline ? Colors.lightBlue.shade50 : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isOnline ? Colors.blue.shade200 : Colors.grey.shade300,
            width: 1.5,
          ),
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
                Row(
                  children: [
                    Icon(
                      Icons.thermostat,
                      color: isOnline ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'MQTT',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
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
            Text(
              'ID: ${truncateString(device.deviceId, 8)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
                      '${device.temperature.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.water_drop, size: 20, color: Colors.blue),
                    const SizedBox(height: 4),
                    Text(
                      '${device.humidity.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? Colors.black87 : Colors.grey,
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

  // 可切換設備卡片
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

  // 風扇設備卡片
  Widget _buildFanCard(SwitchableModel device) {
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
      onTap: () => _navigateToDeviceControl(),
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
      onTap: () => _navigateToDeviceControl(),
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
      onTap: () => _navigateToDeviceControl(),
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
      onTap: () => _navigateToDeviceControl(),
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
