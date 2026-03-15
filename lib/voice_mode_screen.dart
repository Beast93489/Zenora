import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'config.dart';
import 'dart:convert';
import 'dart:math';

class VoiceModeScreen extends StatefulWidget {
  const VoiceModeScreen({super.key});
  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAnalyzing = false;
  bool _speechAvailable = false;
  String _transcript = '';
  String _detectedEmotion = '';
  String _aiResponse = '';
  double _soundLevel = 0.0;

  late AnimationController _rippleController;
  late AnimationController _waveController;
  late AnimationController _resultController;
  late Animation<double> _ripple1;
  late Animation<double> _ripple2;
  late Animation<double> _ripple3;
  late Animation<double> _resultAnim;

  final List<String> _hints = [
    'bol daal yaar, no judgment here 🎤',
    'aaj kaisa feel ho raha hai? bata...',
    'dil ki baat karo, AI sun raha hai 🤖',
    'sharma ji ki tarah mat socho, bas bolo',
    'kya chal raha hai life mein?',
    'frustrated ho? khushi mein ho? bolo!',
  ];
  late String _currentHint;

  final List<double> _waveHeights = List.filled(20, 0.3);
  final _random = Random();

  final Map<String, Map<String, dynamic>> _emotionData = {
    'joy':      {'emoji': '😊', 'color': Color(0xFFFFB800), 'label': 'Joyful',    'genZ': 'you\'re literally radiating happiness rn ✨'},
    'sadness':  {'emoji': '😔', 'color': Color(0xFF4A90D9), 'label': 'Sad',       'genZ': 'it\'s okay to not be okay bestie 💙'},
    'anger':    {'emoji': '😤', 'color': Color(0xFFE74C3C), 'label': 'Angry',     'genZ': 'villain arc activated, we respect it 😈'},
    'fear':     {'emoji': '😰', 'color': Color(0xFF9B59B6), 'label': 'Anxious',   'genZ': 'sab theek hoga, breathe in breathe out 🧘'},
    'surprise': {'emoji': '😲', 'color': Color(0xFF00B4B4), 'label': 'Surprised', 'genZ': 'plot twist loading... 😲'},
    'disgust':  {'emoji': '🤢', 'color': Color(0xFF27AE60), 'label': 'Disgusted', 'genZ': 'that ain\'t it and you know it 💀'},
    'neutral':  {'emoji': '😐', 'color': Color(0xFF95A5A6), 'label': 'Neutral',   'genZ': 'just existing peacefully, valid 😌'},
  };

