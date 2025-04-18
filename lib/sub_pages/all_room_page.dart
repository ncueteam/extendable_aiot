import 'package:flutter/material.dart';

class AllRoomPage extends StatefulWidget {
  const AllRoomPage({super.key});

  @override
  State<AllRoomPage> createState() => _AllRoomPageState();
}

class _AllRoomPageState extends State<AllRoomPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          ControlCard(
            title: "中央空調",
            room: "客廳",
            icon: Icons.ac_unit,
            isOn: true,
          ),
          ControlCard(
            title: "燈",
            room: "臥室",
            icon: Icons.lightbulb,
            isOn: false,
          ),
          ControlCard(title: "電視機", room: "客廳", icon: Icons.tv, isOn: false),
          ControlCard(
            title: "無線路由器",
            room: "客廳",
            icon: Icons.router,
            isOn: false,
          ),
        ],
      ),
    );
  }
}

class ControlCard extends StatelessWidget {
  final String title;
  final String room;
  final IconData icon;
  final bool isOn;

  const ControlCard({
    super.key,
    required this.title,
    required this.room,
    required this.icon,
    this.isOn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOn ? Colors.blue : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isOn ? Colors.white : Colors.black, size: 30),
          const Spacer(),
          Text(
            room,
            style: TextStyle(color: isOn ? Colors.white70 : Colors.grey),
          ),
          Text(
            title,
            style: TextStyle(
              color: isOn ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Switch(
              value: isOn,
              onChanged: (_) {},
              activeColor: Colors.white,
              inactiveThumbColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
