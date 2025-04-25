import 'package:app_chiseletor/theme/theme_manager.dart';
import 'package:extendable_aiot/pages/user_drawer.dart';
import 'package:extendable_aiot/temp/sensor_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'root_pages/home_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

// const Map<String, String> _bottomNames = {
//   'home': '首頁',
//   'setting': '設定',
//   'notify': '通知',
//   'profile': '我的',
// };

class _RootPageState extends State<RootPage> {
  //當前選中頁索引
  int _currentIndex = 0;
  //頁面集合
  final List<Widget> _pages = [
    const HomePage(),
    PlaceholderWidget(color: Colors.green, text: "設定頁面"),
    // PlaceholderWidget(color: Colors.orange, text: "通知頁面"),
    const SensorPage(),
    Scaffold(
      appBar: AppBar(title: const Text("個人頁面")),
      drawer: UserDrawer(),
      body: const PlaceholderWidget(color: Colors.blue, text: "你看不到"),
    ),
  ];
  // final List<IndexedStackChild> _pages = [
  //   IndexedStackChild(child: const HomePage()),
  //   IndexedStackChild(child: const MusicPage()),
  //   IndexedStackChild(child: Container()),
  //   IndexedStackChild(child: const TinyVideoPage()),
  //   IndexedStackChild(child: const ProfilePage()),
  // ];
  //底部導航數組
  final Map<IconData, String> _bottomNames = {
    Icons.home: "首頁",
    Icons.settings: "設定",
    Icons.notifications: "通知",
    Icons.person: "我的",
  };
  final List<BottomNavigationBarItem> _bottomNavBarList = [];

  @override
  void initState() {
    super.initState();
    // 生成底部導航項目
    _bottomNames.forEach((key, value) {
      _bottomNavBarList.add(_bottomNavBarItem(key, value));
    });
  }

  BottomNavigationBarItem _bottomNavBarItem(IconData icon, String label) {
    return BottomNavigationBarItem(icon: Icon(icon), label: '');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeManager themeManager = context.read<ThemeManager>();
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _bottomNavBarList,
        selectedItemColor: themeManager.currentTheme?.lightTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// 測試用佔位頁面
class PlaceholderWidget extends StatelessWidget {
  final Color color;
  final String text;

  const PlaceholderWidget({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
