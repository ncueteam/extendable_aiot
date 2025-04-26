import 'package:extendable_aiot/utils/util.dart';
import 'package:extendable_aiot/views/card/airconditioner.dart';
import 'package:extendable_aiot/temp/sensor_page.dart';
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
    return GestureDetector(
      onTap: () {
        Widget targetPage = SensorPage(); // Default page
        switch (widget.roomItem['type']) {
          case "中央空調":
            targetPage = Airconditioner(
              roomItem: widget.roomItem,
              roomName: widget.roomName,
            );
            break;
          // case "2":
          //   targetPage = Page2();
          //   break;
          // case "3":
          //   targetPage = Page3();
          //   break;
          // case "4":
          //   targetPage = Page4();
          //   break;
          // default:
          //   targetPage = SensorPage(); // 預設頁面
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.roomItem['status'] ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(
                    IconData(
                      int.parse(widget.roomItem['icon']),
                      fontFamily: 'MaterialIcons',
                    ),
                    color: AppColors.getCardColor(widget.roomItem['status']),
                    size: 30,
                  ),
                  Expanded(child: SizedBox()),
                  Icon(
                    Icons.more_vert,
                    color: AppColors.getCardColor(widget.roomItem['status']),
                    size: 30,
                  ),
                ],
              ),
            ),
            const SizedBox(),
            Text(
              widget.roomName,
              style: TextStyle(
                color: AppColors.getCardColor(widget.roomItem['status']),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  truncateString(widget.roomItem['name'],10),
                  style: TextStyle(
                    color: AppColors.getCardColor(widget.roomItem['status']),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                Switch(
                  value: widget.roomItem['status'],
                  onChanged: (_) async {
                    try {} catch (e) {}
                  },
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
