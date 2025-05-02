import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/general_model.dart';
import 'package:extendable_aiot/models/switchable_model.dart';
import 'package:extendable_aiot/models/airconditioner_model.dart';
import 'package:extendable_aiot/models/dht11_sensor_model.dart';
import 'package:extendable_aiot/services/add_data.dart';
import 'package:extendable_aiot/services/fetch_data.dart';
import 'package:extendable_aiot/views/card/device_card.dart';
import 'package:flutter/material.dart';

class AllRoomPage extends StatefulWidget {
  const AllRoomPage({super.key});

  @override
  State<AllRoomPage> createState() => _AllRoomPageState();
}

class _AllRoomPageState extends State<AllRoomPage> {
  final AddData _addData = AddData();
  final FetchData _fetchData = FetchData();
  final TextEditingController _roomNameController = TextEditingController();

  // 设备类型列表用于图标匹配
  final List<Map<String, dynamic>> _deviceTypes = [
    {'type': '中央空調', 'name': '中央空調', 'icon': Icons.ac_unit},
    {'type': '風扇', 'name': '風扇', 'icon': Icons.wind_power},
    {'type': '燈光', 'name': '燈光', 'icon': Icons.lightbulb},
    {'type': '窗簾', 'name': '窗簾', 'icon': Icons.curtains},
    {'type': '門鎖', 'name': '門鎖', 'icon': Icons.lock},
    {'type': '感測器', 'name': '感測器', 'icon': Icons.sensors},
    {'type': 'dht11', 'name': 'DHT11溫濕度傳感器', 'icon': Icons.thermostat},
  ];

  Future<void> _showAddRoomDialog() async {
    final localizations = AppLocalizations.of(context);

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.addRoom ?? '新增房間'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _roomNameController,
                  decoration: InputDecoration(
                    labelText: localizations?.roomName ?? '房間名稱',
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.cancel ?? '取消'),
              ),
              TextButton(
                onPressed: () async {
                  if (_roomNameController.text.isNotEmpty) {
                    await _addData.addRoom(name: _roomNameController.text);
                    _roomNameController.clear();
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(localizations?.confirm ?? '確認'),
              ),
            ],
          ),
    );
  }

  // 根据设备类型获取对应的图标
  IconData _getIconForType(String type) {
    for (var deviceType in _deviceTypes) {
      if (deviceType['type'] == type) {
        return deviceType['icon'] as IconData;
      }
    }
    return Icons.device_unknown;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _fetchData.getAllDevices(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('錯誤: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data ?? [];

          if (devices.isEmpty) {
            return Center(child: Text(localizations?.noDevices ?? '還沒有創建設備'));
          }

          // 将设备数据转换为对应的模型
          List<GeneralModel> deviceModels = [];
          for (var device in devices) {
            try {
              final data = device.data() as Map<String, dynamic>;
              // 防止字段不存在引发错误
              final String type = data['type'] as String? ?? '未知';
              final String roomId = data['roomId'] as String? ?? '';
              final String name = data['name'] as String? ?? '未命名設備';
              final Timestamp lastUpdated =
                  data['lastUpdated'] as Timestamp? ?? Timestamp.now();
              final bool status = data['status'] as bool? ?? false;

              switch (type) {
                case '中央空調':
                  try {
                    final acDevice = AirConditionerModel(
                      device.id,
                      name: name,
                      roomId: roomId,
                      lastUpdated: lastUpdated,
                    );
                    // 安全地调用 fromJson 方法
                    acDevice.fromJson(data);
                    deviceModels.add(acDevice);
                  } catch (e) {
                    print('解析空調設備錯誤: $e');
                    // 添加一个基本的设备模型，以防解析失败
                    final fallbackDevice = SwitchableModel(
                      device.id,
                      name: name,
                      type: type,
                      lastUpdated: lastUpdated,
                      icon: _getIconForType(type),
                      updateValue: [true, false],
                      previousValue: [false, true],
                      status: status,
                    );
                    deviceModels.add(fallbackDevice);
                  }
                  break;
                case 'dht11':
                  try {
                    final dht11Device = DHT11SensorModel(
                      device.id,
                      name: name,
                      roomId: roomId,
                      lastUpdated: lastUpdated,
                      temperature:
                          (data['temperature'] as num?)?.toDouble() ?? 0.0,
                      humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
                    );
                    deviceModels.add(dht11Device);
                  } catch (e) {
                    print('解析DHT11設備錯誤: $e');
                    // 添加一个基本的设备模型，以防解析失败
                    final fallbackDevice = SwitchableModel(
                      device.id,
                      name: name,
                      type: type,
                      lastUpdated: lastUpdated,
                      icon: _getIconForType(type),
                      updateValue: [true, false],
                      previousValue: [false, true],
                      status: status,
                    );
                    deviceModels.add(fallbackDevice);
                  }
                  break;
                default:
                  // 默认使用基本的SwitchableModel
                  final switchable = SwitchableModel(
                    device.id,
                    name: name,
                    type: type,
                    lastUpdated: lastUpdated,
                    icon: _getIconForType(type),
                    updateValue: [true, false],
                    previousValue: [false, true],
                    status: status,
                  );
                  deviceModels.add(switchable);
                  break;
              }
            } catch (e) {
              print('設備數據解析錯誤: $e');
            }
          }

          return EasyRefresh(
            header: const ClassicHeader(),
            footer: const ClassicFooter(),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
              ),
              itemCount: deviceModels.length,
              itemBuilder: (BuildContext context, int index) {
                return DeviceCard(device: deviceModels[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
