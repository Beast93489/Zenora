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

  // Emotion counts for summary
  Map<String, int> get _emotionCounts {
    final counts = <String, int>{};
    for (final entry in _moodEntries) {
      final emotion = entry['emotion'] as String;
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    return counts;
  }

  String get _dominantMood {
    final counts = _emotionCounts;
    if (counts.isEmpty) return 'neutral';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await FirebaseService.getMoodEntries();
    if (!mounted) return;
    setState(() {
      _moodEntries = entries.map((e) {
        final emotion = e['emotion'] as String? ?? 'neutral';
        final colorMap = {
          'joy':      Color(0xFFFFB800),
          'sadness':  Color(0xFF4A90D9),
          'anger':    Color(0xFFE74C3C),
          'fear':     Color(0xFF9B59B6),
          'surprise': Color(0xFF00B4B4),
          'disgust':  Color(0xFF27AE60),
          'neutral':  Color(0xFF95A5A6),
        };
        final ts = e['timestamp'];
        String dateStr = 'Today';
        String timeStr = '';
        if (ts != null) {
          final dt = (ts as dynamic).toDate() as DateTime;
          final now = DateTime.now();
          final diff = now.difference(dt).inDays;
          if (diff == 0) dateStr = 'Today';
          else if (diff == 1) dateStr = 'Yesterday';
          else dateStr = '${dt.day} ${_monthName(dt.month)}';
          timeStr = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
        }
        return {
          'date': dateStr,
          'time': timeStr,
          'mode': _modeName(e['mode'] as String? ?? 'journal'),
          'modeIcon': _modeIcon(e['mode'] as String? ?? 'journal'),
          'emotion': emotion,
          'emoji': e['emoji'] as String? ?? '😐',
          'label': e['emotionLabel'] as String? ?? 'Neutral',
          'color': colorMap[emotion] ?? Color(0xFF95A5A6),
          'preview': e['preview'] as String? ?? '',
          'points': e['points'] as int? ?? 5,
        };
      }).toList();
      _loading = false;
    });
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  String _modeName(String mode) {
    const names = {
      'journal':     'Journal',
      'emoji_board': 'Emoji Board',
      'vibe_slider': 'Vibe Slider',
      'weather':     'Weather',
    };
    return names[mode] ?? 'Journal';
  }

  String _modeIcon(String mode) {
    const icons = {
      'journal':     '✍️',
      'emoji_board': '😊',
      'vibe_slider': '⚡',
      'weather':     '🌤️',
    };
    return icons[mode] ?? '✍️';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '📊 Mood History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5C2D91), Color(0xFF007A7A)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '📋  Timeline'),
                    Tab(text: '📈  Summary'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTimeline(),
                    _buildSummary(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9B59F5)),
      );
    }
    if (_moodEntries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('😊', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No entries yet!',
                style: TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Start logging your mood to see history here',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }
    return Column(
      children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF5C2D91), Color(0xFF007A7A)])
                        : null,
                    color: selected ? null : Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Color(0x33FFFFFF),
                    ),
                  ),
                  child: Text(
                    _filters[i],
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 16),

        // Entry list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _moodEntries.length,
            itemBuilder: (context, index) {
              final entry = _moodEntries[index];
              final showDateHeader = index == 0 ||
                  _moodEntries[index - 1]['date'] != entry['date'];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDateHeader) ...[
                    if (index != 0) const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        entry['date'] as String,
                        style: const TextStyle(
                          color: Color(0xFF9B59F5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
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
      ],
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final color = entry['color'] as Color;
    return Container(
      decoration: BoxDecoration(
        color: Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Emotion emoji
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(entry['emoji'] as String,
                    style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry['label'] as String,
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        entry['time'] as String,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry['preview'] as String,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry['modeIcon']} ${entry['mode']}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${entry['points']} pts',
                        style: const TextStyle(
                          color: Color(0xFF9B59F5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final counts = _emotionCounts;
    final total = _moodEntries.length;
    final dominant = _dominantMood;

    final emotionInfo = {
      'joy':      {'emoji': '😊', 'label': 'Joyful',    'color': Color(0xFFFFB800)},
      'sadness':  {'emoji': '😔', 'label': 'Sad',       'color': Color(0xFF4A90D9)},
      'anger':    {'emoji': '😤', 'label': 'Angry',     'color': Color(0xFFE74C3C)},
      'fear':     {'emoji': '😰', 'label': 'Anxious',   'color': Color(0xFF9B59B6)},
      'surprise': {'emoji': '😲', 'label': 'Surprised', 'color': Color(0xFF00B4B4)},
      'disgust':  {'emoji': '🤢', 'label': 'Disgusted', 'color': Color(0xFF27AE60)},
      'neutral':  {'emoji': '😐', 'label': 'Neutral',   'color': Color(0xFF95A5A6)},
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly overview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C2D91), Color(0xFF007A7A)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'This Week',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  emotionInfo[dominant]?['emoji'] as String? ?? '😐',
                  style: const TextStyle(fontSize: 52),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mostly ${emotionInfo[dominant]?['label'] ?? 'Neutral'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total entries logged this week',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _statCard('🔥', '3', 'Day Streak'),
              const SizedBox(width: 12),
              _statCard('⚡', '${total * 8}', 'Zeno Points'),
              const SizedBox(width: 12),
              _statCard('📝', '$total', 'Total Entries'),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'Emotion Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Emotion bars
          ...counts.entries.map((entry) {
            final info = emotionInfo[entry.key]!;
            final pct = entry.value / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(info['emoji'] as String,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        info['label'] as String,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        '${entry.value}x  (${(pct * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: Color(0x1AFFFFFF),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          info['color'] as Color),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // AI Insight card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFF9B59F5).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🤖', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      'Zenora Insight',
                      style: TextStyle(
                        color: Color(0xFF9B59F5),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'You\'ve been logging consistently! Your mood trends show more positive entries in the evenings. '
                  'Try journaling in the morning too — it can help set a positive tone for the day. 🌅',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0x1AFFFFFF)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}