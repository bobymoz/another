import 'package:another_iptv_player/controllers/playlist_controller.dart';
import 'package:another_iptv_player/screens/app_initializer_screen.dart';
import 'package:flutter/material.dart';
import 'package:another_iptv_player/services/service_locator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/locale_provider.dart';
import 'controllers/theme_provider.dart';
import 'l10n/app_localizations.dart';
import 'l10n/supported_languages.dart';
import 'utils/app_themes.dart';
import 'screens/language_selection_screen.dart'; // A nossa nova tela

Future<void> main() async {
  // Garante que o Flutter está pronto antes de verificar as preferências
  WidgetsFlutterBinding.ensureInitialized(); 
  await setupServiceLocator();

  // Verifica se é a primeira vez que a app corre
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstRun = prefs.getBool('first_run') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistController()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(isFirstRun: isFirstRun), // Passa a informação para a app
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;

  const MyApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      locale: localeProvider.locale,
      supportedLocales:
      supportedLanguages.map((lang) => Locale(lang['code'])).toList(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'PlayTVNow',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      // Se for a primeira vez, mostra a seleção de idioma, senão vai para a app normal
      home: isFirstRun ? const LanguageSelectionScreen() : AppInitializerScreen(),
      debugShowCheckedModeBanner: false,
      // Define a rota para onde a seleção de idioma deve navegar após a escolha
      routes: {
        '/home': (context) => AppInitializerScreen(),
      },
    );
  }
}
