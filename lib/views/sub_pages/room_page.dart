import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FetchData _fetchData = FetchData();
  late ScrollController _scrollController;

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<DocumentSnapshot>>(
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
          child: ListView.builder(
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
    );
  }

  @override
  bool get wantKeepAlive => true;
}
