import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';

class ZenoRewardsScreen extends StatefulWidget {
  const ZenoRewardsScreen({super.key});
  @override
  State<ZenoRewardsScreen> createState() => _ZenoRewardsScreenState();
}

class _ZenoRewardsScreenState extends State<ZenoRewardsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _levelController;
  late Animation<double> _fadeAnim;
  late Animation<double> _levelAnim;
  int _zenoPoints = 0;
  bool _loading = true;

  // Level definitions
  static const List<Map<String, dynamic>> _levels = [
    {
      'min': 0, 'max': 99,
      'emoji': '🌱', 'title': 'Seedling',
      'genZ': 'just started the journey fr',
      'color': Color(0xFF27AE60),
      'perks': ['Basic mood tracking', 'Journal access', 'Emoji board'],
    },
    {
      'min': 100, 'max': 299,
      'emoji': '🔥', 'title': 'Vibe Checker',
      'genZ': 'okay we\'re doing this bestie',
      'color': Color(0xFFFF6B35),
      'perks': ['All basic features', 'Mood history calendar', 'Streak tracking', '🎭 Unlock: Scenario Cards'],
    },
    {
      'min': 300, 'max': 599,
      'emoji': '⚡', 'title': 'Mood Master',
      'genZ': 'main character arc activated',
      'color': Color(0xFF9B59F5),
      'perks': ['All previous perks', 'Weekly mood insights', 'Badge collection', '🎵 Unlock: Music Mood AI analysis'],
    },
    {
      'min': 600, 'max': 999,
      'emoji': '💜', 'title': 'Zenora OG',
      'genZ': 'you\'re built different fr fr',
      'color': Color(0xFFE91E8C),
      'perks': ['All previous perks', 'Priority AI responses', 'Exclusive OG badge', '🎨 Unlock: Advanced Canvas modes'],
    },
    {
      'min': 1000, 'max': 999999,
      'emoji': '💎', 'title': 'Diamond Mind',
      'genZ': 'legend status unlocked 👑',
      'color': Color(0xFF4A90D9),
      'perks': ['All features unlocked', 'Diamond badge', 'Research contributor status', '🏆 Unlock: Campus Vibe Map (coming soon)'],
    },
  ];

  // How to earn points
  static const List<Map<String, dynamic>> _earning = [
    {'emoji': '✍️', 'mode': 'Journal', 'pts': '+10 pts', 'desc': 'write ur feelings'},
    {'emoji': '🎤', 'mode': 'Voice Mode', 'pts': '+15 pts', 'desc': 'highest earner fr'},
    {'emoji': '😊', 'mode': 'Emoji Board', 'pts': '+5 pts', 'desc': 'quick vibe check'},
    {'emoji': '🎵', 'mode': 'Music Mood', 'pts': '+8 pts', 'desc': 'songs don\'t lie'},
    {'emoji': '🎨', 'mode': 'Mood Canvas', 'pts': '+8 pts', 'desc': 'paint ur soul'},
    {'emoji': '🌤️', 'mode': 'Weather', 'pts': '+5 pts', 'desc': 'what\'s ur forecast'},
    {'emoji': '⚡', 'mode': 'Vibe Slider', 'pts': '+5 pts', 'desc': '2 sec check-in'},
    {'emoji': '🃏', 'mode': 'Scenarios', 'pts': '+8 pts', 'desc': 'relatable hits'},
    {'emoji': '🔥', 'mode': 'Daily Streak', 'pts': '+5 pts', 'desc': 'consistency wins'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _levelController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _levelAnim = CurvedAnimation(parent: _levelController, curve: Curves.easeOutBack);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final profile = await FirebaseService.getUserProfile();
    if (!mounted) return;
    setState(() {
      _zenoPoints = (profile?['zenoPoints'] as int?) ?? 0;
      _loading = false;
    });
    _levelController.forward();
  }

  Map<String, dynamic> get _currentLevel {
    for (final level in _levels.reversed) {
      if (_zenoPoints >= (level['min'] as int)) return level;
    }
    return _levels.first;
  }

  Map<String, dynamic>? get _nextLevel {
    final idx = _levels.indexOf(_currentLevel);
    if (idx < _levels.length - 1) return _levels[idx + 1];
    return null;
  }

  double get _levelProgress {
    final current = _currentLevel;
    final min = current['min'] as int;
    final max = current['max'] as int;
    if (max == 999999) return 1.0;
    return ((_zenoPoints - min) / (max - min)).clamp(0.0, 1.0);
  }

  int get _ptsToNextLevel {
    final next = _nextLevel;
    if (next == null) return 0;
    return (next['min'] as int) - _zenoPoints;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentLevel;
    final next = _nextLevel;
    final color = current['color'] as Color;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.3),
              const Color(0xFF0F0F1E),
              const Color(0xFF003333),
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF9B59F5)))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      // ── Header ──────────────────────────────
                      Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 18)),
                        ),
                        const SizedBox(width: 12),
                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('⚡ Zeno Points', style: TextStyle(
                              color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.bold)),
                          Text('your wellness journey level', style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                        ]),
                      ]),

                      const SizedBox(height: 28),

                      // ── Current level card ──────────────────
                      AnimatedBuilder(
                        animation: _levelController,
                        builder: (_, __) => Transform.scale(
                          scale: _levelAnim.value,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withValues(alpha: 0.3),
                                  color.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                              boxShadow: [BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 20, spreadRadius: 2)],
                            ),
                            child: Column(children: [
                              Text(current['emoji'] as String,
                                  style: const TextStyle(fontSize: 56)),
                              const SizedBox(height: 8),
                              Text(current['title'] as String,
                                  style: TextStyle(color: color, fontSize: 28,
                                      fontWeight: FontWeight.w900, letterSpacing: 2)),
                              const SizedBox(height: 4),
                              Text(current['genZ'] as String,
                                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
                              const SizedBox(height: 20),

                              // Points display
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('$_zenoPoints', style: TextStyle(
                                    color: color, fontSize: 42,
                                    fontWeight: FontWeight.w900)),
                                const SizedBox(width: 8),
                                const Text('pts', style: TextStyle(
                                    color: Colors.white54, fontSize: 18)),
                              ]),

                              const SizedBox(height: 16),

                              // Progress bar
                              if (next != null) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(current['title'] as String,
                                        style: TextStyle(color: color, fontSize: 11)),
                                    Text('${next['title']} in $_ptsToNextLevel pts',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: _levelProgress),
                                    duration: const Duration(milliseconds: 1000),
                                    curve: Curves.easeOut,
                                    builder: (_, val, __) => LinearProgressIndicator(
                                      value: val, minHeight: 10,
                                      backgroundColor: Colors.white12,
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('MAX LEVEL ACHIEVED 🏆',
                                      style: TextStyle(color: Colors.white,
                                          fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ]),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Current level perks ─────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(current['emoji'] as String,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text('${current['title']} Perks',
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 12),
                          ...(current['perks'] as List<String>).map((perk) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Icon(Icons.check_circle,
                                  color: color, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(perk, style: const TextStyle(
                                  color: Colors.white70, fontSize: 13))),
                            ]),
                          )),
                        ]),
                      ),

                      const SizedBox(height: 20),

                      // ── All levels ──────────────────────────
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('🏆 All Levels',
                            style: TextStyle(color: Colors.white,
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),

                      ...List.generate(_levels.length, (i) {
                        final level = _levels[i];
                        final lvlColor = level['color'] as Color;
                        final isCurrentLevel = level == _currentLevel;
                        final isUnlocked = _zenoPoints >= (level['min'] as int);
                        final isLast = i == _levels.length - 1;

                        return Column(children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              if (!isUnlocked) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      '${level['min']} pts needed — ${(level['min'] as int) - _zenoPoints} more to go! 🎯',
                                      style: const TextStyle(color: Colors.white)),
                                  backgroundColor: const Color(0xFF5C2D91),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCurrentLevel
                                    ? lvlColor.withValues(alpha: 0.15)
                                    : isUnlocked
                                        ? const Color(0x0DFFFFFF)
                                        : const Color(0x08FFFFFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCurrentLevel
                                      ? lvlColor.withValues(alpha: 0.6)
                                      : isUnlocked
                                          ? lvlColor.withValues(alpha: 0.2)
                                          : const Color(0x0FFFFFFF),
                                  width: isCurrentLevel ? 2 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Text(
                                  isUnlocked
                                      ? (level['emoji'] as String)
                                      : '🔒',
                                  style: TextStyle(
                                      fontSize: 28,
                                      color: isUnlocked ? null
                                          : Colors.white.withValues(alpha: 0.2)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(level['title'] as String,
                                          style: TextStyle(
                                              color: isUnlocked ? Colors.white : Colors.white24,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold)),
                                      if (isCurrentLevel) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: lvlColor.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text('CURRENT',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ]),
                                    const SizedBox(height: 2),
                                    Text(
                                      isUnlocked
                                          ? (level['genZ'] as String)
                                          : '${level['min']} pts needed',
                                      style: TextStyle(
                                          color: isUnlocked
                                              ? Colors.white38
                                              : Colors.white.withValues(alpha: 0.15),
                                          fontSize: 11),
                                    ),
                                  ],
                                )),
                                Text(
                                  '${level['min']}${(level['max'] as int) < 999999 ? '-${level['max']}' : '+'}',
                                  style: TextStyle(
                                      color: isUnlocked ? lvlColor : Colors.white12,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ]),
                            ),
                          ),
                          if (!isLast) Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 28),
                            width: 2, height: 16,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ]);
                      }),

                      const SizedBox(height: 24),

                      // ── How to earn ─────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('💡 How to Earn Points',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('log more, earn more, level up fr',
                              style: TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 16),
                          ..._earning.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(children: [
                              Text(e['emoji'] as String,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e['mode'] as String,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  Text(e['desc'] as String,
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11)),
                                ],
                              )),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9B59F5).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(e['pts'] as String,
                                    style: const TextStyle(
                                        color: Color(0xFF9B59F5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ]),
                          )),
                        ]),
                      ),

                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
        ),
      ),
    );
  }
}