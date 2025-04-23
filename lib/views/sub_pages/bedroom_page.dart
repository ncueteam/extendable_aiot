import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

class BedRoomPage extends StatefulWidget {
  const BedRoomPage({super.key});

  @override
  State<BedRoomPage> createState() => _BedRoomPageState();
}

class _BedRoomPageState extends State<BedRoomPage> {
  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      header: const ClassicHeader(),
      footer: const ClassicFooter(),
      child: ListView.builder(
        itemCount: 4,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            height: 80,
            color: Colors.black.withOpacity(index / 10),
          );
          
        },
      ),
    );
  }
}
