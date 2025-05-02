import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/general_model.dart';
import 'package:extendable_aiot/models/room_model.dart';
import 'package:extendable_aiot/models/switch_model.dart';
import 'package:extendable_aiot/models/airconditioner_model.dart';
import 'package:extendable_aiot/models/dht11_sensor_model.dart';
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
  final TextEditingController _deviceNameController = TextEditingController();
  String _selectedDeviceType = '中央空調';
  RoomModel? _roomModel;

  int page = 1;
  int limit = 10;
  bool loading = true;
  bool error = false;
  String? errorMsg;

  // 设备类型列表
  final List<Map<String, dynamic>> _deviceTypes = [
    {'type': 'air_conditioner', 'name': '中央空調', 'icon': Icons.ac_unit},
    {'type': '風扇', 'name': '風扇', 'icon': Icons.wind_power},
    {'type': '燈光', 'name': '燈光', 'icon': Icons.lightbulb},
    {'type': '窗簾', 'name': '窗簾', 'icon': Icons.curtains},
    {'type': '門鎖', 'name': '門鎖', 'icon': Icons.lock},
    {'type': '感測器', 'name': '感測器', 'icon': Icons.sensors},
    {'type': 'dht11', 'name': 'DHT11溫濕度傳感器', 'icon': Icons.thermostat},
  ];

  @override
  void initState() {
    super.initState();
    _loadRoomModel();
  }

  Future<void> _loadRoomModel() async {
    try {
      final room = await RoomModel.getRoom(widget.roomId);
      if (mounted) {
        setState(() {
          _roomModel = room;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = true;
          errorMsg = e.toString();
          loading = false;
        });
      }
    }
  }

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
                  if (_deviceNameController.text.isNotEmpty &&
                      _roomModel != null) {
                    await _addDevice(
                      _deviceNameController.text,
                      _selectedDeviceType,
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

  // 使用模型来添加设备
  Future<void> _addDevice(String name, String type) async {
    if (_roomModel == null) return;

    try {
      switch (type) {
        case 'air_conditioner':
          final acDevice = AirConditionerModel(
            null, // Firebase 会自动生成 ID
            name: name,
            roomId: widget.roomId,
            lastUpdated: Timestamp.now(),
          );
          await acDevice.createData();
          await _roomModel!.addDevice(acDevice.id);
          break;
        case 'dht11':
          final dht11Device = DHT11SensorModel(
            null, // Firebase 会自动生成 ID
            name: name,
            roomId: widget.roomId,
            lastUpdated: Timestamp.now(),
            temperature: 0.0,
            humidity: 0.0,
          );
          await dht11Device.createData();
          await _roomModel!.addDevice(dht11Device.id);
          break;
        default:
          // 默认使用基本的 SwitchModel
          final switchable = SwitchModel(
            null, // Firebase 会自动生成 ID
            name: name,
            type: type,
            lastUpdated: Timestamp.now(),
            icon: _getIconForType(type),
            updateValue: [true, false],
            previousValue: [false, true],
            status: false,
          );
          await switchable.createData();
          await _roomModel!.addDevice(switchable.id);
          break;
      }
    } catch (e) {
      print('添加设备错误: $e');
      // 可以添加错误处理逻辑，如显示错误消息等
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error) {
      return Center(child: Text('錯誤: $errorMsg'));
    }

    if (_roomModel == null) {
      return Center(child: Text(localizations?.roomNotFound ?? '找不到房間'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_roomModel?.name ?? ''), // 显示房间名称
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeviceDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _roomModel!.devicesStream(),
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
              final String type = data['type'] as String? ?? '未知';
              final String name = data['name'] as String? ?? '未命名設備';
              final Timestamp lastUpdated =
                  data['lastUpdated'] as Timestamp? ?? Timestamp.now();
              final bool status = data['status'] as bool? ?? false;

              switch (type) {
                case 'air_conditioner':
                  try {
                    final acDevice = AirConditionerModel(
                      device.id,
                      name: name,
                      roomId: widget.roomId,
                      lastUpdated: lastUpdated,
                    );
                    acDevice.fromJson(data);
                    deviceModels.add(acDevice);
                  } catch (e) {
                    print('解析空调设备错误: $e');
                    // 使用基本的 SwitchModel 作为备用
                    final fallbackDevice = SwitchModel(
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
                      roomId: widget.roomId,
                      lastUpdated: lastUpdated,
                      temperature:
                          (data['temperature'] as num?)?.toDouble() ?? 0.0,
                      humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
                    );
                    deviceModels.add(dht11Device);
                  } catch (e) {
                    print('解析DHT11设备错误: $e');
                    // 使用基本的 SwitchModel 作为备用
                    final fallbackDevice = SwitchModel(
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
                  // 默认使用基本的SwitchModel
                  final switchable = SwitchModel(
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
