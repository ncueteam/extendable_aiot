import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:extendable_aiot/services/fetch_data.dart';
import 'package:extendable_aiot/views/card/room_card.dart';
import 'package:flutter/material.dart';

class AllRoomPage extends StatefulWidget {
  const AllRoomPage({super.key});

  @override
  State<AllRoomPage> createState() => _AllRoomPageState();
}

class _AllRoomPageState extends State<AllRoomPage> {
  final FetchData _fetchData = FetchData();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DocumentSnapshot>>(
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
                    roomItem: devices[index].data() as Map<String, dynamic>,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
