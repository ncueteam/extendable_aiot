import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/services/fetch_data.dart';
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
    return Container(
      child: Text("test"),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
