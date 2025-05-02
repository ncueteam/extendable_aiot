import 'package:app_chiseletor/widgets/language_toggle_button.dart';
import 'package:app_chiseletor/widgets/theme_toggle_button.dart';
import 'package:extendable_aiot/views/root_pages/automatic.dart';
import 'package:extendable_aiot/views/root_pages/profile.dart';
import 'package:extendable_aiot/views/root_pages/test_page.dart';
import 'package:flutter/material.dart';
import 'root_pages/home_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const Automatic(),
    const TestPage(),
    const Profile(),
  ];
  final List<BottomNavigationBarItem> _bottomNavBarList = [
    BottomNavigationBarItem(icon: const Icon(Icons.home), label: "首頁"),
    BottomNavigationBarItem(icon: const Icon(Icons.settings), label: "設定"),
    BottomNavigationBarItem(icon: const Icon(Icons.notifications), label: "通知"),
    BottomNavigationBarItem(icon: const Icon(Icons.person), label: "我的"),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).size.height * 0.07,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  icon: const Icon(Icons.menu),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [ThemeToggleButton(), LanguageToggleButton()],
            ),
          ],
        ),
      ),
      drawer: Profile(),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _bottomNavBarList,
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
