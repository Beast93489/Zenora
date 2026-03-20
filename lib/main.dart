import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'mood_canvas_screen.dart';
import 'voice_mode_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'consent_screen.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ── Firebase Messaging setup ──────────────────────────────
  final messaging = FirebaseMessaging.instance;
  
  // Request permission
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // Get FCM token and save to Firestore
  final token = await messaging.getToken();
  if (token != null) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }
  
  runApp(const ZenoraApp());
}

class ZenoraApp extends StatelessWidget {
  const ZenoraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,  // ← add this
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

  final List<String> _loadingTexts = [
    'loading serotonin... please wait 🧠',
    'manifesting good vibes rn ✨',
    'asking the universe fr fr... 🌌',
    'your AI dost is waking up ☕',
    'sab theek ho jayega, promise 🫶',
    'mood check incoming... 📲',
  ];

  late String _loadingText;

  @override
  void initState() {
    super.initState();
    _loadingText = (_loadingTexts..shuffle()).first;

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
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()));
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
                        BoxShadow(color: const Color(0xFF5C2D91),
                            blurRadius: 30, spreadRadius: 5)
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
                            fontSize: 48, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 8)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Know Your Mind',
                      style: TextStyle(
                          fontSize: 18, color: Color(0xFF00B4B4),
                          fontStyle: FontStyle.italic, letterSpacing: 2)),
                ]),
              ),
            ),
            const SizedBox(height: 80),
            FadeTransition(
              opacity: _textFade,
              child: Column(children: [
                SizedBox(
                  width: 40, height: 40,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C2D91)),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(_loadingText,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13, letterSpacing: 0.5)),
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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _zenoPoints = 0;
  int _streak = 0;
  int _totalEntries = 0;
  String _userName = 'Yaar';
  int _selectedMoodIndex = -1;
  bool _moodCheckedIn = false;
  late AnimationController _cardPulseController;
  late Animation<double> _cardPulse;

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😊', 'label': 'Happy',   'emotion': 'joy',     'msg': 'ek dum mast vibe! 🔥'},
    {'emoji': '😔', 'label': 'Sad',     'emotion': 'sadness', 'msg': 'arey yaar... we got you 🫶'},
    {'emoji': '😤', 'label': 'Angry',   'emotion': 'anger',   'msg': 'shant ho ja bhai/behen 😤'},
    {'emoji': '😰', 'label': 'Anxious', 'emotion': 'fear',    'msg': 'sab theek ho jayega 🧘'},
    {'emoji': '😐', 'label': 'Neutral', 'emotion': 'neutral', 'msg': 'theek thaak hu yaar 😌'},
  ];

  final List<String> _genZGreetings = [
    'main character energy loading... 💫',
    'no thoughts, just vibes ✨',
    'it\'s giving wellness era 💜',
    'arey mood log karo pehle 😤',
    'sharma ji ka beta bhi ye use karta hai 👀',
    'Ctrl+Z nahi hota life mein, log karo 📝',
    'teri anxiety Ki Ch...inta hum krenge 💀',
    'kuch bhi ho jaye, hum hain yahan 🕊️',
    'pagal ho? (affectionately) 🤗',
    'Crush ki yaad aa rahi hai? write it out! 🥲',
    'Phukega kya? (in the nicest way possible) 😎',
    ' Himachal se ho? (because that\'s the vibe I\'m getting) 🏔️',
    'BGMI ya Free Fire? (just trying to connect) 🎮',
    'chhote se chhota problem bhi bada lagta hai, but we\'ll get through it together 🫂',
    'tumhari feelings ko samajhne ki koshish kar raha hoon, thoda time do 🧠',
    'Teri ex ki yaad aa rahi hai? (because that\'s a mood) 🥲',
  ];

  // Mode card data with unique gradients
  final List<Map<String, dynamic>> _modes = [
    {
      'emoji': '✍️', 'title': 'Journal', 'subtitle': 'spill the tea ☕',
      'colors': [Color(0xFF5C2D91), Color(0xFFE91E8C)],
      'screen': 'journal',
    },
    {
      'emoji': '🎤', 'title': 'Voice', 'subtitle': 'bol daal yaar',
      'colors': [Color(0xFF007A7A), Color(0xFF00D4FF)],
      'screen': 'voice',
    },
    {
      'emoji': '😊', 'title': 'Emoji Board', 'subtitle': 'pick ur vibe',
      'colors': [Color(0xFFFF8C00), Color(0xFFFFD700)],
      'screen': 'emoji',
    },
    {
      'emoji': '🎵', 'title': 'Music Mood', 'subtitle': 'songs don\'t lie',
      'colors': [Color(0xFF1DB954), Color(0xFF006400)],
      'screen': 'music',
    },
    {
      'emoji': '🎨', 'title': 'Mood Canvas', 'subtitle': 'paint ur soul',
      'colors': [Color(0xFFFF69B4), Color(0xFF9B59B6)],
      'screen': 'canvas'
    },
    {
      'emoji': '🌤️', 'title': 'Weather', 'subtitle': 'what\'s ur forecast',
      'colors': [Color(0xFF2193b0), Color(0xFF6dd5ed)],
      'screen': 'weather',
    },
    {
      'emoji': '⚡', 'title': 'Vibe Slider', 'subtitle': '2 sec check-in',
      'colors': [Color(0xFFFF6B35), Color(0xFFFFB800)],
      'screen': 'vibe',
    },
    {
      'emoji': '🃏', 'title': 'Scenarios', 'subtitle': 'relatable hits',
      'colors': [Color(0xFF1A4A7A), Color(0xFF00B4B4)],
      'screen': 'scenario',
    },
  ];

  late String _currentGreeting;

  @override
  void initState() {
    super.initState();
    _currentGreeting = (_genZGreetings..shuffle()).first;
    _cardPulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _cardPulse = Tween<double>(begin: 1.0, end: 1.02).animate(
        CurvedAnimation(parent: _cardPulseController, curve: Curves.easeInOut));
    _loadUserData();
  }

  @override
  void dispose() {
    _cardPulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final profile = await FirebaseService.getUserProfile();
    if (!mounted) return;
    if (profile != null) {
      setState(() {
        _zenoPoints   = (profile['zenoPoints'] as int?) ?? 0;
        _streak       = (profile['streak'] as int?) ?? 0;
        _totalEntries = (profile['totalEntries'] as int?) ?? 0;
        final fullName = (profile['name'] as String?) ?? 'Yaar';
        _userName = fullName.split(' ').first;
      });
    }
  }

  Future<void> _checkInMood(int index) async {
    if (_moodCheckedIn) return;
    HapticFeedback.mediumImpact();
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
      preview: 'Quick check-in: ${mood['label']}',
    );
    await _loadUserData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${mood['emoji']} ${mood['msg']}  +5 pts!',
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      backgroundColor: const Color(0xFF5C2D91),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getStreakMessage() {
    if (_streak == 0) return 'start your streak today! 🌱';
    if (_streak == 1) return 'okay we\'re doing this 🔥';
    if (_streak < 7)  return '$_streak din ka streak, slay! 💅';
    if (_streak < 30) return '$_streak days?? built different fr 🐐';
    return '$_streak days! legend status 👑';
  }

  void _navigateTo(String? screen, BuildContext context) {
    if (screen == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Coming soon yaar! 🚧', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF5C2D91),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Widget? page;
    switch (screen) {
      case 'journal':  page = const JournalScreen(); break;
      case 'emoji':    page = const EmojiBoardScreen(); break;
      case 'music':    page = const MusicMoodScreen(); break;
      case 'weather':  page = const WeatherMetaphorScreen(); break;
      case 'vibe':     page = const VibeSliderScreen(); break;
      case 'scenario': page = const ScenarioCardsScreen(); break;
      case 'canvas':   page = const MoodCanvasScreen(); break;
      case 'voice':    page = const VoiceModeScreen(); break;
    }
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    }
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getGreeting(),
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13, letterSpacing: 1)),
                            const SizedBox(height: 2),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF9B59F5), Color(0xFF00B4B4)],
                              ).createShader(bounds),
                              child: Text(_userName,
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                            const SizedBox(height: 2),
                            Text(_currentGreeting,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen())),
                        child: ScaleTransition(
                          scale: _cardPulse,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF5C2D91).withValues(alpha: 0.4),
                                    blurRadius: 12, spreadRadius: 1)
                              ],
                            ),
                            child: Row(children: [
                              const Text('🔥', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_streak ${_streak == 1 ? 'day' : 'days'}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  Text(_getStreakMessage(),
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 9),
                                      maxLines: 1),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Mood Check-in ────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('How are you feeling today?',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          if (_moodCheckedIn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27AE60).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('noted 📝',
                                  style: TextStyle(
                                      color: Color(0xFF27AE60), fontSize: 10)),
                            ),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          _moodCheckedIn
                              ? 'bhai/behen kal phir aana! 🌟'
                              : 'tap karo, no judgment here 😌',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(_moods.length, (i) {
                            final isSelected = _selectedMoodIndex == i;
                            return GestureDetector(
                              onTap: () => _checkInMood(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.elasticOut,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF5C2D91)
                                      : const Color(0x12FFFFFF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF9B59F5)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                        color: const Color(0xFF9B59F5).withValues(alpha: 0.4),
                                        blurRadius: 10)
                                  ] : null,
                                ),
                                child: Text(_moods[i]['emoji'] as String,
                                    style: TextStyle(
                                        fontSize: isSelected ? 28 : 24)),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Express Yourself ─────────────────────────
                  Row(children: [
                    const Text('Express Yourself',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    const Text('(no filter needed 😭)',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ]),
                  const SizedBox(height: 14),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: _modes.length,
                    itemBuilder: (_, i) => _buildModeCard(_modes[i], context),
                  ),

                  const SizedBox(height: 20),

                  // ── Zeno Points ──────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x1AFFFFFF)),
                      ),
                      child: Column(children: [
                        Row(children: [
                          const Text('⚡', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
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
                                  fontSize: 14)),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const SizedBox(width: 34),
                          Text(
                            _zenoPoints == 0
                                ? 'log mood, earn points, simple hai yaar 😌'
                                : '${100 - (_zenoPoints % 100)} pts to next level 🎯',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: pointsProgress,
                            minHeight: 8,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF9B59F5)),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Stats ────────────────────────────────────
                  Row(children: [
                    _statCard('📝', '$_totalEntries',
                        _totalEntries == 0 ? 'kuch toh likho yaar' : 'Total Entries',
                        const Color(0xFF00B4B4)),
                    const SizedBox(width: 12),
                    _statCard('🔥', '$_streak',
                        _streak == 0 ? 'start today!' : '${_streak == 1 ? 'Day' : 'Days'} Streak',
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
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF9B59F5),
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            if (index == 1) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('upar se mode choose karo yaar 😤',
                    style: TextStyle(color: Colors.white)),
                backgroundColor: Color(0xFF5C2D91),
                behavior: SnackBarBehavior.floating,
              ));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const MoodHistoryScreen()));
            } else if (index == 3) {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ProfileScreen()));
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline_rounded), label: 'Express'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded), label: 'History'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(Map<String, dynamic> mode, BuildContext context) {
    final colors = mode['colors'] as List<Color>;
    final screen = mode['screen'] as String?;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _navigateTo(screen, context);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors[0].withValues(alpha: 0.7),
              colors[1].withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: colors[0].withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: colors[0].withValues(alpha: 0.25),
                blurRadius: 12, spreadRadius: 0,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            // Background glow circle
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[0].withValues(alpha: 0.15),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(mode['emoji'] as String,
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 6),
                  Text(mode['title'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  Text(mode['subtitle'] as String,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
            // Coming soon badge
            if (screen == null)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('soon',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 9)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color, fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Auth Wrapper ──────────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const WelcomeScreen();
        }
        return _ConsentChecker(key: ValueKey(snapshot.data!.uid));
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0F1E),
      body: Center(child: CircularProgressIndicator(
          color: Color(0xFF9B59F5))),
    );
  }
}

class _ConsentChecker extends StatefulWidget {
  const _ConsentChecker({super.key});
  @override
  State<_ConsentChecker> createState() => _ConsentCheckerState();
}

class _ConsentCheckerState extends State<_ConsentChecker> {
  bool _loading = true;
  bool _hasConsent = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final consent = await FirebaseService.hasGivenConsent();
    if (!mounted) return;
    setState(() {
      _hasConsent = consent;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1E),
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF9B59F5)),
            SizedBox(height: 16),
            Text('Checking your profile...', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        )),
      );
    }
    if (!_hasConsent) {
      return ConsentScreen(
        nextScreen: const HomeScreen(),
        onConsent: () => setState(() => _hasConsent = true),
      );
    }
    return const HomeScreen();
  }
}