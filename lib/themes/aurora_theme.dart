import 'package:app_chiseletor/theme/theme_interface.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Aurora Theme: A modern, elegant theme with gradients inspired by aurora borealis
class AuroraTheme implements ThemeInterface {
  @override
  String get name => 'ThemeAurora';

  @override
  String getLocalizedName(BuildContext context) {
    return AppLocalizations.of(context)?.themeAurora ?? 'Aurora Theme';
  }

  // Aurora color palette
  static const Color primaryColor = Color(0xFF6A5ACD); // Slate blue
  static const Color secondaryColor = Color(0xFF7B68EE); // Medium slate blue
  static const Color accentColor = Color(0xFF4CAF50); // Green
  static const Color backgroundColor = Color(0xFFF8F9FA); // Light gray
  static const Color darkBackgroundColor = Color(0xFF2D3436); // Dark gray
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color darkCardColor = Color(0xFF353B48); // Dark blue-gray
  static const Color navColor = Color(0xFFFFFFFF); // White
  static const Color darkNavColor = Color(0xFF2D3250); // Dark blue-gray
  static const Color activeColor = Color(0xFF6A5ACD); // Slate blue
  static const Color inactiveColor = Color(0xFF9E9E9E); // Gray
  static const Color textColor = Color(0xFF2D3436); // Dark gray
  static const Color darkTextColor = Color(0xFFF8F9FA); // Light gray
  static const Color errorColor = Color(0xFFFF5252); // Red
  static const Color warningColor = Color(0xFFFFB74D); // Orange
  static const Color successColor = Color(0xFF66BB6A); // Green

  @override
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    splashColor: primaryColor.withOpacity(0.1),
    highlightColor: primaryColor.withOpacity(0.05),
    dividerColor: Colors.grey.shade300,

    // Typography
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(color: textColor.withOpacity(0.9)),
      bodyMedium: TextStyle(color: textColor.withOpacity(0.9)),
      bodySmall: TextStyle(color: textColor.withOpacity(0.8)),
      labelLarge: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: const TextStyle(color: primaryColor),
      labelSmall: const TextStyle(color: primaryColor),
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: navColor,
      elevation: 0,
      foregroundColor: textColor,
      titleTextStyle: const TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: primaryColor),
    ),

    // TabBar
    tabBarTheme: const TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: inactiveColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontSize: 16),
      labelPadding: EdgeInsets.symmetric(horizontal: 16),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryColor, width: 3.0),
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: navColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: inactiveColor,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Card
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) return primaryColor;
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected))
          return primaryColor.withOpacity(0.5);
        return Colors.grey.withOpacity(0.5);
      }),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) return primaryColor;
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Radio
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) return primaryColor;
        return inactiveColor;
      }),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: primaryColor.withOpacity(0.3),
      thumbColor: primaryColor,
      valueIndicatorColor: primaryColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),

    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: Colors.grey,
      linearTrackColor: Colors.grey,
    ),
  );

  @override
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    cardColor: darkCardColor,
    splashColor: primaryColor.withOpacity(0.2),
    highlightColor: primaryColor.withOpacity(0.1),
    dividerColor: Colors.grey.shade700,

    // Typography
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        color: darkTextColor,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: const TextStyle(
        color: darkTextColor,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: const TextStyle(
        color: darkTextColor,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: const TextStyle(
        color: darkTextColor,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: const TextStyle(
        color: darkTextColor,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: const TextStyle(
        color: darkTextColor,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: const TextStyle(
        color: darkTextColor,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: const TextStyle(
        color: darkTextColor,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: const TextStyle(
        color: darkTextColor,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(color: darkTextColor.withOpacity(0.9)),
      bodyMedium: TextStyle(color: darkTextColor.withOpacity(0.9)),
      bodySmall: TextStyle(color: darkTextColor.withOpacity(0.8)),
      labelLarge: const TextStyle(
        color: secondaryColor,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: const TextStyle(color: secondaryColor),
      labelSmall: const TextStyle(color: secondaryColor),
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: darkNavColor,
      elevation: 0,
      foregroundColor: darkTextColor,
      titleTextStyle: const TextStyle(
        color: darkTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: secondaryColor),
    ),

    // TabBar
    tabBarTheme: const TabBarTheme(
      labelColor: secondaryColor,
      unselectedLabelColor: inactiveColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontSize: 16),
      labelPadding: EdgeInsets.symmetric(horizontal: 16),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: secondaryColor, width: 3.0),
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkNavColor,
      selectedItemColor: secondaryColor,
      unselectedItemColor: inactiveColor,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryColor,
        side: const BorderSide(color: secondaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Card
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: secondaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      labelStyle: TextStyle(color: darkTextColor.withOpacity(0.7)),
      hintStyle: TextStyle(color: darkTextColor.withOpacity(0.5)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) return secondaryColor;
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected))
          return secondaryColor.withOpacity(0.5);
        return Colors.grey.withOpacity(0.5);
      }),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) return secondaryColor;
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Radio
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) return secondaryColor;
        return inactiveColor;
      }),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: secondaryColor,
      inactiveTrackColor: secondaryColor.withOpacity(0.3),
      thumbColor: secondaryColor,
      valueIndicatorColor: secondaryColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),

    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: secondaryColor,
      circularTrackColor: Colors.grey,
      linearTrackColor: Colors.grey,
    ),
  );
}
