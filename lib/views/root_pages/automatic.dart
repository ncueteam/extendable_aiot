import 'package:extendable_aiot/models/abstract/room_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Automatic extends StatefulWidget {
  const Automatic({super.key});

  @override
  State<Automatic> createState() => _AutomaticState();
}

class _AutomaticState extends State<Automatic> {
  // 修改 automations 為空列表，將從資料庫加載
  final List<Map<String, dynamic>> automations = [];

  @override
  void initState() {
    super.initState();
    // 在初始化時加載數據
    _loadAutomations();
  }

  // 添加加載自動化設定的方法
  Future<void> _loadAutomations() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('autos')
            .get();

    setState(() {
      automations.clear();
      for (var doc in snapshot.docs) {
        automations.add(doc.data());
      }
    });
  }

  bool isArrivingHomeOn = true;
  bool isBedTimeOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('定時裝置'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('autos')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('發生錯誤'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final automations = snapshot.data?.docs ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTopButton(Icons.add, 'Create New'),
                    const SizedBox(width: 10),
                    _buildTopButton(Icons.auto_awesome, 'AI Suggestion'),
                  ],
                ),
                const SizedBox(height: 20),
                ...automations.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildAutomationCard(
                      title: data['title'] ?? '',
                      location: data['location'] ?? '',
                      time: data['time'] ?? '',
                      lights: List<String>.from(data['lights'] ?? []),
                      isOn: data['isOn'] ?? false,
                      onToggle: (value) async {
                        await doc.reference.update({'isOn': value});
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopButton(IconData icon, String label) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          if (label == 'Create New') {
            _showCreateDialog();
          }
        },
        icon: Icon(icon, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showCreateDialog() {
    String? selectedRoom;
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now();
    String? selectedDevice;
    final devices = ['Air Conditioner', 'Fan', 'Light'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // 改用 dialogContext 避免混淆
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 改名為 setDialogState 以區分
            return AlertDialog(
              title: const Text('Create New Automation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Room Dropdown
                    FutureBuilder<List<String>>(
                      future:
                          RoomModel.getAllRooms()
                              .map(
                                (rooms) =>
                                    rooms.map((room) => room.name).toList(),
                              )
                              .first,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Room',
                            ),
                            value: selectedRoom,
                            items:
                                snapshot.data!.map((room) {
                                  return DropdownMenuItem(
                                    value: room,
                                    child: Text(room),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedRoom = value;
                              });
                            },
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                    const SizedBox(height: 16),
                    // Time Selection
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (time != null) {
                                setDialogState(() {
                                  startTime = time;
                                });
                              }
                            },
                            child: Text('Start: ${startTime.format(context)}'),
                          ),
                        ),
                        const Text(' - '),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (time != null) {
                                setDialogState(() {
                                  endTime = time;
                                });
                              }
                            },
                            child: Text('End: ${endTime.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Device Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Device'),
                      value: selectedDevice,
                      items:
                          devices.map((device) {
                            return DropdownMenuItem(
                              value: device,
                              child: Text(device),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDevice = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedRoom != null && selectedDevice != null) {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId == null) return;

                      final title = '$selectedDevice in $selectedRoom';
                      final timeRange =
                          '${startTime.format(context)} - ${endTime.format(context)}';

                      // 創建要保存的數據
                      final autoData = {
                        'title': title,
                        'location': selectedRoom,
                        'time': timeRange,
                        'lights': [selectedDevice],
                        'isOn': true,
                        'createdAt': FieldValue.serverTimestamp(),
                      };

                      // 保存到 Firestore
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('autos')
                          .add(autoData);

                      // 重新加載數據
                      await _loadAutomations();

                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAutomationCard({
    required String title,
    required String location,
    required String time,
    required List<String> lights,
    required bool isOn,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Switch(value: isOn, onChanged: onToggle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LightChip extends StatelessWidget {
  final String label;

  const _LightChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), backgroundColor: Colors.grey[200]);
  }
}
