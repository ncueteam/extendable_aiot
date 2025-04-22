import 'package:app_chiseletor/theme/theme_interface.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/themes/app_colors.dart';
import 'package:flutter/material.dart';

class DefaultTheme implements ThemeInterface {
  @override
  String get name => 'ThemeVicky';

  @override
  String getLocalizedName(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    print('Current localizations: $localizations'); // 添加調試輸出
    return AppLocalizations.of(context)?.themeVicky ?? name;
  }

  @override
  ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.page,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.unactive),
    ),
    tabBarTheme: const TabBarThemeData(
      unselectedLabelColor: AppColors.unactive,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontSize: 18),
      labelPadding: EdgeInsets.symmetric(horizontal: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.nav,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.nav,
      selectedItemColor: AppColors.active,
      unselectedItemColor: AppColors.unactive,
      selectedLabelStyle: TextStyle(fontSize: 12),
    ),
  );

  @override
  ThemeData get darkTheme => ThemeData(
    hintColor: Colors.white,
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.page,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.unactive),
    ),
    tabBarTheme: const TabBarThemeData(
      unselectedLabelColor: AppColors.unactive,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontSize: 18),
      labelPadding: EdgeInsets.symmetric(horizontal: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.nav,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.nav,
      selectedItemColor: AppColors.active,
      unselectedItemColor: AppColors.unactive,
      selectedLabelStyle: TextStyle(fontSize: 12),
    ),
  );
}
