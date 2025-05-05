import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/components/airconditioner_control.dart';
import 'package:extendable_aiot/models/sub_type/airconditioner_model.dart';
import 'package:extendable_aiot/models/sub_type/dht11_sensor_model.dart';
import 'package:extendable_aiot/models/abstract/room_model.dart';
import 'package:extendable_aiot/models/sub_type/switch_model.dart';
import 'package:extendable_aiot/models/abstract/switchable_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IntegratedDevicesPage extends StatefulWidget {
  const IntegratedDevicesPage({super.key});

  @override
  State<IntegratedDevicesPage> createState() => _IntegratedDevicesPageState();
}

class _IntegratedDevicesPageState extends State<IntegratedDevicesPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();

  late TabController _tabController;
  String? _selectedRoomId;
  String? _selectedRoomName;
  bool _isLoading = false;
  String _operationMessage = '';
  String _deviceType = 'switch';

  final List<Map<String, dynamic>> _deviceTypes = [
    {'type': 'switch', 'name': '可切換設備', 'icon': Icons.toggle_on},
    {'type': 'air_conditioner', 'name': '空調設備', 'icon': Icons.ac_unit},
    {'type': 'dht11', 'name': 'DHT11溫濕度傳感器', 'icon': Icons.thermostat},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
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

  Future<void> _createRoom() async {
    if (_roomNameController.text.isEmpty) {
      setState(() {
        _operationMessage = '請輸入房間名稱';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _operationMessage = '創建房間中...';
    });

    try {
      RoomModel roomModel = RoomModel(name: _roomNameController.text);
      roomModel.createdAt = Timestamp.now();
      roomModel.createRoom();
      setState(() {
        _selectedRoomId = roomModel.id;
        _roomNameController.clear();
        _operationMessage = '房間創建成功: $_selectedRoomId';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _operationMessage = '房間創建錯誤: $e';
      });
    }
  }

  Future<void> _showDeviceTypeSelectionDialog() async {
    if (_selectedRoomId == null) {
      setState(() {
        _operationMessage = '請先選擇或創建一個房間';
      });
      return;
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('創建新設備'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('請選擇要創建的設備類型:'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _deviceType,
                        decoration: const InputDecoration(
                          labelText: '設備類型',
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

                      // 設備名稱輸入
                      TextField(
                        controller: _deviceNameController,
                        decoration: const InputDecoration(
                          labelText: '設備名稱',
                          border: OutlineInputBorder(),
                          hintText: '輸入設備名稱',
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
                      _operationMessage = '請輸入設備名稱';
                    });
                    return;
                  }

                  Navigator.pop(context);
                  _createDeviceInRoom();
                },
                child: const Text('創建'),
              ),
            ],
          ),
    );
  }

  Future<void> _createDeviceInRoom() async {
    if (_deviceNameController.text.isEmpty) {
      setState(() {
        _operationMessage = '請輸入設備名稱';
      });
      return;
    }

    if (_selectedRoomId == null) {
      setState(() {
        _operationMessage = '請先選擇或創建一個房間';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _operationMessage = '創建設備中...';
    });

    try {
      RoomModel roomModel = await RoomModel.getRoom(_selectedRoomId!);
      switch (_deviceType) {
        case 'switch':
          {
            SwitchableModel device = SwitchModel(
              null,
              name: _deviceNameController.text,
              type: 'switch',
              lastUpdated: Timestamp.now(),
              icon: Icons.toggle_on,
              updateValue: [false],
              previousValue: [false],
              status: false,
            );
            device.createData();
            roomModel.addDevice(device.id);
            setState(() {
              _deviceNameController.clear();
              _isLoading = false;
              _operationMessage = '單開關設備創建成功: ${device.name}';
            });
            break;
          }
        case 'air_conditioner':
          {
            final AirConditionerModel device = AirConditionerModel(
              null,
              name: _deviceNameController.text,
              roomId: _selectedRoomId!,
              lastUpdated: Timestamp.now(),
              temperature: 25.0,
              mode: 'Auto',
              fanSpeed: 'Mid',
            );
            device.createData();
            roomModel.addDevice(device.id);
            setState(() {
              _deviceNameController.clear();
              _isLoading = false;
              _operationMessage = '空調設備創建成功: ${device.name}';
            });
          }
        case 'dht11':
          {
            DHT11SensorModel dht11Sensor = DHT11SensorModel(
              null,
              name: _deviceNameController.text,
              roomId: _selectedRoomId!,
              lastUpdated: Timestamp.now(),
              temperature: 0.0,
              humidity: 0.0,
            );
            dht11Sensor.createData();
            roomModel.addDevice(dht11Sensor.id);
            setState(() {
              _deviceNameController.clear();
              _isLoading = false;
              _operationMessage = 'DHT11溫溼度計創建成功: ${dht11Sensor.name}';
            });
          }
        default:
          throw Exception('未知設備類型: $_deviceType');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _operationMessage = '設備創建錯誤: $e';
      });
    }
  }

  Future<void> _loadDevicesInRoom(String roomId) async {
    setState(() {
      _isLoading = true;
      _operationMessage = '載入房間設備...';
    });

    try {
      RoomModel roomModel = await RoomModel.getRoom(roomId);

      setState(() {
        _selectedRoomId = roomId;
        _selectedRoomName = roomModel.name;
        _isLoading = false;
        _operationMessage = '已選擇房間: ${roomModel.name}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _operationMessage = '載入房間設備錯誤: $e';
      });
    }
  }

  Future<void> _toggleDeviceStatus(String deviceId, bool currentStatus) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('devices')
              .doc(deviceId)
              .get();

      if (!docSnapshot.exists) {
        setState(() {
          _operationMessage = '設備不存在';
        });
        return;
      }

      final data = docSnapshot.data()!;
      final SwitchModel device = SwitchModel(
        deviceId,
        name: data['name'],
        type: data['type'],
        lastUpdated: data['lastUpdated'],
        icon: IconData(data['icon'] ?? 0xe037, fontFamily: 'MaterialIcons'),
        updateValue: data['updateValue'] ?? [false],
        previousValue: data['previousValue'] ?? [false],
        status: data['status'] ?? false,
      );

      // 切換狀態
      device.status = !currentStatus;

      // 更新設備
      await device.updateData();

      setState(() {
        _operationMessage = '設備狀態已更新';
      });
    } catch (e) {
      setState(() {
        _operationMessage = '更新設備狀態失敗: $e';
      });
    }
  }

  Future<void> _deleteDevice(String deviceId) async {
    if (_selectedRoomId == null) return;

    try {
      RoomModel roomModel = await RoomModel.getRoom(_selectedRoomId!);
      await roomModel.removeDevice(deviceId);
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .delete();

      setState(() {
        _operationMessage = '設備已刪除';
      });
    } catch (e) {
      setState(() {
        _operationMessage = '刪除設備失敗: $e';
      });
    }
  }

  void _openAirConditionerControl(AirConditionerModel airConditioner) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AirConditionerControl(
              airConditioner: airConditioner,
              onUpdate: () {
                setState(() {
                  _operationMessage = '空調設備已更新: ${airConditioner.name}';
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedRoomName ?? '設備管理中心'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '房間選擇'),
            Tab(text: '可切換設備'),
            Tab(text: '空調設備'),
            Tab(text: 'DHT11傳感器'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // 房間選擇页面
                  _buildRoomSelectionTab(),

                  // 可切換設備页面
                  _buildSwitchableDevicesTab(),

                  // 空調設備页面
                  _buildAirConditionerTab(),

                  // DHT11傳感器页面
                  _buildDHT11SensorTab(),
                ],
              ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(75),
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
                  color: Colors.grey.withAlpha(75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_operationMessage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSelectionTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '選擇或創建房間',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '創建新房間',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _roomNameController,
                          decoration: const InputDecoration(
                            labelText: '房間名稱',
                            border: OutlineInputBorder(),
                            hintText: '輸入房間名稱',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _createRoom,
                        icon: const Icon(Icons.add),
                        label: const Text('創建'),
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

          const Text(
            '現有房間',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<List<RoomModel>>(
              stream: RoomModel.getAllRooms(),
              builder: (context, rooms) {
                if (rooms.hasError) {
                  return Center(child: Text('錯誤: ${rooms.error}'));
                }

                if (rooms.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (rooms.data == null || rooms.data!.isEmpty) {
                  return const Center(child: Text('請先創建房間'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: rooms.data!.length,
                  itemBuilder: (context, index) {
                    final room = rooms.data![index];
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
                                    room.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSelected
                                              ? Colors.blue[800]
                                              : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
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

  Widget _buildSwitchableDevicesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '創建可切換設備',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedRoomName != null
                        ? '在房間"$_selectedRoomName"中創建設備'
                        : '請先在房間選擇標籤頁中選擇房間',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _deviceNameController,
                          decoration: const InputDecoration(
                            labelText: '設備名稱',
                            border: OutlineInputBorder(),
                            hintText: '輸入設備名稱',
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
                        label: const Text('創建'),
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

          // 設備列表區域
          Expanded(
            child:
                _selectedRoomId == null
                    ? const Center(child: Text('請先在房間選擇標籤頁中選擇房間'))
                    : FutureBuilder<RoomModel>(
                      future: RoomModel.getRoom(_selectedRoomId!),
                      builder: (context, roomSnapshot) {
                        if (roomSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (roomSnapshot.hasError || !roomSnapshot.hasData) {
                          return Center(
                            child: Text(
                              '載入房間錯誤: ${roomSnapshot.error ?? "未知錯誤"}',
                            ),
                          );
                        }

                        final roomModel = roomSnapshot.data!;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '房間"${roomModel.name}"中的可切換設備',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: StreamBuilder<List<DocumentSnapshot>>(
                                    stream: roomModel.devicesStream(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text('錯誤: ${snapshot.error}'),
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
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            return data['type'] == 'switch';
                                          }).toList();
                                      if (switchableDevices.isEmpty) {
                                        return const Center(
                                          child: Text('該房間還沒有可切換設備'),
                                        );
                                      }
                                      return ListView.builder(
                                        itemCount: switchableDevices.length,
                                        itemBuilder: (context, index) {
                                          final device =
                                              switchableDevices[index];
                                          final data =
                                              device.data()
                                                  as Map<String, dynamic>;
                                          final deviceId = device.id;
                                          final deviceName =
                                              data['name'] as String;
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
                                                '最後更新: ${(data['lastUpdated'] as Timestamp?)?.toDate().toString().substring(0, 19) ?? '未知'}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    status ? '開' : '關',
                                                    style: TextStyle(
                                                      color:
                                                          status
                                                              ? Colors.green
                                                              : Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
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
                                                    tooltip: '刪除設備',
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
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirConditionerTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '創建空調設備',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedRoomName != null
                        ? '在房間"$_selectedRoomName"中創建空調'
                        : '請先在房間選擇標籤頁中選擇房間',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _deviceNameController,
                          decoration: const InputDecoration(
                            labelText: '空調設備名稱',
                            border: OutlineInputBorder(),
                            hintText: '輸入空調名稱',
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
                        label: const Text('創建'),
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

          Expanded(
            child:
                _selectedRoomId == null
                    ? const Center(child: Text('請先在房間選擇標籤頁中選擇房間'))
                    : FutureBuilder<RoomModel>(
                      future: RoomModel.getRoom(_selectedRoomId!),
                      builder: (context, roomSnapshot) {
                        if (roomSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (roomSnapshot.hasError || !roomSnapshot.hasData) {
                          return Center(
                            child: Text(
                              '載入房間錯誤: ${roomSnapshot.error ?? "未知錯誤"}',
                            ),
                          );
                        }

                        final roomModel = roomSnapshot.data!;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '房間"${roomModel.name}"中的空調設備',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: StreamBuilder<List<DocumentSnapshot>>(
                                    stream: roomModel.devicesStream(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text('錯誤: ${snapshot.error}'),
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
                                      // 篩選出空調設備
                                      for (var device in devices) {
                                        final data =
                                            device.data()
                                                as Map<String, dynamic>;
                                        if (data['type'] == 'air_conditioner') {
                                          try {
                                            final acDevice =
                                                AirConditionerModel(
                                                  device.id,
                                                  name: data['name'],
                                                  roomId: _selectedRoomId!,
                                                  lastUpdated:
                                                      data['lastUpdated'],
                                                  temperature:
                                                      data['temperature'] ??
                                                      25.0,
                                                  mode: data['mode'] ?? 'Auto',
                                                  fanSpeed:
                                                      data['fanSpeed'] ?? 'Mid',
                                                );
                                            acDevices.add(acDevice);
                                          } catch (e) {
                                            print('載入設備錯誤: $e');
                                          }
                                        }
                                      }
                                      if (acDevices.isEmpty) {
                                        return const Center(
                                          child: Text('該房間還沒有空調設備'),
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
                                                () =>
                                                    _openAirConditionerControl(
                                                      device,
                                                    ),
                                            child: Card(
                                              elevation: 3,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
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
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            device.status
                                                                ? Colors
                                                                    .blue[700]
                                                                : Colors
                                                                    .grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
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
                                                                ? '開啟'
                                                                : '關閉',
                                                            style: TextStyle(
                                                              color:
                                                                  device.status
                                                                      ? Colors
                                                                          .green[800]
                                                                      : Colors
                                                                          .red[800],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 3,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors.blue[50],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            device.mode,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .blue[800],
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
                                                      tooltip: '刪除空調',
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
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDHT11SensorTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 傳感器創建區域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '創建DHT11傳感器',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedRoomName != null
                        ? '在房間"$_selectedRoomName"中創建傳感器'
                        : '請先在房間選擇標籤頁中選擇房間',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _deviceNameController,
                          decoration: const InputDecoration(
                            labelText: '傳感器名稱',
                            border: OutlineInputBorder(),
                            hintText: '輸入傳感器名稱',
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
                        label: const Text('創建'),
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

          // 傳感器列表區域
          Expanded(
            child:
                _selectedRoomId == null
                    ? const Center(child: Text('請先在房間選擇標籤頁中選擇房間'))
                    : FutureBuilder<RoomModel>(
                      future: RoomModel.getRoom(_selectedRoomId!),
                      builder: (context, roomSnapshot) {
                        if (roomSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (roomSnapshot.hasError || !roomSnapshot.hasData) {
                          return Center(
                            child: Text(
                              '載入房間錯誤: ${roomSnapshot.error ?? "未知錯誤"}',
                            ),
                          );
                        }

                        final roomModel = roomSnapshot.data!;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '房間"${roomModel.name}"中的DHT11傳感器',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: StreamBuilder<List<DocumentSnapshot>>(
                                    stream: roomModel.devicesStream(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text('錯誤: ${snapshot.error}'),
                                        );
                                      }

                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final devices = snapshot.data ?? [];
                                      final dht11Devices = <DHT11SensorModel>[];

                                      // 篩選出DHT11傳感器設備
                                      for (var device in devices) {
                                        final data =
                                            device.data()
                                                as Map<String, dynamic>;
                                        if (data['type'] == 'dht11') {
                                          try {
                                            final dht11Device =
                                                DHT11SensorModel(
                                                  device.id,
                                                  name: data['name'],
                                                  roomId: _selectedRoomId!,
                                                  lastUpdated:
                                                      data['lastUpdated'],
                                                  temperature:
                                                      data['temperature'] ??
                                                      0.0,
                                                  humidity:
                                                      data['humidity'] ?? 0.0,
                                                );
                                            dht11Devices.add(dht11Device);
                                          } catch (e) {
                                            print('載入設備錯誤: $e');
                                          }
                                        }
                                      }

                                      if (dht11Devices.isEmpty) {
                                        return const Center(
                                          child: Text('該房間還沒有DHT11傳感器設備'),
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
                                        itemCount: dht11Devices.length,
                                        itemBuilder: (context, index) {
                                          final device = dht11Devices[index];
                                          return Card(
                                            elevation: 3,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.thermostat,
                                                    size: 36,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    device.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '溫度: ${device.temperature.toInt()}°C',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '濕度: ${device.humidity.toInt()}%',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
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
                                                    tooltip: '刪除傳感器',
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
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
