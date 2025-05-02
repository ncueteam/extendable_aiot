import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/switch_model.dart';
import 'package:extendable_aiot/views/demo_pages/integrated_devices_page.dart';
import 'package:flutter/material.dart';
import 'package:extendable_aiot/models/switchable_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();
  String _operationResult = '';
  bool _isLoading = false;
  SwitchableModel? _currentDevice;
  final List<SwitchableModel> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  // 載入所有裝置
  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _operationResult = '讀取裝置中...';
    });

    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('devices')
                .get();

        _devices.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final device = SwitchModel(
            doc.id,
            name: data['name'],
            type: data['type'],
            lastUpdated: data['lastUpdated'],
            icon: IconData(data['icon'], fontFamily: 'MaterialIcons'),
            updateValue: data['updateValue'],
            previousValue: data['previousValue'],
            status: data['status'],
          );
          _devices.add(device);
        }

        setState(() {
          _operationResult = '已載入 ${_devices.length} 個裝置';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _operationResult = '載入裝置錯誤: $e';
        _isLoading = false;
      });
    }
  }

  // 創建裝置
  Future<void> _createDevice() async {
    if (_deviceNameController.text.isEmpty) {
      setState(() {
        _operationResult = '請輸入裝置名稱';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _operationResult = '創建裝置中...';
    });

    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // 使用Firebase自動生成的文檔ID
        final docRef =
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('devices')
                .doc(); // 自動生成ID

        final deviceId = docRef.id; // 獲取生成的ID

        final device = SwitchModel(
          deviceId,
          name: _deviceNameController.text,
          type: 'switch',
          lastUpdated: Timestamp.now(),
          icon: Icons.lightbulb_outline,
          updateValue: [true, false],
          previousValue: [false, true],
          status: false,
        );

        // 使用set方法存入文檔
        await docRef.set(device.toJson());

        setState(() {
          _currentDevice = device;
          _deviceIdController.text = deviceId; // 顯示自動生成的ID
          _operationResult = '裝置創建成功: ${device.id}';
          _isLoading = false;
        });

        // Refresh the device list
        _loadDevices();
      }
    } catch (e) {
      setState(() {
        _operationResult = '創建裝置錯誤: $e';
        _isLoading = false;
      });
    }
  }

  // 讀取裝置
  Future<void> _readDevice(String deviceId) async {
    setState(() {
      _isLoading = true;
      _operationResult = '讀取裝置中...';
    });

    try {
      final device = SwitchModel(
        deviceId,
        name: '',
        type: '',
        lastUpdated: Timestamp.now(),
        icon: Icons.device_unknown,
        updateValue: [],
        previousValue: [],
        status: false,
      );

      await device.readData();

      setState(() {
        _currentDevice = device;
        _deviceNameController.text = device.name;
        _deviceIdController.text = device.id;
        _operationResult = '裝置讀取成功: ${device.name}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _operationResult = '讀取裝置錯誤: $e';
        _isLoading = false;
      });
    }
  }

  // 更新裝置
  Future<void> _updateDevice() async {
    if (_currentDevice == null) {
      setState(() {
        _operationResult = '請先創建或讀取一個裝置';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _operationResult = '更新裝置中...';
    });

    try {
      _currentDevice!.name = _deviceNameController.text;
      _currentDevice!.status = !_currentDevice!.status; // 切換狀態
      _currentDevice!.lastUpdated = Timestamp.now();

      await _currentDevice!.updateData();

      setState(() {
        _operationResult =
            '裝置更新成功: ${_currentDevice!.name}, 狀態: ${_currentDevice!.status ? '開啟' : '關閉'}';
        _isLoading = false;
      });

      // Refresh the device list
      _loadDevices();
    } catch (e) {
      setState(() {
        _operationResult = '更新裝置錯誤: $e';
        _isLoading = false;
      });
    }
  }

  // 刪除裝置
  Future<void> _deleteDevice() async {
    if (_currentDevice == null) {
      setState(() {
        _operationResult = '請先創建或讀取一個裝置';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _operationResult = '刪除裝置中...';
    });

    try {
      final deviceName = _currentDevice!.name;
      await _currentDevice!.deleteData();

      setState(() {
        _operationResult = '裝置刪除成功: $deviceName';
        _currentDevice = null;
        _deviceNameController.text = '';
        _deviceIdController.text = '';
        _isLoading = false;
      });

      // Refresh the device list
      _loadDevices();
    } catch (e) {
      setState(() {
        _operationResult = '刪除裝置錯誤: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase CRUD 測試')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const IntegratedDevicesPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '整合设备管理页面 (空调+开关)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '单独的示例页面:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '裝置資訊',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _deviceNameController,
                                decoration: const InputDecoration(
                                  labelText: '裝置名稱',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _deviceIdController,
                                decoration: const InputDecoration(
                                  labelText: '裝置 ID',
                                  border: OutlineInputBorder(),
                                  hintText: '用於讀取、更新、刪除已存在的裝置',
                                ),
                                readOnly: true, // 唯讀，防止修改自動生成的ID
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CRUD 按鈕
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CRUD 操作',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _createDevice,
                                    icon: const Icon(Icons.add),
                                    label: const Text('創建 (Create)'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (_deviceIdController.text.isNotEmpty) {
                                        _readDevice(_deviceIdController.text);
                                      } else {
                                        setState(() {
                                          _operationResult =
                                              '請先創建裝置或從裝置列表選擇一個裝置';
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.search),
                                    label: const Text('讀取 (Read)'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _updateDevice,
                                    icon: const Icon(Icons.update),
                                    label: const Text('更新 (Update)'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _deleteDevice,
                                    icon: const Icon(Icons.delete),
                                    label: const Text('刪除 (Delete)'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _loadDevices,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('刷新裝置列表'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 操作結果
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '操作結果',
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
                                child: Text(_operationResult),
                              ),
                              const SizedBox(height: 16),
                              if (_currentDevice != null) ...[
                                const Text(
                                  '當前裝置狀態',
                                  style: TextStyle(
                                    fontSize: 16,
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('ID: ${_currentDevice!.id}'),
                                      Text('名稱: ${_currentDevice!.name}'),
                                      Text('類型: ${_currentDevice!.type}'),
                                      Text(
                                        '狀態: ${_currentDevice!.status ? '開啟' : '關閉'}',
                                      ),
                                      Text(
                                        '最後更新: ${_currentDevice!.lastUpdated.toDate()}',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 裝置列表
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '裝置列表',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _devices.isEmpty
                                  ? const Center(child: Text('尚無裝置'))
                                  : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _devices.length,
                                    itemBuilder: (context, index) {
                                      final device = _devices[index];
                                      return ListTile(
                                        leading: Icon(device.icon),
                                        title: Text(device.name),
                                        subtitle: Text('ID: ${device.id}'),
                                        trailing: Text(
                                          device.status ? '開啟' : '關閉',
                                          style: TextStyle(
                                            color:
                                                device.status
                                                    ? Colors.green
                                                    : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onTap: () {
                                          _deviceIdController.text = device.id;
                                          _readDevice(device.id);
                                        },
                                      );
                                    },
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
