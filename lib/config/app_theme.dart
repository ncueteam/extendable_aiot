import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData themeData = ThemeData(
  scaffoldBackgroundColor: AppColors.page,//頁面背景色
  indicatorColor: AppColors.active, // 選項卡列中所選選項卡指示器的顏色
  splashColor: Colors.transparent, // 取消水波纹效果
  highlightColor: Colors.transparent, // 取消水波纹效果
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      color: AppColors.unactive, // 文字颜色
    ),
  ),
  // tabbar的样式
  tabBarTheme: const TabBarTheme(
    unselectedLabelColor: AppColors.unactive,
    indicatorSize: TabBarIndicatorSize.label,
    labelStyle: TextStyle(
      fontSize: 18,
    ),
    labelPadding: EdgeInsets.symmetric(horizontal: 12),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.nav,
    elevation: 0,
  ),
  //底部按鈕主題
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.nav,
    selectedItemColor: AppColors.active,
    unselectedItemColor: AppColors.unactive,
    selectedLabelStyle: TextStyle(
      fontSize: 12,
    ),
  ),
);