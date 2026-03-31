import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../controllers/playlist_controller.dart';
import '../models/playlist_model.dart';
import '../repositories/user_preferences.dart';
import 'app_initializer_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  bool _isLoading = false;

  void _selectLanguage(BuildContext context, String lang) async {
    // Mostra a rodinha de carregamento enquanto prepara
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_lang', lang);
    await prefs.setBool('first_run', false);
    
    // Escolhe a lista com base na linguagem
    final url = lang == 'pt' 
        ? "https://iptv-org.github.io/iptv/languages/por.m3u" 
        : "https://iptv-org.github.io/iptv/languages/eng.m3u";

    final playlistController = Provider.of<PlaylistController>(context, listen: false);
    
    // Cria a lista automaticamente
    final playlist = await playlistController.createPlaylist(
      name: 'PlayTVNow - Canais Livres',
      type: PlaylistType.m3u,
      url: url,
    );

    if (context.mounted) {
      if (playlist != null) {
        // Grava como a lista principal/última aberta
        await UserPreferences.setLastPlaylist(playlist.id);
        
        // Vai para a tela de inicialização original.
        // É ela que vai fazer o download seguro dos canais sem deixar a tela cinza!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AppInitializerScreen()),
        );
      } else {
        // Se algo falhar na criação, vai para a Home vazia
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: _isLoading 
        ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 20),
              Text("Preparando canais / Preparing channels...", style: TextStyle(color: Colors.white)),
            ],
          )
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "PlayTVNow",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 40),
            const Text("Select your language / Selecione seu idioma", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(200, 50)),
              onPressed: () => _selectLanguage(context, 'en'),
              child: const Text("English"),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(200, 50)),
              onPressed: () => _selectLanguage(context, 'pt'),
              child: const Text("Português"),
            ),
          ],
        ),
      ),
    );
  }
}
