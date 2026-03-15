import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class MoodCanvasScreen extends StatefulWidget {
  const MoodCanvasScreen({super.key});
  @override
  State<MoodCanvasScreen> createState() => _MoodCanvasScreenState();
}

class _MoodCanvasScreenState extends State<MoodCanvasScreen>
    with TickerProviderStateMixin {
  final List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;
  Color _selectedColor = const Color(0xFF9B59F5);
  double _brushSize = 8.0;
  bool _isAnalyzing = false;
  bool _showResult = false;
  String _detectedEmotion = '';
  String _aiResponse = '';
  bool _isEraser = false;
  late AnimationController _resultController;
  late Animation<double> _resultAnimation;

  // Color palette with emotion mapping
  final List<Map<String, dynamic>> _palette = [
    {'color': Color(0xFFFF4444), 'name': 'Red',    'emotion': 'anger'},
    {'color': Color(0xFFFF8C00), 'name': 'Orange', 'emotion': 'hype'},
    {'color': Color(0xFFFFD700), 'name': 'Yellow', 'emotion': 'joy'},
    {'color': Color(0xFF27AE60), 'name': 'Green',  'emotion': 'neutral'},
    {'color': Color(0xFF4A90D9), 'name': 'Blue',   'emotion': 'sadness'},
    {'color': Color(0xFF9B59F5), 'name': 'Purple', 'emotion': 'fear'},
    {'color': Color(0xFFFF69B4), 'name': 'Pink',   'emotion': 'joy'},
    {'color': Color(0xFF00B4B4), 'name': 'Teal',   'emotion': 'neutral'},
    {'color': Color(0xFFFF1493), 'name': 'Magenta','emotion': 'surprise'},
    {'color': Color(0xFFFFFFFF), 'name': 'White',  'emotion': 'neutral'},
    {'color': Color(0xFF888888), 'name': 'Gray',   'emotion': 'neutral'},
    {'color': Color(0xFF1A1A1A), 'name': 'Black',  'emotion': 'sadness'},
  ];

  final Map<String, Map<String, dynamic>> _emotionData = {
    'joy':      {'emoji': '😊', 'color': Color(0xFFFFB800), 'label': 'Joyful',
      'msg': 'Warm colors = warm soul! Your canvas is giving happy era fr 🌟'},
    'sadness':  {'emoji': '😔', 'color': Color(0xFF4A90D9), 'label': 'Melancholic',
      'msg': 'Blues and darks... we see the depth in you bestie 💙'},
    'anger':    {'emoji': '😤', 'color': Color(0xFFE74C3C), 'label': 'Fired Up',
      'msg': 'That red energy is INTENSE. Villain arc confirmed 🔥'},
    'fear':     {'emoji': '😰', 'color': Color(0xFF9B59B6), 'label': 'Anxious',
      'msg': 'Cool purples... your mind is running overtime isn\'t it 💜'},
    'surprise': {'emoji': '😲', 'color': Color(0xFF00B4B4), 'label': 'Excited',
      'msg': 'Vibrant chaos! That\'s some main character energy ✨'},
    'neutral':  {'emoji': '😌', 'color': Color(0xFF95A5A6), 'label': 'Balanced',
      'msg': 'Balanced palette = balanced mind. Slay peacefully 😌'},
    'hype':     {'emoji': '🔥', 'color': Color(0xFFFF6B35), 'label': 'Hyped',
      'msg': 'Those fire colors! You\'re absolutely built different today 🔥'},
  };

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _resultAnimation = CurvedAnimation(
        parent: _resultController, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  // Analyze colors used to detect emotion
  String _analyzeColors() {
    if (_strokes.isEmpty) return 'neutral';

    final colorCounts = <String, int>{};
    for (final stroke in _strokes) {
      final color = stroke.color;
      if (color == const Color(0xFFFFFFFF) ||
          color == const Color(0xFF888888)) continue;

      // Map color to emotion
      String emotion = 'neutral';
      final hsv = HSVColor.fromColor(color);
      final hue = hsv.hue;
      final saturation = hsv.saturation;
      final value = hsv.value;

      if (value < 0.2) {
        emotion = 'sadness'; // dark colors
      } else if (saturation < 0.2) {
        emotion = 'neutral'; // gray colors
      } else if (hue < 30 || hue > 330) {
        emotion = 'anger'; // red
      } else if (hue < 60) {
        emotion = 'hype'; // orange
      } else if (hue < 90) {
        emotion = 'joy'; // yellow
      } else if (hue < 150) {
        emotion = 'neutral'; // green
      } else if (hue < 210) {
        emotion = 'sadness'; // blue
      } else if (hue < 270) {
        emotion = 'fear'; // purple
      } else if (hue < 330) {
        emotion = 'surprise'; // pink/magenta
      }

      colorCounts[emotion] = (colorCounts[emotion] ?? 0) + stroke.points.length;
    }

    if (colorCounts.isEmpty) return 'neutral';
    return colorCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  void _analyzeCanvas() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('pehle kuch toh banao yaar! 🎨',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF5C2D91),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    final emotion = _analyzeColors();
    final emotionInfo = _emotionData[emotion] ?? _emotionData['neutral']!;

    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _detectedEmotion = emotion;
      _aiResponse = emotionInfo['msg'] as String;
      _showResult = true;
    });
    _resultController.forward();

    FirebaseService.saveMoodEntry(
      mode: 'mood_canvas',
      emotion: emotion,
      emotionLabel: emotionInfo['label'] as String,
      emoji: emotionInfo['emoji'] as String,
      points: 10,
      preview: 'Mood Canvas: painted with ${_strokes.length} strokes',
    );
    FirebaseService.checkAndAwardBadges();
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
      _showResult = false;
      _detectedEmotion = '';
      _aiResponse = '';
    });
    _resultController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final emotionInfo = _detectedEmotion.isNotEmpty
        ? _emotionData[_detectedEmotion]
        : null;
    final resultColor = emotionInfo != null
        ? (emotionInfo['color'] as Color)
        : const Color(0xFF9B59F5);

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
          child: Column(children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('🎨 Mood Canvas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                // Stroke count
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${_strokes.length} strokes',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _clearCanvas,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white54, size: 20),
                  ),
                ),
              ]),
            ),

            // ── Instruction ──────────────────────────────────
            if (!_showResult)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'paint ur feelings — no art degree needed 🎨 colors reveal your mood',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ── Canvas ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _selectedColor.withValues(alpha: 0.3),
                          width: 1.5),
                    ),
                    child: GestureDetector(
                      onPanStart: (details) {
                        if (_showResult) return;
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentStroke = _Stroke(
                            color: _isEraser
                                ? const Color(0xFF0A0A1A)
                                : _selectedColor,
                            size: _isEraser ? _brushSize * 3 : _brushSize,
                            points: [details.localPosition],
                          );
                          _strokes.add(_currentStroke!);
                        });
                      },
                      onPanUpdate: (details) {
                        if (_showResult) return;
                        setState(() {
                          _currentStroke?.points.add(details.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() => _currentStroke = null);
                      },
                      child: Stack(
                        children: [
                          // Canvas painter
                          CustomPaint(
                            painter: _CanvasPainter(_strokes),
                            size: Size.infinite,
                          ),
                          // Empty state
                          if (_strokes.isEmpty)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('🎨',
                                      style: TextStyle(
                                          fontSize: 48,
                                          color: Colors.white.withValues(alpha: 0.2))),
                                  const SizedBox(height: 12),
                                  Text(
                                    'start painting bestie\nno judgment here',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          // Analyzing overlay
                          if (_isAnalyzing)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('🤖', style: TextStyle(fontSize: 48)),
                                    SizedBox(height: 16),
                                    CircularProgressIndicator(
                                        color: Color(0xFF9B59F5)),
                                    SizedBox(height: 16),
                                    Text(
                                      'reading your color energy...',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Result ───────────────────────────────────────
            if (_showResult && emotionInfo != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScaleTransition(
                  scale: _resultAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: resultColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      Text(emotionInfo['emoji'] as String,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Feeling ${emotionInfo['label']}',
                              style: TextStyle(
                                  color: resultColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(_aiResponse,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.4)),
                            const SizedBox(height: 6),
                            const Text('⚡ +10 Zeno Points earned!',
                                style: TextStyle(
                                    color: Color(0xFF9B59F5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ── Tools ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                // Brush size
                Row(children: [
                  const Text('🖌️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10),
                        activeTrackColor: _selectedColor,
                        inactiveTrackColor:
                            _selectedColor.withValues(alpha: 0.2),
                        thumbColor: Colors.white,
                        overlayColor:
                            _selectedColor.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _brushSize,
                        min: 3, max: 30,
                        onChanged: (v) =>
                            setState(() => _brushSize = v),
                      ),
                    ),
                  ),
                  // Brush preview
                  Container(
                    width: _brushSize.clamp(8.0, 28.0),
                    height: _brushSize.clamp(8.0, 28.0),
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Eraser toggle
                  GestureDetector(
                    onTap: () => setState(() => _isEraser = !_isEraser),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isEraser
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isEraser
                              ? Colors.white
                              : Colors.transparent,
                        ),
                      ),
                      child: const Text('🧹',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ]),

                const SizedBox(height: 10),

                // Color palette
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _palette.length,
                    itemBuilder: (_, i) {
                      final c = _palette[i]['color'] as Color;
                      final isSelected = _selectedColor == c && !_isEraser;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedColor = c;
                          _isEraser = false;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          width: isSelected ? 44 : 36,
                          height: isSelected ? 44 : 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(
                                    color: c.withValues(alpha: 0.6),
                                    blurRadius: 8)]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Analyse Button ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                if (_showResult)
                  Expanded(
                    child: GestureDetector(
                      onTap: _clearCanvas,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0x33FFFFFF)),
                        ),
                        child: const Center(
                          child: Text('🔄  Paint Again',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GestureDetector(
                      onTap: _isAnalyzing ? null : _analyzeCanvas,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5C2D91),
                                Color(0xFF007A7A)
                              ]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5C2D91)
                                  .withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isAnalyzing
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('✨ Read My Canvas',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                if (_showResult) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            resultColor,
                            resultColor.withValues(alpha: 0.6)
                          ]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('🏠  Home',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

// ── Stroke model ──────────────────────────────────────────────────
class _Stroke {
  final Color color;
  final double size;
  final List<Offset> points;
  _Stroke({required this.color, required this.size, required this.points});
}

// ── Canvas painter ────────────────────────────────────────────────
class _CanvasPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _CanvasPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.size
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.size / 2, paint..style = PaintingStyle.fill);
        continue;
      }

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        final p0 = stroke.points[i - 1];
        final p1 = stroke.points[i];
        path.quadraticBezierTo(
            p0.dx, p0.dy,
            (p0.dx + p1.dx) / 2,
            (p0.dy + p1.dy) / 2);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}