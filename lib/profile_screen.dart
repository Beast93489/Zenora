import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'dart:math';

// ── Theme provider ───────────────────────────────────────────────
enum ZenoraTheme { dark, purple, teal }

class ThemeNotifier extends ChangeNotifier {
  ZenoraTheme _theme = ZenoraTheme.dark;
  ZenoraTheme get theme => _theme;
  void setTheme(ZenoraTheme t) { _theme = t; notifyListeners(); }
  List<Color> get bgGradient {
    switch (_theme) {
      case ZenoraTheme.purple: return [Color(0xFF2D0B5C), Color(0xFF1A0533), Color(0xFF0D0020)];
      case ZenoraTheme.teal:   return [Color(0xFF003333), Color(0xFF0F0F1E), Color(0xFF001A1A)];
      default:                 return [Color(0xFF1A0533), Color(0xFF0F0F1E), Color(0xFF003333)];
    }
  }
}

final themeNotifier = ThemeNotifier();

// ── Profile Screen ───────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _avatarController;
  late AnimationController _badgeController;
  late Animation<double> _fadeAnim;
  late Animation<double> _avatarScale;
  late Animation<double> _avatarGlow;

  // Firebase data
  String _name       = '';
  String _username   = '';
  String _university = '';
  String _joinedDate = '';
  int    _zenoPoints = 0;
  int    _streak     = 0;
  int    _totalEntries = 0;
  List<String> _earnedBadges = [];
  List<Map<String, dynamic>> _weekMoods = [];
  String _dominantMood = 'Joyful';
  bool _loading = true;

  bool _notifDaily    = true;
  bool _notifInsights = true;
  bool _notifStreak   = true;

  // Gen Z badge definitions
  final List<Map<String, dynamic>> _allBadges = [
    {
      'id': 'first_entry',
      'icon': '🌱', 'title': 'Baby Steps',
      'desc': 'logged first mood, we stan',
      'genZ': 'origin story unlocked',
      'color': Color(0xFF27AE60), 'earned': false,
    },
    {
      'id': 'streak_3',
      'icon': '🔥', 'title': '3-Day Streak',
      'desc': 'consistent king/queen',
      'genZ': '3 days? okay we\'re doing this',
      'color': Color(0xFFFF6B35), 'earned': false,
    },
    {
      'id': 'streak_7',
      'icon': '⚡', 'title': 'Week Warrior',
      'desc': '7 days no cap',
      'genZ': 'slay consistently bestie',
      'color': Color(0xFFFFB800), 'earned': false,
    },
    {
      'id': 'vibe_master',
      'icon': '🎵', 'title': 'Vibe Master',
      'desc': 'vibe slider addict fr',
      'genZ': 'no thoughts just vibes',
      'color': Color(0xFF9B59F5), 'earned': false,
    },
    {
      'id': 'journaler',
      'icon': '✍️', 'title': 'Main Character',
      'desc': '10 journal entries',
      'genZ': 'writing their origin story',
      'color': Color(0xFFE91E8C), 'earned': false,
    },
    {
      'id': 'emotion_explorer',
      'icon': '🎭', 'title': 'Emotion Otaku',
      'desc': 'felt all 7 emotions',
      'genZ': 'full emotional spectrum unlocked',
      'color': Color(0xFF00B4B4), 'earned': false,
    },
    {
      'id': 'streak_30',
      'icon': '💎', 'title': 'Diamond Era',
      'desc': '30-day streak legend',
      'genZ': 'you\'re built different fr',
      'color': Color(0xFF4A90D9), 'earned': false,
    },
    {
      'id': 'music_lover',
      'icon': '🎧', 'title': 'Playlist Feeler',
      'desc': 'music mood 5 times',
      'genZ': 'spotify knows ur feels',
      'color': Color(0xFF1DB954), 'earned': false,
    },
    {
      'id': 'artist',
      'icon': '🎨', 'title': 'Artsy Soul',
      'desc': 'painted 3 mood canvases',
      'genZ': 'picasso of feelings no cap',
      'color': Color(0xFFFF69B4), 'earned': false,
    },
  ];

  final List<Map<String, dynamic>> _settings = [
    {'icon': Icons.notifications_outlined, 'label': 'Notifications', 'color': Color(0xFF9B59F5)},
    {'icon': Icons.lock_outline,           'label': 'Privacy',        'color': Color(0xFF00B4B4)},
    {'icon': Icons.palette_outlined,       'label': 'Theme',          'color': Color(0xFFFFB800)},
    {'icon': Icons.help_outline,           'label': 'Help & Support', 'color': Color(0xFF27AE60)},
    {'icon': Icons.info_outline,           'label': 'About Zenora',   'color': Color(0xFF4A90D9)},
    {'icon': Icons.logout,                 'label': 'Sign Out',       'color': Color(0xFFE74C3C)},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _avatarController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _badgeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _avatarScale = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut));
    _avatarGlow = Tween<double>(begin: 15.0, end: 30.0).animate(
        CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut));
    themeNotifier.addListener(_onThemeChange);
    _loadData();
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    _fadeController.dispose();
    _avatarController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final profile = await FirebaseService.getUserProfile();
    final entries = await FirebaseService.getMoodEntries(limit: 50);
    final weekEntries = await FirebaseService.getWeekEntries();

    if (!mounted) return;

    // Build week moods
    final List<Map<String, dynamic>> weekMoods = [];
    final now = DateTime.now();
    final emotionEmoji = {
      'joy': '😊', 'sadness': '😔', 'anger': '😤',
      'fear': '😰', 'surprise': '😲', 'neutral': '😐',
      'hype': '🔥', 'romantic': '🥰', 'disgust': '🤢',
    };
    final emotionColor = {
      'joy': Color(0xFFFFB800), 'sadness': Color(0xFF4A90D9),
      'anger': Color(0xFFE74C3C), 'fear': Color(0xFF9B59B6),
      'surprise': Color(0xFF00B4B4), 'neutral': Color(0xFF95A5A6),
      'hype': Color(0xFFFF6B35), 'romantic': Color(0xFFFF69B4),
    };
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayEntries = weekEntries.where((e) {
        final ts = e['timestamp'];
        if (ts == null) return false;
        try {
          final dt = (ts as dynamic).toDate() as DateTime;
          return dt.day == day.day && dt.month == day.month;
        } catch (_) { return false; }
      }).toList();
      final emotion = dayEntries.isNotEmpty
          ? (dayEntries.first['emotion'] as String? ?? 'neutral')
          : '';
      weekMoods.add({
        'day': dayLabels[day.weekday - 1],
        'emoji': emotion.isNotEmpty ? (emotionEmoji[emotion] ?? '😐') : '',
        'color': emotion.isNotEmpty
            ? (emotionColor[emotion] ?? Color(0xFF95A5A6))
            : Color(0x1AFFFFFF),
        'hasEntry': emotion.isNotEmpty,
      });
    }

    // Dominant mood this week
    final emotionCounts = <String, int>{};
    for (final e in weekEntries) {
      final em = e['emotion'] as String? ?? 'neutral';
      emotionCounts[em] = (emotionCounts[em] ?? 0) + 1;
    }
    String dominant = 'Neutral';
    if (emotionCounts.isNotEmpty) {
      final top = emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      const labels = {
        'joy': 'Joyful', 'sadness': 'Sad', 'anger': 'Angry',
        'fear': 'Anxious', 'surprise': 'Surprised', 'neutral': 'Chill',
        'hype': 'Hyped', 'romantic': 'Romantic',
      };
      dominant = labels[top] ?? 'Chill';
    }

    // Badge detection
    final earnedBadges = List<String>.from(profile?['badges'] ?? []);
    final updatedBadges = _allBadges.map((b) {
      return {...b, 'earned': earnedBadges.contains(b['id'])};
    }).toList();

    // Joined date
    String joined = 'Recently';
    try {
      final ts = profile?['joinedAt'];
      if (ts != null) {
        final dt = (ts as dynamic).toDate() as DateTime;
        const months = ['Jan','Feb','Mar','Apr','May','Jun',
            'Jul','Aug','Sep','Oct','Nov','Dec'];
        joined = '${months[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}

    setState(() {
      _name         = (profile?['name'] as String?) ?? 'Zenora User';
      _username     = '@${(profile?['username'] as String?) ?? 'zenorauser'}';
      _university   = (profile?['university'] as String?) ?? 'Chandigarh University';
      _joinedDate   = joined;
      _zenoPoints   = (profile?['zenoPoints'] as int?) ?? 0;
      _streak       = (profile?['streak'] as int?) ?? 0;
      _totalEntries = (profile?['totalEntries'] as int?) ?? 0;
      _earnedBadges = earnedBadges;
      _weekMoods    = weekMoods;
      _dominantMood = dominant;
      _loading      = false;
      _allBadges.clear();
      _allBadges.addAll(updatedBadges);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _badgeController.forward();
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF5C2D91),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _openEditProfile() {
    final nameCtrl = TextEditingController(text: _name);
    final userCtrl = TextEditingController(text: _username.replaceAll('@', ''));
    final uniCtrl  = TextEditingController(text: _university);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _sheet(title: '✏️  Edit Profile', child: Column(mainAxisSize: MainAxisSize.min, children: [
          _editField('Full Name', nameCtrl, Icons.person_outline),
          const SizedBox(height: 14),
          _editField('Username', userCtrl, Icons.alternate_email),
          const SizedBox(height: 14),
          _editField('University', uniCtrl, Icons.school_outlined),
          const SizedBox(height: 24),
          _gradBtn('Save Changes 💾', () async {
            Navigator.pop(context);
            if (nameCtrl.text.trim().isNotEmpty) {
              await FirebaseService.updateUserProfile({
                'name': nameCtrl.text.trim(),
                'username': userCtrl.text.trim(),
                'university': uniCtrl.text.trim(),
              });
              await _loadData();
              _snack('Profile updated! slay bestie ✅');
            }
          }),
        ])),
      ),
    );
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) => _sheet(
        title: '🔔  Notifications',
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _toggleTile('Daily Check-in Reminder', 'so we don\'t have to @ you every day 😅',
              _notifDaily, (v) { setState(() => _notifDaily = v); setLocal(() {}); }),
          _divider(),
          _toggleTile('Weekly Insights', 'your weekly mood report every Sunday fr',
              _notifInsights, (v) { setState(() => _notifInsights = v); setLocal(() {}); }),
          _divider(),
          _toggleTile('Streak Alerts', 'don\'t let the streak die bestie 🔥',
              _notifStreak, (v) { setState(() => _notifStreak = v); setLocal(() {}); }),
          const SizedBox(height: 20),
          _gradBtn('Save Preferences 🔔', () { Navigator.pop(ctx); _snack('Notification prefs saved! ✅'); }),
        ]),
      )),
    );
  }

  void _openPrivacy() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _sheet(title: '🔒  Privacy & Data', child: Column(mainAxisSize: MainAxisSize.min, children: [
        _infoTile('🛡️', 'Data Storage', 'Stored anonymously on Firebase. No personal info linked to your mood entries.'),
        _divider(),
        _infoTile('🔑', 'AI Security', 'Gemini analyzes text for emotion detection only — not stored permanently.'),
        _divider(),
        _infoTile('📊', 'Research', 'Only anonymous aggregated data used in academic publications. You\'re safe yaar.'),
        _divider(),
        _infoTile('🗑️', 'Delete Data', 'Request deletion: ds7794092@gmail.com. We\'ll handle it ASAP.'),
        const SizedBox(height: 20),
        _gradBtn('Got it! 👍', () => Navigator.pop(context)),
      ])),
    );
  }

  void _openThemeSwitcher() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) => _sheet(
        title: '🎨  Choose Your Aesthetic',
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _themeOption(ctx, setLocal, ZenoraTheme.dark,   '🌑 Midnight Dark',  'deep navy + teal, classic era',
              [Color(0xFF1A0533), Color(0xFF0F0F1E), Color(0xFF003333)]),
          const SizedBox(height: 12),
          _themeOption(ctx, setLocal, ZenoraTheme.purple, '💜 Deep Purple',    'rich purple, villain arc vibes',
              [Color(0xFF2D0B5C), Color(0xFF1A0533), Color(0xFF0D0020)]),
          const SizedBox(height: 12),
          _themeOption(ctx, setLocal, ZenoraTheme.teal,   '🌊 Ocean Teal',     'cool teal, chill era unlocked',
              [Color(0xFF003333), Color(0xFF0F0F1E), Color(0xFF001A1A)]),
        ]),
      )),
    );
  }

  void _openHelp() {
    final faqs = [
      {'q': 'How do I log my mood? 🎯', 'a': 'Tap any of the 8 expression modes on Home — Journal, Emoji Board, Vibe Slider, Music Mood, and more!'},
      {'q': 'What are Zeno Points? ⚡', 'a': 'Points earned every time you log a mood. Voice mode gives most (+15 pts), quick check-ins give least (+5 pts).'},
      {'q': 'How does the AI work? 🤖', 'a': 'Google Gemini analyzes your journal/voice text and detects emotion — then crafts a personalized response. No data stored.'},
      {'q': 'Is my data private? 🔒', 'a': 'Yes! All data stored anonymously. Check the Privacy section. Teri diary safe hai yaar 😌'},
      {'q': 'How do I earn badges? 🏅', 'a': 'Auto-earned by logging moods, maintaining streaks, trying all modes. Check your Profile to see which you\'ve unlocked!'},
      {'q': 'App is slow/crashing? 😭', 'a': 'Try restarting the app. If issue persists, email ds7794092@gmail.com — we\'ll fix it ASAP!'},
    ];
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A0533),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Color(0x33FFFFFF)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('❓  Help & Support',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: faqs.length,
              separatorBuilder: (_, __) => _divider(),
              itemBuilder: (_, i) => _faqTile(faqs[i]['q']!, faqs[i]['a']!),
            )),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _gradBtn('Contact Support 📧', () {
                Navigator.pop(context);
                _snack('Email: ds7794092@gmail.com 📧');
              }),
            ),
          ]),
        ),
      ),
    );
  }

  void _openAbout() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1A0533), Color(0xFF0F0F1E), Color(0xFF003333)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Color(0x33FFFFFF)),
          ),
          child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),

              // Animated logo
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, val, __) => Transform.scale(
                  scale: val,
                  child: Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
                      boxShadow: [BoxShadow(
                          color: Color(0xFF5C2D91).withValues(alpha: 0.6),
                          blurRadius: 24, spreadRadius: 4)],
                    ),
                    child: const Center(child: Text('◉',
                        style: TextStyle(color: Colors.white, fontSize: 40))),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF9B59F5), Color(0xFF00B4B4)],
                ).createShader(bounds),
                child: const Text('ZENORA',
                    style: TextStyle(color: Colors.white, fontSize: 32,
                        fontWeight: FontWeight.w900, letterSpacing: 6)),
              ),
              const SizedBox(height: 4),
              const Text('Know Your Mind',
                  style: TextStyle(color: Color(0xFF00B4B4),
                      fontSize: 14, fontStyle: FontStyle.italic, letterSpacing: 2)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(12)),
                child: const Text('v1.0.0 Beta • Research Edition',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ),
              const SizedBox(height: 28),

              // Developer card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF5C2D91).withValues(alpha: 0.3),
                      Color(0xFF007A7A).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF9B59F5).withValues(alpha: 0.4)),
                ),
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
                        boxShadow: [BoxShadow(
                            color: Color(0xFF5C2D91).withValues(alpha: 0.5),
                            blurRadius: 12)],
                      ),
                      child: const Center(child: Text('D',
                          style: TextStyle(color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Divyanshu Sharma',
                          style: TextStyle(color: Colors.white, fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const Text('@Beast93489',
                          style: TextStyle(color: Color(0xFF9B59F5), fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFF9B59F5).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Developer 👨‍💻',
                              style: TextStyle(color: Color(0xFF9B59F5), fontSize: 10)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFF00B4B4).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Researcher 🔬',
                              style: TextStyle(color: Color(0xFF00B4B4), fontSize: 10)),
                        ),
                      ]),
                    ])),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(12)),
                    child: const Text(
                      'B.Tech CSE • Chandigarh University • Class of 2027\nBuilding Zenora as research project targeting IEEE Access publication',
                      style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // Tech stack
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('🛠️ Tech Stack',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _techChip('Flutter', Color(0xFF0553B1)),
                _techChip('Firebase', Color(0xFFFF6B35)),
                _techChip('Gemini AI', Color(0xFF4A90D9)),
                _techChip('Spotify API', Color(0xFF1DB954)),
                _techChip('Firestore', Color(0xFFFFB800)),
                _techChip('Firebase Auth', Color(0xFF9B59F5)),
                _techChip('Speech-to-Text', Color(0xFF00B4B4)),
              ]),

              const SizedBox(height: 20),
              _infoTile('🎯', 'Mission',
                  'Help students understand emotional wellbeing through AI-powered multi-modal mood tracking.'),
              _divider(),
              _infoTile('🔬', 'Research Target',
                  'IEEE Access / JMIR Mental Health. Multi-modal emotion detection using ML.'),
              _divider(),
              _infoTile('💌', 'Contact',
                  'ds7794092@gmail.com\ngithub.com/Beast93489/Zenora'),
              const SizedBox(height: 24),
              _gradBtn('That\'s slay! Close 🔥', () => Navigator.pop(context)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _techChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0533),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out 👋', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your data is safely stored in Firebase.\nCome back whenever you want bestie! 🫶',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Stay 😌', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onSettingTap(String label) {
    switch (label) {
      case 'Notifications': _openNotifications(); break;
      case 'Privacy':       _openPrivacy();        break;
      case 'Theme':         _openThemeSwitcher();  break;
      case 'Help & Support':_openHelp();           break;
      case 'About Zenora':  _openAbout();          break;
      case 'Sign Out':      _confirmSignOut();     break;
    }
  }

  // ── Reusable widgets ─────────────────────────────────────────
  Widget _sheet({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0533),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Color(0x33FFFFFF)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
        const SizedBox(height: 20),
        child,
      ]),
    );
  }

  Widget _gradBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Color(0xFF5C2D91).withValues(alpha: 0.4),
                blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Center(child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.white.withValues(alpha: 0.07), height: 1);

  Widget _toggleTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged,
          activeColor: const Color(0xFF9B59F5)),
    );
  }

  Widget _infoTile(String emoji, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5)),
        ])),
      ]),
    );
  }

  Widget _faqTile(String q, String a) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      iconColor: const Color(0xFF9B59F5),
      collapsedIconColor: Colors.white38,
      title: Text(q, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      children: [Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(a, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5)),
      )],
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          filled: true, fillColor: Color(0x1AFFFFFF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF9B59F5), width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _themeOption(BuildContext ctx, StateSetter setLocal, ZenoraTheme theme,
      String label, String subtitle, List<Color> colors) {
    final selected = themeNotifier.theme == theme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        themeNotifier.setTheme(theme);
        setLocal(() {}); setState(() {});
        Navigator.pop(ctx);
        _snack('$label activated! 🎨');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Color(0x1A9B59F5) : Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? Color(0xFF9B59F5) : Color(0x1AFFFFFF),
              width: selected ? 2 : 1),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 48, height: 36,
                child: Row(children: colors.map((c) => Expanded(child: Container(color: c))).toList())),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ])),
          if (selected) const Icon(Icons.check_circle, color: Color(0xFF9B59F5), size: 22),
        ]),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: themeNotifier.bgGradient,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF9B59F5)),
                    SizedBox(height: 16),
                    Text('loading your era... 💫',
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF9B59F5),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(children: [
                        _buildHeader(),
                        _buildStatsRow(),
                        _buildWeekMoods(),
                        _buildBadges(),
                        _buildSettingsList(),
                        const SizedBox(height: 30),
                      ]),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)),
          ),
          const Spacer(),
          const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18)),
          ),
        ]),
        const SizedBox(height: 28),

        // Animated avatar
        AnimatedBuilder(
          animation: _avatarController,
          builder: (_, __) => Stack(
            alignment: Alignment.bottomRight,
            children: [
              Transform.scale(
                scale: _avatarScale.value,
                child: Container(
                  width: 92, height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
                    boxShadow: [BoxShadow(
                        color: Color(0xFF5C2D91).withValues(alpha: 0.5),
                        blurRadius: _avatarGlow.value,
                        spreadRadius: 2)],
                  ),
                  child: Center(child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : 'Z',
                    style: const TextStyle(color: Colors.white, fontSize: 38,
                        fontWeight: FontWeight.bold),
                  )),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Color(0xFF9B59F5), shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF0F0F1E), width: 2)),
                child: const Text('😊', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        Text(_name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_username, style: const TextStyle(color: Color(0xFF9B59F5), fontSize: 14)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.school_outlined, color: Colors.white38, size: 14),
          const SizedBox(width: 4),
          Text(_university, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 12),
          const SizedBox(width: 4),
          Text('Joined $_joinedDate', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        const SizedBox(height: 14),

        // Dominant mood badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0x33FFFFFF)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('✨', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text('Mostly $_dominantMood this week',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        _statCard('⚡', '$_zenoPoints', 'Zeno Pts', Color(0xFF9B59F5)),
        const SizedBox(width: 10),
        _statCard('🔥', '$_streak', 'Streak', Color(0xFFFF6B35)),
        const SizedBox(width: 10),
        _statCard('📝', '$_totalEntries', 'Entries', Color(0xFF00B4B4)),
        const SizedBox(width: 10),
        _statCard('🏅', '${_earnedBadges.length}', 'Badges', Color(0xFFFFB800)),
      ]),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildWeekMoods() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0x1AFFFFFF)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Text('📅', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('This Week', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          const Text('your 7-day mood map',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekMoods.map((m) {
              final hasEntry = m['hasEntry'] as bool;
              return Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: hasEntry
                        ? (m['color'] as Color).withValues(alpha: 0.15)
                        : Color(0x0AFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasEntry
                          ? (m['color'] as Color).withValues(alpha: 0.5)
                          : Color(0x1AFFFFFF),
                    ),
                  ),
                  child: Center(child: Text(
                    hasEntry ? (m['emoji'] as String) : '·',
                    style: TextStyle(fontSize: hasEntry ? 20 : 16, color: Colors.white24),
                  )),
                ),
                const SizedBox(height: 6),
                Text(m['day'] as String,
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ]);
            }).toList(),
          ),
        ]),
      ),
    );
  }

  Widget _buildBadges() {
    final earned = _allBadges.where((b) => b['earned'] == true).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🏅 Badges', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Text('(unlock them all fr)',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const Spacer(),
          Text('$earned / ${_allBadges.length}',
              style: const TextStyle(color: Color(0xFF9B59F5), fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.78),
          itemCount: _allBadges.length,
          itemBuilder: (_, i) {
            final badge = _allBadges[i];
            final isEarned = badge['earned'] as bool;
            final color = badge['color'] as Color;
            return AnimatedBuilder(
              animation: _badgeController,
              builder: (_, __) {
                final delay = i * 0.1;
                final anim = CurvedAnimation(
                  parent: _badgeController,
                  curve: Interval(delay.clamp(0.0, 0.9), (delay + 0.3).clamp(0.1, 1.0),
                      curve: Curves.elasticOut),
                );
                return Transform.scale(
                  scale: anim.value,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _snack(isEarned
                          ? '${badge['icon']} ${badge['title']}: ${badge['genZ']} ✅'
                          : '${badge['title']}: ${badge['desc']} — not yet!');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isEarned
                            ? color.withValues(alpha: 0.15)
                            : Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isEarned
                                ? color.withValues(alpha: 0.5)
                                : Color(0x1AFFFFFF),
                            width: isEarned ? 1.5 : 1),
                        boxShadow: isEarned ? [BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 8)] : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(badge['icon'] as String,
                            style: TextStyle(
                                fontSize: 28,
                                color: isEarned ? null : Colors.white.withValues(alpha: 0.2))),
                        const SizedBox(height: 6),
                        Text(badge['title'] as String,
                            style: TextStyle(
                                color: isEarned ? Colors.white : Colors.white24,
                                fontSize: 11, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center, maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(isEarned ? (badge['genZ'] as String) : (badge['desc'] as String),
                            style: TextStyle(
                                color: isEarned
                                    ? color.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.15),
                                fontSize: 9),
                            textAlign: TextAlign.center, maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        if (isEarned) ...[
                          const SizedBox(height: 4),
                          Container(width: 16, height: 2,
                              decoration: BoxDecoration(
                                  color: color, borderRadius: BorderRadius.circular(1))),
                        ],
                      ]),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ]),
    );
  }

  Widget _buildSettingsList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⚙️ Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0x1AFFFFFF)),
          ),
          child: Column(
            children: List.generate(_settings.length, (i) {
              final s = _settings[i];
              final isLast = i == _settings.length - 1;
              final isSignOut = s['label'] == 'Sign Out';
              return Column(children: [
                ListTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _onSettingTap(s['label'] as String);
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (s['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s['icon'] as IconData,
                        color: s['color'] as Color, size: 20),
                  ),
                  title: Text(s['label'] as String,
                      style: TextStyle(
                          color: isSignOut ? Color(0xFFE74C3C) : Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: isSignOut
                      ? const Text('see you soon bestie 👋',
                          style: TextStyle(color: Colors.white24, fontSize: 10))
                      : null,
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                ),
                if (!isLast) Divider(
                    color: Colors.white.withValues(alpha: 0.05),
                    height: 1, indent: 16, endIndent: 16),
              ]);
            }),
          ),
        ),
      ]),
    );
  }
}