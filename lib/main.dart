import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColor = Colors.blue[100];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("早上好！", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {})
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2022年6月28日',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            // 天氣卡
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_cloudy, color: Colors.white, size: 50),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('32°', style: TextStyle(color: Colors.white, fontSize: 32)),
                      Text('今日多雲', style: TextStyle(color: Colors.white)),
                      Text('重慶市北區', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 房間Tab
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  RoomTab(text: "所有房間", selected: true),
                  RoomTab(text: "客廳"),
                  RoomTab(text: "臥室"),
                  RoomTab(text: "廚房"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 控制卡片
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: const [
                  ControlCard(title: "中央空調", room: "客廳", icon: Icons.ac_unit, isOn: true),
                  ControlCard(title: "燈", room: "臥室", icon: Icons.lightbulb, isOn: false),
                  ControlCard(title: "電視機", room: "客廳", icon: Icons.tv, isOn: false),
                  ControlCard(title: "無線路由器", room: "客廳", icon: Icons.router, isOn: false),
                ],
              ),
            ),
          ],
        ),
      ),
      // 浮動新增按鈕
      // 底部導航欄
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class RoomTab extends StatelessWidget {
  final String text;
  final bool selected;

  const RoomTab({super.key, required this.text, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
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


