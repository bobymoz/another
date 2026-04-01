import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
// MOTOR DE ANÚNCIOS DA UNITY
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

// ==========================================
// SISTEMA DE TRADUÇÃO TOTAL (INGLÊS / PORTUGUÊS)
// ==========================================
class AppText {
  static const Map<String, Map<String, String>> t = {
    'pt': {
      'loading': 'A preparar os canais...\nPor favor, aguarde.',
      'search': 'Pesquisar canais e filmes...',
      'history': 'O Seu Histórico',
      'all': 'Todos os Canais',
      'no_channels': 'Nenhum canal encontrado.',
      'choose_catalog': 'ESCOLHA O SEU CATÁLOGO',
      'pt_title': 'Canais em Português',
      'pt_desc': 'Inclui canais do Brasil, Portugal e desporto mundial.',
      'en_title': 'English Channels',
      'en_desc': 'International channels, news and world sports.',
      'featured': 'Canais em Destaque',
      'others': 'Outros',
    },
    'en': {
      'loading': 'Loading channels...\nPlease wait.',
      'search': 'Search channels and movies...',
      'history': 'Your Watch History',
      'all': 'All Channels',
      'no_channels': 'No channels found.',
      'choose_catalog': 'CHOOSE YOUR CATALOG',
      'pt_title': 'Portuguese Channels',
      'pt_desc': 'Includes Brazil, Portugal and world sports.',
      'en_title': 'English Channels',
      'en_desc': 'International channels, news and world sports.',
      'featured': 'Featured Channels',
      'others': 'Others',
    }
  };
  static String get(String lang, String key) => t[lang]?[key] ?? key;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  // INICIALIZA A MONETIZAÇÃO DA UNITY ADS
  UnityAds.init(
    gameId: '6079651',
    testMode: false, // Está em FALSE, ou seja, vai gerar dinheiro real!
  );
  
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
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFFE50914),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE50914), secondary: Colors.white),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: initialLang == null ? const PremiumLanguageScreen() : ChannelsScreen(lang: initialLang!),
    );
  }
}

// ==========================================
// MODELO DE DADOS E PROCESSAMENTO RÁPIDO
// ==========================================
class Channel {
  final String name;
  final String logo;
  final String url;
  final String category;

  Channel({required this.name, required this.logo, required this.url, required this.category});

  Map<String, dynamic> toJson() => {'name': name, 'logo': logo, 'url': url, 'category': category};
  factory Channel.fromJson(Map<String, dynamic> json) => 
      Channel(name: json['name'], logo: json['logo'], url: json['url'], category: json['category']);
}

List<Channel> parseM3uData(String body) {
  List<Channel> parsed = [];
  String cName = "Unknown", cLogo = "", cCategory = "Others";
  
  final lines = body.split('\n');
  for (var line in lines) {
    line = line.trim();
    if (line.startsWith('#EXTINF')) {
      final logoMatch = RegExp(r'tvg-logo="(.*?)"').firstMatch(line);
      cLogo = logoMatch != null ? logoMatch.group(1) ?? "" : "";
      
      final groupMatch = RegExp(r'group-title="(.*?)"').firstMatch(line);
      cCategory = groupMatch != null && groupMatch.group(1)!.isNotEmpty ? groupMatch.group(1)! : "Others";
      
      final parts = line.split(',');
      if (parts.length > 1) cName = parts.last.trim();
    } else if (line.startsWith('http')) {
      parsed.add(Channel(name: cName, logo: cLogo, url: line, category: cCategory));
      cName = "Unknown"; cLogo = ""; cCategory = "Others";
    }
  }
  return parsed;
}

