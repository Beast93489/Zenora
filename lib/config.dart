class AppConfig {
  // Groq AI – pass via --dart-define=GROQ_KEY=...
  static const String groqKey = String.fromEnvironment('GROQ_KEY');

  // Spotify – pass via --dart-define=SPOTIFY_CLIENT_ID=... etc.
  static const String spotifyClientId = String.fromEnvironment('SPOTIFY_CLIENT_ID');
  static const String spotifyClientSecret = String.fromEnvironment('SPOTIFY_CLIENT_SECRET');
}