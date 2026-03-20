import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';
import 'scenario_cache_service.dart';

class ScenarioCardsScreen extends StatefulWidget {
  const ScenarioCardsScreen({super.key});
  @override
  State<ScenarioCardsScreen> createState() => _ScenarioCardsScreenState();
}

class _ScenarioCardsScreenState extends State<ScenarioCardsScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final List<String?> _reactions = [];
  bool _sessionComplete = false;
  bool _loadingScenarios = true;
  bool _loadingInsight = false;
  String _aiInsight = '';
  List<Map<String, dynamic>> _scenarios = [];

  late AnimationController _cardController;
  late AnimationController _resultController;
  late Animation<double> _cardAnimation;
  late Animation<double> _resultAnimation;
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _cardAnimation = CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack);
    _resultController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _resultAnimation = CurvedAnimation(parent: _resultController, curve: Curves.easeOutBack);
    _swipeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _swipeAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, 0))
        .animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeIn));
    _stopwatch.start();
    _generateScenarios();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _resultController.dispose();
    _swipeController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _generateScenarios() async {
    setState(() => _loadingScenarios = true);
    try {
      final scenarios = await ScenarioCacheService.getScenariosForUser();
      if (!mounted) return;
      setState(() {
        _scenarios = scenarios;
        _reactions.clear();
        _reactions.addAll(List.filled(_scenarios.length, null));
        _loadingScenarios = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingScenarios = false);
    }
  }

  Future<void> _generateInsight(Map<String, int> counts, String dominant) async {
    if (!mounted) return;
    setState(() => _loadingInsight = true);
    final insight = await ScenarioCacheService.generateInsight(
      counts: counts, dominant: dominant, scenarios: _scenarios);
    if (!mounted) return;
    setState(() { _aiInsight = insight; _loadingInsight = false; });
  }

  void _selectReaction(Map<String, dynamic> reaction) async {
    HapticFeedback.mediumImpact();
    setState(() => _reactions[_currentIndex] = reaction['emotion'] as String);
    await _swipeController.forward();
    if (!mounted) return;
    _swipeController.reset();
    if (_currentIndex < _scenarios.length - 1) {
      setState(() => _currentIndex++);
      _cardController.forward(from: 0);
    } else {
      setState(() => _sessionComplete = true);
      _resultController.forward();
      _saveSession();
    }
  }

  void _saveSession() {
    final emotionCounts = <String, int>{};
    for (final r in _reactions) {
      if (r != null) emotionCounts[r] = (emotionCounts[r] ?? 0) + 1;
    }
    if (emotionCounts.isEmpty) return;
    final dominant = emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    const labelMap = {'joy': 'Joyful', 'sadness': 'Sad', 'anger': 'Angry',
      'fear': 'Anxious', 'surprise': 'Surprised', 'neutral': 'Neutral'};
    const emojiMap = {'joy': '😊', 'sadness': '😔', 'anger': '😤',
      'fear': '😰', 'surprise': '😲', 'neutral': '😐'};
    FirebaseService.saveMoodEntry(
      mode: 'scenario_cards', emotion: dominant,
      emotionLabel: labelMap[dominant] ?? 'Neutral',
      emoji: emojiMap[dominant] ?? '😐', points: 10,
      preview: 'Scenario Cards: ${_scenarios.length} reactions',
      extra: {'reactions': _reactions, 'emotionCounts': emotionCounts},
      timeToWriteSeconds: _stopwatch.elapsed.inSeconds,
    );
    FirebaseService.checkAndAwardBadges();
    _generateInsight(emotionCounts, dominant);
  }

  void _playAgain() {
    setState(() {
      _currentIndex = 0; _reactions.clear();
      _sessionComplete = false; _aiInsight = ''; _loadingInsight = false;
    });
    _resultController.reset();
    _generateScenarios();
  }

  Map<String, int> get _emotionCounts {
    final counts = <String, int>{};
    for (final r in _reactions) {
      if (r != null) counts[r] = (counts[r] ?? 0) + 1;
    }
    return counts;
  }

  String get _dominantEmotion {
    final c = _emotionCounts;
    if (c.isEmpty) return 'neutral';
    return c.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF0F0F1E), Color(0xFF003333)],
          ),
        ),
        child: SafeArea(
          child: _loadingScenarios ? _buildLoading()
              : _sessionComplete ? _buildResult()
              : _buildCards(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18))),
          const SizedBox(width: 16),
          const Text('🃏 Scenario Cards', style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ),
      const Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🤖', style: TextStyle(fontSize: 64)),
        SizedBox(height: 24),
        Text('Loading scenarios...', style: TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('AI generating relatable situations for you',
            style: TextStyle(color: Colors.white38, fontSize: 13), textAlign: TextAlign.center),
        SizedBox(height: 32),
        CircularProgressIndicator(color: Color(0xFF9B59F5)),
      ])),
    ]);
  }

  Widget _buildCards() {
    if (_scenarios.isEmpty) {
      return Column(children: [
        Padding(padding: const EdgeInsets.all(20),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18))),
          ])),
        const Expanded(child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('😅', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Scenarios failed to load', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 8),
          Text('Check your connection yaar', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ]))),
      ]);
    }

    final scenario = _scenarios[_currentIndex];
    final progress = (_currentIndex + 1) / _scenarios.length;
    // Safely get reactions list
    final rawReactions = scenario['reactions'];
    final reactions = rawReactions is List ? rawReactions : [];

    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(children: [
          GestureDetector(onTap: () => Navigator.pop(context),
            child: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18))),
          const SizedBox(width: 16),
          const Text('🃏 Scenario Cards', style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${_currentIndex + 1}/${_scenarios.length}',
              style: const TextStyle(color: Color(0xFF9B59F5), fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ]),
      ),

      const SizedBox(height: 12),

      // Progress bar
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: progress, minHeight: 6,
            backgroundColor: const Color(0x1AFFFFFF),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B59F5))))),

      const SizedBox(height: 12),

      // Category badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x1A00B4B4), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00B4B4).withValues(alpha: 0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🤖', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text('${scenario['category'] ?? 'General'} • AI Generated',
              style: const TextStyle(color: Color(0xFF00B4B4), fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ])),

      const SizedBox(height: 12),

      // Card
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SlideTransition(
            position: _swipeAnimation,
            child: ScaleTransition(
              scale: _cardAnimation,
              child: Container(
                width: double.infinity, padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0x33FFFFFF))),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(scenario['emoji'] as String? ?? '🤔',
                      style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 20),
                  const Text('If this happened to you...',
                      style: TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 1)),
                  const SizedBox(height: 14),
                  Text(scenario['scenario'] as String? ?? 'Something happened...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 17,
                          height: 1.6, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),
                  const Text('How would you feel?', style: TextStyle(
                      color: Color(0xFF9B59F5), fontSize: 14,
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
                ]),
              ),
            ),
          ),
        ),
      ),

      // Reactions — FIXED overflow
      if (reactions.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: reactions.length <= 4
              ? GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: reactions.map((r) {
                    final reaction = r as Map<String, dynamic>;
                    return _reactionButton(reaction);
                  }).toList(),
                )
              : Wrap(
                  spacing: 10, runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: reactions.map((r) {
                    final reaction = r as Map<String, dynamic>;
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 52) / 2,
                      child: _reactionButton(reaction),
                    );
                  }).toList(),
                ),
        )
      else
        Padding(
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: _playAgain,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
                borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('Skip this one 🔄',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          )),
    ]);
  }

  Widget _reactionButton(Map<String, dynamic> reaction) {
    return GestureDetector(
      onTap: () => _selectReaction(reaction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33FFFFFF))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(reaction['emoji'] as String? ?? '😐',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Flexible(child: Text(reaction['label'] as String? ?? 'React',
              style: const TextStyle(color: Colors.white70, fontSize: 13,
                  fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildResult() {
    final dominant = _dominantEmotion;
    final counts = _emotionCounts;
    final total = _reactions.where((r) => r != null).length;

    final emotionInfo = {
      'joy':      {'emoji': '😊', 'color': const Color(0xFFFFB800), 'label': 'Joyful',
        'fallback': 'Your reactions show positive energy! You find the bright side. 🌟'},
      'sadness':  {'emoji': '😔', 'color': const Color(0xFF4A90D9), 'label': 'Sensitive',
        'fallback': 'You feel things deeply — that\'s emotional intelligence. 💙'},
      'anger':    {'emoji': '😤', 'color': const Color(0xFFE74C3C), 'label': 'Passionate',
        'fallback': 'You have strong reactions and clear boundaries. 🔥'},
      'fear':     {'emoji': '😰', 'color': const Color(0xFF9B59B6), 'label': 'Cautious',
        'fallback': 'You\'re thoughtful and aware of potential problems. 💜'},
      'surprise': {'emoji': '😲', 'color': const Color(0xFF00B4B4), 'label': 'Open',
        'fallback': 'Life keeps surprising you and you stay open. ✨'},
      'neutral':  {'emoji': '😌', 'color': const Color(0xFF95A5A6), 'label': 'Balanced',
        'fallback': 'Most situations don\'t shake you easily. ⚖️'},
    };

    final info = emotionInfo[dominant] ?? emotionInfo['neutral']!;
    final color = info['color'] as Color;

    return ScaleTransition(
      scale: _resultAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Align(alignment: Alignment.centerLeft,
            child: GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)))),
          const SizedBox(height: 20),
          Text(info['emoji'] as String, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          Text('You\'re ${info['label']}',
              style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Based on $total scenario reactions',
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3))),
            child: _loadingInsight
                ? const Column(children: [
                    SizedBox(height: 8),
                    CircularProgressIndicator(color: Color(0xFF9B59F5), strokeWidth: 2),
                    SizedBox(height: 12),
                    Text('🤖 Generating your insight...',
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                    SizedBox(height: 8),
                  ])
                : Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('🤖', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text('AI Insight', style: TextStyle(
                          color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 10),
                    Text(_aiInsight.isNotEmpty ? _aiInsight : (info['fallback'] as String),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
                  ]),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x1AFFFFFF))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Reaction Breakdown', style: TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...counts.entries.map((e) {
                final pct = e.value / total;
                final eInfo = emotionInfo[e.key] ?? emotionInfo['neutral']!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(eInfo['emoji'] as String, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(eInfo['label'] as String,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const Spacer(),
                      Text('${e.value}x  (${(pct * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: pct, minHeight: 6,
                        backgroundColor: const Color(0x1AFFFFFF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            eInfo['color'] as Color))),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0x1A9B59F5), borderRadius: BorderRadius.circular(20)),
            child: const Text('⚡ +10 Zeno Points earned!',
                style: TextStyle(color: Color(0xFF9B59F5),
                    fontWeight: FontWeight.bold, fontSize: 14))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: _playAgain,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33FFFFFF))),
                child: const Center(child: Text('🔄  New Scenarios',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)))))),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
                  borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('🏠  Home',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}