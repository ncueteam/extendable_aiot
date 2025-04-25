import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/services/user_service.dart';
import 'package:flutter/material.dart';

class RoomsPage extends StatelessWidget {
  final UserService _userService = UserService();

  RoomsPage({super.key});

  Future<void> _addTestRoom(BuildContext context) async {
    try {
      final roomRef = await _userService.addRoom(name: "測試房間", type: "test");

      await _userService.addDevice(
        name: "測試燈泡",
        type: "light",
        roomId: roomRef.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('測試房間和設備已創建')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('錯誤: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => _addTestRoom(context),
                  child: const Text('創建測試房間'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _userService.updateLastLogin(),
                  child: const Text('更新登入時間'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _userService.getRooms(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('錯誤: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index].data() as Map<String, dynamic>;
                    final roomId = rooms[index].id;

                    return ExpansionTile(
                      title: Text(room['name']),
                      subtitle: Text('類型: ${room['type']}'),
                      children: [
                        StreamBuilder<List<DocumentSnapshot>>(
                          stream: _userService.getRoomDevices(roomId),
                          builder: (context, deviceSnapshot) {
                            if (deviceSnapshot.hasError) {
                              return Text('錯誤: ${deviceSnapshot.error}');
                            }

                            if (deviceSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            final devices = deviceSnapshot.data ?? [];

                            return Column(
                              children:
                                  devices.map((device) {
                                    final deviceData =
                                        device.data() as Map<String, dynamic>;
                                    return ListTile(
                                      title: Text(deviceData['name']),
                                      subtitle: Text(deviceData['type']),
                                      trailing: Switch(
                                        value: deviceData['status'] ?? false,
                                        onChanged: (value) {
                                          _userService.updateDeviceStatus(
                                            deviceId: device.id,
                                            status: value,
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        ),
                      ],
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
}
