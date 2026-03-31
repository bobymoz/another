import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/language_selection_screen.dart';
// Importe aqui a sua tela principal que já veio no fork (ex: lib/screens/home_screen.dart)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstRun = prefs.getBool('first_run') ?? true;

  runApp(MaterialApp(
    title: 'PlayTVNow',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: isFirstRun ? const LanguageSelectionScreen() : const MinhaTelaPrincipal(), // Troque pelo nome da classe da sua Home
    routes: {
      '/home': (context) => const MinhaTelaPrincipal(), // Troque aqui também
    },
  ));
}
