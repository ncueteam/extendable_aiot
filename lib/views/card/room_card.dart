import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/device_data.dart';
import 'package:extendable_aiot/services/user_service.dart';
import 'package:extendable_aiot/utils/util.dart';
import 'package:extendable_aiot/themes/app_colors.dart';
import 'package:flutter/material.dart';

class RoomCard extends StatefulWidget {
  final DeviceData roomItem;

  const RoomCard({super.key, required this.roomItem});

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  @override
  Widget build(BuildContext context) {
    // debugPrint(widget.roomItem.toString());

    DeviceData data = widget.roomItem;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => data.getTargetPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: data.status ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  // Icon(
                  //   IconData(
                  //     int.parse(widget.roomItem['icon'] ?? '0'),
                  //     fontFamily: 'MaterialIcons',
                  //   ),
                  //   color: AppColors.getCardColor(widget.roomItem['status']),
                  //   size: 30,
                  // ),
                  Expanded(child: SizedBox()),
                  Icon(
                    Icons.more_vert,
                    color: AppColors.getCardColor(data.status),
                    size: 30,
                  ),
                ],
              ),
            ),
            const SizedBox(),
            Text(
              truncateString(data.name, 15),
              style: TextStyle(
                color: AppColors.getCardColor(data.status),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  truncateString(data.type, 10),
                  style: TextStyle(
                    color: AppColors.getCardColor(data.status),
                    //fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                Switch(
                  value: data.status,
                  onChanged: (bool value) {
                    //路徑:users/
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(UserService().currentUserId)
                        .collection('devices')
                        .doc(data.id)
                        .update({'status': value});
                    setState(() {
                      data.status = !value;
                    });
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
