import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:extendable_aiot/services/user_service.dart';

class TestRoomPage extends StatefulWidget {
  final String roomId;
  const TestRoomPage({super.key, required this.roomId});

  @override
  State<TestRoomPage> createState() => _TestRoomPageState();
}

class _TestRoomPageState extends State<TestRoomPage> {
  final UserService _userService = UserService();
  final TextEditingController _deviceNameController = TextEditingController();
  final List<String> _deviceTypes = ['light', 'fan', 'sensor', 'switch'];
  String _selectedDeviceType = 'light';

  Future<void> _showAddDeviceDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('新增設備'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _deviceNameController,
                  decoration: const InputDecoration(labelText: '設備名稱'),
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: _selectedDeviceType,
                  items:
                      _deviceTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
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
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  if (_deviceNameController.text.isNotEmpty) {
                    await _userService.addDevice(
                      name: _deviceNameController.text,
                      type: _selectedDeviceType,
                      roomId: widget.roomId,
                    );
                    _deviceNameController.clear();
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('確認'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _userService.getRoomById(widget.roomId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              final roomData = snapshot.data!.data() as Map<String, dynamic>;
              return Text(roomData['name'] ?? '未命名房間');
            }
            return const Text('載入中...');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeviceDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _userService.getRoomDevices(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('錯誤: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data ?? [];

          if (devices.isEmpty) {
            return const Center(child: Text('此房間還沒有設備'));
          }

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final deviceData = devices[index].data() as Map<String, dynamic>;
              final deviceId = devices[index].id;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(_getDeviceIcon(deviceData['type'])),
                  title: Text(deviceData['name']),
                  subtitle: Text('類型: ${deviceData['type']}'),
                  trailing: Switch(
                    value: deviceData['status'] ?? false,
                    onChanged: (value) {
                      _userService.updateDeviceStatus(
                        deviceId: deviceId,
                        status: value,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'light':
        return Icons.lightbulb;
      case 'fan':
        return Icons.wind_power;
      case 'sensor':
        return Icons.sensors;
      case 'switch':
        return Icons.toggle_on;
      default:
        return Icons.device_unknown;
    }
  }
}
