import 'package:extendable_aiot/components/root_page_head.dart';
import 'package:extendable_aiot/config/app_colors.dart';
import 'package:extendable_aiot/sub_pages/all_room_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

const List<Tab> _tabs = [
  Tab(text: '所有房間'),
  Tab(text: '客廳'),
  Tab(text: '臥室'),
  Tab(text: '廚房'),
];

final List<Widget> _tabsContent = [
  //Center(child: Text('這是所有房間的內容')),

  const AllRoomPage(),
  Center(child: Text('這是客廳的內容')),
  Center(child: Text('這是臥室的內容')),
  Center(child: Text('這是廚房的內容')),

  
  // const SingerPage(),
  // const TinyVideoPage(),
  // const ArticlePage(),
];

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        elevation: 0, // 移除 AppBar 的陰影（分隔線）
        toolbarHeight: MediaQuery.of(context).size.height * 0.35,
        title: const RootPageHead(),
        bottom: TabBar(
          tabs: _tabs,
          controller: _tabController,
          dividerColor: AppColors.page,
          //isScrollable: true,
          indicatorColor: AppColors.active,
          labelColor: AppColors.active,
          unselectedLabelColor: AppColors.unactive,
          
        ),
        
      ),      
      body: TabBarView(controller: _tabController, children: _tabsContent),
    );
  }
}
