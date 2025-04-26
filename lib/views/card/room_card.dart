import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/themes/app_colors.dart';
import 'package:flutter/material.dart';

class RoomCard extends StatefulWidget {
  final List<DocumentSnapshot<Object?>> roomItem;

  const RoomCard({super.key, required this.roomItem});

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomLeft,
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      width: MediaQuery.of(context).size.width * 0.5,
      height: MediaQuery.of(context).size.width * 0.5 * 0.8,
      decoration: BoxDecoration(
        //color: widget.roomItem.status ? Colors.blue : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [Text("RoomCard")]),
    );
  }
}
