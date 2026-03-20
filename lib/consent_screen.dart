import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';

class ConsentScreen extends StatefulWidget {
  final Widget nextScreen;
  final VoidCallback? onConsent;
  const ConsentScreen({super.key, required this.nextScreen, this.onConsent});
  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _consentChecked = false;
  bool _ageChecked = false;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  int _currentSection = 0;

  final List<Map<String, dynamic>> _sections = [
    {
      'icon': '🧠',
      'title': 'What is Zenora?',
      'color': Color(0xFF9B59F5),
      'content':
          'Zenora is an AI-powered mental wellness app built as part of academic research at Chandigarh University. It helps you understand your emotions through 8 unique expression modes — Journal, Voice, Music Mood, Emoji Board, and more.\n\nThis app is developed by Divyanshu Sharma (B.Tech CSE, 2027) and is part of a study targeting publication in IEEE Access / JMIR Mental Health.',
    },
    {
      'icon': '📊',
      'title': 'What Data We Collect',
      'color': Color(0xFF00B4B4),
      'content':
          'We collect the following data to provide app functionality and conduct research:\n\n'
          '• Mood entries (emotion, mode used, timestamp)\n'
          '• Passive behavioral signals (time of entry, word count, session duration)\n'
          '• App usage patterns (which features you use, how often)\n'
          '• Anonymous user ID (ZN_xxxxxx format)\n\n'
          'We do NOT collect: location, contacts, camera data, or any data beyond what you voluntarily enter.',
    },
    {
      'icon': '🔒',
      'title': 'How We Protect Your Privacy',
      'color': Color(0xFF27AE60),
      'content':
          'Your privacy is our top priority:\n\n'
          '• Your name and email are stored separately from your research data\n'
          '• All research uses only your anonymous ZN ID (e.g., ZN_847291)\n'
          '• No researcher can link your ZN ID back to your real identity\n'
          '• Data is stored on Firebase (Google) servers with encryption\n'
          '• Your journal text is sent to Groq AI for emotion analysis only — it is NOT stored by Groq\n'
          '• You can request complete deletion of all your data at any time',
    },
    {
      'icon': '🔬',
      'title': 'Research Participation',
      'color': Color(0xFFFFB800),
      'content':
          'By using this app, you agree to participate in academic research:\n\n'
          '• Your anonymized data may be used in research publications\n'
          '• Only aggregate, de-identified data will appear in papers\n'
          '• No individual data points will be published\n'
          '• You can withdraw from the study at any time by deleting your account\n'
          '• Participation is completely voluntary\n\n'
          'This study has been designed in accordance with standard academic ethics guidelines for student research.',
    },
    {
      'icon': '🚨',
      'title': 'Crisis Support Protocol',
      'color': Color(0xFFE74C3C),
      'content':
          'Your safety is our highest priority:\n\n'
          '• Our AI monitors for crisis-related keywords in your entries\n'
          '• If detected, we will show you mental health helpline numbers\n'
          '• This is done automatically and locally — no human reads your entries\n'
          '• We log only a risk level (1/2/3) — never the actual text content\n\n'
          'Emergency contacts we may show:\n'
          '• iCall: 9152987821\n'
          '• Vandrevala Foundation: 1860-2662-345\n'
          '• AASRA: 9820466627\n'
          '• CU Counseling Center: Contact university admin',
    },
    {
      'icon': '⚖️',
      'title': 'Your Rights',
      'color': Color(0xFF4A90D9),
      'content':
          'You have the following rights regarding your data:\n\n'
          '• Right to Access: Request a copy of your data anytime\n'
          '• Right to Deletion: Delete all your data from Settings → Privacy\n'
          '• Right to Withdraw: Stop participating in the study anytime\n'
          '• Right to Correct: Update your profile information anytime\n\n'
          'To exercise any of these rights or for any concerns:\n'
          '📧 ds7794092@gmail.com\n'
          '🐙 github.com/Beast93489/Zenora\n\n'
          'By tapping "I Agree & Continue" below, you confirm that you have read and understood this consent form and agree to participate in the Zenora research study.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.position.pixels;
      if (current >= maxScroll - 100 && !_hasScrolledToBottom) {
        setState(() => _hasScrolledToBottom = true);
      }
      // Update current section for progress
      final progress = current / (maxScroll == 0 ? 1 : maxScroll);
      final section = (progress * _sections.length).floor().clamp(0, _sections.length - 1);
      if (section != _currentSection) setState(() => _currentSection = section);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _acceptConsent() async {
    if (!_consentChecked || !_ageChecked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please check both boxes to continue 📋',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF5C2D91),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await FirebaseService.recordConsent();
    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onConsent?.call();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(children: [
              // ── Header ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  // Logo
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
                      ),
                      child: const Center(child: Text('◉',
                          style: TextStyle(color: Colors.white, fontSize: 18))),
                    ),
                    const SizedBox(width: 10),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF9B59F5), Color(0xFF00B4B4)])
                          .createShader(bounds),
                      child: const Text('ZENORA',
                          style: TextStyle(color: Colors.white, fontSize: 20,
                              fontWeight: FontWeight.bold, letterSpacing: 4)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Informed Consent & Privacy Policy',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('please read everything before continuing 📋',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 12),

                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_sections.length, (i) {
                      final isActive = i <= _currentSection;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 20 : 8, height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? (_sections[_currentSection]['color'] as Color)
                              : const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ]),
              ),

