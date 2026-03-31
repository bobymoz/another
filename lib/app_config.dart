class AppConfig {
  static const String appName = "PlayTVNow";
  
  // Listas M3U Legais (IPTV-Org)
  static const String urlPT = "https://iptv-org.github.io/iptv/languages/por.m3u";
  static const String urlEN = "https://iptv-org.github.io/iptv/languages/eng.m3u";

  static String getPlaylistUrl(String lang) {
    return lang == 'pt' ? urlPT : urlEN;
  }
}
