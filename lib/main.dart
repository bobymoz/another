import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
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
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // Dark theme mais profundo
        primaryColor: const Color(0xFFE50914), // Vermelho tipo Netflix
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE50914), secondary: Colors.white),
      ),
      debugShowCheckedModeBanner: false,
      home: initialLang == null ? const PremiumLanguageScreen() : ChannelsScreen(lang: initialLang!),
    );
  }
}

// ==========================================
// MODELO DE DADOS
// ==========================================
class Channel {
  final String name;
  final String logo;
  final String url;
  final String category;

  Channel({required this.name, required this.logo, required this.url, required this.category});

  // Para salvar e ler do Histórico
  Map<String, dynamic> toJson() => {'name': name, 'logo': logo, 'url': url, 'category': category};
  factory Channel.fromJson(Map<String, dynamic> json) => 
      Channel(name: json['name'], logo: json['logo'], url: json['url'], category: json['category']);
}

// ==========================================
// TELA 1: SELEÇÃO DE IDIOMA PREMIUM
// ==========================================
class PremiumLanguageScreen extends StatefulWidget {
  const PremiumLanguageScreen({super.key});
  @override
  State<PremiumLanguageScreen> createState() => _PremiumLanguageScreenState();
}

class _PremiumLanguageScreenState extends State<PremiumLanguageScreen> {
  bool _isLoading = false;