              // ── Content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    // Research badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x1A9B59F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF9B59F5).withValues(alpha: 0.3)),
                      ),
                      child: const Row(children: [
                        Text('🎓', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Academic Research Study',
                                style: TextStyle(color: Color(0xFF9B59F5),
                                    fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Chandigarh University • B.Tech CSE 2027',
                                style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        )),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Sections
                    ...List.generate(_sections.length, (i) {
                      final s = _sections[i];
                      final color = s['color'] as Color;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: color.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(s['icon'] as String,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(s['title'] as String,
                                  style: TextStyle(color: color, fontSize: 15,
                                      fontWeight: FontWeight.bold))),
                            ]),
                            const SizedBox(height: 10),
                            Text(s['content'] as String,
                                style: const TextStyle(color: Colors.white60,
                                    fontSize: 13, height: 1.6)),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 8),

                    // Version info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(children: [
                        Text('📄', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Consent Form v1.0 • Effective March 2026\nThis form is digitally recorded with timestamp.',
                          style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.4),
                        )),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // ── Checkboxes ─────────────────────────────
                    if (_hasScrolledToBottom) ...[
                      _buildCheckbox(
                        'I have read and understood the consent form. I voluntarily agree to participate in the Zenora research study and allow my anonymized data to be used for academic research.',
                        _consentChecked,
                        (val) => setState(() => _consentChecked = val ?? false),
                        const Color(0xFF9B59F5),
                      ),
                      const SizedBox(height: 12),
                      _buildCheckbox(
                        'I am 18 years or older (or have parental consent) and a student of Chandigarh University or associated institution.',
                        _ageChecked,
                        (val) => setState(() => _ageChecked = val ?? false),
                        const Color(0xFF00B4B4),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                        ),
                        child: const Row(children: [
                          Text('👇', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 10),
                          Expanded(child: Text(
                            'Scroll to the bottom to read everything before accepting',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          )),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Accept button ──────────────────────────
                    GestureDetector(
                      onTap: _hasScrolledToBottom ? _acceptConsent : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: (_hasScrolledToBottom && _consentChecked && _ageChecked)
                              ? const LinearGradient(
                                  colors: [Color(0xFF5C2D91), Color(0xFF007A7A)])
                              : null,
                          color: (_hasScrolledToBottom && _consentChecked && _ageChecked)
                              ? null
                              : const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: (_hasScrolledToBottom && _consentChecked && _ageChecked)
                              ? [BoxShadow(
                                  color: const Color(0xFF5C2D91).withValues(alpha: 0.4),
                                  blurRadius: 16, offset: const Offset(0, 6))]
                              : null,
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _hasScrolledToBottom
                                      ? 'I Agree & Continue ✅'
                                      : 'Read Everything First 📋',
                                  style: TextStyle(
                                      color: (_hasScrolledToBottom && _consentChecked && _ageChecked)
                                          ? Colors.white
                                          : Colors.white38,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Decline option
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF1A0533),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Are you sure? 🥺',
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'Without consent, you can still use Zenora but your data won\'t be part of the research study.\n\nYou can give consent later from Settings.',
                            style: TextStyle(color: Colors.white70, height: 1.5),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Go Back',
                                  style: TextStyle(color: Color(0xFF9B59F5))),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushReplacement(context,
                                    MaterialPageRoute(
                                        builder: (_) => widget.nextScreen));
                              },
                              child: const Text('Skip for Now',
                                  style: TextStyle(color: Colors.white38)),
                            ),
                          ],
                        ),
                      ),
                      child: const Text('Skip for now (not recommended)',
                          style: TextStyle(color: Colors.white24, fontSize: 12)),
                    ),

                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String text, bool value,
      Function(bool?) onChanged, Color color) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.1) : const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: value ? color.withValues(alpha: 0.4) : const Color(0x1AFFFFFF)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: value ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: value ? color : Colors.white38, width: 2),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text,
              style: TextStyle(
                  color: value ? Colors.white70 : Colors.white38,
                  fontSize: 12, height: 1.5))),
        ]),
      ),
    );
  }
}