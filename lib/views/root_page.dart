import 'package:app_chiseletor/theme/theme_manager.dart';
import 'package:extendable_aiot/pages/all_room_page.dart';
import 'package:extendable_aiot/temp/sensor_page.dart';
import 'package:extendable_aiot/temp/testroom_page.dart';
import 'package:extendable_aiot/views/root_pages/automatic.dart';
import 'package:extendable_aiot/views/root_pages/profile.dart';
import 'package:extendable_aiot/views/root_pages/test_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'root_pages/home_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  //當前選中頁索引
  int _currentIndex = 0;
  //頁面集合
  final List<Widget> _pages = [
    const HomePage(),
    const Automatic(),
    // const SensorPage(),
    const TestPage(),
    const Profile(),
  ];
  // final List<IndexedStackChild> _pages = [
  //   IndexedStackChild(child: const HomePage()),
  //   IndexedStackChild(child: const MusicPage()),
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
