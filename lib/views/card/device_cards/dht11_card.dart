import 'package:extendable_aiot/models/sub_type/mqtt_dht11_model.dart';
import 'package:extendable_aiot/views/sub_pages/mqtt_dht11_details_page.dart';
import 'package:flutter/material.dart';

class Dht11Card extends StatefulWidget {
  final MQTTEnabledDHT11Model device;
  const Dht11Card({super.key, required this.device});

  @override
  State<Dht11Card> createState() => _Dht11CardState();
}

class _Dht11CardState extends State<Dht11Card> {
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    // 初始状态
    isOnline = widget.device.isOnline;

    // 添加数据更新监听器
    widget.device.addDataUpdateListener(_onDataUpdated);

    // 添加在线状态监听器
    widget.device.addOnlineStatusListener(_onOnlineStatusChanged);
  }

  @override
  void dispose() {
    // 移除监听器避免内存泄漏
    widget.device.removeDataUpdateListener(_onDataUpdated);
    widget.device.removeOnlineStatusListener(_onOnlineStatusChanged);
    super.dispose();
  }

  // 数据更新回调
  void _onDataUpdated(double temperature, double humidity) {
    if (mounted) {
      setState(() {
        // 数据已在model中更新，只需要刷新UI
      });
    }
  }

  // 在线状态变化回调
  void _onOnlineStatusChanged(bool online) {
    if (mounted) {
      setState(() {
        isOnline = online;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MQTTDht11DetailsPage(sensor: widget.device),
            ),
          );
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.thermostat, size: 30, color: Colors.blueGrey),
            Text(
              widget.device.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(width: 10),
            // 显示在线状态指示器
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              '最後更新: ${widget.device.lastUpdatedTime.toString().split('.')[0]}',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Icon(Icons.thermostat, size: 60, color: Colors.red),
                    Text(
                      '${(widget.device.temperature * 10).round() / 10} °C',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.water_drop, size: 50, color: Colors.blue),
                    Text(
                      '${(widget.device.humidity * 10).round() / 10} %',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),

        tileColor: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