  @override
  void initState() {
    super.initState();
    _currentHint = (_hints..shuffle()).first;
    _rippleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _ripple1 = Tween<double>(begin: 0.8, end: 1.6).animate(CurvedAnimation(parent: _rippleController, curve: Curves.easeOut));
    _ripple2 = Tween<double>(begin: 0.8, end: 1.6).animate(CurvedAnimation(parent: _rippleController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _ripple3 = Tween<double>(begin: 0.8, end: 1.6).animate(CurvedAnimation(parent: _rippleController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))
      ..addListener(_updateWaves)..repeat();
    _resultController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _resultAnim = CurvedAnimation(parent: _resultController, curve: Curves.easeOutBack);
    _initSpeech();
  }

  void _updateWaves() {
    if (_isListening) {
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          final base = 0.2 + (_soundLevel / 100) * 0.6;
          _waveHeights[i] = (base + _random.nextDouble() * 0.5 * (_soundLevel / 100 + 0.3)).clamp(0.1, 1.0);
        }
      });
    } else {
      for (int i = 0; i < _waveHeights.length; i++) {
        _waveHeights[i] = 0.15 + _random.nextDouble() * 0.1;
      }
    }
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechAvailable = await _speech.initialize(
        onError: (e) => debugPrint('Speech error: $e'),
        onStatus: (s) { if ((s == 'done' || s == 'notListening') && mounted && _isListening) _stopListening(); },
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('mic permission nahi hai yaar! 😅', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF5C2D91), behavior: SnackBarBehavior.floating));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() { _isListening = true; _transcript = ''; _detectedEmotion = ''; _aiResponse = ''; });
    _resultController.reset();
    _rippleController.repeat();
    await _speech.listen(
      onResult: (result) => setState(() => _transcript = result.recognizedWords),
      onSoundLevelChange: (level) => setState(() => _soundLevel = (level + 2).clamp(0.0, 10.0) * 10),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_IN',
      listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: false),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    HapticFeedback.mediumImpact();
    setState(() { _isListening = false; _soundLevel = 0; });
    _rippleController.stop();
    if (_transcript.isNotEmpty) _analyzeVoice();
  }

  Future<void> _analyzeVoice() async {
    if (_transcript.trim().isEmpty) return;
    setState(() => _isAnalyzing = true);
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AppConfig.groqKey}'},
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'system', 'content': 'You are an empathetic mental wellness AI. Analyze emotions in voice transcripts.'},
            {'role': 'user', 'content': 'Analyze the emotion in this voice transcript from a mental wellness app.\n\nTranscript: "$_transcript"\n\nRespond EXACTLY:\nEMOTION: [one of: joy, sadness, anger, fear, surprise, disgust, neutral]\nRESPONSE: [warm, empathetic 2-3 sentences. Be genuine and supportive.]'},
          ],
          'max_tokens': 200, 'temperature': 0.7,
        }),
      );

      String emotion = 'neutral';
      String aiResponse = '';

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String;
        for (final line in text.split('\n')) {
          if (line.startsWith('EMOTION:')) emotion = line.replaceFirst('EMOTION:', '').trim().toLowerCase();
          else if (line.startsWith('RESPONSE:')) aiResponse = line.replaceFirst('RESPONSE:', '').trim();
        }
        if (!_emotionData.containsKey(emotion)) emotion = 'neutral';
        if (aiResponse.isEmpty) aiResponse = _getFallback(emotion);
      } else {
        emotion = _detectLocally(_transcript);
        aiResponse = _getFallback(emotion);
      }

      if (!mounted) return;
      setState(() { _detectedEmotion = emotion; _aiResponse = aiResponse; _isAnalyzing = false; });
      _resultController.forward();

      final emotionInfo = _emotionData[emotion]!;
      FirebaseService.saveMoodEntry(mode: 'voice_mode', emotion: emotion, emotionLabel: emotionInfo['label'] as String, emoji: emotionInfo['emoji'] as String, points: 15,
        preview: '🎤 "${_transcript.length > 50 ? _transcript.substring(0, 50) + '...' : _transcript}"');
      FirebaseService.checkAndAwardBadges();
    } catch (e) {
      debugPrint('Voice analysis error: $e');
      final emotion = _detectLocally(_transcript);
      if (!mounted) return;
      setState(() { _detectedEmotion = emotion; _aiResponse = _getFallback(emotion); _isAnalyzing = false; });
      _resultController.forward();
    }
  }

  String _detectLocally(String text) {
    text = text.toLowerCase();
    if (text.contains(RegExp(r'happy|great|amazing|love|excited|good|mast|khush|acha'))) return 'joy';
    if (text.contains(RegExp(r'sad|cry|miss|lonely|hurt|dukh|bura|rona'))) return 'sadness';
    if (text.contains(RegExp(r'angry|mad|hate|annoyed|frustrated|gussa|irritate'))) return 'anger';
    if (text.contains(RegExp(r'scared|worried|anxious|nervous|fear|tension|dara'))) return 'fear';
    if (text.contains(RegExp(r'surprised|shocked|wow|arey|kya'))) return 'surprise';
    return 'neutral';
  }

  String _getFallback(String emotion) {
    final responses = {
      'joy':     'Your voice literally radiates happiness! 🌟 Hold onto this energy — you deserve every bit of it.',
      'sadness': 'Thank you for speaking your truth. 💙 It takes courage to voice what hurts. Be gentle with yourself.',
      'anger':   'That frustration came through clearly. 🌊 Expressing it is the first step to processing it.',
      'fear':    'Anxiety can feel overwhelming, but you\'re stronger than you think. 💪 You\'ve got this.',
      'surprise':'Life loves throwing curveballs! ✨ Whatever it is, you have the strength to navigate it.',
      'disgust': 'Something really bothered you today. 🛡️ Your feelings and boundaries are completely valid.',
      'neutral': 'Thanks for sharing how you\'re doing. 📖 Every check-in is a step toward knowing yourself better.',
    };
    return responses[emotion] ?? responses['neutral']!;
  }

  void _reset() {
    _resultController.reverse().then((_) {
      if (!mounted) return;
      setState(() { _transcript = ''; _detectedEmotion = ''; _aiResponse = ''; _currentHint = (_hints..shuffle()).first; });
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _rippleController.dispose();
    _waveController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Color get _activeColor {
    if (_detectedEmotion.isNotEmpty) return (_emotionData[_detectedEmotion]?['color'] as Color?) ?? const Color(0xFF9B59F5);
    return _isListening ? const Color(0xFFE74C3C) : const Color(0xFF9B59F5);
  }

  @override
  Widget build(BuildContext context) {
    final emotionInfo = _detectedEmotion.isNotEmpty ? _emotionData[_detectedEmotion] : null;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_activeColor.withValues(alpha: _isListening ? 0.4 : 0.2), const Color(0xFF0F0F1E), const Color(0xFF003333)])),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('🎤 Voice Mode', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(_isListening ? 'sun raha hoon... 👂' : _isAnalyzing ? 'AI analyze kar raha hai...' : 'bol daal yaar', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0x1A9B59F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF9B59F5).withValues(alpha: 0.3))), child: const Text('⚡ +15 pts', style: TextStyle(color: Color(0xFF9B59F5), fontSize: 11, fontWeight: FontWeight.bold))),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 220, height: 220,
                    child: Stack(alignment: Alignment.center, children: [
                      if (_isListening) ...[
                        AnimatedBuilder(animation: _ripple3, builder: (_, __) => Container(width: 200 * _ripple3.value, height: 200 * _ripple3.value, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _activeColor.withValues(alpha: (1 - _rippleController.value * 0.8).clamp(0.0, 0.3)), width: 1)))),
                        AnimatedBuilder(animation: _ripple2, builder: (_, __) => Container(width: 160 * _ripple2.value, height: 160 * _ripple2.value, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _activeColor.withValues(alpha: (1 - _rippleController.value * 0.7).clamp(0.0, 0.4)), width: 1.5)))),
                        AnimatedBuilder(animation: _ripple1, builder: (_, __) => Container(width: 120 * _ripple1.value, height: 120 * _ripple1.value, decoration: BoxDecoration(shape: BoxShape.circle, color: _activeColor.withValues(alpha: (1 - _rippleController.value * 0.9).clamp(0.0, 0.15))))),
                      ],
                      GestureDetector(
                        onTap: _isAnalyzing ? null : _isListening ? _stopListening : _startListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _isListening ? 90 : 80, height: _isListening ? 90 : 80,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _isListening ? [const Color(0xFFE74C3C), const Color(0xFFFF6B35)] : [const Color(0xFF5C2D91), const Color(0xFF007A7A)]), boxShadow: [BoxShadow(color: _activeColor.withValues(alpha: 0.5), blurRadius: _isListening ? 30 : 15, spreadRadius: _isListening ? 5 : 2)]),
                          child: _isAnalyzing
                              ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                              : Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                    ]),
                  ),
                  SizedBox(
                    height: 60,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(_waveHeights.length, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        margin: const EdgeInsets.symmetric(horizontal: 2), width: 4,
                        height: 60 * _waveHeights[i],
                        decoration: BoxDecoration(color: _isListening ? _activeColor.withValues(alpha: 0.5 + _waveHeights[i] * 0.5) : Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_isListening ? 'tap red button to stop ⏹️' : _isAnalyzing ? 'AI padh raha hai tera dard... 🤖' : _detectedEmotion.isEmpty ? _currentHint : 'analysis complete! ✅', style: const TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (_transcript.isNotEmpty || _isListening)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: _isListening ? _activeColor.withValues(alpha: 0.4) : const Color(0x1AFFFFFF))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: _isListening ? const Color(0xFFE74C3C) : Colors.white38, shape: BoxShape.circle)), const SizedBox(width: 6), Text(_isListening ? 'Live Transcript' : 'You said', style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1))]),
                        const SizedBox(height: 10),
                        Text(_transcript.isEmpty ? 'waiting for your voice...' : _transcript, style: TextStyle(color: _transcript.isEmpty ? Colors.white24 : Colors.white, fontSize: 15, height: 1.6)),
                      ]),
                    ),
                  const SizedBox(height: 16),
                  if (_detectedEmotion.isNotEmpty && emotionInfo != null)
                    ScaleTransition(
                      scale: _resultAnim,
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: _activeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: _activeColor.withValues(alpha: 0.4))),
                        child: Column(children: [
                          Row(children: [
                            Text(emotionInfo['emoji'] as String, style: const TextStyle(fontSize: 42)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Feeling ${emotionInfo['label']}', style: TextStyle(color: _activeColor, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text(emotionInfo['genZ'] as String, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ])),
                          ]),
                          const SizedBox(height: 14),
                          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(14)), child: Text(_aiResponse, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6))),
                          const SizedBox(height: 14),
                          Row(children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: const Color(0x1A9B59F5), borderRadius: BorderRadius.circular(20)), child: const Text('⚡ +15 Zeno Points!', style: TextStyle(color: Color(0xFF9B59F5), fontWeight: FontWeight.bold, fontSize: 13))),
                            const Spacer(),
                            GestureDetector(onTap: _reset, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x33FFFFFF))), child: const Text('🎤 Again', style: TextStyle(color: Colors.white70, fontSize: 13)))),
                          ]),
                        ]),
                      ),
                    ),
                  if (_transcript.isEmpty && !_isListening && _detectedEmotion.isEmpty) ...[
                    const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1AFFFFFF))),
                      child: Column(children: [
                        const Text('How it works', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        _tipRow('🎤', 'Tap the mic and speak freely'),
                        _tipRow('⏹️', 'Tap stop when you\'re done'),
                        _tipRow('🤖', 'AI analyzes your voice\'s emotion'),
                        _tipRow('⚡', 'Earn 15 Zeno Points — max of any mode!'),
                      ]),
                    ),
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

  Widget _tipRow(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [Text(emoji, style: const TextStyle(fontSize: 18)), const SizedBox(width: 12), Text(text, style: const TextStyle(color: Colors.white54, fontSize: 13))]));
}