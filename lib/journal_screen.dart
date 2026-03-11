import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _controller = TextEditingController();
  String _detectedEmotion = '';
  String _aiResponse = '';
  bool _isAnalyzing = false;
  int _wordCount = 0;

  // Replace with your actual Gemini API key
  static const String _apiKey = 'AIzaSyBiHhDSJJWJULQZvxv_pyWoqv0Sv4Kz64w';

  final Map<String, Map<String, dynamic>> _emotionData = {
    'joy':      {'emoji': '😊', 'color': Color(0xFFFFB800), 'label': 'Joyful'},
    'sadness':  {'emoji': '😔', 'color': Color(0xFF4A90D9), 'label': 'Sad'},
    'anger':    {'emoji': '😤', 'color': Color(0xFFE74C3C), 'label': 'Angry'},
    'fear':     {'emoji': '😰', 'color': Color(0xFF9B59B6), 'label': 'Anxious'},
    'surprise': {'emoji': '😲', 'color': Color(0xFF00B4B4), 'label': 'Surprised'},
    'disgust':  {'emoji': '🤢', 'color': Color(0xFF27AE60), 'label': 'Disgusted'},
    'neutral':  {'emoji': '😐', 'color': Color(0xFF95A5A6), 'label': 'Neutral'},
  };

  void _updateWordCount(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    setState(() {
      _wordCount = text.trim().isEmpty ? 0 : words.length;
    });
  }

  Future<Map<String, String>> _analyzeWithGemini(String text) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = '''
Analyze the emotion in this journal entry and respond in exactly this format:
EMOTION: [one of: joy, sadness, anger, fear, surprise, disgust, neutral]
RESPONSE: [a warm, empathetic 2-3 sentence response to the person]

Journal entry: "$text"
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse the response
      final emotionMatch = RegExp(r'EMOTION:\s*(\w+)').firstMatch(responseText);
      final responseMatch = RegExp(r'RESPONSE:\s*(.+)', dotAll: true).firstMatch(responseText);

      final emotion = emotionMatch?.group(1)?.toLowerCase() ?? 'neutral';
      final aiResponse = responseMatch?.group(1)?.trim() ?? 
          'Thank you for sharing. Keep journaling — every entry helps you understand yourself better.';

      // Validate emotion is one of our supported ones
      final validEmotions = ['joy', 'sadness', 'anger', 'fear', 'surprise', 'disgust', 'neutral'];
      final finalEmotion = validEmotions.contains(emotion) ? emotion : 'neutral';

      return {'emotion': finalEmotion, 'response': aiResponse};
    } catch (e) {
      // Fallback to local detection if API fails
      return {'emotion': _detectEmotionLocally(text), 'response': _getLocalResponse(_detectEmotionLocally(text))};
    }
  }

  String _detectEmotionLocally(String text) {
    text = text.toLowerCase();
    if (text.contains(RegExp(r'happy|joy|great|amazing|wonderful|love|excited|good|fantastic|awesome'))) return 'joy';
    if (text.contains(RegExp(r'sad|cry|tears|miss|lonely|depressed|unhappy|hurt|pain|loss'))) return 'sadness';
    if (text.contains(RegExp(r'angry|mad|furious|hate|annoyed|frustrated|rage|upset'))) return 'anger';
    if (text.contains(RegExp(r'scared|afraid|worried|anxious|nervous|fear|stress|panic'))) return 'fear';
    if (text.contains(RegExp(r'surprised|shocked|unexpected|wow|unbelievable|sudden'))) return 'surprise';
    if (text.contains(RegExp(r'disgusted|gross|horrible|awful|terrible|nasty'))) return 'disgust';
    return 'neutral';
  }

  String _getLocalResponse(String emotion) {
    final responses = {
      'joy': "That's wonderful! Your positive energy is clearly shining through. Keep embracing these moments of joy! 🌟",
      'sadness': "It's okay to feel sad sometimes. Your feelings are valid. Brighter days are ahead. 💙",
      'anger': "I can sense some frustration. Take a deep breath — it's okay to feel this way. 🌊",
      'fear': "Feeling anxious is completely normal. You're stronger than your fears. You've got this! 💪",
      'surprise': "Life is full of unexpected moments! Embrace the unexpected — it often leads to growth. ✨",
      'disgust': "Something really bothered you today. Your boundaries and values matter. 🛡️",
      'neutral': "Thank you for sharing. Keep writing — every entry helps you know yourself better. 📖",
    };
    return responses[emotion] ?? responses['neutral']!;
  }

  void _analyzeEntry() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _detectedEmotion = '';
      _aiResponse = '';
    });

    final result = await _analyzeWithGemini(_controller.text);

    setState(() {
      _isAnalyzing = false;
      _detectedEmotion = result['emotion']!;
      _aiResponse = result['response']!;
    });
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emotionInfo = _detectedEmotion.isNotEmpty
        ? _emotionData[_detectedEmotion]!
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
                      '✍️ Journal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_wordCount words',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
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
                      Text(
                        _getFormattedDate(),
                        style: const TextStyle(
                          color: Color(0xFF9B59F5),
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Text input
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Color(0x1AFFFFFF)),
                        ),
                        child: TextField(
                          controller: _controller,
                          onChanged: _updateWordCount,
                          maxLines: 8,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.6,
                          ),
                          decoration: const InputDecoration(
                            hintText: "What's on your mind today? Write freely...",
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Analyze button
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _isAnalyzing ? null : _analyzeEntry,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5C2D91), Color(0xFF007A7A)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF5C2D91),
                                  blurRadius: 12,
                                ),
                              ],
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
                                      '🤖 Analyse with AI',
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

                      // Emotion result
                      if (emotionInfo != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (emotionInfo['color'] as Color).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (emotionInfo['color'] as Color).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(emotionInfo['emoji'] as String,
                                  style: const TextStyle(fontSize: 48)),
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