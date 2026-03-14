import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class ScenarioCacheService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Multiple API keys — rotate to avoid quota ─────────────────
  // Add more keys here as you create them
  static const List<String> _apiKeys = [
    'AIzaSyCe_Rv4afdSwm2GYzWf31jcz_RMYUaOzFc', // replace with your keys
  ];

  static String get _randomKey =>
      _apiKeys[Random().nextInt(_apiKeys.length)];

  static const String _model =
      'gemini-2.0-flash-lite';

  // ── Categories pool ───────────────────────────────────────────
  static const List<String> _categories = [
    'Social Media & Texting',
    'Academic Pressure',
    'Friendship & Relationships',
    'Family Situations',
    'Hostel & College Life',
    'Career & Future Anxiety',
    'Daily Life Surprises',
    'Personal Achievement',
    'Romantic Relationships',
    'Money & Finance Stress',
  ];

  // ── Get scenarios for user ────────────────────────────────────
  // Returns 5 random scenarios from cache
  // If cache is low, generates more in background
  static Future<List<Map<String, dynamic>>> getScenariosForUser() async {
    try {
      // Get all cached scenario sets
      final snap = await _db
          .collection('scenario_cache')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      if (snap.docs.isEmpty) {
        // Cache is empty — generate synchronously first time
        return await generateAndCache();
      }

      // Pick a random cached set
      final randomIndex = Random().nextInt(snap.docs.length);
      final data = snap.docs[randomIndex].data();
      final scenarios =
          (data['scenarios'] as List).cast<Map<String, dynamic>>();

      // If cache is getting low (<10 sets), generate more in background
      if (snap.docs.length < 10) {
        _generateBatchInBackground();
      }

      return scenarios;
    } catch (e) {
      // Return fallback if anything fails
      return _fallbackScenarios;
    }
  }

  // ── Generate one set and cache it ─────────────────────────────
  static Future<List<Map<String, dynamic>>> generateAndCache() async {
    try {
      final scenarios = await _generateFromAI();
      // Save to Firestore cache
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

  // ── Generate a batch of 5 sets in background ──────────────────
  static void _generateBatchInBackground() async {
    try {
      for (int i = 0; i < 5; i++) {
        final scenarios = await _generateFromAI();
        await _db.collection('scenario_cache').add({
          'scenarios': scenarios,
          'createdAt': FieldValue.serverTimestamp(),
          'usedCount': 0,
        });
        // Small delay between requests to avoid quota
        await Future.delayed(const Duration(seconds: 3));
      }
    } catch (e) {
      // Silently fail — background operation
    }
  }

  // ── Call Gemini API ───────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> _generateFromAI() async {
    final shuffled = List<String>.from(_categories)..shuffle();
    final selected = shuffled.take(5).toList();
    final key = _randomKey;

    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$key');

    final prompt =
        'Generate 5 unique relatable scenario cards for a mental wellness app for Indian college students.\n\n'
        'Categories: ${selected.join(', ')}\n\n'
        'Return ONLY a JSON array:\n'
        '[{"emoji":"emoji","scenario":"situation max 100 chars","category":"name",'
        '"reactions":[{"emoji":"e","label":"label","emotion":"joy"},'
        '{"emoji":"e","label":"label","emotion":"sadness"},'
        '{"emoji":"e","label":"label","emotion":"anger"},'
        '{"emoji":"e","label":"label","emotion":"neutral"}]}]\n\n'
        'Use only: joy, sadness, anger, fear, surprise, neutral\n'
        'Return ONLY the JSON array, no markdown.';

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        data['candidates'][0]['content']['parts'][0]['text'] as String;
    final clean =
        text.replaceAll('```json', '').replaceAll('```', '').trim();
    final parsed = jsonDecode(clean) as List;
    return parsed.map((s) => s as Map<String, dynamic>).toList();
  }

  // ── Generate AI insight ───────────────────────────────────────
  static Future<String> generateInsight({
    required Map<String, int> counts,
    required String dominant,
    required List<Map<String, dynamic>> scenarios,
  }) async {
    try {
      final key = _randomKey;
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$key');

      final countsText =
          counts.entries.map((e) => '${e.key}: ${e.value}x').join(', ');
      final scenarioList =
          scenarios.map((s) => s['scenario'] as String).join(' | ');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'A user completed scenario reactions in a mental wellness app.\n'
                      'Reactions: $countsText\nDominant: $dominant\n'
                      'Scenarios: $scenarioList\n\n'
                      'Write a warm 2-3 sentence insight about their reaction pattern. '
                      'Be empathetic and end with one tip. Max 80 words. No markdown.'
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  // ── Admin: pre-fill cache (run once) ─────────────────────────
  // Call this from a button in your admin panel to pre-generate 20 sets
  static Future<void> prefillCache({int count = 20}) async {
    for (int i = 0; i < count; i++) {
      try {
        await generateAndCache();
        await Future.delayed(const Duration(seconds: 4));
      } catch (e) {
        // Continue even if one fails
      }
    }
  }

  // ── Check cache size ──────────────────────────────────────────
  static Future<int> getCacheSize() async {
    final snap = await _db.collection('scenario_cache').count().get();
    return snap.count ?? 0;
  }

  // ── Fallback scenarios ────────────────────────────────────────
  static final List<Map<String, dynamic>> _fallbackScenarios = [
    {
      'emoji': '📱',
      'scenario': 'You texted someone 2 hours ago. They\'ve seen it but haven\'t replied.',
      'category': 'Social',
      'reactions': [
        {'emoji': '😤', 'label': 'Annoyed', 'emotion': 'anger'},
        {'emoji': '😟', 'label': 'Worried', 'emotion': 'fear'},
        {'emoji': '😐', 'label': 'Whatever', 'emotion': 'neutral'},
        {'emoji': '😢', 'label': 'Hurt', 'emotion': 'sadness'},
      ],
    },
    {
      'emoji': '📝',
      'scenario': 'You have a major exam tomorrow and haven\'t studied enough.',
      'category': 'Academic',
      'reactions': [
        {'emoji': '😰', 'label': 'Panicking', 'emotion': 'fear'},
        {'emoji': '😤', 'label': 'Frustrated', 'emotion': 'anger'},
        {'emoji': '😔', 'label': 'Defeated', 'emotion': 'sadness'},
        {'emoji': '😎', 'label': 'Chill', 'emotion': 'neutral'},
      ],
    },
    {
      'emoji': '🎉',
      'scenario': 'Your best friend got amazing news and is celebrating wildly.',
      'category': 'Friendship',
      'reactions': [
        {'emoji': '🥰', 'label': 'Overjoyed', 'emotion': 'joy'},
        {'emoji': '😊', 'label': 'Happy', 'emotion': 'joy'},
        {'emoji': '😌', 'label': 'Content', 'emotion': 'neutral'},
        {'emoji': '🥺', 'label': 'Emotional', 'emotion': 'sadness'},
      ],
    },
    {
      'emoji': '💼',
      'scenario': 'You worked really hard on something but your efforts went unnoticed.',
      'category': 'Work',
      'reactions': [
        {'emoji': '😤', 'label': 'Frustrated', 'emotion': 'anger'},
        {'emoji': '😔', 'label': 'Disheartened', 'emotion': 'sadness'},
        {'emoji': '😐', 'label': 'Indifferent', 'emotion': 'neutral'},
        {'emoji': '😰', 'label': 'Anxious', 'emotion': 'fear'},
      ],
    },
    {
      'emoji': '🎯',
      'scenario': 'You finally achieved a goal you\'ve been working on for months.',
      'category': 'Achievement',
      'reactions': [
        {'emoji': '🥳', 'label': 'Ecstatic', 'emotion': 'joy'},
        {'emoji': '😊', 'label': 'Proud', 'emotion': 'joy'},
        {'emoji': '😲', 'label': 'Disbelief', 'emotion': 'surprise'},
        {'emoji': '😌', 'label': 'Relieved', 'emotion': 'neutral'},
      ],
    },
  ];
}