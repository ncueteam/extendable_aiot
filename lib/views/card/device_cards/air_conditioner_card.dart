import 'package:extendable_aiot/components/airconditioner_control.dart';
import 'package:extendable_aiot/models/abstract/device_model.dart';
import 'package:extendable_aiot/models/sub_type/airconditioner_model.dart';
import 'package:flutter/material.dart';

class AirConditionerCard extends StatefulWidget {
  final AirConditionerModel device;
  final Function(bool)? onStatusChange; // 添加回调函数属性

  const AirConditionerCard({
    super.key,
    required this.device,
    this.onStatusChange, // 初始化回调
  });

  @override
  State<AirConditionerCard> createState() => _AirConditionerCardState();
}

class _AirConditionerCardState extends State<AirConditionerCard> {
  Future<void> _toggleDeviceStatus(bool currentStatus) async {
    try {
      // 如果有回调，调用它而不是自己做setState
      if (widget.onStatusChange != null) {
        widget.onStatusChange!(!currentStatus);
      }
      setState(() {
        widget.device.status = !currentStatus;
      });

      // 更新Firebase数据
      await DeviceModel.updateDeviceStatus(
        deviceId: widget.device.id,
        status: !currentStatus,
      );
    } catch (e) {
      debugPrint('更新設備狀態失敗: $e');

      // 如果有回调，通知更新失败需要恢复状态
      if (widget.onStatusChange != null) {
        widget.onStatusChange!(currentStatus);
      } else {
        setState(() {
          widget.device.status = currentStatus;
        });
      }

      if (context.mounted) {
        debugPrint('更新設備狀態失敗: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新設備狀態失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[100],
      margin: const EdgeInsets.all(10),
      child: ListTile(
        titleTextStyle: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
        subtitleTextStyle: TextStyle(fontSize: 20, color: Colors.blueGrey),
        textColor: Colors.blueGrey,
        splashColor: Colors.blue.withAlpha(100),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      AirConditionerControl(airConditioner: widget.device),
            ),
          );
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.thermostat, size: 30, color: Colors.blueGrey),
            Text(widget.device.name),
            const SizedBox(width: 10),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Icon(
                      Icons.wind_power_outlined,
                      size: 50,
                      color: Colors.blue,
                    ),
                    Text(widget.device.fanSpeed),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.thermostat, size: 60, color: Colors.red),
                    Text('${(widget.device.temperature * 10).round() / 10} °C'),
                  ],
                ),
              ],
            ),
            Switch(
              value: widget.device.status,
              onChanged: (_) => _toggleDeviceStatus(widget.device.status),
              activeColor: Colors.blue,
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
