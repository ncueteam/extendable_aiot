import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/general_model.dart';
import 'package:extendable_aiot/models/room_model.dart';
import 'package:extendable_aiot/models/switch_model.dart';
import 'package:extendable_aiot/models/airconditioner_model.dart';
import 'package:extendable_aiot/models/dht11_sensor_model.dart';
import 'package:extendable_aiot/views/card/device_card.dart';
import 'package:flutter/material.dart';

class AllRoomPage extends StatefulWidget {
  const AllRoomPage({super.key});

  @override
  State<AllRoomPage> createState() => _AllRoomPageState();
}

class _AllRoomPageState extends State<AllRoomPage> {
  final TextEditingController _roomNameController = TextEditingController();

  // 设备类型列表用于图标匹配
  final List<Map<String, dynamic>> _deviceTypes = [
    {'type': 'air_conditioner', 'name': '中央空調', 'icon': Icons.ac_unit},
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
                    // 使用 RoomModel 创建房间
                    RoomModel roomModel = RoomModel(
                      name: _roomNameController.text,
                    );
                    await roomModel.createRoom();

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
      body: StreamBuilder<List<RoomModel>>(
        // 使用 RoomModel.getAllRooms() 替代 _fetchData.getAllDevices()
        stream: RoomModel.getAllRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('錯誤: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(child: Text(localizations?.noRooms ?? '還沒有創建房間'));
          }

          // 使用 ListView 显示房间列表
          return EasyRefresh(
            header: const ClassicHeader(),
            footer: const ClassicFooter(),
            child: ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (BuildContext context, int index) {
                final room = rooms[index];
                return _buildRoomCard(room);
              },
            ),
          );
        },
      ),
    );
  }

  // 创建房间卡片组件
  Widget _buildRoomCard(RoomModel room) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2.0,
      child: ExpansionTile(
        leading: Icon(room.icon, size: 32),
        title: Text(
          room.name,
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
        ),
        subtitle: Text('ID: ${room.id} | 设备数: ${room.devices.length}'),
        children: [
          if (room.devices.isEmpty)
            const Padding(padding: EdgeInsets.all(16.0), child: Text('该房间没有设备'))
          else
            FutureBuilder<List<DocumentSnapshot>>(
              future: room.loadDevices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('加载设备错误: ${snapshot.error}'));
                }

                final devices = snapshot.data ?? [];
                if (devices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('该房间没有设备'),
                  );
                }

                // 将设备数据转换为对应的模型
                List<GeneralModel> deviceModels = [];
                for (var device in devices) {
                  try {
                    final data = device.data() as Map<String, dynamic>;
                    final String type = data['type'] as String? ?? '未知';
                    final String roomId = data['roomId'] as String? ?? '';
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
                            roomId: roomId,
                            lastUpdated: lastUpdated,
                          );
                          acDevice.fromJson(data);
                          deviceModels.add(acDevice);
                        } catch (e) {
                          print('解析空調設備錯誤: $e');
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
                            roomId: roomId,
                            lastUpdated: lastUpdated,
                            temperature:
                                (data['temperature'] as num?)?.toDouble() ??
                                0.0,
                            humidity:
                                (data['humidity'] as num?)?.toDouble() ?? 0.0,
                          );
                          deviceModels.add(dht11Device);
                        } catch (e) {
                          print('解析DHT11設備錯誤: $e');
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

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                  ),
                  itemCount: deviceModels.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (BuildContext context, int index) {
                    return DeviceCard(device: deviceModels[index]);
                  },
                );
              },
            ),
          // 房间管理按钮
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑房间'),
                  onPressed: () => _showEditRoomDialog(room),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    '删除房间',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => _showDeleteRoomConfirmation(room),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 显示编辑房间对话框
  Future<void> _showEditRoomDialog(RoomModel room) async {
    final localizations = AppLocalizations.of(context);
    final TextEditingController nameController = TextEditingController(
      text: room.name,
    );

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.editRoom ?? '编辑房间'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: localizations?.roomName ?? '房间名称',
                  ),
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
                  if (nameController.text.isNotEmpty) {
                    room.name = nameController.text;
                    await room.updateRoom();
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(localizations?.confirm ?? '确认'),
              ),
            ],
          ),
    );
  }

  // 显示删除房间确认对话框
  Future<void> _showDeleteRoomConfirmation(RoomModel room) async {
    final localizations = AppLocalizations.of(context);

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.confirmDelete ?? '确认删除'),
            content: Text('确定要删除房间 "${room.name}" 吗？此操作无法撤销，且会同时删除所有关联设备。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.cancel ?? '取消'),
              ),
              TextButton(
                onPressed: () async {
                  await room.deleteRoom();
                  if (mounted) Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(localizations?.delete ?? '删除'),
              ),
            ],
          ),
    );
  }
}
