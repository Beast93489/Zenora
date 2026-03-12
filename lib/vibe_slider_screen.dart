import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VibeSliderScreen extends StatefulWidget {
  const VibeSliderScreen({super.key});

  @override
  State<VibeSliderScreen> createState() => _VibeSliderScreenState();
}

class _VibeSliderScreenState extends State<VibeSliderScreen>
    with TickerProviderStateMixin {
  double _sliderValue = 0.5;
  bool _submitted = false;
  bool _isAnimating = false;
  late AnimationController _bounceController;
  late AnimationController _resultController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _resultAnimation;

  // Vibe levels from 0.0 to 1.0
  final List<Map<String, dynamic>> _vibes = [
    {
      'range': [0.0, 0.15],
      'emoji': '😭',
      'label': 'Terrible',
      'sublabel': 'Really rough day',
      'emotion': 'sadness',
      'color': Color(0xFF1A5276),
      'gradientColors': [Color(0xFF1A5276), Color(0xFF0F0F1E)],
      'response': "That sounds really hard. 💙 You don't have to be okay right now — just be gentle with yourself today.",
    },
    {
      'range': [0.15, 0.30],
      'emoji': '😔',
      'label': 'Low',
      'sublabel': 'Not feeling great',
      'emotion': 'sadness',
      'color': Color(0xFF4A90D9),
      'gradientColors': [Color(0xFF2C3E6B), Color(0xFF0F0F1E)],
      'response': "It's okay to have low days. 🌧️ Take it one hour at a time — things will shift.",
    },
    {
      'range': [0.30, 0.45],
      'emoji': '😕',
      'label': 'Meh',
      'sublabel': 'Could be better',
      'emotion': 'neutral',
      'color': Color(0xFF7F8C8D),
      'gradientColors': [Color(0xFF2C3440), Color(0xFF0F0F1E)],
      'response': "Meh days are valid too. 🌫️ Sometimes the best thing to do is just get through it.",
    },
    {
      'range': [0.45, 0.58],
      'emoji': '😐',
      'label': 'Neutral',
      'sublabel': 'Just existing',
      'emotion': 'neutral',
      'color': Color(0xFF95A5A6),
      'gradientColors': [Color(0xFF1A2A3A), Color(0xFF0F0F1E)],
      'response': "Neutral is perfectly fine. 😌 Not every moment needs to be intense — calm is powerful.",
    },
    {
      'range': [0.58, 0.72],
      'emoji': '🙂',
      'label': 'Decent',
      'sublabel': 'Doing alright',
      'emotion': 'neutral',
      'color': Color(0xFF00B4B4),
      'gradientColors': [Color(0xFF003333), Color(0xFF0F0F1E)],
      'response': "Decent is underrated! 🌱 You're doing well — keep that steady energy going.",
    },
    {
      'range': [0.72, 0.86],
      'emoji': '😊',
      'label': 'Good',
      'sublabel': 'Feeling positive',
      'emotion': 'joy',
      'color': Color(0xFFFFB800),
      'gradientColors': [Color(0xFF3D2800), Color(0xFF0F0F1E)],
      'response': "That's great to hear! ✨ You're in a good headspace — use this energy to do something you love.",
    },
    {
      'range': [0.86, 1.01],
      'emoji': '🤩',
      'label': 'Amazing',
      'sublabel': 'On top of the world!',
      'emotion': 'joy',
      'color': Color(0xFFFF6B35),
      'gradientColors': [Color(0xFF4A1A00), Color(0xFF0F0F1E)],
      'response': "You're absolutely thriving! 🔥 This energy is contagious — spread it around today!",
    },
  ];

  Map<String, dynamic> get _currentVibe {
    for (final vibe in _vibes) {
      final range = vibe['range'] as List<double>;
      if (_sliderValue >= range[0] && _sliderValue < range[1]) {
        return vibe;
      }
    }
    return _vibes.last;
  }

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultAnimation = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    HapticFeedback.selectionClick();
    final oldVibe = _currentVibe;
    setState(() => _sliderValue = value);
    if (oldVibe['label'] != _currentVibe['label']) {
      _bounceController.forward(from: 0);
    }
  }

  void _submitVibe() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAnimating = true;
      _submitted = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _resultController.forward();
    if (!mounted) return;
    setState(() => _isAnimating = false);
  }

  void _reset() {
    _resultController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _submitted = false;
        _sliderValue = 0.5;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final vibe = _currentVibe;
    final color = vibe['color'] as Color;
    final gradColors = vibe['gradientColors'] as List<Color>;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradColors[0],
              const Color(0xFF0F0F1E),
              const Color(0xFF003333),
            ],
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
                      '⚡ Vibe Slider',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _submitted
                    ? _buildResult(vibe, color)
                    : _buildSlider(vibe, color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(Map<String, dynamic> vibe, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'How are you\nvibing right now?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'Drag the slider — no thinking required',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),

          const SizedBox(height: 56),

          // Big emoji
          ScaleTransition(
            scale: _bounceAnimation,
            child: Text(
              vibe['emoji'] as String,
              style: const TextStyle(fontSize: 90),
            ),
          ),

          const SizedBox(height: 16),

          // Label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey(vibe['label']),
              children: [
                Text(
                  vibe['label'] as String,
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vibe['sublabel'] as String,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Vibe level indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _vibes.map((v) {
              final isActive = v['label'] == vibe['label'];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? (v['color'] as Color)
                      : Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 18),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
              activeTrackColor: color,
              inactiveTrackColor: Color(0x33FFFFFF),
              thumbColor: Colors.white,
              overlayColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _sliderValue,
              onChanged: _onSliderChanged,
            ),
          ),

          // Emoji scale
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _vibes
                  .map((v) => Text(v['emoji'] as String,
                      style: TextStyle(
                          fontSize: v['label'] == vibe['label'] ? 22 : 16,
                          color: v['label'] == vibe['label']
                              ? Colors.white
                              : Colors.white38)))
                  .toList(),
            ),
          ),

          const SizedBox(height: 48),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isAnimating ? null : _submitVibe,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Lock In My Vibe ⚡',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> vibe, Color color) {
    return ScaleTransition(
      scale: _resultAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vibe['emoji'] as String,
                style: const TextStyle(fontSize: 100)),
            const SizedBox(height: 20),
            Text(
              'Vibe: ${vibe['label']}',
              style: TextStyle(
                color: color,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vibe['sublabel'] as String,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Text(
                vibe['response'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0x1A9B59F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '⚡ +5 Zeno Points earned!',
                style: TextStyle(
                  color: Color(0xFF9B59F5),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0x33FFFFFF)),
                      ),
                      child: const Center(
                        child: Text(
                          '🔄  Check Again',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold),
                        ),
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
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '🏠  Home',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}