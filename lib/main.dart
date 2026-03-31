import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() async {
  // Inicializa o motor do Flutter e o Reprodutor de Vídeo Profissional
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  // Verifica se o usuário já escolheu um idioma antes
  final prefs = await SharedPreferences.getInstance();
  final String? lang = prefs.getString('user_lang');
  
  runApp(PlayTVNowApp(initialLang: lang));
}

class PlayTVNowApp extends StatelessWidget {
  final String? initialLang;
  const PlayTVNowApp({super.key, this.initialLang});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayTVNow',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.blueAccent,
      ),
      debugShowCheckedModeBanner: false,
      // Se não tem idioma, vai pra tela de Seleção. Se tem, vai direto pros canais!
      home: initialLang == null ? const LanguageScreen() : ChannelsScreen(lang: initialLang!),
    );
  }
}

// Estrutura básica de um Canal
class Channel {
  final String name;
  final String logo;
  final String url;
  Channel(this.name, this.logo, this.url);
}

// ==========================================
// TELA 1: SELEÇÃO DE IDIOMA
// ==========================================
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  bool _isLoading = false;

  void _selectLanguage(String lang) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_lang', lang); // Salva a escolha para sempre
    
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChannelsScreen(lang: lang)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.blueAccent)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.live_tv, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 20),
                  const Text("PlayTVNow", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(250, 55), backgroundColor: Colors.blueAccent),
                    onPressed: () => _selectLanguage('en'),
                    child: const Text("English Channels", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(250, 55), backgroundColor: Colors.green),
                    onPressed: () => _selectLanguage('pt'),
                    child: const Text("Canais em Português", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ],
              ),
      ),
    );
  }
}

// ==========================================
// TELA 2: LISTA DE CANAIS (GRELHA)
// ==========================================
class ChannelsScreen extends StatefulWidget {
  final String lang;
  const ChannelsScreen({super.key, required this.lang});
  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  List<Channel> channels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  // Baixa e processa a lista direto da internet (muito mais rápido e sem travar)
  Future<void> _loadChannels() async {
    final url = widget.lang == 'pt' 
        ? "https://iptv-org.github.io/iptv/languages/por.m3u" 
        : "https://iptv-org.github.io/iptv/languages/eng.m3u";
    
    try {
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      List<Channel> parsed = [];
      String currentName = "Canal Desconhecido";
      String currentLogo = "";
      
      for (var line in body.split('\n')) {
        line = line.trim();
        if (line.startsWith('#EXTINF')) {
          final logoMatch = RegExp(r'tvg-logo="(.*?)"').firstMatch(line);
          currentLogo = logoMatch != null ? logoMatch.group(1) ?? "" : "";
          final parts = line.split(',');
          if (parts.length > 1) {
            currentName = parts.last.trim();
          }
        } else if (line.startsWith('http')) {
          parsed.add(Channel(currentName, currentLogo, line));
          currentName = "Canal Desconhecido";
          currentLogo = "";
        }
      }
      
      setState(() {
        channels = parsed;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Permite ao usuário trocar de idioma nas configurações (ícone no topo)
  void _changeLang() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_lang');
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lang == 'pt' ? 'Canais Livres' : 'Free Channels', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.language), onPressed: _changeLang, tooltip: "Trocar Idioma"),
        ],
      ),
      body: isLoading 
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blueAccent),
                SizedBox(height: 15),
                Text("Carregando canais / Loading...", style: TextStyle(color: Colors.grey))
              ],
            ))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Mostra 3 canais por linha
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final c = channels[index];
                return InkWell(
                  onTap: () {
                    // Ao clicar, abre o reprodutor de vídeo
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: c)));
                  },
                  child: Card(
                    color: const Color(0xFF1E1E1E),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (c.logo.isNotEmpty) 
                          Expanded(child: Padding(
                            padding: const EdgeInsets.all(8.0), 
                            child: Image.network(c.logo, errorBuilder: (_,__,___) => const Icon(Icons.tv, size: 40, color: Colors.grey))
                          )),
                        if (c.logo.isEmpty)
                          const Expanded(child: Icon(Icons.tv, size: 40, color: Colors.grey)),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(c.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// TELA 3: REPRODUTOR DE VÍDEO (TELA CHEIA)
// ==========================================
class PlayerScreen extends StatefulWidget {
  final Channel channel;
  const PlayerScreen({super.key, required this.channel});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    // Força o celular a deitar e esconde os botões do sistema
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Inicia a reprodução
    player.open(Media(widget.channel.url));
  }

  @override
  void dispose() {
    player.dispose();
    // Quando fechar o vídeo, o celular volta a ficar em pé
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: Video(controller: controller)),
          // Botão de voltar (Sair do ecrã inteiro)
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
