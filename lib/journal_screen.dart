import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'config.dart';
import 'dart:convert';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _detectedEmotion = '';
  String _aiResponse = '';
  bool _isAnalyzing = false;
  int _wordCount = 0;
  late AnimationController _resultController;
  late Animation<double> _resultAnimation;
  late AnimationController _shimmerController;

  final List<String> _prompts = [
    'spill the tea bhai, what happened today? ☕',
    'arey yaar, kya chal raha hai life mein? 🤔',
    'no filter zone — write whatever is on ur mind 💭',
    'teri anxiety teri hai, yahan safe space hai 🫶',
    'sharma ji ka beta nahi padh raha yahan, be free 😤',
    'dear diary... (just kidding, be yourself) ✍️',
    'pagal thoughts? likho, we don\'t judge 🧠',
    'what\'s living rent free in your head rn? 🏠',
    'sab theek? if not, that\'s okay too 💜',
    'today was giving... (you complete it) 👀',
    'what\'s on your mind today, baawe? 🤔'
    'let it all out, I\'m here to listen 🫂',
    'write like no one\'s reading, because they aren\'t! 🕵️‍♂️',
    'your vibe attracts your tribe — what energy are you putting out? 🌌',
    'sometimes the messiest thoughts lead to the clearest insights — just write! 🌀',
    'don\'t overthink it, just let the words flow like a river 🌊',
    'your journal is your personal therapist, baawe — spill the tea without holding back ☕',
  ];

  late String _currentPrompt;

  final Map<String, Map<String, dynamic>> _emotionData = {
    'joy':      {'emoji': '😊', 'color': Color(0xFFFFB800), 'label': 'Joyful',    'genZ': 'you\'re eating and leaving no crumbs fr 🔥'},
    'sadness':  {'emoji': '😔', 'color': Color(0xFF4A90D9), 'label': 'Sad',       'genZ': 'it\'s okay to not be okay bestie 💙'},
    'anger':    {'emoji': '😤', 'color': Color(0xFFE74C3C), 'label': 'Angry',     'genZ': 'villain era unlocked, we respect it 😈'},
    'fear':     {'emoji': '😰', 'color': Color(0xFF9B59B6), 'label': 'Anxious',   'genZ': 'breathe in, breathe out, sab theek hoga 🧘'},
    'surprise': {'emoji': '😲', 'color': Color(0xFF00B4B4), 'label': 'Surprised', 'genZ': 'plot twist incoming fr fr 😲'},
    'disgust':  {'emoji': '🤢', 'color': Color(0xFF27AE60), 'label': 'Disgusted', 'genZ': 'that ain\'t it chief and you know it 💀'},
    'neutral':  {'emoji': '😐', 'color': Color(0xFF95A5A6), 'label': 'Neutral',   'genZ': 'just existing peacefully, valid 😌'},
  };

  final List<Map<String, dynamic>> _writingTips = [
    {'emoji': '💡', 'tip': 'Write at least 20 words for better AI analysis'},
    {'emoji': '🔒', 'tip': 'Your journal is private — only you can see this'},
    {'emoji': '🧠', 'tip': 'AI reads tone, not just words — be honest'},
    {'emoji': '✨', 'tip': 'No grammar police here, write however you want'},
    {'emoji': '🫶', 'tip': 'Regular journaling = main character development'},
  ];

  late Map<String, dynamic> _currentTip;

  @override
  void initState() {
    super.initState();
    _currentPrompt = (_prompts..shuffle()).first;
    _currentTip = (_writingTips..shuffle()).first;
    _resultController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _resultAnimation = CurvedAnimation(
        parent: _resultController, curve: Curves.easeOutBack);
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _resultController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _updateWordCount(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    setState(() {
      _wordCount = text.trim().isEmpty ? 0 : words.length;
    });
  }

  Future<Map<String, String>> _analyzeWithGroq(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.groqKey}',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an empathetic mental wellness AI. Analyze emotions in journal entries and respond warmly.',
            },
            {
              'role': 'user',
              'content': '''Analyze the emotion in this journal entry and respond in exactly this format:
EMOTION: [one of: joy, sadness, anger, fear, surprise, disgust, neutral]
RESPONSE: [a warm, empathetic 2-3 sentence response to the person]

Journal entry: "$text"''',
            }
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['choices'][0]['message']['content'] as String;
        final lines = responseText.split('\n');
        String emotion = 'neutral';
        String aiResponse = '';
        for (final line in lines) {
          if (line.startsWith('EMOTION:')) {
            emotion = line.replaceFirst('EMOTION:', '').trim().toLowerCase();
          } else if (line.startsWith('RESPONSE:')) {
            aiResponse = line.replaceFirst('RESPONSE:', '').trim();
          }
        }
        if (!['joy','sadness','anger','fear','surprise','disgust','neutral'].contains(emotion)) {
          emotion = 'neutral';
        }
        if (aiResponse.isEmpty) aiResponse = _getLocalResponse(emotion);
        return {'emotion': emotion, 'response': aiResponse};
      } else {
        debugPrint('Groq error: ${response.body}');
        final emotion = _detectEmotionLocally(text);
        return {'emotion': emotion, 'response': _getLocalResponse(emotion)};
      }
    } catch (e) {
      debugPrint('Journal error: $e');
      final emotion = _detectEmotionLocally(text);
      return {'emotion': emotion, 'response': _getLocalResponse(emotion)};
    }
  }

  String _detectEmotionLocally(String text) {
    text = text.toLowerCase();
    if (text.contains(RegExp(r'happy|joy|great|amazing|wonderful|love|excited|good|fantastic|awesome|mast|khush'))) return 'joy';
    if (text.contains(RegExp(r'sad|cry|tears|miss|lonely|depressed|unhappy|hurt|pain|loss|dukh|rona'))) return 'sadness';
    if (text.contains(RegExp(r'angry|mad|furious|hate|annoyed|frustrated|rage|upset|gussa|irritate'))) return 'anger';
    if (text.contains(RegExp(r'scared|afraid|worried|anxious|nervous|fear|stress|panic|dara|tension'))) return 'fear';
    if (text.contains(RegExp(r'surprised|shocked|unexpected|wow|unbelievable|sudden|arey|kya'))) return 'surprise';
    if (text.contains(RegExp(r'disgusted|gross|horrible|awful|terrible|nasty|bakwaas|ganda'))) return 'disgust';
    return 'neutral';
  }

  String _getLocalResponse(String emotion) {
    final responses = {
      'joy':     'That positive energy is radiating from every word! 🌟 Hold onto this feeling — you deserve every bit of this happiness.',
      'sadness': 'It takes courage to write about pain. 💙 Your feelings are completely valid. Be gentle with yourself today.',
      'anger':   'That frustration is completely valid. 🌊 Take a breath — writing it out is already a step toward processing it.',
      'fear':    'Anxiety can feel overwhelming, but you\'re stronger than you think. 💪 You\'ve survived 100% of your bad days so far.',
      'surprise':'Life loves throwing curveballs! ✨ Whether good or challenging — you have the strength to navigate whatever comes.',
      'disgust': 'Something really bothered you today, and that\'s okay. 🛡️ Your boundaries and values matter deeply.',
      'neutral': 'Thank you for showing up and writing today. 📖 Every entry is a step toward knowing yourself better.',
    };
    return responses[emotion] ?? responses['neutral']!;
  }

  void _analyzeEntry() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('kuch toh likho yaar! 😤', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF5C2D91), behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_wordCount < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('thoda aur likho, 5+ words chahiye 📝', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF5C2D91), behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    _focusNode.unfocus();
    setState(() { _isAnalyzing = true; _detectedEmotion = ''; _aiResponse = ''; });
    _resultController.reset();

    final result = await _analyzeWithGroq(_controller.text);
    final emotion = result['emotion']!;
    final emotionInfo = _emotionData[emotion] ?? _emotionData['neutral']!;

    if (!mounted) return;
    setState(() { _isAnalyzing = false; _detectedEmotion = emotion; _aiResponse = result['response']!; });
    _resultController.forward();

    FirebaseService.saveMoodEntry(
      mode: 'journal', emotion: emotion,
      emotionLabel: emotionInfo['label'] as String,
      emoji: emotionInfo['emoji'] as String, points: 10,
      preview: _controller.text.length > 60 ? '${_controller.text.substring(0, 60)}...' : _controller.text,
    );
    FirebaseService.checkAndAwardBadges();
  }

  void _clearEntry() {
    setState(() {
      _controller.clear(); _wordCount = 0; _detectedEmotion = ''; _aiResponse = '';
      _currentPrompt = (_prompts..shuffle()).first;
      _currentTip = (_writingTips..shuffle()).first;
    });
    _resultController.reset();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Color get _gradientColor {
    if (_detectedEmotion.isEmpty) return const Color(0xFF5C2D91);
    return (_emotionData[_detectedEmotion]?['color'] as Color?) ?? const Color(0xFF5C2D91);
  }

  @override
  Widget build(BuildContext context) {
    final emotionInfo = _detectedEmotion.isNotEmpty ? _emotionData[_detectedEmotion] : null;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: _detectedEmotion.isEmpty
                ? [const Color(0xFF1A0533), const Color(0xFF0F0F1E), const Color(0xFF003333)]
                : [_gradientColor.withValues(alpha: 0.4), const Color(0xFF0F0F1E), const Color(0xFF003333)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Text('✍️  ', style: TextStyle(fontSize: 20)), Text('Journal', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]),
                  Text(_getFormattedDate(), style: const TextStyle(color: Color(0xFF9B59F5), fontSize: 11)),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _wordCount >= 20 ? const Color(0xFF27AE60).withValues(alpha: 0.2) : const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _wordCount >= 20 ? const Color(0xFF27AE60).withValues(alpha: 0.5) : const Color(0x1AFFFFFF)),
                  ),
                  child: Text('$_wordCount words', style: TextStyle(color: _wordCount >= 20 ? const Color(0xFF27AE60) : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                if (_controller.text.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(onTap: _clearEntry, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 18))),
                ],
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  Container(
                    decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: _focusNode.hasFocus ? const Color(0xFF9B59F5).withValues(alpha: 0.5) : const Color(0x1AFFFFFF))),
                    child: TextField(
                      controller: _controller, focusNode: _focusNode,
                      maxLines: null, minLines: 8,
                      onChanged: _updateWordCount, onTap: () => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                      decoration: InputDecoration(hintText: _currentPrompt, hintStyle: const TextStyle(color: Colors.white24, fontSize: 14, height: 1.5), border: InputBorder.none, contentPadding: const EdgeInsets.all(20)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_wordCount > 0 && _detectedEmotion.isEmpty) ...[
                    Row(children: [
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (_wordCount / 20).clamp(0.0, 1.0), minHeight: 4, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(_wordCount >= 20 ? const Color(0xFF27AE60) : const Color(0xFF9B59F5))))),
                      const SizedBox(width: 8),
                      Text(_wordCount >= 20 ? 'ready to analyse! ✅' : '${20 - _wordCount} more words for best results', style: TextStyle(color: _wordCount >= 20 ? const Color(0xFF27AE60) : Colors.white38, fontSize: 11)),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _isAnalyzing ? null : _analyzeEntry,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF5C2D91), Color(0xFF007A7A)]), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: const Color(0xFF5C2D91).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))]),
                        child: Center(
                          child: _isAnalyzing
                              ? Row(mainAxisSize: MainAxisSize.min, children: [
                                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                  const SizedBox(width: 12),
                                  Text(['AI padh raha hai tera dard... 🤖', 'decoding your vibe fr...', 'asking Groq ji... 🙏', 'manifesting your result...'][DateTime.now().second % 4], style: const TextStyle(color: Colors.white, fontSize: 14)),
                                ])
                              : const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text('🤖', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 8),
                                  Text('Analyse with AI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_detectedEmotion.isNotEmpty && emotionInfo != null)
                    ScaleTransition(
                      scale: _resultAnimation,
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: _gradientColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: _gradientColor.withValues(alpha: 0.4))),
                        child: Column(children: [
                          Row(children: [
                            Text(emotionInfo['emoji'] as String, style: const TextStyle(fontSize: 40)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Feeling ${emotionInfo['label']}', style: TextStyle(color: _gradientColor, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text(emotionInfo['genZ'] as String, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ])),
                          ]),
                          const SizedBox(height: 16),
                          Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(14)), child: Text(_aiResponse, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6))),
                          const SizedBox(height: 14),
                          Row(children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: const Color(0x1A9B59F5), borderRadius: BorderRadius.circular(20)), child: const Text('⚡ +10 Zeno Points!', style: TextStyle(color: Color(0xFF9B59F5), fontWeight: FontWeight.bold, fontSize: 13))),
                            const Spacer(),
                            GestureDetector(onTap: _clearEntry, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x33FFFFFF))), child: const Text('✍️ Write more', style: TextStyle(color: Colors.white70, fontSize: 13)))),
                          ]),
                        ]),
                      ),
                    ),
                  if (_detectedEmotion.isEmpty) ...[
                    Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1AFFFFFF))),
                      child: Row(children: [Text(_currentTip['emoji'] as String, style: const TextStyle(fontSize: 20)), const SizedBox(width: 12), Expanded(child: Text(_currentTip['tip'] as String, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)))])),
                    const SizedBox(height: 12),
                    Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x0A9B59F5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF9B59F5).withValues(alpha: 0.2))),
                      child: const Row(children: [Text('🏆', style: TextStyle(fontSize: 20)), SizedBox(width: 12), Expanded(child: Text('Journal entries give +10 Zeno Points — most of any mode! Log daily for max streak 🔥', style: TextStyle(color: Color(0xFF9B59F5), fontSize: 12, height: 1.4)))])),
                  ],
                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}