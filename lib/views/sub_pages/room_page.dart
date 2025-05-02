import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/general_model.dart';
import 'package:extendable_aiot/models/switch_model.dart';
import 'package:extendable_aiot/models/switchable_model.dart';
import 'package:extendable_aiot/models/airconditioner_model.dart';
import 'package:extendable_aiot/models/dht11_sensor_model.dart';
import 'package:extendable_aiot/services/add_data.dart';
import 'package:extendable_aiot/services/fetch_data.dart';
import 'package:extendable_aiot/views/card/device_card.dart';
import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';

class RoomPage extends StatefulWidget {
  final String roomId;

  const RoomPage({super.key, required this.roomId});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage>
    with AutomaticKeepAliveClientMixin {
  final AddData _addData = AddData();
  final FetchData _fetchData = FetchData();
  final TextEditingController _deviceNameController = TextEditingController();
  String _selectedDeviceType = '中央空調';

  int page = 1;
  int limit = 10;
  bool loading = true;
  bool error = false;
  String? errorMsg;

  // 设备类型列表
  final List<Map<String, dynamic>> _deviceTypes = [
    {'type': '中央空調', 'name': '中央空調', 'icon': Icons.ac_unit},
    {'type': '風扇', 'name': '風扇', 'icon': Icons.wind_power},
    {'type': '燈光', 'name': '燈光', 'icon': Icons.lightbulb},
    {'type': '窗簾', 'name': '窗簾', 'icon': Icons.curtains},
    {'type': '門鎖', 'name': '門鎖', 'icon': Icons.lock},
    {'type': '感測器', 'name': '感測器', 'icon': Icons.sensors},
    {'type': 'dht11', 'name': 'DHT11溫濕度傳感器', 'icon': Icons.thermostat},
  ];

  Future<void> _showAddDeviceDialog() async {
    final localizations = AppLocalizations.of(context);

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.addDevice ?? '新增設備'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _deviceNameController,
                  decoration: InputDecoration(
                    labelText: localizations?.deviceName ?? '設備名稱',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: _selectedDeviceType,
                  items:
                      _deviceTypes.map((Map<String, dynamic> type) {
                        return DropdownMenuItem<String>(
                          value: type['type'] as String,
                          child: Row(
                            children: [
                              Icon(type['icon'] as IconData),
                              const SizedBox(width: 8),
                              Text(type['name'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDeviceType = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.cancel ?? '取消'),
              ),
              TextButton(
                onPressed: () async {
                  if (_deviceNameController.text.isNotEmpty) {
                    await _addData.addDevice(
                      name: _deviceNameController.text,
                      type: _selectedDeviceType,
                      roomId: widget.roomId,
                    );
                    _deviceNameController.clear();
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(localizations?.confirm ?? '確認'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeviceDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _fetchData.getRoomDevices(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('錯誤: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data ?? [];

          if (devices.isEmpty) {
            return Center(child: Text(localizations?.noDevices ?? '此房間還沒有設備'));
          }

          // 将设备数据转换为对应的模型
          List<GeneralModel> deviceModels = [];
          for (var device in devices) {
            try {
              final data = device.data() as Map<String, dynamic>;
              final String type = data['type'] as String;

              switch (type) {
                case '中央空調':
                  final acDevice = AirConditionerModel(
                    device.id,
                    name: data['name'] as String,
                    roomId: widget.roomId,
                    lastUpdated:
                        data['lastUpdated'] as Timestamp? ?? Timestamp.now(),
                  );
                  acDevice.fromJson(data);
                  deviceModels.add(acDevice);
                  break;
                case 'dht11':
                  final dht11Device = DHT11SensorModel(
                    device.id,
                    name: data['name'] as String,
                    roomId: widget.roomId,
                    lastUpdated:
                        data['lastUpdated'] as Timestamp? ?? Timestamp.now(),
                    temperature:
                        (data['temperature'] as num?)?.toDouble() ?? 0.0,
                    humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
                  );
                  deviceModels.add(dht11Device);
                  break;
                default:
                  // 默认使用基本的SwitchableModel
                  final switchable = SwitchModel(
                    device.id,
                    name: data['name'] as String,
                    type: type,
                    lastUpdated:
                        data['lastUpdated'] as Timestamp? ?? Timestamp.now(),
                    icon: _getIconForType(type),
                    updateValue: [true, false],
                    previousValue: [false, true],
                    status: data['status'] as bool? ?? false,
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
  bool get wantKeepAlive => true;
}
