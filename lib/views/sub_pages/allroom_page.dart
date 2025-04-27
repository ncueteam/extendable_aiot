import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:extendable_aiot/models/device_data.dart';
import 'package:extendable_aiot/services/add_data.dart';
import 'package:extendable_aiot/services/fetch_data.dart';
import 'package:extendable_aiot/views/card/room_card.dart';
import 'package:flutter/material.dart';

class AllRoomPage extends StatefulWidget {
  const AllRoomPage({super.key});

  @override
  State<AllRoomPage> createState() => _AllRoomPageState();
}

class _AllRoomPageState extends State<AllRoomPage> {
  final AddData _addData = AddData();
  final FetchData _fetchData = FetchData();
  final TextEditingController _roomNameController = TextEditingController();

  Future<void> _showAddRoomDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('新增房間'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(labelText: '房間名稱'),
                ),
                const SizedBox(height: 16),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  if (_roomNameController.text.isNotEmpty) {
                    await _addData.addRoom(roomId: _roomNameController.text);
                    _roomNameController.clear();
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
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _fetchData.getAllDevices(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('錯誤: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data ?? [];

          if (devices.isEmpty) {
            return const Center(child: Text('還沒有創建設備'));
          }
          return EasyRefresh(
            header: const ClassicHeader(),
            footer: const ClassicFooter(),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                //crossAxisSpacing: 12,
                //mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: devices.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    RoomCard(
                      roomItem: DeviceData.fromJson(
                        devices[index].id,
                        devices[index].data() as Map<String, dynamic>,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