  void _selectLanguage(String lang) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_lang', lang);
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChannelsScreen(lang: lang)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF4A0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: _isLoading 
            ? const CircularProgressIndicator(color: Color(0xFFE50914))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill, size: 90, color: Color(0xFFE50914)),
                  const SizedBox(height: 10),
                  const Text("PlayTVNow", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                  const SizedBox(height: 50),
                  const Text("Escolha o seu catálogo\nChoose your catalog", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 30),
                  _buildLangCard("Português", "Canais do Brasil, Portugal e dublados.", 'pt', Icons.flag),
                  const SizedBox(height: 20),
                  _buildLangCard("English", "International channels & movies.", 'en', Icons.public),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildLangCard(String title, String subtitle, String code, IconData icon) {
    return InkWell(
      onTap: () => _selectLanguage(code),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TELA 2: CATÁLOGO DE CANAIS (COM CATEGORIAS E PESQUISA)
// ==========================================
class ChannelsScreen extends StatefulWidget {
  final String lang;
  const ChannelsScreen({super.key, required this.lang});
  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  List<Channel> allChannels = [];
  List<Channel> history = [];
  List<String> categories = ['Histórico', 'Tudo'];
  
  String selectedCategory = 'Tudo';
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadChannels();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('watch_history');
    if (historyJson != null) {
      final List decoded = json.decode(historyJson);
      setState(() {
        history = decoded.map((item) => Channel.fromJson(item)).toList();
        if (history.isNotEmpty) selectedCategory = 'Histórico';
      });
    }
  }

  Future<void> _addToHistory(Channel channel) async {
    history.removeWhere((c) => c.url == channel.url); // Remove duplicado
    history.insert(0, channel); // Adiciona no topo
    if (history.length > 15) history.removeLast(); // Mantém apenas os últimos 15
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('watch_history', json.encode(history.map((c) => c.toJson()).toList()));
    setState(() {});
  }

  Future<void> _loadChannels() async {
    final url = widget.lang == 'pt' 
        ? "https://iptv-org.github.io/iptv/languages/por.m3u" 
        : "https://iptv-org.github.io/iptv/languages/eng.m3u";
    
    try {
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      List<Channel> parsed = [];
      String cName = "Desconhecido", cLogo = "", cCategory = "Outros";
      
      for (var line in body.split('\n')) {
        line = line.trim();
        if (line.startsWith('#EXTINF')) {
          // Extrai Logo
          final logoMatch = RegExp(r'tvg-logo="(.*?)"').firstMatch(line);
          cLogo = logoMatch != null ? logoMatch.group(1) ?? "" : "";
          
          // Extrai Categoria (group-title)
          final groupMatch = RegExp(r'group-title="(.*?)"').firstMatch(line);
          cCategory = groupMatch != null && groupMatch.group(1)!.isNotEmpty ? groupMatch.group(1)! : "Outros";
          
          // Extrai Nome
          final parts = line.split(',');
          if (parts.length > 1) cName = parts.last.trim();
        } else if (line.startsWith('http')) {
          parsed.add(Channel(name: cName, logo: cLogo, url: line, category: cCategory));
          cName = "Desconhecido"; cLogo = ""; cCategory = "Outros";
        }
      }
      
      // Monta as categorias únicas ordenadas
      final Set<String> cats = parsed.map((c) => c.category).toSet();
      List<String> sortedCats = cats.toList()..sort();
      
      setState(() {
        allChannels = parsed;
        categories.addAll(sortedCats);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<Channel> get displayedChannels {
    List<Channel> list;
    if (selectedCategory == 'Histórico') list = history;
    else if (selectedCategory == 'Tudo') list = allChannels;
    else list = allChannels.where((c) => c.category == selectedCategory).toList();

    if (searchQuery.isNotEmpty) {
      list = list.where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('PlayTVNow', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE50914))),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_lang');
              if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PremiumLanguageScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Barra de Pesquisa Animada
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar canais, filmes...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: const EdgeInsets.all(0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          // Abas de Categorias
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == selectedCategory;
                if (cat == 'Histórico' && history.isEmpty) return const SizedBox.shrink(); // Esconde histórico se vazio
                
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE50914) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? const Color(0xFFE50914) : Colors.grey),
                    ),
                    child: Center(
                      child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 10),

          // Grelha de Canais ou Skeleton Loading
          Expanded(
            child: isLoading 
              ? const SkeletonGrid() // Animação bonita de carregamento
              : displayedChannels.isEmpty
                  ? const Center(child: Text("Nenhum canal encontrado.", style: TextStyle(color: Colors.grey)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(15),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, 
                        crossAxisSpacing: 12, 
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85
                      ),
                      itemCount: displayedChannels.length,
                      itemBuilder: (context, index) {
                        final c = displayedChannels[index];
                        return InkWell(
                          onTap: () {
                            _addToHistory(c);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: c)));
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: c.logo.isNotEmpty 
                                      ? Image.network(c.logo, errorBuilder: (_,__,___) => const Icon(Icons.live_tv, size: 40, color: Colors.grey))
                                      : const Icon(Icons.live_tv, size: 40, color: Colors.grey),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))
                                  ),
                                  child: Text(c.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ANIMAÇÃO DE SKELETON (CARREGAMENTO)
// ==========================================
class SkeletonGrid extends StatefulWidget {
  const SkeletonGrid({super.key});
  @override
  State<SkeletonGrid> createState() => _SkeletonGridState();
}

class _SkeletonGridState extends State<SkeletonGrid> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.8).animate(_controller),
      child: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
        itemCount: 12,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// ==========================================
// TELA 3: REPRODUTOR DE VÍDEO (RÁPIDO & COM GESTOS)
// ==========================================
class PlayerScreen extends StatefulWidget {
  final Channel channel;
  const PlayerScreen({super.key, required this.channel});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // O SEGREDO PARA INTERNET LENTA: Aumentar o Buffer para 64MB!
    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 64 * 1024 * 1024, // 64MB de cache para não travar
      ),
    );
    controller = VideoController(player);
    
    player.open(Media(widget.channel.url));
  }

  @override
  void dispose() {
    player.dispose();
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
          // O media_kit_video já vem com controlos de arrastar! (Volume e Brilho)
          Center(
            child: Video(
              controller: controller,
              controls: AdaptiveVideoControls, // Gestos nativos ativados
            ),
          ),
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
