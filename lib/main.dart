import 'package:flutter/material.dart';
import 'journal_screen.dart';
import 'mood_history_screen.dart';
import 'emoji_board_screen.dart';
import 'vibe_slider_screen.dart';
import 'profile_screen.dart';
import 'weather_metaphor_screen.dart';
import 'welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scenario_cards_screen.dart';
import 'music_mood_screen.dart';
import 'firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ZenoraApp());
}

class ZenoraApp extends StatelessWidget {
  const ZenoraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'sans-serif'),
      home: const SplashScreen(),
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login':   (_) => const LoginScreen(),
        '/home':    (_) => const HomeScreen(),
      },
    );
  }
}

// ── Splash Screen ─────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textController, curve: Curves.easeOut));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      // Check if user is already logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF0F0F1E), Color(0xFF003333)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) => FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5C2D91), Color(0xFF007A7A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF5C2D91),
                            blurRadius: 30,
                            spreadRadius: 5)
                      ],
                    ),
                    child: const Center(
                      child: Text('◉',
                          style: TextStyle(fontSize: 60, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textFade,
                child: Column(children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF9B59F5), Color(0xFF00B4B4)],
                    ).createShader(bounds),
                    child: const Text('ZENORA',
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 8)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Know Your Mind',
                      style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF00B4B4),
                          fontStyle: FontStyle.italic,
                          letterSpacing: 2)),
                ]),
              ),
            ),
            const SizedBox(height: 80),
            FadeTransition(
              opacity: _textFade,
              child: Column(children: [
                SizedBox(
                  width: 40, height: 40,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF5C2D91)),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Loading your wellness journey...',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        letterSpacing: 1)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home Screen ───────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _zenoPoints = 0;
  int _streak = 0;
  int _totalEntries = 0;
  String _userName = 'Friend';
  int _selectedMoodIndex = -1;
  bool _moodCheckedIn = false;

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😊', 'label': 'Happy',   'emotion': 'joy'},
    {'emoji': '😔', 'label': 'Sad',     'emotion': 'sadness'},
    {'emoji': '😤', 'label': 'Angry',   'emotion': 'anger'},
    {'emoji': '😰', 'label': 'Anxious', 'emotion': 'fear'},
    {'emoji': '😐', 'label': 'Neutral', 'emotion': 'neutral'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profile = await FirebaseService.getUserProfile();
    if (!mounted) return;
    if (profile != null) {
      setState(() {
        _zenoPoints   = (profile['zenoPoints'] as int?) ?? 0;
        _streak       = (profile['streak'] as int?) ?? 0;
        _totalEntries = (profile['totalEntries'] as int?) ?? 0;
        _userName     = (profile['name'] as String?)?.split(' ').first ?? 'Friend';
      });
    }
  }

  Future<void> _checkInMood(int index) async {
    if (_moodCheckedIn) return;
    setState(() {
      _selectedMoodIndex = index;
      _moodCheckedIn = true;
    });
    final mood = _moods[index];
    await FirebaseService.saveMoodEntry(
      mode: 'emoji_checkin',
      emotion: mood['emotion'] as String,
      emotionLabel: mood['label'] as String,
      emoji: mood['emoji'] as String,
      points: 5,
      preview: 'Quick mood check-in: ${mood['label']}',
    );
    await _loadUserData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${mood['emoji']} Mood logged! +5 Zeno Points 💜',
          style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF5C2D91),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGenZGreeting() {
    final greetings = [
      'no thoughts, just vibes ✨',
      'main character energy loading... 💫',
      'it\'s giving wellness era 💜',
      'slay, then log your mood 🔥',
      'bestie, how are we doing? 🫶',
    ];
    final hour = DateTime.now().hour;
    return greetings[hour % greetings.length];
  }

  @override
  Widget build(BuildContext context) {
    final pointsProgress = (_zenoPoints % 100) / 100;

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
          child: RefreshIndicator(
            onRefresh: _loadUserData,
            color: const Color(0xFF9B59F5),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getGreeting(),
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                  letterSpacing: 1)),
                          const SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF9B59F5), Color(0xFF00B4B4)],
                            ).createShader(bounds),
                            child: Text(_userName,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                          const SizedBox(height: 2),
                          Text(_getGenZGreeting(),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5C2D91),
                                  Color(0xFF007A7A)
                                ]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            const Text('🔥',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              '$_streak ${_streak == 1 ? 'day' : 'days'}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Mood check-in
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('How are you feeling today?',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          _moodCheckedIn
                              ? 'Mood logged! Come back tomorrow 🌟'
                              : 'Tap any mood to begin your check-in',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(_moods.length, (i) {
                            final isSelected = _selectedMoodIndex == i;
                            return GestureDetector(
                              onTap: () => _checkInMood(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF5C2D91)
                                      : const Color(0x12FFFFFF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF9B59F5)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(_moods[i]['emoji'] as String,
                                    style: TextStyle(
                                        fontSize: isSelected ? 30 : 26)),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Express Yourself
                  const Text('Express Yourself',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _ModeCard(
                        emoji: '✍️', title: 'Journal',
                        color: const Color(0xFF5C2D91),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const JournalScreen())),
                      ),
                      _ModeCard(
                        emoji: '🎤', title: 'Voice',
                        color: const Color(0xFF007A7A),
                      ),
                      _ModeCard(
                        emoji: '😊', title: 'Emoji Board',
                        color: const Color(0xFF2D5C91),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const EmojiBoardScreen())),
                      ),
                      _ModeCard(
                        emoji: '🎵', title: 'Music Mood',
                        color: const Color(0xFF1A5C1A),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const MusicMoodScreen())),
                      ),
                      _ModeCard(
                        emoji: '🎨', title: 'Mood Canvas',
                        color: const Color(0xFF1A7A4A),
                      ),
                      _ModeCard(
                        emoji: '🌤️', title: 'Weather',
                        color: const Color(0xFF2D6091),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const WeatherMetaphorScreen())),
                      ),
                      _ModeCard(
                        emoji: '⚡', title: 'Vibe Slider',
                        color: const Color(0xFF2D915C),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const VibeSliderScreen())),
                      ),
                      _ModeCard(
                        emoji: '🃏', title: 'Scenarios',
                        color: const Color(0xFF1A4A7A),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const ScenarioCardsScreen())),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Zeno Points bar
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: const Color(0x1AFFFFFF)),
                      ),
                      child: Row(children: [
                        const Text('⚡',
                            style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Text('Zeno Points',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const Spacer(),
                                Text('$_zenoPoints pts',
                                    style: const TextStyle(
                                        color: Color(0xFF9B59F5),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ]),
                              const SizedBox(height: 2),
                              Text(
                                '${100 - (_zenoPoints % 100)} pts to next level',
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: pointsProgress,
                                  minHeight: 8,
                                  backgroundColor: Colors.white12,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF9B59F5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Stats row
                  Row(children: [
                    _statCard('📝', '$_totalEntries', 'Total Entries',
                        const Color(0xFF00B4B4)),
                    const SizedBox(width: 12),
                    _statCard('🔥', '$_streak',
                        _streak == 1 ? 'Day Streak' : 'Days Streak',
                        const Color(0xFFFF6B35)),
                  ]),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A0533),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 10)
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF9B59F5),
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            if (index == 0) {
              // Already home
            } else if (index == 1) {
              // Express — scroll to grid
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pick a mode above to express yourself! 💜',
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: Color(0xFF5C2D91),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (index == 2) {
              Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const MoodHistoryScreen()));
            } else if (index == 3) {
              Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const ProfileScreen()));
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline_rounded),
                label: 'Express'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded), label: 'History'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}

// ── Mode Card ─────────────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Auth Wrapper ──────────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1E),
            body: Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF9B59F5)),
            ),
          );
        }
        if (snapshot.hasData) return const HomeScreen();
        return const WelcomeScreen();
      },
    );
  }
}