IconData getCategoryIcon(String category) {
  final cat = category.toLowerCase();
  if (cat.contains('sport') || cat.contains('desporto') || cat.contains('futebol') || cat.contains('soccer')) return Icons.sports_soccer;
  if (cat.contains('movie') || cat.contains('filme') || cat.contains('cinema')) return Icons.movie;
  if (cat.contains('news') || cat.contains('notícia') || cat.contains('journal')) return Icons.article;
  if (cat.contains('music') || cat.contains('música')) return Icons.music_note;
  if (cat.contains('kid') || cat.contains('infantil') || cat.contains('cartoon')) return Icons.child_care;
  if (cat.contains('doc') || cat.contains('nature')) return Icons.landscape;
  if (cat.contains('comedy') || cat.contains('comédia')) return Icons.sentiment_very_satisfied;
  if (cat.contains('serie') || cat.contains('série')) return Icons.live_tv;
  return Icons.tv;
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
                  Image.asset('assets/logo.png', width: 140, errorBuilder: (c, e, s) => const Icon(Icons.live_tv, size: 100, color: Colors.white)),
                  const SizedBox(height: 20),
                  const Text("PlayTVNow", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                  const SizedBox(height: 50),
                  Text(AppText.get('pt', 'choose_catalog'), style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  _buildLangCard(AppText.get('pt', 'pt_title'), AppText.get('pt', 'pt_desc'), 'pt', Icons.flag),
                  const SizedBox(height: 20),
                  _buildLangCard(AppText.get('en', 'en_title'), AppText.get('en', 'en_desc'), 'en', Icons.public),
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
        width: 350,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, size: 45, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 5),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TELA 2: CATÁLOGO DE CANAIS E CARROSSEL
// ==========================================
class ChannelsScreen extends StatefulWidget {
  final String lang;
  const ChannelsScreen({super.key, required this.lang});
  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  List<Channel> allChannels = [];
  List<Channel> carouselChannels = [];
  List<String> categories = [];
  
  late String selectedCategory;
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedCategory = AppText.get(widget.lang, 'all');
    _loadAllData();
    
    // CARREGA O ANÚNCIO INTERSTITIAL EM SEGUNDO PLANO
    UnityAds.load(placementId: 'Interstitial_Android');
  }

  Future<void> _loadAllData() async {
    final langUrl = widget.lang == 'pt' 
        ? "https://iptv-org.github.io/iptv/languages/por.m3u" 
        : "https://iptv-org.github.io/iptv/languages/eng.m3u";
    final sportsUrl = "https://iptv-org.github.io/iptv/categories/sports.m3u";
    
    try {
      List<Channel> tempList = [];
      
      for (String url in [langUrl, sportsUrl]) {
        try {
          final request = await HttpClient().getUrl(Uri.parse(url));
          final response = await request.close();
          final body = await response.transform(utf8.decoder).join();
          final parsed = await compute(parseM3uData, body);
          tempList.addAll(parsed);
        } catch(e) {}
      }

      final uniqueChannels = <String, Channel>{};
      for (var c in tempList) {
        String catName = c.category == "Others" ? AppText.get(widget.lang, 'others') : c.category;
        uniqueChannels[c.url] = Channel(name: c.name, logo: c.logo, url: c.url, category: catName);
      }
      
      final finalChannels = uniqueChannels.values.toList();
      final Set<String> cats = finalChannels.map((c) => c.category).toSet();
      List<String> sortedCats = cats.toList()..sort();
      
      final random = Random();
      List<Channel> randomCarousel = [];
      if (finalChannels.isNotEmpty) {
        for(int i=0; i < (finalChannels.length < 5 ? finalChannels.length : 5); i++) {
          randomCarousel.add(finalChannels[random.nextInt(finalChannels.length)]);
        }
      }

      setState(() {
        allChannels = finalChannels;
        categories = [AppText.get(widget.lang, 'all'), ...sortedCats];
        carouselChannels = randomCarousel;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<Channel> get displayedChannels {
    List<Channel> list;
    if (selectedCategory == AppText.get(widget.lang, 'all')) list = allChannels;
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
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 35, errorBuilder: (_,__,___) => const Icon(Icons.tv, color: Color(0xFFE50914))),
            const SizedBox(width: 10),
            const Text('PlayTVNow', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 30, color: Colors.white),
            tooltip: AppText.get(widget.lang, 'history'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen(lang: widget.lang))),
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 30, color: Colors.grey),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_lang');
              if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PremiumLanguageScreen()));
            },
          )
        ],
      ),
      // BANNER DA UNITY ADS FIXO NO FUNDO DO ECRÃ
      bottomNavigationBar: Container(
        color: Colors.black,
        height: 50,
        width: double.infinity,
        child: const UnityBannerAd(
          placementId: 'Banner_Android',
        ),
      ),
      body: isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFFE50914)),
                const SizedBox(height: 20),
                Text(AppText.get(widget.lang, 'loading'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            )
          )
        : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: AppText.get(widget.lang, 'search'),
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == selectedCategory;
                
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: isSelected ? [const BoxShadow(color: Colors.redAccent, blurRadius: 8)] : [],
                    ),
                    child: Row(
                      children: [
                        Icon(cat == AppText.get(widget.lang, 'all') ? Icons.view_module : getCategoryIcon(cat), 
                             color: isSelected ? Colors.white : Colors.grey, size: 22),
                        const SizedBox(width: 8),
                        Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 15),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (searchQuery.isEmpty && carouselChannels.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 10),
                      child: Text(AppText.get(widget.lang, 'featured'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        itemCount: carouselChannels.length,
                        controller: PageController(viewportFraction: 0.85),
                        itemBuilder: (context, index) {
                          final c = carouselChannels[index];
                          return InkWell(
                            onTap: () => _openPlayer(context, c),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFF4A0000)]),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -20, bottom: -20,
                                    child: Icon(getCategoryIcon(c.category), size: 150, color: Colors.white.withOpacity(0.1)),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (c.logo.isNotEmpty) Image.network(c.logo, height: 80, errorBuilder: (_,__,___) => const Icon(Icons.tv, size: 80, color: Colors.white)),
                                        const SizedBox(height: 10),
                                        Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],

                  displayedChannels.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(AppText.get(widget.lang, 'no_channels'), style: const TextStyle(color: Colors.grey, fontSize: 18))))
                    : GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, 
                          crossAxisSpacing: 12, 
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.80
                        ),
                        itemCount: displayedChannels.length,
                        itemBuilder: (context, index) {
                          final c = displayedChannels[index];
                          return InkWell(
                            onTap: () => _openPlayer(context, c),
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: c.logo.isNotEmpty 
                                        ? Image.network(c.logo, errorBuilder: (_,__,___) => Icon(getCategoryIcon(c.category), size: 50, color: Colors.grey))
                                        : Icon(getCategoryIcon(c.category), size: 50, color: Colors.grey),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15))
                                    ),
                                    child: Text(c.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlayer(BuildContext context, Channel c) async {
    final prefs = await SharedPreferences.getInstance();
    final String? histStr = prefs.getString('watch_history');
    List<Channel> hist = histStr != null ? (json.decode(histStr) as List).map((i) => Channel.fromJson(i)).toList() : [];
    hist.removeWhere((item) => item.url == c.url);
    hist.insert(0, c);
    if (hist.length > 20) hist.removeLast();
    await prefs.setString('watch_history', json.encode(hist.map((e) => e.toJson()).toList()));
    
    if (context.mounted) {
      // Abre o reprodutor de vídeo
      await Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: c)));
      
      // DEPOIS QUE ELE FECHAR O VÍDEO: MOSTRA O ANÚNCIO DE TELA INTEIRA E CARREGA O PRÓXIMO!
      UnityAds.showVideoAd(placementId: 'Interstitial_Android');
      UnityAds.load(placementId: 'Interstitial_Android');
    }
  }
}

