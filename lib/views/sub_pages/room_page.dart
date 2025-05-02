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

  // 添加用户服务和好友列表状态
  final UserService _userService = UserService();
  List<FriendModel> _roomFriends = [];
  bool _loadingFriends = true;
  List<FriendModel> _allFriends = [];
  bool _loadingAllFriends = true;

  // 设备类型列表
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

  // 加载有权限访问该房间的好友
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
      print('Error loading room friends: $e');
      if (mounted) {
        setState(() {
          _loadingFriends = false;
        });
      }
    }
  }

  // 加载所有好友，用于添加新好友到房间
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
        print("Error loading all friends: $error");
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
                                (data['temperature'] as num?)?.toDouble() ??
                                0.0,
                            humidity:
                                (data['humidity'] as num?)?.toDouble() ?? 0.0,
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
          _buildRoomActions(localizations),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(),
        child: const Icon(Icons.add),
        tooltip: localizations?.addDevice ?? '添加设备',
      ),
    );
  }

  // 房间头部信息
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
                    tooltip: localizations?.manageFriends ?? '管理好友访问权限',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditRoomDialog(localizations),
                    tooltip: localizations?.editRoom ?? '编辑房间',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 房间底部操作区
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
              localizations?.deleteRoom ?? '删除房间',
              style: const TextStyle(color: Colors.red),
            ),
            onPressed: () => _showDeleteRoomConfirmation(localizations),
          ),
        ],
      ),
    );
  }

  // 显示管理好友访问权限的对话框
  void _showManageFriendsDialog(AppLocalizations? localizations) {
    if (_loadingAllFriends || _loadingFriends) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.loadingFriends ?? '正在加载好友列表...')),
      );
      return;
    }

    if (_allFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.noFriends ?? '您还没有添加任何好友')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.manageFriends ?? '管理好友访问权限'),
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
                          // 添加访问权限
                          await _userService.addFriendToRoom(
                            friend.id,
                            widget.roomId,
                          );
                        } else {
                          // 移除访问权限
                          await _userService.removeFriendFromRoom(
                            friend.id,
                            widget.roomId,
                          );
                        }

                        // 重新加载房间好友列表
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
                child: Text(localizations?.close ?? '关闭'),
              ),
            ],
          ),
    );
  }

  // 显示编辑房间对话框
  void _showEditRoomDialog(AppLocalizations? localizations) {
    final TextEditingController nameController = TextEditingController(
      text: _roomModel?.name,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.editRoom ?? '编辑房间'),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: localizations?.roomName ?? '房间名称',
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
                          content: Text(localizations?.roomUpdated ?? '房间已更新'),
                        ),
                      );
                    }
                  }
                },
                child: Text(localizations?.save ?? '保存'),
              ),
            ],
          ),
    );
  }

  // 确认删除房间
  void _showDeleteRoomConfirmation(AppLocalizations? localizations) {
    if (_roomModel == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations?.confirmDelete ?? '确认删除'),
            content: Text(
              localizations?.confirmDeleteRoom("") ??
                  '确定要删除房间吗？此操作无法撤销，且会同时删除所有关联设备。',
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
                      Navigator.pop(context); // 返回上一级页面
                    }
                  }
                },
                child: Text(localizations?.delete ?? '删除'),
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
  bool get wantKeepAlive => true;
}
