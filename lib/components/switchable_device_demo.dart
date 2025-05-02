import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/switchable_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SwitchableDeviceDemo extends StatefulWidget {
  const SwitchableDeviceDemo({Key? key}) : super(key: key);

  @override
  State<SwitchableDeviceDemo> createState() => _SwitchableDeviceDemoState();
}

class _SwitchableDeviceDemoState extends State<SwitchableDeviceDemo> {
  final TextEditingController _deviceNameController = TextEditingController();
  final List<SwitchableModel> _devices = [];
  bool _isLoading = false;
  String _operationMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  // 加载已有设备
  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _operationMessage = '加载设备中...';
    });

    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('devices')
                .where('type', isEqualTo: 'switch')
                .get();

        final devices =
            snapshot.docs.map((doc) {
              return SwitchableModel(
                doc.id,
                name: doc['name'],
                type: doc['type'],
                lastUpdated: doc['lastUpdated'],
                icon: Icons.toggle_on,
                updateValue: doc['updateValue'],
                previousValue: doc['previousValue'],
                status: doc['status'],
              );
            }).toList();

        setState(() {
          _devices.clear();
          _devices.addAll(devices);
          _isLoading = false;
          _operationMessage = '已加载 ${devices.length} 个设备';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _operationMessage = '加载设备错误: $e';
      });
    }
  }

  // 创建新设备
  Future<void> _createDevice() async {
    if (_deviceNameController.text.isEmpty) {
      setState(() {
        _operationMessage = '请输入设备名称';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _operationMessage = '创建设备中...';
    });

    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // 使用Firebase自动生成的文档ID
        final docRef =
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('devices')
                .doc();

        final deviceId = docRef.id;

        final device = SwitchableModel(
          deviceId,
          name: _deviceNameController.text,
          type: 'switch',
          lastUpdated: Timestamp.now(),
          icon: Icons.toggle_on,
          updateValue: [true, false],
          previousValue: [false, true],
          status: false,
        );

        await device.createData();

        setState(() {
          _devices.add(device);
          _deviceNameController.clear();
          _isLoading = false;
          _operationMessage = '设备创建成功: ${device.name}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _operationMessage = '创建设备错误: $e';
      });
    }
  }

  // 更新设备状态
  Future<void> _toggleDeviceStatus(SwitchableModel device) async {
    try {
      // 先更新UI状态，提供即时反馈
      setState(() {
        device.status = !device.status;
      });

      // 更新Firebase中的数据
      device.lastUpdated = Timestamp.now();
      await device.updateData();

      setState(() {
        _operationMessage = '设备状态已更新: ${device.status ? "开启" : "关闭"}';
      });
    } catch (e) {
      // 如果更新失败，恢复原状态
      setState(() {
        device.status = !device.status;
        _operationMessage = '更新设备状态失败: $e';
      });
    }
  }

  // 删除设备
  Future<void> _deleteDevice(SwitchableModel device) async {
    try {
      await device.deleteData();

      setState(() {
        _devices.remove(device);
        _operationMessage = '设备已删除: ${device.name}';
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
      appBar: AppBar(title: Text(localizations?.deviceName ?? '可切换设备示例')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 创建设备表单
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '创建新的可切换设备',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _deviceNameController,
                              decoration: const InputDecoration(
                                labelText: '设备名称',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _createDevice,
                              icon: const Icon(Icons.add),
                              label: const Text('创建设备'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 设备列表
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '设备列表',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _loadDevices,
                                    tooltip: '刷新设备列表',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child:
                                    _devices.isEmpty
                                        ? const Center(child: Text('还没有创建任何设备'))
                                        : ListView.builder(
                                          itemCount: _devices.length,
                                          itemBuilder: (context, index) {
                                            final device = _devices[index];
                                            return SwitchableDeviceCard(
                                              device: device,
                                              onToggle:
                                                  () => _toggleDeviceStatus(
                                                    device,
                                                  ),
                                              onDelete:
                                                  () => _deleteDevice(device),
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

class SwitchableDeviceCard extends StatelessWidget {
  final SwitchableModel device;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const SwitchableDeviceCard({
    Key? key,
    required this.device,
    required this.onToggle,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          device.icon,
          color: device.status ? Colors.blue : Colors.grey,
          size: 30,
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '最后更新: ${device.lastUpdated.toDate().toString().substring(0, 19)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: device.status,
              onChanged: (_) => onToggle(),
              activeColor: Colors.blue,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: '删除设备',
            ),
          ],
        ),
      ),
    );
  }
}
