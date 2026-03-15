import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';

// ── Welcome / Onboarding Screen ──────────────────────────────────
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _pages = [
    {
      'emoji': '🧠',
      'title': 'Know Your Mind',
      'subtitle': 'Zenora helps you understand your emotions through 8 unique expression modes — designed for how YOU feel.',
      'color': Color(0xFF9B59F5),
      'genZ': 'main character arc starts here 💫',
    },
    {
      'emoji': '🤖',
      'title': 'AI That Listens',
      'subtitle': 'Powered by Google Gemini AI — Zenora reads your mood from text, emojis, voice, and more. Then responds with empathy.',
      'color': Color(0xFF00B4B4),
      'genZ': 'your AI dost fr fr 🤖',
    },
    {
      'emoji': '📊',
      'title': 'Track Your Journey',
      'subtitle': 'Watch your emotional patterns over time. Build streaks, earn badges, and grow your self-awareness every single day.',
      'color': Color(0xFFFFB800),
      'genZ': 'glow up era loading... ✨',
    },
    {
      'emoji': '🔒',
      'title': 'Private & Safe',
      'subtitle': 'Your data is stored anonymously. No ads, no tracking, no judgment. Just a safe space to be yourself.',
      'color': Color(0xFF27AE60),
      'genZ': 'teri diary safe hai yaar 🛡️',
    },
  ];

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _logoScale = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _pages[_currentPage]['color'] as Color;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              currentColor.withValues(alpha: 0.3),
              const Color(0xFF0F0F1E),
              const Color(0xFF003333),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _goToLogin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Text('Skip',
                          style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ),
                  ),
                ),
              ),

              // Logo
              ScaleTransition(
                scale: _logoScale,
                child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFF5C2D91).withValues(alpha: 0.5),
                          blurRadius: 24, spreadRadius: 2)],
                    ),
                    child: const Center(child: Text('◉',
                        style: TextStyle(color: Colors.white, fontSize: 36))),
                  ),
                  const SizedBox(height: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF9B59F5), Color(0xFF00B4B4)],
                    ).createShader(bounds),
                    child: const Text('ZENORA',
                        style: TextStyle(color: Colors.white, fontSize: 28,
                            fontWeight: FontWeight.bold, letterSpacing: 6)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(p['emoji'] as String,
                                key: ValueKey(i),
                                style: const TextStyle(fontSize: 72)),
                          ),
                          const SizedBox(height: 20),
                          Text(p['title'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: p['color'] as Color,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          // Gen Z subtitle
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: (p['color'] as Color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(p['genZ'] as String,
                                style: TextStyle(
                                    color: (p['color'] as Color).withValues(alpha: 0.9),
                                    fontSize: 11)),
                          ),
                          const SizedBox(height: 14),
                          Text(p['subtitle'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 15, height: 1.6)),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Dots + button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8, height: 8,
                        decoration: BoxDecoration(
                          color: active ? currentColor : const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _currentPage < _pages.length - 1 ? _nextPage() : _goToLogin();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            currentColor,
                            currentColor.withValues(alpha: 0.7),
                          ]),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(
                            color: currentColor.withValues(alpha: 0.4),
                            blurRadius: 20, offset: const Offset(0, 8),
                          )],
                        ),
                        child: Center(
                          child: Text(
                            _currentPage < _pages.length - 1
                                ? 'Next  →'
                                : 'Get Started  🚀',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Login Screen ─────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _isLogin  = true;
  bool _loading  = false;
  bool _googleLoading = false;
  bool _obscure  = true;
  late AnimationController _animCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    _animCtrl.dispose(); _slideCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() => _isLogin = !_isLogin);
    _animCtrl.forward(from: 0);
    _slideCtrl.forward(from: 0);
  }

  void _submit() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _snack('kuch toh bharo yaar! 😤'); return;
    }
    if (!_isLogin && _nameCtrl.text.trim().isEmpty) {
      _snack('naam toh batao apna! 😅'); return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    Map<String, dynamic> result;
    if (_isLogin) {
      result = await FirebaseService.signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text);
    } else {
      result = await FirebaseService.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          name: _nameCtrl.text.trim());
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _snack(result['error']?.toString() ?? 'Something went wrong yaar 😔');
    }
  }

  void _signInWithGoogle() async {
    HapticFeedback.mediumImpact();
    setState(() => _googleLoading = true);
    final result = await FirebaseService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (result['success'] == true) {
      final isNew = result['isNew'] == true;
      if (isNew) {
        _snack('Welcome to Zenora baawe! 🎉');
      }
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final error = result['error']?.toString() ?? '';
      if (!error.contains('Cancelled')) {
        _snack('Google sign-in failed: $error');
      }
    }
  }

  void _continueAsGuest() async {
    HapticFeedback.selectionClick();
    setState(() => _loading = true);
    final result = await FirebaseService.signInAsGuest();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _snack(result['error']?.toString() ?? 'Guest sign-in failed');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF5C2D91),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 16),

                // Logo
                Center(
                  child: Column(children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (_, val, __) => Transform.scale(
                        scale: val,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
                            boxShadow: [BoxShadow(
                                color: const Color(0xFF5C2D91).withValues(alpha: 0.5),
                                blurRadius: 20)],
                          ),
                          child: const Center(child: Text('◉',
                              style: TextStyle(color: Colors.white, fontSize: 30))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFF9B59F5), Color(0xFF00B4B4)])
                          .createShader(b),
                      child: const Text('ZENORA',
                          style: TextStyle(color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.bold, letterSpacing: 5)),
                    ),
                  ]),
                ),

                const SizedBox(height: 28),

                // Tab switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    _tabBtn('Sign In', _isLogin, () { if (!_isLogin) _toggleMode(); }),
                    _tabBtn('Sign Up', !_isLogin, () { if (_isLogin) _toggleMode(); }),
                  ]),
                ),

                const SizedBox(height: 24),

                // Subtitle
                SlideTransition(
                  position: _slideAnim,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _isLogin ? 'Welcome back baawe 👋' : 'Join the wellness era ✨',
                      style: const TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLogin
                          ? 'your streak is waiting fr 🔥'
                          : 'origin story starts now 🌱',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // Form fields
                SlideTransition(
                  position: _slideAnim,
                  child: Column(children: [
                    if (!_isLogin) ...[
                      _field('Full Name', _nameCtrl, Icons.person_outline, false,
                          'sharma ji ka beta 😅'),
                      const SizedBox(height: 14),
                    ],
                    _field('Email', _emailCtrl, Icons.email_outlined, false,
                        'your@email.com'),
                    const SizedBox(height: 14),
                    _passField(),
                    if (_isLogin) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _snack('Password reset coming soon! 🔥'),
                          child: const Text('Forgot password?',
                              style: TextStyle(
                                  color: Color(0xFF9B59F5), fontSize: 13)),
                        ),
                      ),
                    ],
                  ]),
                ),

                const SizedBox(height: 24),

                // Submit button
                GestureDetector(
                  onTap: _loading ? null : _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFF5C2D91).withValues(alpha: 0.4),
                          blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              _isLogin ? 'Sign In 🚀' : 'Create Account ✨',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Divider
                Row(children: [
                  Expanded(child: Divider(color: Colors.white12)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.white12)),
                ]),

                const SizedBox(height: 16),

                // Google Sign-In button
                GestureDetector(
                  onTap: _googleLoading ? null : _signInWithGoogle,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Center(
                      child: _googleLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Color(0xFF5C2D91), strokeWidth: 2))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              // Google G logo
                              Container(
                                width: 22, height: 22,
                                decoration: const BoxDecoration(shape: BoxShape.circle),
                                child: const Text('G',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4285F4))),
                              ),
                              const SizedBox(width: 10),
                              const Text('Continue with Google',
                                  style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ]),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Guest button
                GestureDetector(
                  onTap: _continueAsGuest,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: const Center(
                      child: Text('just vibing, no account needed 👻',
                          style: TextStyle(color: Colors.white54,
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Toggle
                Center(
                  child: GestureDetector(
                    onTap: _toggleMode,
                    child: RichText(
                      text: TextSpan(
                        text: _isLogin
                            ? "new here?  "
                            : 'already got an account?  ',
                        style: const TextStyle(color: Colors.white38, fontSize: 14),
                        children: [
                          TextSpan(
                            text: _isLogin ? 'Sign Up 🌱' : 'Sign In 👋',
                            style: const TextStyle(
                                color: Color(0xFF9B59F5),
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: active ? const LinearGradient(
                colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active ? [BoxShadow(
                color: const Color(0xFF5C2D91).withValues(alpha: 0.3),
                blurRadius: 8)] : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: active ? Colors.white : Colors.white38,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      IconData icon, bool obscure, String hint) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12,
          fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: label == 'Email'
            ? TextInputType.emailAddress
            : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          filled: true, fillColor: const Color(0x1AFFFFFF),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFF9B59F5), width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _passField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Password', style: TextStyle(color: Colors.white54,
          fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(
        controller: _passCtrl,
        obscureText: _obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline,
              color: Colors.white38, size: 20),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
                _obscure ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38, size: 20),
          ),
          filled: true, fillColor: const Color(0x1AFFFFFF),
          hintText: '••••••••',
          hintStyle: const TextStyle(color: Colors.white24),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFF9B59F5), width: 1.5)),
        ),
      ),
    ]);
  }
}