import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'config.dart';

class ScenarioCacheService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> _categories = [
    'Social Media & Texting', 'Academic Pressure',
    'Friendship & Relationships', 'Family Situations',
    'Hostel & College Life', 'Career & Future Anxiety',
    'Daily Life Surprises', 'Personal Achievement',
    'Romantic Relationships', 'Money & Finance Stress',
  ];

  static Future<List<Map<String, dynamic>>> getScenariosForUser() async {
    try {
      final snap = await _db.collection('scenario_cache').orderBy('createdAt', descending: true).limit(50).get();
      if (snap.docs.isEmpty) return await generateAndCache();
      final randomIndex = Random().nextInt(snap.docs.length);
      final data = snap.docs[randomIndex].data();
      final scenarios = (data['scenarios'] as List).cast<Map<String, dynamic>>();
      if (snap.docs.length < 10) _generateBatchInBackground();
      return scenarios;
    } catch (e) {
      return _fallbackScenarios;
    }
  }

  static Future<List<Map<String, dynamic>>> generateAndCache() async {
    try {
      final scenarios = await _generateFromAI();
      await _db.collection('scenario_cache').add({
        'scenarios': scenarios,
        'createdAt': FieldValue.serverTimestamp(),
        'usedCount': 0,
      });
      return scenarios;
    } catch (e) {
      return _fallbackScenarios;
    }
  }

  static void _generateBatchInBackground() async {
    try {
      for (int i = 0; i < 5; i++) {
        final scenarios = await _generateFromAI();
        await _db.collection('scenario_cache').add({
          'scenarios': scenarios,
          'createdAt': FieldValue.serverTimestamp(),
          'usedCount': 0,
        });
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {}
  }

  static Future<List<Map<String, dynamic>>> _generateFromAI() async {
    final shuffled = List<String>.from(_categories)..shuffle();
    final selected = shuffled.take(5).toList();

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
            'content': 'You are a mental wellness app content generator. Always respond with valid JSON only, no markdown.',
          },
          {
            'role': 'user',
            'content': 'Generate 5 unique relatable scenario cards for a mental wellness app for Indian college students.\n\n'
                'Categories: ${selected.join(', ')}\n\n'
                'Return ONLY a JSON array:\n'
                '[{"emoji":"emoji","scenario":"situation max 100 chars","category":"name","reactions":[{"emoji":"e","label":"label","emotion":"joy"},{"emoji":"e","label":"label","emotion":"sadness"},{"emoji":"e","label":"label","emotion":"anger"},{"emoji":"e","label":"label","emotion":"neutral"}]}]\n\n'
                'Use only: joy, sadness, anger, fear, surprise, neutral. Return ONLY the JSON array.',
          }
        ],
        'max_tokens': 1000,
        'temperature': 0.8,
      }),
    );

    if (response.statusCode != 200) throw Exception('API error ${response.statusCode}');
    final data = jsonDecode(response.body);
    final text = data['choices'][0]['message']['content'] as String;
    final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final parsed = jsonDecode(clean) as List;
    return parsed.map((s) => s as Map<String, dynamic>).toList();
  }

  static Future<String> generateInsight({
    required Map<String, int> counts,
    required String dominant,
    required List<Map<String, dynamic>> scenarios,
  }) async {
    try {
      final countsText = counts.entries.map((e) => '${e.key}: ${e.value}x').join(', ');
      final scenarioList = scenarios.map((s) => s['scenario'] as String).join(' | ');

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
              'content': 'You are an empathetic mental wellness AI for Indian college students.',
            },
            {
              'role': 'user',
              'content': 'A user completed scenario reactions in a mental wellness app.\n'
                  'Reactions: $countsText\nDominant: $dominant\nScenarios: $scenarioList\n\n'
                  'Write a warm 2-3 sentence insight about their reaction pattern. Be empathetic and end with one tip. Max 80 words. No markdown.',
            }
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  static Future<int> getCacheSize() async {
    final snap = await _db.collection('scenario_cache').count().get();
    return snap.count ?? 0;
  }

  static final List<Map<String, dynamic>> _fallbackScenarios = [
    {
      'emoji': '📱', 'scenario': 'You texted someone 2 hours ago. They\'ve seen it but haven\'t replied.', 'category': 'Social',
      'reactions': [{'emoji': '😤', 'label': 'Annoyed', 'emotion': 'anger'}, {'emoji': '😟', 'label': 'Worried', 'emotion': 'fear'}, {'emoji': '😐', 'label': 'Whatever', 'emotion': 'neutral'}, {'emoji': '😢', 'label': 'Hurt', 'emotion': 'sadness'}],
    },
    {
      'emoji': '📝', 'scenario': 'You have a major exam tomorrow and haven\'t studied enough.', 'category': 'Academic',
      'reactions': [{'emoji': '😰', 'label': 'Panicking', 'emotion': 'fear'}, {'emoji': '😤', 'label': 'Frustrated', 'emotion': 'anger'}, {'emoji': '😔', 'label': 'Defeated', 'emotion': 'sadness'}, {'emoji': '😎', 'label': 'Chill', 'emotion': 'neutral'}],
    },
    {
      'emoji': '🎉', 'scenario': 'Your best friend got amazing news and is celebrating wildly.', 'category': 'Friendship',
      'reactions': [{'emoji': '🥰', 'label': 'Overjoyed', 'emotion': 'joy'}, {'emoji': '😊', 'label': 'Happy', 'emotion': 'joy'}, {'emoji': '😌', 'label': 'Content', 'emotion': 'neutral'}, {'emoji': '🥺', 'label': 'Emotional', 'emotion': 'sadness'}],
    },
    {
      'emoji': '💼', 'scenario': 'You worked really hard on something but your efforts went unnoticed.', 'category': 'Work',
      'reactions': [{'emoji': '😤', 'label': 'Frustrated', 'emotion': 'anger'}, {'emoji': '😔', 'label': 'Disheartened', 'emotion': 'sadness'}, {'emoji': '😐', 'label': 'Indifferent', 'emotion': 'neutral'}, {'emoji': '😰', 'label': 'Anxious', 'emotion': 'fear'}],
    },
    {
      'emoji': '🎯', 'scenario': 'You finally achieved a goal you\'ve been working on for months.', 'category': 'Achievement',
      'reactions': [{'emoji': '🥳', 'label': 'Ecstatic', 'emotion': 'joy'}, {'emoji': '😊', 'label': 'Proud', 'emotion': 'joy'}, {'emoji': '😲', 'label': 'Disbelief', 'emotion': 'surprise'}, {'emoji': '😌', 'label': 'Relieved', 'emotion': 'neutral'}],
    },
  ];
}