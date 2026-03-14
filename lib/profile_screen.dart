import 'package:flutter/material.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  String _name       = 'Divyanshu Sharma';
  String _username   = '@divyanshu';
  String _university = 'Chandigarh University';
  bool   _notifDaily    = true;
  bool   _notifInsights = true;
  bool   _notifStreak   = true;

  final int    _zenoPoints   = 56;
  final int    _streak       = 3;
  final int    _totalEntries = 7;
  final int    _badgesEarned = 2;
  final String _joinedDate   = 'March 2026';

  final List<Map<String, dynamic>> _badges = [
    {'icon': '🌱', 'title': 'First Entry',      'desc': 'Logged your first mood',      'earned': true},
    {'icon': '🔥', 'title': '3-Day Streak',     'desc': 'Logged 3 days in a row',      'earned': true},
    {'icon': '⚡', 'title': 'Vibe Master',      'desc': 'Used Vibe Slider 5 times',    'earned': false},
    {'icon': '✍️', 'title': 'Journaler',        'desc': 'Wrote 10 journal entries',    'earned': false},
    {'icon': '🎭', 'title': 'Emotion Explorer', 'desc': 'Detected all 7 emotions',     'earned': false},
    {'icon': '💎', 'title': '30-Day Streak',    'desc': 'Logged 30 days in a row',     'earned': false},
  ];

  final List<Map<String, dynamic>> _weekMoods = [
    {'day': 'M', 'emoji': '😊', 'color': Color(0xFFFFB800)},
    {'day': 'T', 'emoji': '😔', 'color': Color(0xFF4A90D9)},
    {'day': 'W', 'emoji': '😤', 'color': Color(0xFFE74C3C)},
    {'day': 'T', 'emoji': '😊', 'color': Color(0xFFFFB800)},
    {'day': 'F', 'emoji': '😰', 'color': Color(0xFF9B59B6)},
    {'day': 'S', 'emoji': '🤩', 'color': Color(0xFFFF6B35)},
    {'day': 'S', 'emoji': '😐', 'color': Color(0xFF95A5A6)},
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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fadeAnimation  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() => setState(() {});

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    _animController.dispose();
    super.dispose();
  }

  // ── Snack helper ─────────────────────────────────────────────
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF5C2D91),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Edit Profile ─────────────────────────────────────────────
  void _openEditProfile() {
    final nameCtrl = TextEditingController(text: _name);
    final userCtrl = TextEditingController(text: _username.replaceAll('@', ''));
    final uniCtrl  = TextEditingController(text: _university);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _sheet(
          title: '✏️  Edit Profile',
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _editField('Full Name', nameCtrl, Icons.person_outline),
            const SizedBox(height: 14),
            _editField('Username', userCtrl, Icons.alternate_email),
            const SizedBox(height: 14),
            _editField('University', uniCtrl, Icons.school_outlined),
            const SizedBox(height: 24),
            _gradBtn('Save Changes', () {
              setState(() {
                if (nameCtrl.text.trim().isNotEmpty) _name       = nameCtrl.text.trim();
                _username   = '@${userCtrl.text.trim()}';
                if (uniCtrl.text.trim().isNotEmpty)  _university = uniCtrl.text.trim();
              });
              Navigator.pop(context);
              _snack('Profile updated! ✅');
            }),
          ]),
        ),
      ),
    );
  }

  // ── Notifications ─────────────────────────────────────────────
  void _openNotifications() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) => _sheet(
        title: '🔔  Notifications',
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _toggleTile(
            'Daily Check-in Reminder',
            'Reminds you to log your mood every day',
            _notifDaily,
            (v) { setState(() => _notifDaily = v); setLocal(() {}); },
          ),
          _divider(),
          _toggleTile(
            'Weekly Insights',
            'Get your weekly mood summary every Sunday',
            _notifInsights,
            (v) { setState(() => _notifInsights = v); setLocal(() {}); },
          ),
          _divider(),
          _toggleTile(
            'Streak Alerts',
            'Reminds you before your streak breaks',
            _notifStreak,
            (v) { setState(() => _notifStreak = v); setLocal(() {}); },
          ),
          const SizedBox(height: 20),
          _gradBtn('Save Preferences', () { Navigator.pop(ctx); _snack('Notification preferences saved! ✅'); }),
        ]),
      )),
    );
  }

  // ── Privacy ──────────────────────────────────────────────────
  void _openPrivacy() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _sheet(
        title: '🔒  Privacy',
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _infoTile('🛡️', 'Data Storage', 'Your mood data is stored anonymously on Firebase with a unique user ID. No personal info is linked to your entries.'),
          _divider(),
          _infoTile('🔑', 'API Security', 'AI analysis is powered by Google Gemini. Your journal text is sent to Gemini for analysis and is not stored by Anthropic or Google.'),
          _divider(),
          _infoTile('📊', 'Research Data', 'If you participate in the Zenora research study, only anonymous aggregated data will be used in academic publications.'),
          _divider(),
          _infoTile('🗑️', 'Delete Your Data', 'You can request complete deletion of all your Zenora data by contacting us at ds7794092@gmail.com.'),
          const SizedBox(height: 20),
          _gradBtn('I Understand', () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  // ── Theme ─────────────────────────────────────────────────────
  void _openThemeSwitcher() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) => _sheet(
        title: '🎨  Choose Theme',
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _themeOption(ctx, setLocal, ZenoraTheme.dark,   'Midnight Dark', 'Deep navy + teal (default)',
              [Color(0xFF1A0533), Color(0xFF0F0F1E), Color(0xFF003333)]),
          const SizedBox(height: 12),
          _themeOption(ctx, setLocal, ZenoraTheme.purple, 'Deep Purple',   'Rich purple tones',
              [Color(0xFF2D0B5C), Color(0xFF1A0533), Color(0xFF0D0020)]),
          const SizedBox(height: 12),
          _themeOption(ctx, setLocal, ZenoraTheme.teal,   'Ocean Teal',    'Cool teal vibes',
              [Color(0xFF003333), Color(0xFF0F0F1E), Color(0xFF001A1A)]),
          const SizedBox(height: 8),
        ]),
      )),
    );
  }

  // ── Help & Support ────────────────────────────────────────────
  void _openHelp() {
    final faqs = [
      {'q': 'How do I log my mood?', 'a': 'Tap any of the 8 expression modes on the Home screen — Journal, Emoji Board, Vibe Slider, and more!'},
      {'q': 'What are Zeno Points?', 'a': 'Zeno Points are earned every time you log a mood entry. Journal entries give +10 pts, quick check-ins give +5 pts.'},
      {'q': 'How does the AI work?', 'a': 'Journal entries are analyzed by Google Gemini AI which detects your emotion and crafts a personalized empathetic response.'},
      {'q': 'Is my data private?', 'a': 'Yes! All data is stored anonymously. Check the Privacy section for full details.'},
      {'q': 'How do I earn badges?', 'a': 'Badges are earned automatically — log your first entry, maintain streaks, try all expression modes, and more!'},
      {'q': 'I found a bug. What do I do?', 'a': 'Please email ds7794092@gmail.com with a description of the issue. We appreciate every report!'},
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
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: faqs.length,
                separatorBuilder: (_, __) => _divider(),
                itemBuilder: (_, i) => _faqTile(faqs[i]['q']!, faqs[i]['a']!),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _gradBtn('Contact Support', () {
                Navigator.pop(context);
                _snack('Email: ds7794092@gmail.com 📧');
              }),
            ),
          ]),
        ),
      ),
    );
  }

  // ── About Zenora ──────────────────────────────────────────────
  void _openAbout() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _sheet(
        title: '',
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Logo area
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
            ),
            child: const Center(child: Text('◉', style: TextStyle(color: Colors.white, fontSize: 32))),
          ),
          const SizedBox(height: 12),
          const Text('ZENORA', style: TextStyle(color: Colors.white, fontSize: 24,
              fontWeight: FontWeight.bold, letterSpacing: 4)),
          const SizedBox(height: 4),
          const Text('Know Your Mind', style: TextStyle(color: Color(0xFF00B4B4),
              fontSize: 13, fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(12)),
            child: const Text('Version 1.0.0 • Beta',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          const SizedBox(height: 20),
          _infoTile('🎯', 'Mission', 'Zenora helps students and young adults understand their emotional well-being through AI-powered multi-modal mood tracking.'),
          _divider(),
          _infoTile('🔬', 'Research', 'Built as part of academic research at Chandigarh University. Targeting publication in IEEE Access / JMIR Mental Health.'),
          _divider(),
          _infoTile('👨‍💻', 'Developer', 'Divyanshu Sharma — B.Tech CSE, Chandigarh University (Class of 2027)'),
          _divider(),
          _infoTile('🤖', 'AI Powered By', 'Google Gemini 1.5 Flash for emotion analysis and empathetic responses. Hugging Face for NLP classification.'),
          const SizedBox(height: 20),
          _gradBtn('Close', () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  // ── Sign Out ──────────────────────────────────────────────────
  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0533),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your mood data will be saved locally.\nSign back in anytime to continue your streak! 🔥',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Replace with FirebaseAuth.instance.signOut() after Firebase setup
              // For now pop back to root
              Navigator.of(context).popUntil((route) => route.isFirst);
              _snack('Signed out. See you soon! 👋');
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Settings tap handler ──────────────────────────────────────
  void _onSettingTap(String label) {
    switch (label) {
      case 'Notifications': _openNotifications();  break;
      case 'Privacy':       _openPrivacy();         break;
      case 'Theme':         _openThemeSwitcher();   break;
      case 'Help & Support':_openHelp();            break;
      case 'About Zenora':  _openAbout();           break;
      case 'Sign Out':      _confirmSignOut();      break;
    }
  }

  // ── Reusable widgets ──────────────────────────────────────────
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
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF5C2D91),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.white.withValues(alpha: 0.07), height: 1);

  Widget _toggleTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF9B59F5),
      ),
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
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(a, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5)),
        ),
      ],
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

  Widget _themeOption(BuildContext ctx, StateSetter setLocal,
      ZenoraTheme theme, String label, String subtitle, List<Color> colors) {
    final selected = themeNotifier.theme == theme;
    return GestureDetector(
      onTap: () {
        themeNotifier.setTheme(theme);
        setLocal(() {}); setState(() {});
        Navigator.pop(ctx);
        _snack('Theme changed to $label! 🎨');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Color(0x1A9B59F5) : Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Color(0xFF9B59F5) : Color(0x1AFFFFFF), width: selected ? 2 : 1),
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
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
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
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
        Stack(alignment: Alignment.bottomRight, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
              boxShadow: [BoxShadow(color: Color(0xFF5C2D91).withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Center(child: Text(
              _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
            )),
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Color(0xFF9B59F5), shape: BoxShape.circle,
                border: Border.all(color: Color(0xFF0F0F1E), width: 2)),
            child: const Text('😊', style: TextStyle(fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 14),
        Text(_name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_username, style: const TextStyle(color: Color(0xFF9B59F5), fontSize: 14)),
        const SizedBox(height: 4),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0x33FFFFFF)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('😊', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text('Mostly Joyful this week', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        _statCard('⚡', '$_zenoPoints', 'Zeno Points', Color(0xFF9B59F5)),
        const SizedBox(width: 10),
        _statCard('🔥', '$_streak',      'Day Streak',  Color(0xFFFF6B35)),
        const SizedBox(width: 10),
        _statCard('📝', '$_totalEntries','Entries',     Color(0xFF00B4B4)),
        const SizedBox(width: 10),
        _statCard('🏅', '$_badgesEarned','Badges',      Color(0xFFFFB800)),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekMoods.map((m) => Column(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: (m['color'] as Color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (m['color'] as Color).withValues(alpha: 0.4)),
                ),
                child: Center(child: Text(m['emoji'] as String, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(height: 6),
              Text(m['day'] as String, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ])).toList(),
          ),
        ]),
      ),
    );
  }

  Widget _buildBadges() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🏅 Badges', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('$_badgesEarned / ${_badges.length}', style: const TextStyle(color: Color(0xFF9B59F5), fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8,
          children: _badges.map((badge) {
            final earned = badge['earned'] as bool;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: earned ? Color(0x1A9B59F5) : Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: earned ? Color(0xFF9B59F5).withValues(alpha: 0.4) : Color(0x1AFFFFFF)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(badge['icon'] as String, style: TextStyle(fontSize: 28, color: earned ? null : Colors.grey)),
                const SizedBox(height: 6),
                Text(badge['title'] as String,
                    style: TextStyle(color: earned ? Colors.white : Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 2),
                Text(badge['desc'] as String,
                    style: TextStyle(color: earned ? Colors.white38 : Colors.white.withValues(alpha: 0.15), fontSize: 9),
                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            );
          }).toList(),
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
              return Column(children: [
                ListTile(
                  onTap: () => _onSettingTap(s['label'] as String),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (s['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                  ),
                  title: Text(s['label'] as String,
                      style: TextStyle(
                          color: s['label'] == 'Sign Out' ? Color(0xFFE74C3C) : Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                ),
                if (!isLast) Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 16, endIndent: 16),
              ]);
            }),
          ),
        ),
      ]),
    );
  }
}