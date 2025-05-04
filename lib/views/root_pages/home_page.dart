import 'package:extendable_aiot/components/root_page_head.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/abstract/room_model.dart';
import 'package:extendable_aiot/themes/app_colors.dart';
import 'package:extendable_aiot/views/sub_pages/allroom_page.dart';
import 'package:extendable_aiot/views/sub_pages/room_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return StreamBuilder<List<RoomModel>>(
      stream: RoomModel.getAllRooms(),
      builder: (context, snapshot) {
        // 創建選項卡和內容
        List<Tab> tabs = [Tab(text: localizations?.allRooms ?? '所有房間')];
        List<Widget> tabContents = [const AllRoomPage()];

        if (snapshot.hasData) {
          final rooms = snapshot.data!;
          for (var room in rooms) {
            tabs.add(Tab(text: room.name));
            tabContents.add(RoomPage(roomId: room.id));
          }
        }

        // 每次重建都重新初始化 TabController
        _tabController?.dispose();
        _tabController = TabController(length: tabs.length, vsync: this);

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
              MediaQuery.of(context).size.height * 0.2,
            ),
            child: Column(
              children: [
                SizedBox.fromSize(
                  size: Size.fromHeight(
                    MediaQuery.of(context).size.height * 0.03,
                  ),
                ),
                PreferredSize(
                  preferredSize: Size.fromHeight(
                    MediaQuery.of(context).size.height * 0.2,
                  ),
                  child: const RootPageHead(),
                ),
                PreferredSize(
                  preferredSize: Size.fromHeight(
                    MediaQuery.of(context).size.height * 0.1,
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: tabs,
                    dividerColor: AppColors.page,
                    indicatorColor: AppColors.active,
                    labelColor: AppColors.active,
                    unselectedLabelColor: AppColors.unactive,
                    isScrollable: true,
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(controller: _tabController, children: tabContents),
        );
      },
    );
  }
}
