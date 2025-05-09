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
    // 使用外層的 LayoutBuilder 獲取卡片的可用空間
    return LayoutBuilder(
      builder: (context, constraints) {
        // 基於卡片的實際寬度調整所有元素大小
        final cardWidth = constraints.maxWidth;
        final cardPadding = cardWidth * 0.03;

        return Card(
          color: Colors.grey[100],
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
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
                  final windIconSize = contentWidth * 0.28;
                  final tempIconSize = contentWidth * 0.32;
                  final titleFontSize = contentWidth * 0.12;
                  final dataFontSize = contentWidth * 0.08;
                  final switchScaleFactor = contentWidth * 0.003;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 標題區域
                      Row(
                        children: [
                          Icon(
                            Icons.ac_unit,
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
                          Transform.scale(
                            scale: switchScaleFactor,
                            child: Switch(
                              value: widget.device.status,
                              onChanged:
                                  (_) =>
                                      _toggleDeviceStatus(widget.device.status),
                              activeColor: Colors.blue,
                            ),
                          ),
                          SizedBox(width: contentWidth * 0.02),
                          // 在線狀態指示器
                          Container(
                            width: statusSize,
                            height: statusSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: contentWidth * 0.06),

                      // 溫度和風速資訊
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.wind_power_outlined,
                                  size: windIconSize,
                                  color: Colors.blue,
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.device.fanSpeed,
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
