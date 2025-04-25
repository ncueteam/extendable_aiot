import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/services/fetch_data.dart';

class RoomPage extends StatelessWidget {
  final String roomId;
  final FetchData _fetchData = FetchData();

  RoomPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _fetchData.getRoomById(roomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('發生錯誤'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final roomData = snapshot.data!.data() as Map<String, dynamic>;

        return Center(
          child: Text('房間: ${roomData['name']}'),
        );
      },
    );
  }
}