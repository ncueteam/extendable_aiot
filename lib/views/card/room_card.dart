import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/themes/app_colors.dart';
import 'package:flutter/material.dart';

class RoomCard extends StatefulWidget {
  final String roomName;
  final Map<String, dynamic> roomItem;

  const RoomCard({super.key, required this.roomName, required this.roomItem});

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
        color: widget.roomItem['status'] ? Colors.blue : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconData(
                  int.parse(widget.roomItem['icon']),
                  fontFamily: 'MaterialIcons',
                ),
                color: AppColors.getCardColor(widget.roomItem['status']),
                size: 40,
              ),
              Expanded(child: SizedBox()),
              Icon(
                Icons.more_vert,
                color: AppColors.getCardColor(widget.roomItem['status']),
                size: 40,
              ),
            ],
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: TextStyle(
                    color: AppColors.getCardColor(widget.roomItem['status']),
                  ),
                ),
                Text(
                  widget.roomItem['name'],
                  style: TextStyle(
                    color: AppColors.getCardColor(widget.roomItem['status']),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Switch(
              value: widget.roomItem['status'],
              onChanged: (_) async {
                try {} catch (e) {}
              },
              activeColor: Colors.white,
              inactiveThumbColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
