import 'package:extendable_aiot/components/root_page_head.dart';
import 'package:extendable_aiot/themes/app_colors.dart';
import 'package:extendable_aiot/pages/all_room_page.dart';
import 'package:extendable_aiot/views/sub_pages/bedroom_page.dart';
import 'package:extendable_aiot/views/sub_pages/testroom_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

const List<Tab> _tabs = [
  Tab(text: '所有房間'),
  Tab(text: '測試功能'),
  Tab(text: '臥室'),
  Tab(text: '廚房'),
];

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  late List<Widget> _tabsContent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabsContent = [
      const AllRoomPage(),
      TestRoomPage(roomId: "8GnD6B55eAdh1V7D6jYp"),
      const BedRoomPage(),
      const Center(child: Text('這是廚房的內容')),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.35,
        title: const RootPageHead(),
        bottom: TabBar(
          tabs: _tabs,
          controller: _tabController,
          dividerColor: AppColors.page,
          indicatorColor: AppColors.active,
          labelColor: AppColors.active,
          unselectedLabelColor: AppColors.unactive,
        ),
      ),
      body: TabBarView(controller: _tabController, children: _tabsContent),
    );
  }
}
