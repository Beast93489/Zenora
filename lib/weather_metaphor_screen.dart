import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';

class WeatherMetaphorScreen extends StatefulWidget {
  const WeatherMetaphorScreen({super.key});

  @override
  State<WeatherMetaphorScreen> createState() => _WeatherMetaphorScreenState();
}

class _WeatherMetaphorScreenState extends State<WeatherMetaphorScreen>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  bool _submitted = false;
  late AnimationController _bgController;
  late AnimationController _resultController;
  late Animation<double> _resultAnimation;
  final Stopwatch _stopwatch = Stopwatch();

  final List<Map<String, dynamic>> _weathers = [
    {
      'emoji': '☀️',
      'label': 'Sunny',
      'desc': 'Clear skies, full of energy',
      'emotion': 'joy',
      'emotionLabel': 'Joyful',
      'color': Color(0xFFFFB800),
      'bgColors': [Color(0xFF3D2800), Color(0xFF1A1000), Color(0xFF0F0F1E)],
      'response': "You're radiating sunshine today! ☀️ That positive energy is contagious — share it with someone around you and make their day brighter too!",
    },
    {
      'emoji': '🌤️',
      'label': 'Mostly Clear',
      'desc': 'Bright with a few clouds',
      'emotion': 'joy',
      'emotionLabel': 'Content',
      'color': Color(0xFFFFD166),
      'bgColors': [Color(0xFF2D2200), Color(0xFF1A1500), Color(0xFF0F0F1E)],
      'response': "Mostly clear skies ahead! 🌤️ Life feels balanced and good right now — enjoy this calm, positive headspace while it lasts.",
    },
    {
      'emoji': '⛅',
      'label': 'Partly Cloudy',
      'desc': 'Mixed feelings today',
      'emotion': 'neutral',
      'emotionLabel': 'Neutral',
      'color': Color(0xFF95A5A6),
      'bgColors': [Color(0xFF1A2030), Color(0xFF0F1520), Color(0xFF0F0F1E)],
      'response': "Mixed skies, mixed feelings — that's perfectly human. ⛅ Not every day is sunshine, and that's okay. Just go with the flow today.",
    },
    {
      'emoji': '🌥️',
      'label': 'Overcast',
      'desc': 'Heavy and grey inside',
      'emotion': 'sadness',
      'emotionLabel': 'Low',
      'color': Color(0xFF7F8C8D),
      'bgColors': [Color(0xFF151A20), Color(0xFF0F1218), Color(0xFF0F0F1E)],
      'response': "Grey skies can feel heavy. 🌥️ It's okay to have a quiet, low-energy day. Be kind to yourself — rest is productive too.",
    },
    {
      'emoji': '🌧️',
      'label': 'Rainy',
      'desc': 'Feeling a bit down',
      'emotion': 'sadness',
      'emotionLabel': 'Sad',
      'color': Color(0xFF4A90D9),
      'bgColors': [Color(0xFF0A1520), Color(0xFF081018), Color(0xFF0F0F1E)],
      'response': "Rain has its own kind of beauty — it cleans and renews. 🌧️ Let yourself feel this. Reach out to someone you trust today, you don't have to weather this alone.",
    },
    {
      'emoji': '⛈️',
      'label': 'Stormy',
      'desc': 'Everything feels intense',
      'emotion': 'anger',
      'emotionLabel': 'Angry',
      'color': Color(0xFFE74C3C),
      'bgColors': [Color(0xFF200808), Color(0xFF150505), Color(0xFF0F0F1E)],
      'response': "Storms are powerful but temporary. ⛈️ Take a few deep breaths — in for 4, hold for 4, out for 4. This intensity will pass, I promise.",
    },
    {
      'emoji': '🌪️',
      'label': 'Tornado',
      'desc': 'Completely overwhelmed',
      'emotion': 'fear',
      'emotionLabel': 'Anxious',
      'color': Color(0xFF9B59B6),
      'bgColors': [Color(0xFF1A0533), Color(0xFF120022), Color(0xFF0F0F1E)],
      'response': "When everything spins, find one thing to anchor to. 🌪️ Name 5 things you can see right now. Breathe. You've survived every storm so far — this one too.",
    },
    {
      'emoji': '🌫️',
      'label': 'Foggy',
      'desc': "Can't see the way forward",
      'emotion': 'fear',
      'emotionLabel': 'Confused',
      'color': Color(0xFFBDC3C7),
      'bgColors': [Color(0xFF1A1A2E), Color(0xFF10101E), Color(0xFF0F0F1E)],
      'response': "Fog makes it hard to see — but the path is still there. 🌫️ You don't need to see the whole road, just the next step. What's one small thing you can do right now?",
    },
    {
      'emoji': '🌈',
      'label': 'Rainbow',
      'desc': 'After the storm — hopeful!',
      'emotion': 'joy',
      'emotionLabel': 'Hopeful',
      'color': Color(0xFF00B4B4),
      'bgColors': [Color(0xFF003333), Color(0xFF001A1A), Color(0xFF0F0F1E)],
      'response': "Rainbows only come after rain — and you're here for it! 🌈 Something good is on the horizon. Keep that hopeful energy close, it'll carry you far.",
    },
    {
      'emoji': '❄️',
      'label': 'Snowy',
      'desc': 'Quiet, still, numb inside',
      'emotion': 'sadness',
      'emotionLabel': 'Numb',
      'color': Color(0xFFAED6F1),
      'bgColors': [Color(0xFF0A1520), Color(0xFF060E18), Color(0xFF0F0F1E)],
      'response': "Sometimes we go numb — it's the mind's way of protecting itself. ❄️ That's okay. Wrap yourself in something warm today, literally or figuratively. You matter.",
    },
    {
      'emoji': '🌙',
      'label': 'Night Sky',
      'desc': 'Calm, reflective, at peace',
      'emotion': 'neutral',
      'emotionLabel': 'Peaceful',
      'color': Color(0xFF9B59F5),
      'bgColors': [Color(0xFF0D0030), Color(0xFF080020), Color(0xFF0F0F1E)],
      'response': "Still nights are for deep thoughts. 🌙 There's something beautiful about sitting quietly with yourself. Reflect, rest, and let the world be still for a moment.",
    },
    {
      'emoji': '🌅',
      'label': 'Sunrise',
      'desc': 'A fresh new beginning',
      'emotion': 'joy',
      'emotionLabel': 'Renewed',
      'color': Color(0xFFFF6B35),
      'bgColors': [Color(0xFF3D1500), Color(0xFF200C00), Color(0xFF0F0F1E)],
      'response': "Every sunrise is a second chance. 🌅 Something feels fresh and new today — lean into that energy and start something you've been putting off. Today is the day!",
    },
  ];

  Map<String, dynamic>? get _selected =>
      _selectedIndex != null ? _weathers[_selectedIndex!] : null;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _resultController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _resultAnimation = CurvedAnimation(
      parent: _resultController, curve: Curves.easeOutBack);
    _stopwatch.start();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _resultController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  void _selectWeather(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
      _submitted = false;
    });
    _resultController.reset();
  }

  void _submit() async {
    if (_selectedIndex == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitted = true);
    _resultController.forward();
    final sel = _selected!;
    FirebaseService.saveMoodEntry(
      mode: 'weather',
      emotion: sel['emotion'] as String,
      emotionLabel: sel['emotionLabel'] as String,
      emoji: sel['emoji'] as String,
      points: 5,
      preview: 'Weather: ${sel['label']}',
      timeToWriteSeconds: _stopwatch.elapsed.inSeconds,
    );
    FirebaseService.checkAndAwardBadges();
  }

  void _reset() {
    _resultController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _selectedIndex = null;
        _submitted = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    final bgColors = sel != null
        ? sel['bgColors'] as List<Color>
        : [Color(0xFF1A0533), Color(0xFF0F0F1E), Color(0xFF003333)];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: bgColors,
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
                      color: Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('🌤️ Weather Metaphor',
                    style: TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ),

            Expanded(
              child: _submitted && sel != null
                  ? _buildResult(sel)
                  : _buildPicker(),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPicker() {
    return Column(children: [
      // Instruction
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          Text(
            _selected != null
                ? (_selected!['emoji'] as String)
                : '🌈',
            style: const TextStyle(fontSize: 72),
          ),
          const SizedBox(height: 8),
          Text(
            _selected != null
                ? (_selected!['label'] as String)
                : 'Pick your weather',
            style: TextStyle(
              color: _selected != null
                  ? (_selected!['color'] as Color)
                  : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selected != null
                ? (_selected!['desc'] as String)
                : 'What does your inner world feel like right now?',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ]),
      ),

      const SizedBox(height: 20),

      // Weather grid
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: _weathers.length,
          itemBuilder: (_, i) {
            final w = _weathers[i];
            final isSelected = _selectedIndex == i;
            final color = w['color'] as Color;
            return GestureDetector(
              onTap: () => _selectWeather(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.25)
                      : Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : Color(0x1AFFFFFF),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(w['emoji'] as String,
                          style: TextStyle(
                              fontSize: isSelected ? 30 : 26)),
                      const SizedBox(height: 4),
                      Text(w['label'] as String,
                          style: TextStyle(
                            color: isSelected ? color : Colors.white54,
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center),
                    ]),
              ),
            );
          },
        ),
      ),

      // Submit button
      if (_selectedIndex != null)
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    (_selected!['color'] as Color),
                    (_selected!['color'] as Color).withValues(alpha: 0.6),
                  ]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (_selected!['color'] as Color).withValues(alpha: 0.4),
                      blurRadius: 20, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('This is my weather ✨',
                      style: TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildResult(Map<String, dynamic> sel) {
    final color = sel['color'] as Color;
    return ScaleTransition(
      scale: _resultAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(sel['emoji'] as String,
                style: const TextStyle(fontSize: 90)),
            const SizedBox(height: 16),
            Text(
              sel['label'] as String,
              style: TextStyle(
                  color: color, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Feeling ${sel['emotionLabel']}',
                style: TextStyle(color: color, fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                sel['response'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 15, height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0x1A9B59F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('⚡ +5 Zeno Points earned!',
                  style: TextStyle(color: Color(0xFF9B59F5),
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 28),
            Row(children: [
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
                      child: Text('🔄  Try Again',
                          style: TextStyle(color: Colors.white70,
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
                      gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.6)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('🏠  Home',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}