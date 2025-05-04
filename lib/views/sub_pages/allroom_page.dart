import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/abstract/device_model.dart';
import 'package:extendable_aiot/models/abstract/general_model.dart';
import 'package:extendable_aiot/models/abstract/room_model.dart';
import 'package:extendable_aiot/views/card/device_card.dart';
import 'package:flutter/material.dart';

class AllRoomPage extends StatefulWidget {
  const AllRoomPage({super.key});

  @override
  State<AllRoomPage> createState() => _AllRoomPageSate();
}

class _AllRoomPageSate extends State<AllRoomPage> {
  final TextEditingController _roomNameController = TextEditingController();

  // 裝置類型列表用於圖標匹配
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
                    // 使用 RoomModel 創建房間
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

  // 根據裝置類型獲取對應的圖標
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

          // 使用 ListView 顯示房間列表
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

  // 創建房間卡片元件
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
        subtitle: Text('裝置數: ${room.devices.length}'), //ID: ${room.id} |
        children: [
          if (room.devices.isEmpty)
            const Padding(padding: EdgeInsets.all(16.0), child: Text('此房間沒有裝置'))
          else
            FutureBuilder<List<DocumentSnapshot>>(
              future: room.loadDevices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('載入裝置錯誤: ${snapshot.error}'));
                }

                final devices = snapshot.data ?? [];
                if (devices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('此房間沒有裝置'),
                  );
                }

                // 將裝置數據轉換為對應的模型
                List<GeneralModel> deviceModels = [];
                for (var device in devices) {
                  try {
                    // 使用 DeviceModel.fromDocumentSnapshot 處理設備數據
                    GeneralModel? deviceModel =
                        DeviceModel.fromDocumentSnapshot(
                          device,
                          _getIconForType,
                        );
                    if (deviceModel != null) {
                      deviceModels.add(deviceModel);
                    }
                  } catch (e) {
                    print('裝置數據解析錯誤: $e');
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
          // 房間管理按鈕
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('編輯房間'),
                  onPressed: () => _showEditRoomDialog(room),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    '刪除房間',
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

  // 顯示編輯房間對話框
  Future<void> _showEditRoomDialog(RoomModel room) async {
    final localizations = AppLocalizations.of(context);
    final TextEditingController nameController = TextEditingController(
      text: room.name,
    );

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.editRoom ?? '編輯房間'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: localizations?.roomName ?? '房間名稱',
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
                child: Text(localizations?.confirm ?? '確認'),
              ),
            ],
          ),
    );
  }

  // 顯示刪除房間確認對話框
  Future<void> _showDeleteRoomConfirmation(RoomModel room) async {
    final localizations = AppLocalizations.of(context);

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.confirmDelete ?? '確認刪除'),
            content: Text('確定要刪除房間 "${room.name}" 嗎？此操作無法撤銷，且會同時刪除所有關聯裝置。'),
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
                child: Text(localizations?.delete ?? '刪除'),
              ),
            ],
          ),
    );
  }
}
