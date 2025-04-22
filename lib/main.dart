import 'package:app_chiseletor/auth/auth_wrapper.dart';
import 'package:app_chiseletor/theme/app_initializer.dart';
import 'package:app_chiseletor/widgets/theme_material_app.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/themes/default_theme.dart';
import 'package:flutter/material.dart';
import 'package:extendable_aiot/pages/root_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final providers = await AppInitializer.initialize(
    customThemes: [DefaultTheme()],
    defaultLocale: const Locale('zh', 'TW'),
  );

  runApp(
    MultiProvider(
      providers: providers,
      child: const ThemedMaterialApp(
        home: AuthWrapper(homepage: RootPage()),
        localization: AppLocalizations.delegate, // 這裡是多國語言的代理
      ),
    ),
  );
}