// ==========================================
// TELA DO HISTÓRICO 
// ==========================================
class HistoryScreen extends StatefulWidget {
  final String lang;
  const HistoryScreen({super.key, required this.lang});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Channel> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    UnityAds.load(placementId: 'Interstitial_Android');
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? histStr = prefs.getString('watch_history');
    if (histStr != null) {
      setState(() {
        history = (json.decode(histStr) as List).map((i) => Channel.fromJson(i)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.get(widget.lang, 'history'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      // BANNER NO HISTÓRICO TAMBÉM
      bottomNavigationBar: Container(
        color: Colors.black,
        height: 50,
        width: double.infinity,
        child: const UnityBannerAd(placementId: 'Banner_Android'),
      ),
      body: history.isEmpty 
          ? Center(child: Text(AppText.get(widget.lang, 'no_channels'), style: const TextStyle(color: Colors.grey, fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final c = history[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    tileColor: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    leading: c.logo.isNotEmpty 
                        ? Image.network(c.logo, width: 60, errorBuilder: (_,__,___) => Icon(getCategoryIcon(c.category), size: 40))
                        : Icon(getCategoryIcon(c.category), size: 40),
                    title: Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(c.category, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                    trailing: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: c)));
                      UnityAds.showVideoAd(placementId: 'Interstitial_Android');
                      UnityAds.load(placementId: 'Interstitial_Android');
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// TELA 3: REPRODUTOR DE VÍDEO ESTÁVEL
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
    
    player = Player();
    controller = VideoController(player);
    
    player.open(
      Media(
        widget.channel.url,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
        },
      ),
    );
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
          Center(
            child: Video(
              controller: controller,
              controls: MaterialVideoControls,
            ),
          ),
          Positioned(
            top: 25,
            left: 25,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 35),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
