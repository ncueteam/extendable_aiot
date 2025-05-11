import 'package:app_chiseletor/auth/auth_wrapper.dart';
import 'package:app_chiseletor/theme/app_initializer.dart';
import 'package:app_chiseletor/widgets/theme_material_app.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/themes/default_theme.dart';
import 'package:flutter/material.dart';
import 'package:extendable_aiot/views/root_page.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  if (const bool.fromEnvironment('dart.vm.product')) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 等待 Firebase 應用檢查實例的啟動
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.debug,
  // );
  final providers = await AppInitializer.initialize(
    customThemes: [DefaultTheme()],
    defaultLocale: const Locale('zh', 'TW'),
  );

  runApp(
    MultiProvider(
      providers: providers,
      child: const ThemedMaterialApp(
        title: '智能家居系統',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AuthWrapper(homepage: RootPage()),
      ),
    ),
  );
}
