class AppConfig {
  // Groq AI
  static const String groqKey = String.fromEnvironment(
    'GROQ_KEY',
    defaultValue: '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',
  );

  // Spotify
  static const String spotifyClientId = String.fromEnvironment(
    'SPOTIFY_CLIENT_ID',
    defaultValue: '6a641d5f715d4e5e9de3f2faf6f7973d',
  );
  static const String spotifyClientSecret = String.fromEnvironment(
    'SPOTIFY_CLIENT_SECRET',
    defaultValue: '552ba2407f4d447aa5ffa3f69ba9f0ff',
  );
}