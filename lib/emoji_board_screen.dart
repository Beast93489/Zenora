import 'package:flutter/material.dart';

class EmojiBoardScreen extends StatefulWidget {
  const EmojiBoardScreen({super.key});

  @override
  State<EmojiBoardScreen> createState() => _EmojiBoardScreenState();
}

class _EmojiBoardScreenState extends State<EmojiBoardScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedEmojis = {};
  String _detectedEmotion = '';
  String _aiResponse = '';
  bool _isAnalyzing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Emoji categories
  final Map<String, List<Map<String, dynamic>>> _emojiCategories = {
    'Happiness': [
      {'emoji': '😊', 'emotion': 'joy', 'label': 'Happy'},
      {'emoji': '😄', 'emotion': 'joy', 'label': 'Excited'},
      {'emoji': '🥰', 'emotion': 'joy', 'label': 'Loved'},
      {'emoji': '😎', 'emotion': 'joy', 'label': 'Cool'},
      {'emoji': '🤩', 'emotion': 'joy', 'label': 'Amazed'},
      {'emoji': '😇', 'emotion': 'joy', 'label': 'Blessed'},
    ],
    'Sadness': [
      {'emoji': '😔', 'emotion': 'sadness', 'label': 'Sad'},
      {'emoji': '😢', 'emotion': 'sadness', 'label': 'Crying'},
      {'emoji': '😞', 'emotion': 'sadness', 'label': 'Disappointed'},
      {'emoji': '🥺', 'emotion': 'sadness', 'label': 'Pleading'},
      {'emoji': '😪', 'emotion': 'sadness', 'label': 'Sleepy'},
      {'emoji': '💔', 'emotion': 'sadness', 'label': 'Heartbroken'},
    ],
    'Anger': [
      {'emoji': '😤', 'emotion': 'anger', 'label': 'Frustrated'},
      {'emoji': '😠', 'emotion': 'anger', 'label': 'Angry'},
      {'emoji': '🤬', 'emotion': 'anger', 'label': 'Furious'},
      {'emoji': '😒', 'emotion': 'anger', 'label': 'Annoyed'},
      {'emoji': '🙄', 'emotion': 'anger', 'label': 'Eye Roll'},
      {'emoji': '😑', 'emotion': 'anger', 'label': 'Done'},
    ],
    'Anxiety': [
      {'emoji': '😰', 'emotion': 'fear', 'label': 'Anxious'},
      {'emoji': '😟', 'emotion': 'fear', 'label': 'Worried'},
      {'emoji': '😨', 'emotion': 'fear', 'label': 'Scared'},
      {'emoji': '🫠', 'emotion': 'fear', 'label': 'Melting'},
      {'emoji': '😬', 'emotion': 'fear', 'label': 'Nervous'},
      {'emoji': '🤯', 'emotion': 'fear', 'label': 'Overwhelmed'},
    ],
    'Neutral': [
      {'emoji': '😐', 'emotion': 'neutral', 'label': 'Neutral'},
      {'emoji': '🙂', 'emotion': 'neutral', 'label': 'Okay'},
      {'emoji': '😌', 'emotion': 'neutral', 'label': 'Calm'},
      {'emoji': '🤔', 'emotion': 'neutral', 'label': 'Thinking'},
      {'emoji': '😶', 'emotion': 'neutral', 'label': 'Speechless'},
      {'emoji': '🫤', 'emotion': 'neutral', 'label': 'Meh'},
    ],
    'Surprise': [
      {'emoji': '😲', 'emotion': 'surprise', 'label': 'Shocked'},
      {'emoji': '🤭', 'emotion': 'surprise', 'label': 'Surprised'},
      {'emoji': '😮', 'emotion': 'surprise', 'label': 'Wow'},
      {'emoji': '🫢', 'emotion': 'surprise', 'label': 'Gasp'},
      {'emoji': '🥳', 'emotion': 'surprise', 'label': 'Celebrate'},
      {'emoji': '😯', 'emotion': 'surprise', 'label': 'Stunned'},
    ],
  };

  final Map<String, Map<String, dynamic>> _emotionData = {
    'joy':      {'emoji': '😊', 'color': Color(0xFFFFB800), 'label': 'Joyful'},
    'sadness':  {'emoji': '😔', 'color': Color(0xFF4A90D9), 'label': 'Sad'},
    'anger':    {'emoji': '😤', 'color': Color(0xFFE74C3C), 'label': 'Angry'},
    'fear':     {'emoji': '😰', 'color': Color(0xFF9B59B6), 'label': 'Anxious'},
    'surprise': {'emoji': '😲', 'color': Color(0xFF00B4B4), 'label': 'Surprised'},
    'disgust':  {'emoji': '🤢', 'color': Color(0xFF27AE60), 'label': 'Disgusted'},
    'neutral':  {'emoji': '😐', 'color': Color(0xFF95A5A6), 'label': 'Neutral'},
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _detectEmotionFromEmojis() {
    if (_selectedEmojis.isEmpty) return 'neutral';
    final emotionCounts = <String, int>{};
    for (final category in _emojiCategories.values) {
      for (final item in category) {
        if (_selectedEmojis.contains(item['emoji'])) {
          final emotion = item['emotion'] as String;
          emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
        }
      }
    }
    if (emotionCounts.isEmpty) return 'neutral';
    return emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String _getResponse(String emotion) {
    final responses = {
      'joy': "Your emoji selection radiates positive energy! 🌟 These feelings of happiness are wonderful — hold onto them and let them fuel your day!",
      'sadness': "It's okay to feel this way. 💙 Your emotions are valid. Take it easy today — be gentle with yourself and reach out to someone you trust.",
      'anger': "I can see you're feeling frustrated right now. 🌊 Take a few deep breaths. This feeling will pass — try to channel it into something productive.",
      'fear': "Anxiety can feel overwhelming, but you're stronger than you think. 💪 Try the 5-4-3-2-1 grounding technique: name 5 things you can see right now.",
      'surprise': "Life is full of unexpected moments! ✨ Whether it's good or challenging news, remember that you have the strength to adapt and grow.",
      'neutral': "Feeling balanced today? 😌 That's perfectly fine — not every day needs to be intense. Use this calm energy to focus on something meaningful.",
    };
    return responses[emotion] ?? responses['neutral']!;
  }

  void _analyzeBoard() async {
    if (_selectedEmojis.isEmpty) return;
    setState(() {
      _isAnalyzing = true;
      _detectedEmotion = '';
      _aiResponse = '';
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    final emotion = _detectEmotionFromEmojis();
    setState(() {
      _isAnalyzing = false;
      _detectedEmotion = emotion;
      _aiResponse = _getResponse(emotion);
    });
  }

  void _toggleEmoji(String emoji) {
    setState(() {
      if (_selectedEmojis.contains(emoji)) {
        _selectedEmojis.remove(emoji);
      } else {
        if (_selectedEmojis.length < 6) {
          _selectedEmojis.add(emoji);
        }
      }
      // Reset result when selection changes
      _detectedEmotion = '';
      _aiResponse = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final emotionInfo = _detectedEmotion.isNotEmpty
        ? _emotionData[_detectedEmotion]
        : null;

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
                      '😊 Emoji Board',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedEmojis.length}/6',
                      style: const TextStyle(
                        color: Color(0xFF9B59F5),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instruction
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0x1AFFFFFF)),
                        ),
                        child: const Text(
                          'Pick up to 6 emojis that best describe how you feel right now. Mix and match across categories!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Selected emojis preview
                      if (_selectedEmojis.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0x1A9B59F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Color(0xFF9B59F5).withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Your Selection',
                                style: TextStyle(
                                  color: Color(0xFF9B59F5),
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: _selectedEmojis
                                    .map((e) => ScaleTransition(
                                          scale: _pulseAnimation,
                                          child: Text(e,
                                              style: const TextStyle(
                                                  fontSize: 32)),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Emoji categories
                      ..._emojiCategories.entries.map((category) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.key,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              children: category.value.map((item) {
                                final emoji = item['emoji'] as String;
                                final isSelected =
                                    _selectedEmojis.contains(emoji);
                                return GestureDetector(
                                  onTap: () => _toggleEmoji(emoji),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(0xFF5C2D91)
                                          : Color(0x1AFFFFFF),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Color(0xFF9B59F5)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(emoji,
                                          style: TextStyle(
                                              fontSize:
                                                  isSelected ? 26 : 22)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),

                      // Analyse button
                      if (_selectedEmojis.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: _isAnalyzing ? null : _analyzeBoard,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF5C2D91),
                                    Color(0xFF007A7A)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: _isAnalyzing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        '✨ Read My Mood',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                      // Result
                      if (emotionInfo != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (emotionInfo['color'] as Color)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (emotionInfo['color'] as Color)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                emotionInfo['emoji'] as String,
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Feeling ${emotionInfo['label']}',
                                style: TextStyle(
                                  color: emotionInfo['color'] as Color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _aiResponse,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Points earned
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Color(0x1A9B59F5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '⚡ +5 Zeno Points earned!',
                                  style: TextStyle(
                                    color: Color(0xFF9B59F5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}