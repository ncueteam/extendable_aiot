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
    // 使用外層的 LayoutBuilder 獲取卡片的可用空間
    return LayoutBuilder(
      builder: (context, constraints) {
        // 基於卡片的實際寬度調整所有元素大小
        final cardWidth = constraints.maxWidth;
        final cardPadding = cardWidth * 0.03;

        return Card(
          margin: const EdgeInsets.all(10),
          color: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => MQTTDht11DetailsPage(sensor: widget.device),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  // 取得內部容器的實際尺寸
                  final contentWidth = innerConstraints.maxWidth;

                  // 基於內部容器大小動態計算各元素尺寸
                  final titleIconSize = contentWidth * 0.16;
                  final statusSize = contentWidth * 0.06;
                  final tempIconSize = contentWidth * 0.32;
                  final humidityIconSize = contentWidth * 0.28;
                  final titleFontSize = contentWidth * 0.12;
                  final dataFontSize = contentWidth * 0.08;
                  final infoFontSize = contentWidth * 0.07;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 標題區域
                      Row(
                        children: [
                          Icon(
                            Icons.thermostat,
                            size: titleIconSize,
                            color: Colors.blueGrey,
                          ),
                          SizedBox(width: contentWidth * 0.02),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.device.name,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: contentWidth * 0.02),
                          // 在線狀態指示器
                          Container(
                            width: statusSize,
                            height: statusSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: contentWidth * 0.03),

                      // 更新時間
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '最後更新: ${widget.device.lastUpdatedTime.toString().split('.')[0]}',
                          style: TextStyle(fontSize: infoFontSize),
                        ),
                      ),

                      SizedBox(height: contentWidth * 0.04),

                      // 溫度和濕度資訊
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.thermostat,
                                  size: tempIconSize,
                                  color: Colors.red,
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${(widget.device.temperature * 10).round() / 10} °C',
                                    style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: dataFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  size: humidityIconSize,
                                  color: Colors.blue,
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${(widget.device.humidity * 10).round() / 10} %',
                                    style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: dataFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
