import 'package:extendable_aiot/models/bedroom_model.dart';
import 'package:extendable_aiot/themes/app_colors.dart';
import 'package:flutter/material.dart';

class BedRoomCard extends StatefulWidget {
  final BedRoomItem bedRoomItem;
  const BedRoomCard({super.key, required this.bedRoomItem});

  @override
  State<BedRoomCard> createState() => _BedRoomCardState();
}

class _BedRoomCardState extends State<BedRoomCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomLeft,
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      width: MediaQuery.of(context).size.width * 0.5,
      height: MediaQuery.of(context).size.width * 0.5 * 0.8,
      decoration: BoxDecoration(
        color: widget.bedRoomItem.isOn ? Colors.blue : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.bedRoomItem.icon,
                color: AppColors.getCardColor(widget.bedRoomItem.isOn),
                size: 30,
              ),
              Expanded(child: SizedBox()),
              Icon(
                Icons.more_vert,
                color: AppColors.getCardColor(widget.bedRoomItem.isOn),
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "臥室",
            style: TextStyle(
              color: AppColors.getCardColor(widget.bedRoomItem.isOn),
            ),
          ),
          Text(
            widget.bedRoomItem.name,
            style: TextStyle(
              color: AppColors.getCardColor(widget.bedRoomItem.isOn),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Switch(
              value: widget.bedRoomItem.isOn,
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
