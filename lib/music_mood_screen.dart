import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'firebase_service.dart';
import 'dart:convert';

class MusicMoodScreen extends StatefulWidget {
  const MusicMoodScreen({super.key});
  @override
  State<MusicMoodScreen> createState() => _MusicMoodScreenState();
}

class _MusicMoodScreenState extends State<MusicMoodScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedSong;
  bool _isSearching = false;
  bool _isAnalyzing = false;
  String _detectedEmotion = '';
  String _aiResponse = '';
  String? _spotifyToken;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentPreviewUrl;
  late AnimationController _resultController;
  late Animation<double> _resultAnimation;

  static const String _clientId = '6a641d5f715d4e5e9de3f2faf6f7973d';
  static const String _clientSecret = '552ba2407f4d447aa5ffa3f69ba9f0ff';
  static const String _geminiKey = 'AIzaSyCe_Rv4afdSwm2GYzWf31jcz_RMYUaOzFc';
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=';

  // Mood-based recommendations shown on empty screen
  final List<Map<String, dynamic>> _moodPlaylists = [
    {'emoji': '🔥', 'mood': 'Feeling Hype', 'query': 'hype workout pump up'},
    {'emoji': '😔', 'mood': 'In My Feels', 'query': 'sad emotional heartbreak'},
    {'emoji': '😌', 'mood': 'Chill Vibes', 'query': 'lofi chill relax study'},
    {'emoji': '🥰', 'mood': 'Soft Hours', 'query': 'romantic love songs'},
    {'emoji': '😤', 'mood': 'Villain Arc', 'query': 'angry rap aggressive'},
    {'emoji': '✨', 'mood': 'Main Character', 'query': 'indie pop feel good'},
    {'emoji': '🌙', 'mood': 'Night Drive', 'query': 'night drive synthwave'},
    {'emoji': '🎉', 'mood': 'Party Mode', 'query': 'party dance hits 2024'},
  ];

  // Popular search suggestions
  final List<String> _suggestions = [
    'Arijit Singh', 'AP Dhillon', 'The Weeknd', 'Taylor Swift',
    'Sidhu Moosewala', 'Diljit Dosanjh', 'Pritam', 'A.R. Rahman',
    'Drake', 'Billie Eilish', 'Yo Yo Honey Singh', 'Shreya Ghoshal',
  ];

  final Map<String, Map<String, dynamic>> _emotionData = {
    'joy':      {'emoji': '😊', 'color': Color(0xFFFFB800), 'label': 'Joyful'},
    'sadness':  {'emoji': '😔', 'color': Color(0xFF4A90D9), 'label': 'Sad'},
    'anger':    {'emoji': '😤', 'color': Color(0xFFE74C3C), 'label': 'Angry'},
    'fear':     {'emoji': '😰', 'color': Color(0xFF9B59B6), 'label': 'Anxious'},
    'surprise': {'emoji': '😲', 'color': Color(0xFF00B4B4), 'label': 'Surprised'},
    'neutral':  {'emoji': '😌', 'color': Color(0xFF95A5A6), 'label': 'Chill'},
    'hype':     {'emoji': '🔥', 'color': Color(0xFFFF6B35), 'label': 'Hyped'},
    'romantic': {'emoji': '🥰', 'color': Color(0xFFFF69B4), 'label': 'Romantic'},
  };

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _resultAnimation = CurvedAnimation(
        parent: _resultController, curve: Curves.easeOutBack);
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
    _getSpotifyToken();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _resultController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _getSpotifyToken() async {
    try {
      final credentials =
          base64Encode(utf8.encode('$_clientId:$_clientSecret'));
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );
      debugPrint('Spotify token status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _spotifyToken = data['access_token']);
      } else {
        debugPrint('Spotify token error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Spotify token exception: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    // Load trending songs in India as default recommendations
    await _searchSongs('top hits india 2024', isRecommendation: true);
  }

  Future<void> _searchSongs(String query, {bool isRecommendation = false}) async {
    if (query.trim().isEmpty) return;
    if (_spotifyToken == null) {
      await _getSpotifyToken();
      if (_spotifyToken == null) return;
    }
    setState(() {
      _isSearching = true;
      if (!isRecommendation) _searchResults = [];
    });
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=track&limit=10&market=IN'),
        headers: {'Authorization': 'Bearer $_spotifyToken'},
      );
      debugPrint('Search status: ${response.statusCode}');
      if (response.statusCode == 401) {
        await _getSpotifyToken();
        return _searchSongs(query, isRecommendation: isRecommendation);
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tracks = data['tracks']['items'] as List;
        if (!mounted) return;
        setState(() {
          _searchResults = tracks.map((t) {
            final artists = (t['artists'] as List)
                .map((a) => a['name'] as String)
                .join(', ');
            final album = t['album'];
            final images = album['images'] as List;
            return {
              'id': t['id'] as String,
              'name': t['name'] as String,
              'artist': artists,
              'album': album['name'] as String,
              'image': images.isNotEmpty ? images[0]['url'] as String : '',
              'preview_url': t['preview_url'],
              'popularity': (t['popularity'] as int?) ?? 0,
            };
          }).toList();
          _isSearching = false;
        });
      } else {
        debugPrint('Search error: ${response.body}');
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      debugPrint('Search exception: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _togglePreview(String? previewUrl) async {
    if (previewUrl == null || previewUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No preview available for this song 😔',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF5C2D91),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_isPlaying && _currentPreviewUrl == previewUrl) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(previewUrl));
      setState(() {
        _isPlaying = true;
        _currentPreviewUrl = previewUrl;
      });
    }
  }

  Future<void> _analyzeSong(Map<String, dynamic> song) async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _selectedSong = song;
      _isAnalyzing = true;
      _detectedEmotion = '';
      _aiResponse = '';
      _searchResults = [];
    });
    _resultController.reset();
    try {
      final response = await http.post(
        Uri.parse('$_geminiUrl$_geminiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Analyze the emotional vibe of this song for a mental wellness app.\n\n'
                      'Song: "${song['name']}"\nArtist: ${song['artist']}\nAlbum: ${song['album']}\n\n'
                      'Respond EXACTLY in this format:\n'
                      'EMOTION: [one of: joy, sadness, anger, fear, surprise, neutral, hype, romantic]\n'
                      'RESPONSE: [2-3 sentences about what this song choice says about the user\'s current mood. '
                      'Be warm, Gen Z friendly, casual. Use words like "bestie", "fr", "era", "vibes", "lowkey"]\n\n'
                      'Valid emotions: joy, sadness, anger, fear, surprise, neutral, hype, romantic'
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        String emotion = 'neutral';
        String aiResponse = '';
        for (final line in text.split('\n')) {
          if (line.startsWith('EMOTION:')) {
            emotion = line.replaceFirst('EMOTION:', '').trim().toLowerCase();
          } else if (line.startsWith('RESPONSE:')) {
            aiResponse = line.replaceFirst('RESPONSE:', '').trim();
          }
        }
        if (!_emotionData.containsKey(emotion)) emotion = 'neutral';
        if (aiResponse.isEmpty) {
          aiResponse = _getFallbackResponse(emotion, song['name'] as String);
        }
        if (!mounted) return;
        setState(() {
          _detectedEmotion = emotion;
          _aiResponse = aiResponse;
          _isAnalyzing = false;
        });
        _resultController.forward();
        _saveToFirebase(song, emotion);
      } else {
        _fallbackAnalysis(song);
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
      _fallbackAnalysis(song);
    }
  }

  void _fallbackAnalysis(Map<String, dynamic> song) {
    if (!mounted) return;
    const emotion = 'neutral';
    setState(() {
      _detectedEmotion = emotion;
      _aiResponse = _getFallbackResponse(emotion, song['name'] as String);
      _isAnalyzing = false;
    });
    _resultController.forward();
    _saveToFirebase(song, emotion);
  }

  void _saveToFirebase(Map<String, dynamic> song, String emotion) {
    final emotionInfo = _emotionData[emotion]!;
    FirebaseService.saveMoodEntry(
      mode: 'music_mood',
      emotion: emotion,
      emotionLabel: emotionInfo['label'] as String,
      emoji: emotionInfo['emoji'] as String,
      points: 10,
      preview: '🎵 ${song['name']} — ${song['artist']}',
      extra: {
        'songName': song['name'],
        'artist': song['artist'],
        'album': song['album'],
      },
    );
    FirebaseService.checkAndAwardBadges();
  }

  String _getFallbackResponse(String emotion, String songName) {
    final responses = {
      'joy':      'Okay bestie, "$songName" energy is giving main character vibes fr fr ✨ You\'re clearly in your happy era!',
      'sadness':  'Ah, "$songName" hours... We see you 💙 It\'s okay to sit in your feels. You\'re not alone.',
      'anger':    '"$songName" when you\'re in your villain arc? Iconic. Channel that energy! 🔥',
      'fear':     'Listening to "$songName" when the anxiety hits different 😰 Take a breath — you\'ve got this.',
      'hype':     '"$songName" on repeat means you\'re built different today 🔥 Go conquer something!',
      'romantic': 'The "$songName" playlist era... someone\'s catching feelings 🥰 It\'s giving soft hours.',
      'neutral':  '"$songName" as your vibe? Lowkey iconic. You\'re just existing peacefully and that\'s valid 😌',
      'surprise': '"$songName" out of nowhere? Love the spontaneous energy! ✨',
    };
    return responses[emotion] ?? responses['neutral']!;
  }

  void _reset() {
    _audioPlayer.stop();
    setState(() => _isPlaying = false);
    _resultController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _selectedSong = null;
        _detectedEmotion = '';
        _aiResponse = '';
        _searchCtrl.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0020), Color(0xFF0F0F1E), Color(0xFF001A00)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('🎵 Music Mood',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF1DB954)
                            .withValues(alpha: 0.5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _spotifyToken != null
                            ? const Color(0xFF1DB954)
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _spotifyToken != null ? 'Spotify ✓' : 'Connecting...',
                      style: TextStyle(
                          color: _spotifyToken != null
                              ? const Color(0xFF1DB954)
                              : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ]),
                ),
              ]),
            ),

            Expanded(
              child: _detectedEmotion.isNotEmpty && !_isAnalyzing
                  ? _buildResult()
                  : _buildSearch(),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    final showResults = _searchResults.isNotEmpty;
    final showEmpty = !_isSearching && !_isAnalyzing && !showResults;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF1DB954).withValues(alpha: 0.4)),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            onSubmitted: (q) => _searchSongs(q),
            onChanged: (q) {
              if (q.isEmpty) _loadRecommendations();
            },
            decoration: InputDecoration(
              hintText: 'Search songs, artists, albums...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF1DB954)),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Color(0xFF1DB954), strokeWidth: 2),
                      ),
                    )
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.white38, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _loadRecommendations();
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: Color(0xFF1DB954)),
                        onPressed: () => _searchSongs(_searchCtrl.text),
                      ),
                    ]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Artist suggestions chips
        if (showEmpty) ...[
          const Text('🎤 Quick Search',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  _searchCtrl.text = s;
                  _searchSongs(s);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF1DB954)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(s,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Mood playlists
          const Text('🎭 Pick Your Vibe',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: _moodPlaylists.map((mp) {
              return GestureDetector(
                onTap: () => _searchSongs(mp['query'] as String),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0x1AFFFFFF)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(mp['emoji'] as String,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(mp['mood'] as String,
                          style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 2),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Results header
        if (showResults) ...[
          Row(children: [
            const Text('🎵 Songs',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_searchResults.length} results',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11)),
          ]),
          const SizedBox(height: 10),
        ],

        // Song results
        if (showResults)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (_, i) => _buildSongTile(_searchResults[i]),
          ),

        // Analyzing state
        if (_isAnalyzing && _selectedSong != null) ...[
          const SizedBox(height: 40),
          Center(
            child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _selectedSong!['image'].toString().isNotEmpty
                    ? Image.network(
                        _selectedSong!['image'] as String,
                        width: 120, height: 120,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 120, height: 120,
                        color: const Color(0xFF1DB954)
                            .withValues(alpha: 0.2),
                        child: const Icon(Icons.music_note,
                            color: Color(0xFF1DB954), size: 48),
                      ),
              ),
              const SizedBox(height: 16),
              Text(_selectedSong!['name'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(_selectedSong!['artist'] as String,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                  color: Color(0xFF1DB954)),
              const SizedBox(height: 16),
              const Text('🤖 Decoding your vibe...',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 14)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildSongTile(Map<String, dynamic> song) {
    final previewUrl = song['preview_url'] as String?;
    final isThisPlaying =
        _isPlaying && _currentPreviewUrl == previewUrl && previewUrl != null;

    return GestureDetector(
      onTap: () => _analyzeSong(song),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: song['image'].toString().isNotEmpty
                ? Image.network(
                    song['image'] as String,
                    width: 52, height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _musicPlaceholder(),
                  )
                : _musicPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song['name'] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(song['artist'] as String,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(song['album'] as String,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: () => _togglePreview(previewUrl),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: previewUrl != null
                      ? const Color(0xFF1DB954).withValues(alpha: 0.2)
                      : const Color(0x1AFFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isThisPlaying
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  color: previewUrl != null
                      ? const Color(0xFF1DB954)
                      : Colors.white24,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                color: Colors.white24, size: 20),
          ]),
        ]),
      ),
    );
  }

  Widget _musicPlaceholder() {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note,
          color: Color(0xFF1DB954), size: 24),
    );
  }

  Widget _buildResult() {
    final emotionInfo =
        _emotionData[_detectedEmotion] ?? _emotionData['neutral']!;
    final color = emotionInfo['color'] as Color;

    return ScaleTransition(
      scale: _resultAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          if (_selectedSong != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _selectedSong!['image'].toString().isNotEmpty
                  ? Image.network(
                      _selectedSong!['image'] as String,
                      width: 160, height: 160,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.music_note,
                          color: Colors.white, size: 64),
                    ),
            ),
            const SizedBox(height: 12),
            Text(_selectedSong!['name'] as String,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(_selectedSong!['artist'] as String,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 14)),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Column(children: [
              Text(emotionInfo['emoji'] as String,
                  style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text('Vibe: ${emotionInfo['label']}',
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(_aiResponse,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x1A9B59F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('⚡ +10 Zeno Points earned!',
                    style: TextStyle(
                        color: Color(0xFF9B59F5),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0x33FFFFFF)),
                  ),
                  child: const Center(
                    child: Text('🔄  Try Another',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      color, color.withValues(alpha: 0.6)
                    ]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('🏠  Home',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}