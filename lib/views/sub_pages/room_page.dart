import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/services/add_data.dart';
import 'package:extendable_aiot/services/fetch_data.dart';
import 'package:extendable_aiot/themes/app_colors.dart';
import 'package:extendable_aiot/views/card/room_card.dart';
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
  final AddData _addData = AddData();
  final FetchData _fetchData = FetchData();
  final TextEditingController _deviceNameController = TextEditingController();
  final List<String> _deviceTypes = ['中央空調', '風扇', '燈光'];
  String _selectedDeviceType = '中央空調';

  int page = 1;
  int limit = 10;
  bool hasMore = true;
  bool loading = true;
  bool error = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
                    await _addData.addDevice(
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
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeviceDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _fetchData.getRoomDevices(widget.roomId),
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

          return EasyRefresh(
            header: const ClassicHeader(),
            footer: const ClassicFooter(),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: devices.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    RoomCard(
                      roomName: widget.roomId,
                      roomItem: devices[index].data() as Map<String, dynamic>,
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

  @override
  bool get wantKeepAlive => true;
}
