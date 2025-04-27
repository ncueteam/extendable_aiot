import 'package:app_chiseletor/auth/auth_button.dart';
import 'package:app_chiseletor/theme/theme_manager.dart';
import 'package:app_chiseletor/widgets/language_toggle_button.dart';
import 'package:app_chiseletor/widgets/theme_selection_button.dart';
import 'package:app_chiseletor/widgets/theme_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_colors.dart';
// import 'dart:async';

class RootPageHead extends StatefulWidget {
  const RootPageHead({super.key});

  @override
  State<RootPageHead> createState() => _RootPageHeadState();
}

class _RootPageHeadState extends State<RootPageHead> {
  // late String _currentTime;

  @override
  void initState() {
    super.initState();
    // _updateTime();
    // Update the time every second
    // Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeManager themeManager = context.read<ThemeManager>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Row(
        //   children: [
        //     IconButton(
        //       icon: Icon(
        //         Icons.menu,
        //         color:
        //             themeManager
        //                 .currentTheme
        //                 ?.lightTheme
        //                 .bottomNavigationBarTheme
        //                 .selectedItemColor,
        //       ),
        //       alignment: Alignment.topLeft,
        //       onPressed: () {
        //         Scaffold.of(context).openDrawer();
        //       },
        //     ),
        //     ThemeToggleButton(),
        //     ThemeSelectionButton(),
        //     LanguageToggleButton(),
        //     AuthButton(),
        //   ],
        // ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          //decoration: BoxDecoration(color: AppColors.nav),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hello",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(),
              const Text(
                "let's manage your smart home.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Text(_currentTime, style: const TextStyle(color: Colors.blue)),
              SizedBox(height: 16),
              //天氣卡
              // Container(
              //   padding: const EdgeInsets.all(8),
              //   decoration: BoxDecoration(
              //     color: Colors.blue,
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       const Icon(Icons.wb_cloudy, color: Colors.white, size: 120),
              //       Container(
              //         padding: EdgeInsets.only(left: 50),
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: const [
              //             Text(
              //               '32°',
              //               style: TextStyle(color: Colors.white, fontSize: 40),
              //             ),
              //             Text(
              //               '今日多雲',
              //               style: TextStyle(color: Colors.white, fontSize: 20),
              //             ),
              //             Text(
              //               '彰化市彰化區',
              //               style: TextStyle(color: Colors.white, fontSize: 20),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
