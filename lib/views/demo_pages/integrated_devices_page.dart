import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/components/airconditioner_control.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/airconditioner_model.dart';
import 'package:extendable_aiot/models/switchable_model.dart';
import 'package:extendable_aiot/services/add_data.dart';
import 'package:extendable_aiot/services/fetch_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IntegratedDevicesPage extends StatefulWidget {
  const IntegratedDevicesPage({Key? key}) : super(key: key);

  @override
  State<IntegratedDevicesPage> createState() => _IntegratedDevicesPageState();
}

class _IntegratedDevicesPageState extends State<IntegratedDevicesPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();

  final FetchData _fetchData = FetchData();
  final AddData _addData = AddData();

  late TabController _tabController;
  String? _selectedRoomId;
  bool _isLoading = false;
  String _operationMessage = '';
  String _deviceType = 'switch'; // 默认为开关设备类型

  // 可用设备类型列表
  final List<Map<String, dynamic>> _deviceTypes = [
    {'type': 'switch', 'name': '可切换设备', 'icon': Icons.toggle_on},
    {'type': 'airconditioner', 'name': '空调设备', 'icon': Icons.ac_unit},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // 清空设备名称
      if (_tabController.indexIsChanging) {
        _deviceNameController.clear();
      }
    });
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _roomNameController.dispose();
    _tabController.dispose();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
        _operationMessage = '创建房间错误: $e';
      });
    }
  }

  // 显示选择设备类型的对话框
  Future<void> _showDeviceTypeSelectionDialog() async {
    if (_selectedRoomId == null) {
      setState(() {
        _operationMessage = '请先选择或创建一个房间';
      });
      return;
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('创建新设备'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('请选择要创建的设备类型:'),
                      const SizedBox(height: 16),

                      // 设备类型选择
                      DropdownButtonFormField<String>(
                        value: _deviceType,
                        decoration: const InputDecoration(
                          labelText: '设备类型',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _deviceTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type['type'],
                                child: Row(
                                  children: [
                                    Icon(type['icon']),
                                    const SizedBox(width: 8),
                                    Text(type['name']),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _deviceType = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // 设备名称输入
                      TextField(
                        controller: _deviceNameController,
                        decoration: const InputDecoration(
                          labelText: '设备名称',
                          border: OutlineInputBorder(),
                          hintText: '输入设备名称',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (_deviceNameController.text.isEmpty) {
                    setState(() {
                      _operationMessage = '请输入设备名称';
                    });
                    return;
                  }

                  Navigator.pop(context);
                  _createDeviceInRoom();
                },
                child: const Text('创建'),
              ),
            ],
          ),
    );
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
      if (_deviceType == 'switch') {
        // 创建可切换设备
        final deviceRef = await _addData.addDevice(
          name: _deviceNameController.text,
          type: 'switch',
          roomId: _selectedRoomId!,
        );

        setState(() {
          _deviceNameController.clear();
          _isLoading = false;
          _operationMessage = '可切换设备创建成功: ${deviceRef.id}';
        });
      } else if (_deviceType == 'airconditioner') {
        // 创建空调设备
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception('用户未登录');

        final docRef =
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('devices')
                .doc();

        final airConditioner = AirConditionerModel(
          docRef.id,
          name: _deviceNameController.text,
          roomId: _selectedRoomId!,
          lastUpdated: Timestamp.now(),
          temperature: 25.0,
          mode: 'Auto',
          fanSpeed: 'Mid',
          status: false,
        );

        await airConditioner.createData();

        setState(() {
          _deviceNameController.clear();
          _isLoading = false;
          _operationMessage = '空调设备创建成功: ${airConditioner.name}';
        });

        // 打开控制页面
        if (mounted) {
          _openAirConditionerControl(airConditioner);
        }
      }
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

  // 更新可切换设备状态
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

  // 打开空调控制页面
  void _openAirConditionerControl(AirConditionerModel airConditioner) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AirConditionerControl(
              airConditioner: airConditioner,
              onUpdate: () {
                setState(() {
                  _operationMessage = '空调设备已更新: ${airConditioner.name}';
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设备管理中心'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '房间选择'),
            Tab(text: '可切换设备'),
            Tab(text: '空调设备'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // 房间选择页面
                  _buildRoomSelectionTab(),

                  // 可切换设备页面
                  _buildSwitchableDevicesTab(),

                  // 空调设备页面
                  _buildAirConditionerTab(),
                ],
              ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _operationMessage,
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 房间选择标签页
  Widget _buildRoomSelectionTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择或创建房间',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 房间创建区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '创建新房间',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _roomNameController,
                          decoration: const InputDecoration(
                            labelText: '房间名称',
                            border: OutlineInputBorder(),
                            hintText: '输入房间名称',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _createRoom,
                        icon: const Icon(Icons.add),
                        label: const Text('创建'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 房间列表区域
          const Text(
            '现有房间',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 现有房间列表
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchData.getRooms(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('错误: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data?.docs ?? [];

                if (rooms.isEmpty) {
                  return const Center(child: Text('还没有创建任何房间，请先创建房间'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final roomId = room.id;
                    final isSelected = roomId == _selectedRoomId;

                    return GestureDetector(
                      onTap: () => _loadDevicesInRoom(roomId),
                      child: Card(
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.blue.shade50 : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? Colors.blue
                                    : Colors.grey.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.meeting_room,
                                    size: 40,
                                    color:
                                        isSelected
                                            ? Colors.blue
                                            : Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    roomId,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSelected
                                              ? Colors.blue[800]
                                              : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
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
    );
  }

  // 可切换设备标签页
  Widget _buildSwitchableDevicesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 设备创建区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '创建可切换设备',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedRoomId != null
                        ? '在房间"$_selectedRoomId"中创建设备'
                        : '请先在房间选择标签页中选择房间',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                            hintText: '输入设备名称',
                          ),
                          enabled: _selectedRoomId != null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed:
                            _selectedRoomId != null
                                ? () => _showDeviceTypeSelectionDialog()
                                : null,
                        icon: const Icon(Icons.add),
                        label: const Text('创建'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 设备列表区域
          Expanded(
            child:
                _selectedRoomId == null
                    ? const Center(child: Text('请先在房间选择标签页中选择房间'))
                    : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '房间"$_selectedRoomId"中的可切换设备',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                  final switchableDevices =
                                      devices.where((doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        return data['type'] == 'switch';
                                      }).toList();

                                  if (switchableDevices.isEmpty) {
                                    return const Center(
                                      child: Text('该房间还没有可切换设备'),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: switchableDevices.length,
                                    itemBuilder: (context, index) {
                                      final device = switchableDevices[index];
                                      final data =
                                          device.data() as Map<String, dynamic>;
                                      final deviceId = device.id;
                                      final deviceName = data['name'] as String;
                                      final status =
                                          data['status'] as bool? ?? false;

                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
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
                                            '最后更新: ${(data['lastUpdate'] as Timestamp?)?.toDate().toString().substring(0, 19) ?? '未知'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                status ? '开' : '关',
                                                style: TextStyle(
                                                  color:
                                                      status
                                                          ? Colors.green
                                                          : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Switch(
                                                value: status,
                                                onChanged:
                                                    (_) => _toggleDeviceStatus(
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
                                                    () =>
                                                        _deleteDevice(deviceId),
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
        ],
      ),
    );
  }

  // 空调设备标签页
  Widget _buildAirConditionerTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 设备创建区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '创建空调设备',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedRoomId != null
                        ? '在房间"$_selectedRoomId"中创建空调'
                        : '请先在房间选择标签页中选择房间',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _deviceNameController,
                          decoration: const InputDecoration(
                            labelText: '空调设备名称',
                            border: OutlineInputBorder(),
                            hintText: '输入空调名称',
                          ),
                          enabled: _selectedRoomId != null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed:
                            _selectedRoomId != null
                                ? () => _showDeviceTypeSelectionDialog()
                                : null,
                        icon: const Icon(Icons.add),
                        label: const Text('创建'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 空调设备列表区域
          Expanded(
            child:
                _selectedRoomId == null
                    ? const Center(child: Text('请先在房间选择标签页中选择房间'))
                    : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '房间"$_selectedRoomId"中的空调设备',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                  final acDevices = <AirConditionerModel>[];

                                  // 筛选出空调设备
                                  for (var device in devices) {
                                    final data =
                                        device.data() as Map<String, dynamic>;
                                    if (data['type'] == '冷气') {
                                      try {
                                        final acDevice = AirConditionerModel(
                                          device.id,
                                          name: data['name'],
                                          roomId: _selectedRoomId!,
                                          lastUpdated: data['lastUpdated'],
                                        );
                                        acDevice.fromJson(data);
                                        acDevices.add(acDevice);
                                      } catch (e) {
                                        print('加载设备错误: $e');
                                      }
                                    }
                                  }

                                  if (acDevices.isEmpty) {
                                    return const Center(
                                      child: Text('该房间还没有空调设备'),
                                    );
                                  }

                                  return GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 1.0,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                        ),
                                    itemCount: acDevices.length,
                                    itemBuilder: (context, index) {
                                      final device = acDevices[index];
                                      return GestureDetector(
                                        onTap:
                                            () => _openAirConditionerControl(
                                              device,
                                            ),
                                        child: Card(
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.ac_unit,
                                                  size: 36,
                                                  color:
                                                      device.status
                                                          ? Colors.blue
                                                          : Colors.grey,
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  device.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${device.temperature.toInt()}°C',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        device.status
                                                            ? Colors.blue[700]
                                                            : Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            device.status
                                                                ? Colors
                                                                    .green[100]
                                                                : Colors
                                                                    .red[100],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        device.status
                                                            ? '开启'
                                                            : '关闭',
                                                        style: TextStyle(
                                                          color:
                                                              device.status
                                                                  ? Colors
                                                                      .green[800]
                                                                  : Colors
                                                                      .red[800],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue[50],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        device.mode,
                                                        style: TextStyle(
                                                          color:
                                                              Colors.blue[800],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => _deleteDevice(
                                                        device.id,
                                                      ),
                                                  tooltip: '删除空调',
                                                ),
                                              ],
                                            ),
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
        ],
      ),
    );
  }
}
