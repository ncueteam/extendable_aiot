import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/switchable_model.dart';
import 'package:extendable_aiot/services/add_data.dart';
import 'package:extendable_aiot/services/fetch_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SwitchableDeviceInRoomDemo extends StatefulWidget {
  const SwitchableDeviceInRoomDemo({Key? key}) : super(key: key);

  @override
  State<SwitchableDeviceInRoomDemo> createState() =>
      _SwitchableDeviceInRoomDemoState();
}

class _SwitchableDeviceInRoomDemoState
    extends State<SwitchableDeviceInRoomDemo> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();

  final FetchData _fetchData = FetchData();
  final AddData _addData = AddData();

  String? _selectedRoomId;
  bool _isLoading = false;
  String _operationMessage = '';
  List<SwitchableModel> _devices = [];

  @override
  void dispose() {
    _deviceNameController.dispose();
    _roomNameController.dispose();
    super.dispose();
  }

  // 创建新房间
  Future<void> _createRoom() async {
    if (_roomNameController.text.isEmpty) {
      setState(() {
        _operationMessage = '请输入房间名称';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _operationMessage = '创建房间中...';
    });

    try {
      await _addData.addRoom(roomId: _roomNameController.text);
      setState(() {
        _selectedRoomId = _roomNameController.text;
        _roomNameController.clear();
        _isLoading = false;
        _operationMessage = '房间创建成功: $_selectedRoomId';
      });
      // 创建房间后自动加载该房间的设备
      _loadDevicesInRoom(_selectedRoomId!);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _operationMessage = '创建房间错误: $e';
      });
    }
  }

  // 在选定的房间内创建新设备
  Future<void> _createDeviceInRoom() async {
    if (_deviceNameController.text.isEmpty) {
      setState(() {
        _operationMessage = '请输入设备名称';
      });
      return;
    }

    if (_selectedRoomId == null) {
      setState(() {
        _operationMessage = '请先选择或创建一个房间';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _operationMessage = '创建设备中...';
    });

    try {
      // 使用AddData服务创建设备
      final deviceRef = await _addData.addDevice(
        name: _deviceNameController.text,
        type: 'switch',
        roomId: _selectedRoomId!,
      );

      setState(() {
        _deviceNameController.clear();
        _isLoading = false;
        _operationMessage = '设备创建成功: ${deviceRef.id}';
      });

      // 重新加载房间中的设备
      _loadDevicesInRoom(_selectedRoomId!);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _operationMessage = '创建设备错误: $e';
      });
    }
  }

  // 加载指定房间的设备
  Future<void> _loadDevicesInRoom(String roomId) async {
    setState(() {
      _isLoading = true;
      _operationMessage = '加载房间设备中...';
    });

    try {
      // 使用StreamBuilder替代这里的直接加载，让UI能够自动更新
      setState(() {
        _selectedRoomId = roomId;
        _isLoading = false;
        _operationMessage = '已选择房间: $roomId';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _operationMessage = '加载房间设备错误: $e';
      });
    }
  }

  // 更新设备状态
  Future<void> _toggleDeviceStatus(String deviceId, bool currentStatus) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // 更新Firebase中的数据
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .update({
            'status': !currentStatus,
            'lastUpdate': FieldValue.serverTimestamp(),
          });

      setState(() {
        _operationMessage = '设备状态已更新';
      });
    } catch (e) {
      setState(() {
        _operationMessage = '更新设备状态失败: $e';
      });
    }
  }

  // 删除设备
  Future<void> _deleteDevice(String deviceId) async {
    if (_selectedRoomId == null) return;

    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // 1. 从房间中移除设备引用
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('rooms')
          .doc(_selectedRoomId)
          .update({
            'devices': FieldValue.arrayRemove([deviceId]),
          });

      // 2. 删除设备文档
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .delete();

      setState(() {
        _operationMessage = '设备已删除';
      });
    } catch (e) {
      setState(() {
        _operationMessage = '删除设备失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations?.deviceName ?? '房间内可切换设备示例')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 房间选择部分
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '选择房间',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 显示现有房间供选择
                            StreamBuilder<QuerySnapshot>(
                              stream: _fetchData.getRooms(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Text('错误: ${snapshot.error}');
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final rooms = snapshot.data?.docs ?? [];

                                if (rooms.isEmpty) {
                                  return const Text('还没有创建任何房间，请先创建房间');
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('选择一个房间:'),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 50,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: rooms.length,
                                        itemBuilder: (context, index) {
                                          final roomId = rooms[index].id;
                                          final isSelected =
                                              roomId == _selectedRoomId;

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    isSelected
                                                        ? Colors.blue
                                                        : null,
                                                foregroundColor:
                                                    isSelected
                                                        ? Colors.white
                                                        : null,
                                              ),
                                              onPressed:
                                                  () => _loadDevicesInRoom(
                                                    roomId,
                                                  ),
                                              child: Text(roomId),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // 创建新房间
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _roomNameController,
                                    decoration: const InputDecoration(
                                      labelText: '新房间名称',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _createRoom,
                                  icon: const Icon(Icons.add),
                                  label: const Text('创建房间'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 创建设备部分（仅当选择了房间时显示）
                    if (_selectedRoomId != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '在房间"$_selectedRoomId"中创建新的可切换设备',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _deviceNameController,
                                      decoration: const InputDecoration(
                                        labelText: '设备名称',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: _createDeviceInRoom,
                                    icon: const Icon(Icons.add),
                                    label: const Text('创建设备'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 设备列表部分（仅当选择了房间时显示）
                    if (_selectedRoomId != null)
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '房间"$_selectedRoomId"中的设备',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: StreamBuilder<List<DocumentSnapshot>>(
                                    stream: _fetchData.getRoomDevices(
                                      _selectedRoomId!,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text('错误: ${snapshot.error}'),
                                        );
                                      }

                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final devices = snapshot.data ?? [];

                                      if (devices.isEmpty) {
                                        return const Center(
                                          child: Text('该房间还没有设备'),
                                        );
                                      }

                                      return ListView.builder(
                                        itemCount: devices.length,
                                        itemBuilder: (context, index) {
                                          final device = devices[index];
                                          final deviceData =
                                              device.data()
                                                  as Map<String, dynamic>;
                                          final deviceId = device.id;
                                          final deviceName =
                                              deviceData['name'] as String;
                                          final isSwitch =
                                              (deviceData['type'] as String) ==
                                              'switch';
                                          final status =
                                              deviceData['status'] as bool? ??
                                              false;

                                          // 只显示类型为"switch"的设备
                                          if (!isSwitch) {
                                            return const SizedBox.shrink();
                                          }

                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.toggle_on,
                                                color:
                                                    status
                                                        ? Colors.blue
                                                        : Colors.grey,
                                                size: 30,
                                              ),
                                              title: Text(
                                                deviceName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '设备ID: $deviceId',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Switch(
                                                    value: status,
                                                    onChanged:
                                                        (_) =>
                                                            _toggleDeviceStatus(
                                                              deviceId,
                                                              status,
                                                            ),
                                                    activeColor: Colors.blue,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed:
                                                        () => _deleteDevice(
                                                          deviceId,
                                                        ),
                                                    tooltip: '删除设备',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // 操作消息
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '操作结果',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              width: double.infinity,
                              child: Text(_operationMessage),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
