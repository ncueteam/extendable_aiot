import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:extendable_aiot/models/bedroom_model.dart';
import 'package:extendable_aiot/views/card/bedroom_card.dart';
import 'package:flutter/material.dart';

class BedRoomPage extends StatefulWidget {
  const BedRoomPage({super.key});

  @override
  State<BedRoomPage> createState() => _BedRoomPageState();
}

class _BedRoomPageState extends State<BedRoomPage>
    with AutomaticKeepAliveClientMixin {
  // EasyRefreshController _easyRefreshController = EasyRefreshController(
  //   controlFinishRefresh: true,
  //   controlFinishLoad: true,
  // );
  // 下拉刷新控制器
  //late EasyRefreshController _easyRefreshController;
  // 獨立的捲動視圖 防止tab切換時觸發下拉刷新
  late ScrollController _scrollController;
  List<BedRoomItem> _bedRoomList = BedRoomList([]).list;
  int page = 1;
  int limit = 10;
  bool hasMore = true;
  bool loading = true;
  bool error = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();

    _getDevices();
  }

  Future _getDevices() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('BedRoomItem').get();

      print('Fetched ${querySnapshot.docs.length} documents');

      List<dynamic> deviceDataList =
          querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            print("Document data: $data"); // 調試用
            return data;
          }).toList();

      BedRoomList deviceListModel = BedRoomList.fromJson(deviceDataList);
      setState(() => _bedRoomList = deviceListModel.list);

      print('Fetching finished');
    } catch (e) {
      print('Error fetching devices: $e');
      setState(() {
        error = true;
        errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EasyRefresh(
      header: const ClassicHeader(),
      footer: const ClassicFooter(),
      child: ListView.builder(
        itemCount: _bedRoomList.length,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              BedRoomCard(bedRoomItem: _bedRoomList[index]),
            ],
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
