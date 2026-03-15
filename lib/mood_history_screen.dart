import 'package:flutter/material.dart';
import 'firebase_service.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});
  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Week', 'Month'];
  List<Map<String, dynamic>> _moodEntries = [];
  bool _loading = true;
  Map<String, dynamic>? _userProfile;

  final Map<String, Map<String, dynamic>> _emotionMeta = {
    'joy':      {'emoji': '😊', 'color': Color(0xFFFFB800), 'label': 'Joyful',   'dot': Color(0xFFFFB800)},
    'sadness':  {'emoji': '😔', 'color': Color(0xFF4A90D9), 'label': 'Sad',      'dot': Color(0xFF4A90D9)},
    'anger':    {'emoji': '😤', 'color': Color(0xFFE74C3C), 'label': 'Angry',    'dot': Color(0xFFE74C3C)},
    'fear':     {'emoji': '😰', 'color': Color(0xFF9B59B6), 'label': 'Anxious',  'dot': Color(0xFF9B59B6)},
    'surprise': {'emoji': '😲', 'color': Color(0xFF00B4B4), 'label': 'Surprised','dot': Color(0xFF00B4B4)},
    'disgust':  {'emoji': '🤢', 'color': Color(0xFF27AE60), 'label': 'Disgusted','dot': Color(0xFF27AE60)},
    'neutral':  {'emoji': '😐', 'color': Color(0xFF95A5A6), 'label': 'Neutral',  'dot': Color(0xFF95A5A6)},
    'hype':     {'emoji': '🔥', 'color': Color(0xFFFF6B35), 'label': 'Hyped',    'dot': Color(0xFFFF6B35)},
    'romantic': {'emoji': '🥰', 'color': Color(0xFFFF69B4), 'label': 'Romantic', 'dot': Color(0xFFFF69B4)},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final entries = await FirebaseService.getMoodEntries(limit: 100);
    final profile = await FirebaseService.getUserProfile();
    if (!mounted) return;
    setState(() {
      _moodEntries = entries.map((e) {
        final emotion = e['emotion'] as String? ?? 'neutral';
        final meta = _emotionMeta[emotion] ?? _emotionMeta['neutral']!;
        final ts = e['timestamp'];
        String dateStr = 'Today';
        String timeStr = '';
        DateTime? dt;
        if (ts != null) {
          try {
            dt = (ts as dynamic).toDate() as DateTime;
            final now = DateTime.now();
            final diff = now.difference(dt).inDays;
            if (diff == 0) dateStr = 'Today';
            else if (diff == 1) dateStr = 'Yesterday';
            else dateStr = '${dt.day} ${_monthName(dt.month)}';
            timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {}
        }
        return {
          'date': dateStr,
          'time': timeStr,
          'dt': dt,
          'mode': e['mode'] as String? ?? 'journal',
          'modeIcon': _modeIcon(e['mode'] as String? ?? 'journal'),
          'modeLabel': _modeLabel(e['mode'] as String? ?? 'journal'),
          'emotion': emotion,
          'emoji': e['emoji'] as String? ?? (meta['emoji'] as String),
          'label': e['emotionLabel'] as String? ?? (meta['label'] as String),
          'color': meta['color'] as Color,
          'preview': e['preview'] as String? ?? '',
          'points': e['points'] as int? ?? 5,
        };
      }).toList();
      _userProfile = profile;
      _loading = false;
    });
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  String _modeIcon(String mode) {
    const icons = {
      'journal': '✍️', 'emoji_board': '😊', 'vibe_slider': '⚡',
      'weather': '🌤️', 'music_mood': '🎵', 'scenario_cards': '🃏',
      'mood_canvas': '🎨', 'emoji_checkin': '👋',
    };
    return icons[mode] ?? '📝';
  }

  String _modeLabel(String mode) {
    const labels = {
      'journal': 'spilled tea ☕', 'emoji_board': 'emoji vibes 😊',
      'vibe_slider': 'vibe check ⚡', 'weather': 'weather mood 🌤️',
      'music_mood': 'music hours 🎵', 'scenario_cards': 'scenario reacted 🃏',
      'mood_canvas': 'painted feels 🎨', 'emoji_checkin': 'quick check-in 👋',
    };
    return labels[mode] ?? '📝 logged';
  }

  // ── Analytics helpers ─────────────────────────────────────────
  List<Map<String, dynamic>> get _weekEntries {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _moodEntries.where((e) {
      final dt = e['dt'] as DateTime?;
      return dt != null && dt.isAfter(weekAgo);
    }).toList();
  }

  List<Map<String, dynamic>> get _lastWeekEntries {
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _moodEntries.where((e) {
      final dt = e['dt'] as DateTime?;
      return dt != null && dt.isAfter(twoWeeksAgo) && dt.isBefore(weekAgo);
    }).toList();
  }

  Map<String, int> _countEmotions(List<Map<String, dynamic>> entries) {
    final counts = <String, int>{};
    for (final e in entries) {
      final emotion = e['emotion'] as String;
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    return counts;
  }

  String get _dominantEmotion {
    final counts = _countEmotions(_weekEntries);
    if (counts.isEmpty) return 'neutral';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String get _dominantMode {
    if (_moodEntries.isEmpty) return 'journal';
    final counts = <String, int>{};
    for (final e in _moodEntries) {
      final mode = e['mode'] as String;
      counts[mode] = (counts[mode] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // ── Mood Weather Report ───────────────────────────────────────
  String _getMoodWeather() {
    final dominant = _dominantEmotion;
    final count = _weekEntries.length;
    if (count == 0) return '🌫️ No data yet — start logging!';
    switch (dominant) {
      case 'joy':     return '☀️ Clear skies ahead! Mostly sunny vibes this week';
      case 'sadness': return '🌧️ Rainy week detected — ${_countEmotions(_weekEntries)['sadness'] ?? 0} sad days';
      case 'anger':   return '⛈️ Stormy! High pressure system detected this week';
      case 'fear':    return '🌪️ Tornado warning — anxiety levels elevated this week';
      case 'neutral': return '⛅ Partly cloudy — stable but unremarkable week';
      case 'hype':    return '🔥 Heat wave! You\'re absolutely on fire this week';
      default:        return '🌤️ Mixed forecast — quite the rollercoaster week!';
    }
  }

  // ── Personality Badge ─────────────────────────────────────────
  Map<String, String> _getPersonalityBadge() {
    final mode = _dominantMode;
    const badges = {
      'journal':       {'badge': '✍️ The Overthinker',    'desc': 'you journal more than you sleep fr'},
      'emoji_board':   {'badge': '😊 The Visual Feeler',  'desc': 'words are overrated, emojis understand'},
      'vibe_slider':   {'badge': '⚡ The Impulse Logger',  'desc': '2 seconds and done, respect the efficiency'},
      'weather':       {'badge': '🌤️ The Metaphor Queen', 'desc': 'life is a vibe and weather is the vibe check'},
      'music_mood':    {'badge': '🎵 The Playlist Feeler', 'desc': 'your spotify knows you better than you do'},
      'scenario_cards':{'badge': '🃏 The Scenario Reactor','desc': 'always ready for the plot twist'},
      'mood_canvas':   {'badge': '🎨 The Artsy Soul',     'desc': 'picasso of feelings, no cap'},
      'emoji_checkin': {'badge': '👋 The Quick Logger',   'desc': 'efficient king/queen of mood tracking'},
    };
    return Map<String, String>.from(
        badges[mode] ?? {'badge': '🌟 The Wellness Warrior', 'desc': 'using all modes like a legend'});
  }

  // ── Mood Roast ────────────────────────────────────────────────
  String _getMoodRoast() {
    final counts = _countEmotions(_weekEntries);
    final total = _weekEntries.length;
    if (total == 0) return 'arey kuch toh log karo... ghost mode mat bano 👻';

    final joyCount = counts['joy'] ?? 0;
    final sadCount = counts['sadness'] ?? 0;
    final angryCount = counts['anger'] ?? 0;
    final fearCount = counts['fear'] ?? 0;
    final neutralCount = counts['neutral'] ?? 0;

    if (joyCount == total) return 'itna khush? suspicious hai yaar... kuch toh chhupa raha/rahi hai 👀';
    if (sadCount >= total * 0.6) return 'bhai/behen theek ho? 3 baar sad log kiya hai 💀 chai pi lo';
    if (angryCount >= total * 0.5) return 'villain arc toh hai par ek break le lo yaar 😤 sab theek hoga';
    if (fearCount >= total * 0.5) return 'anxiety checked in aur checkout nahi kiya abhi tak 😰';
    if (neutralCount == total) return 'robot energy giving... kuch toh feel karo yaar 🤖';
    if (total < 3) return 'sirf ${total} entry? app download ki thi use karne ke liye 😭';
    return 'mixed bag week tha — life ka full drama chal raha tha 🎭';
  }

  // ── Weekly comparison ─────────────────────────────────────────
  String _getWeeklyComparison() {
    final thisWeek = _weekEntries.length;
    final lastWeek = _lastWeekEntries.length;
    final thisJoy = (_countEmotions(_weekEntries)['joy'] ?? 0);
    final lastJoy = (_countEmotions(_lastWeekEntries)['joy'] ?? 0);

    if (lastWeek == 0) return '📊 First week of data — nothing to compare yet!';

    final joyDiff = thisJoy - lastJoy;
    final entryDiff = thisWeek - lastWeek;

    if (joyDiff > 0 && entryDiff >= 0) {
      return '📈 ${joyDiff}x more happy moments than last week! glow up confirmed ✨';
    } else if (joyDiff < 0) {
      return '📉 Fewer happy days than last week — rough week tha, it happens 💜';
    } else if (entryDiff > 0) {
      return '📊 More entries than last week! consistency king/queen 👑';
    } else {
      return '📊 Similar week as before — steady as she goes 😌';
    }
  }

  // ── GitHub-style calendar ─────────────────────────────────────
  Map<String, Color> _buildCalendarData() {
    final calMap = <String, Color>{};
    for (final e in _moodEntries) {
      final dt = e['dt'] as DateTime?;
      if (dt == null) continue;
      final key = '${dt.year}-${dt.month}-${dt.day}';
      final color = (e['color'] as Color?) ?? const Color(0xFF95A5A6);
      calMap[key] = color; // last emotion of day wins
    }
    return calMap;
  }

  List<Map<String, dynamic>> get _filteredEntries {
    if (_selectedFilter == 0) return _moodEntries;
    if (_selectedFilter == 1) return _weekEntries;
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return _moodEntries.where((e) {
      final dt = e['dt'] as DateTime?;
      return dt != null && dt.isAfter(monthAgo);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF0F0F1E), Color(0xFF003333)],
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
                const Text('📊 Mood History',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: _loadData,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white54, size: 20),
                  ),
                ),
              ]),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '📋  Timeline'),
                  Tab(text: '📈  Summary'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                              color: Color(0xFF9B59F5)),
                          SizedBox(height: 16),
                          Text('loading your feels...',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTimeline(),
                        _buildSummary(),
                      ],
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final entries = _filteredEntries;
    return Column(children: [
      // Filter chips
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(_filters.length, (i) {
            final selected = _selectedFilter == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF5C2D91), Color(0xFF007A7A)])
                      : null,
                  color: selected ? null : const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : const Color(0x33FFFFFF),
                  ),
                ),
                child: Text(_filters[i],
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.white54,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
            );
          }),
        ),
      ),

      const SizedBox(height: 16),

      // Entry list
      Expanded(
        child: entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('👀', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text('kuch toh log karo yaar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFilter == 0
                          ? 'abhi tak koi entry nahi hai'
                          : 'is period mein koi entry nahi',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF9B59F5),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final showDateHeader = index == 0 ||
                        entries[index - 1]['date'] != entry['date'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader) ...[
                          if (index != 0) const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 8, top: 4),
                            child: Text(
                              entry['date'] as String,
                              style: const TextStyle(
                                  color: Color(0xFF9B59F5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1),
                            ),
                          ),
                        ],
                        _buildEntryCard(entry),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
              ),
      ),
    ]);
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final color = entry['color'] as Color;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
            child: Center(
              child: Text(entry['emoji'] as String,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(entry['label'] as String,
                      style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(entry['time'] as String,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ]),
                const SizedBox(height: 3),
                Text(
                  (entry['preview'] as String).isNotEmpty
                      ? entry['preview'] as String
                      : entry['modeLabel'] as String,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(entry['modeLabel'] as String,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  Text('+${entry['points']} pts',
                      style: const TextStyle(
                          color: Color(0xFF9B59F5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSummary() {
    final counts = _countEmotions(_weekEntries);
    final total = _weekEntries.length;
    final dominant = _dominantEmotion;
    final dominantMeta = _emotionMeta[dominant] ?? _emotionMeta['neutral']!;
    final badge = _getPersonalityBadge();
    final calData = _buildCalendarData();
    final zenoPoints = (_userProfile?['zenoPoints'] as int?) ?? 0;
    final streak = (_userProfile?['streak'] as int?) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        // ── Mood Weather Report ──────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (dominantMeta['color'] as Color).withValues(alpha: 0.3),
                const Color(0xFF0F0F1E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: (dominantMeta['color'] as Color)
                    .withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Text(dominantMeta['emoji'] as String,
                style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(
              total == 0 ? 'No entries yet' : _getMoodWeather(),
              style: TextStyle(
                  color: dominantMeta['color'] as Color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text('$total entries this week',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12)),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Stats row ────────────────────────────────────
        Row(children: [
          _miniStat('⚡', '$zenoPoints', 'Zeno Points', const Color(0xFF9B59F5)),
          const SizedBox(width: 10),
          _miniStat('🔥', '$streak', 'Day Streak', const Color(0xFFFF6B35)),
          const SizedBox(width: 10),
          _miniStat('📝', '${_moodEntries.length}', 'Total Logs', const Color(0xFF00B4B4)),
        ]),

        const SizedBox(height: 16),

        // ── Weekly comparison ────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Text(_getWeeklyComparison(),
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center),
        ),

        const SizedBox(height: 16),

        // ── GitHub-style Mood Calendar ───────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Text('🗓️', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Mood Calendar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              const Text('your month at a glance',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 14),
              _buildCalendar(calData),
              const SizedBox(height: 10),
              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: _emotionMeta.entries.take(6).map((e) {
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: e.value['dot'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(e.value['label'] as String,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 9)),
                  ]);
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Personality Badge ────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x1A9B59F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF9B59F5).withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Text('🏷️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Personality Badge',
                      style: TextStyle(
                          color: Color(0xFF9B59F5),
                          fontSize: 11,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(badge['badge']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(badge['desc']!,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Emotion Breakdown ────────────────────────────
        if (total > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Emotion Breakdown',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...counts.entries.map((entry) {
                  final pct = entry.value / total;
                  final meta = _emotionMeta[entry.key] ??
                      _emotionMeta['neutral']!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(meta['emoji'] as String,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(meta['label'] as String,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const Spacer(),
                          Text(
                              '${entry.value}x  (${(pct * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ]),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: const Color(0x1AFFFFFF),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                meta['color'] as Color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Mood Roast ───────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Zenora\'s Honest Take',
                      style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(_getMoodRoast(),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5)),
                ],
              ),
            ),
          ]),
        ),

        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _buildCalendar(Map<String, Color> calData) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDay = DateTime(now.year, now.month, 1);
    final startOffset = firstDay.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: startOffset + daysInMonth,
      itemBuilder: (_, i) {
        if (i < startOffset) return const SizedBox();
        final day = i - startOffset + 1;
        final key = '${now.year}-${now.month}-$day';
        final color = calData[key];
        final isToday = day == now.day;
        return Container(
          decoration: BoxDecoration(
            color: color?.withValues(alpha: 0.7) ??
                const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(4),
            border: isToday
                ? Border.all(color: Colors.white, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text('$day',
                style: TextStyle(
                    color: color != null ? Colors.white : Colors.white24,
                    fontSize: 8,
                    fontWeight: isToday
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ),
        );
      },
    );
  }

  Widget _miniStat(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 9),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}