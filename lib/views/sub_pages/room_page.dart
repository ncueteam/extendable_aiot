import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/general_model.dart';
import 'package:extendable_aiot/models/room_model.dart';
import 'package:extendable_aiot/models/switch_model.dart';
import 'package:extendable_aiot/models/airconditioner_model.dart';
import 'package:extendable_aiot/models/dht11_sensor_model.dart';
import 'package:extendable_aiot/models/friend_model.dart';
import 'package:extendable_aiot/services/user_service.dart';
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
  String _selectedDeviceType = 'air_conditioner';
  RoomModel? _roomModel;

  int page = 1;
  int limit = 10;
  bool loading = true;
  bool error = false;
  String? errorMsg;

  // 新增使用者服務和好友列表狀態
  final UserService _userService = UserService();
  List<FriendModel> _roomFriends = [];
  bool _loadingFriends = true;
  List<FriendModel> _allFriends = [];
  bool _loadingAllFriends = true;

  // 裝置類型列表
  final List<Map<String, dynamic>> _deviceTypes = [
    {'type': 'air_conditioner', 'name': '中央空調', 'icon': Icons.ac_unit},
    {'type': 'fan', 'name': '風扇', 'icon': Icons.wind_power},
    {'type': 'light', 'name': '燈光', 'icon': Icons.lightbulb},
    {'type': 'curtain', 'name': '窗簾', 'icon': Icons.curtains},
    {'type': 'door', 'name': '門鎖', 'icon': Icons.lock},
    {'type': 'sensor', 'name': '感測器', 'icon': Icons.sensors},
    {'type': 'dht11', 'name': 'DHT11溫濕度傳感器', 'icon': Icons.thermostat},
  ];

  @override
  void initState() {
    super.initState();
    _loadRoomModel();
    _loadRoomFriends();
    _loadAllFriends();
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

  // 載入有權限訪問該房間的好友
  Future<void> _loadRoomFriends() async {
    try {
      final friends = await _userService.getFriendsForRoom(widget.roomId);
      if (mounted) {
        setState(() {
          _roomFriends = friends;
          _loadingFriends = false;
        });
      }
    } catch (e) {
      print('載入房間好友錯誤: $e');
      if (mounted) {
        setState(() {
          _loadingFriends = false;
        });
      }
    }
  }

  // 載入所有好友，用於新增新好友到房間
  void _loadAllFriends() {
    _userService.getFriends().listen(
      (friendsList) {
        if (mounted) {
          setState(() {
            _allFriends = friendsList;
            _loadingAllFriends = false;
          });
        }
      },
      onError: (error) {
        print("載入所有好友錯誤: $error");
        if (mounted) {
          setState(() {
            _loadingAllFriends = false;
          });
        }
      },
    );
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

  // 使用模型來新增設備
  Future<void> _addDevice(String name, String type) async {
    if (_roomModel == null) return;

    try {
      switch (type) {
        case 'air_conditioner':
          final acDevice = AirConditionerModel(
            null, // Firebase 會自動生成 ID
            name: name,
            roomId: widget.roomId,
            lastUpdated: Timestamp.now(),
          );
          await acDevice.createData();
          await _roomModel!.addDevice(acDevice.id);
          break;
        case 'dht11':
          final dht11Device = DHT11SensorModel(
            null, // Firebase 會自動生成 ID
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
          // 預設使用基本的 SwitchModel
          final switchable = SwitchModel(
            null, // Firebase 會自動生成 ID
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
      print('新增設備錯誤: $e');
      // 可以新增錯誤處理邏輯，如顯示錯誤訊息等
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
      body: Column(
        children: [
          _buildRoomHeader(localizations),
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
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
                  return Center(
                    child: Text(localizations?.noDevices ?? '此房間還沒有設備'),
                  );
                }

                // 將設備資料轉換為對應的模型
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
                          print('解析空調設備錯誤: $e');
                          // 使用基本的 SwitchModel 作為備用
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
                                (data['temperature'] as num?)?.toDouble() ??
                                0.0,
                            humidity:
                                (data['humidity'] as num?)?.toDouble() ?? 0.0,
                          );
                          deviceModels.add(dht11Device);
                        } catch (e) {
                          print('解析DHT11設備錯誤: $e');
                          // 使用基本的 SwitchModel 作為備用
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
                        // 預設使用基本的SwitchModel
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
                    print('設備資料解析錯誤: $e');
                  }
                }

                return EasyRefresh(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: deviceModels.length,
                    padding: const EdgeInsets.all(8.0),
                    itemBuilder: (BuildContext context, int index) {
                      return DeviceCard(device: deviceModels[index]);
                    },
                  ),
                );
              },
            ),
          ),
          //_buildRoomActions(localizations),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(),
        tooltip: localizations?.addDevice ?? '新增設備',
        child: const Icon(Icons.add),
      ),
    );
  }

  // 房間頭部資訊
  Widget _buildRoomHeader(AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _roomModel!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.group_add),
                    onPressed: () => _showManageFriendsDialog(localizations),
                    tooltip: localizations?.manageFriends ?? '管理好友存取權限',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditRoomDialog(localizations),
                    tooltip: localizations?.editRoom ?? '編輯房間',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteRoomConfirmation(localizations),
                    tooltip: localizations?.deleteRoom ?? '刪除房間',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 房間底部操作區
  Widget _buildRoomActions(AppLocalizations? localizations) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.person),
            label: Text(localizations?.manageFriends ?? '管理好友'),
            onPressed: () => _showManageFriendsDialog(localizations),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text(
              localizations?.deleteRoom ?? '刪除房間',
              style: const TextStyle(color: Colors.red),
            ),
            onPressed: () => _showDeleteRoomConfirmation(localizations),
          ),
        ],
      ),
    );
  }

  // 顯示管理好友存取權限的對話框
  void _showManageFriendsDialog(AppLocalizations? localizations) {
    if (_loadingAllFriends || _loadingFriends) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.loadingFriends ?? '正在載入好友列表...')),
      );
      return;
    }

    if (_allFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.noFriends ?? '您還沒有新增任何好友')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.manageFriends ?? '管理好友存取權限'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: _allFriends.length,
                itemBuilder: (context, index) {
                  final friend = _allFriends[index];
                  final hasAccess = friend.sharedRooms.contains(widget.roomId);

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(friend.name),
                    subtitle: Text(friend.email),
                    trailing: Switch(
                      value: hasAccess,
                      onChanged: (value) async {
                        if (value) {
                          // 新增存取權限
                          await _userService.addFriendToRoom(
                            friend.id,
                            widget.roomId,
                          );
                        } else {
                          // 移除存取權限
                          await _userService.removeFriendFromRoom(
                            friend.id,
                            widget.roomId,
                          );
                        }

                        // 重新載入房間好友列表
                        _loadRoomFriends();
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.close ?? '關閉'),
              ),
            ],
          ),
    );
  }

  // 顯示編輯房間對話框
  void _showEditRoomDialog(AppLocalizations? localizations) {
    final TextEditingController nameController = TextEditingController(
      text: _roomModel?.name,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.editRoom ?? '編輯房間'),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: localizations?.roomName ?? '房間名稱',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.cancel ?? '取消'),
              ),
              TextButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty && _roomModel != null) {
                    _roomModel!.name = newName;
                    await _roomModel!.updateRoom();
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations?.roomUpdated ?? '房間已更新'),
                        ),
                      );
                    }
                  }
                },
                child: Text(localizations?.save ?? '儲存'),
              ),
            ],
          ),
    );
  }

  // 確認刪除房間
  void _showDeleteRoomConfirmation(AppLocalizations? localizations) {
    if (_roomModel == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.confirmDelete ?? '確認刪除'),
            content: Text(
              localizations?.confirmDeleteRoom("") ??
                  '確定要刪除房間嗎？此操作無法撤銷，且會同時刪除所有關聯設備。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.cancel ?? '取消'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  if (_roomModel != null) {
                    await _roomModel!.deleteRoom();
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context); // 返回上一級頁面
                    }
                  }
                },
                child: Text(localizations?.delete ?? '刪除'),
              ),
            ],
          ),
    );
  }

  // 根據設備類型獲取對應的圖標
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
