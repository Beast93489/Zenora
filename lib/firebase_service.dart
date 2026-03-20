import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Current user ──────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static String? get userId => _auth.currentUser?.uid;
  static bool get isLoggedIn => _auth.currentUser != null;

  // ── Generate anonymous ZN ID ──────────────────────────────────
  static String _generateZenoId() {
    final random = Random();
    final number = random.nextInt(900000) + 100000;
    return 'ZN_$number';
  }

  // ── Crisis keyword detection ──────────────────────────────────
  static const List<String> _level1Keywords = [
    'stressed', 'can\'t sleep', 'overwhelmed', 'nobody cares',
    'alone', 'failing', 'bahut thak gaya', 'kuch nahi lagta',
    'hopeless feeling', 'so tired', 'exhausted', 'breaking down',
    'akela', 'dar lag raha', 'anxiety', 'panic',
    'udaas', 'dukhi', 'pareshan', 'tension ho rahi',
    'neend nahi aati', 'rona aa raha', 'bahut bura lag raha',
    'tanhaai', 'koi nahi hai', 'sab galat ho raha',
    'mann nahi lag raha', 'bahut dar lag raha', 'ghabrahat',
    'khud se nafrat', 'kuch achha nahi lagta',
    'depressed', 'empty inside', 'numb', 'crying',
    'can\'t breathe', 'suffocating', 'trapped',
    'takleef', 'bechain', 'ro raha', 'ro rahi',
    'thak gaya', 'thak gayi', 'dard ho raha',
    'mann udaas', 'bahut bura', 'disturbed', 'restless',
  ];

  static const List<String> _level2Keywords = [
    'hopeless', 'worthless', 'useless', 'give up', 'what\'s the point',
    'hate myself', 'no reason to', 'can\'t go on', 'nahi rehna',
    'khatam kar dun', 'sab chod dun', 'disappear',
    'nobody would care', 'bekar hu main', 'koi farak nahi padta',
    'jeene ka mann nahi', 'sab khatam', 'haar gaya', 'haar gayi',
    'zindagi se thak', 'mujhe koi nahi chahta',
    'main bekar hu', 'kuch nahi bacha', 'sab bikhar gaya',
    'kisi ko farak nahi padta', 'main kuch nahi hu',
    'bahut toot gaya', 'bahut toot gayi', 'jee nahi lagta',
    'no one wants me', 'nobody wants me', 'i am burden',
    'i\'m a burden', 'better without me', 'don\'t belong',
    'can\'t take it', 'not worth it', 'hate my life',
    'life is pointless', 'fayda nahi', 'koi pyaar nahi karta',
    'sab mere khilaf', 'bekaar zindagi',
    'nafrat', 'barbaad', 'toot chuka', 'toot chuki',
    'zindagi bekar', 'jeena mushkil', 'sab khatam kar do',
    'koi matlab nahi', 'duniya chod', 'khatam karna',
  ];

  static const List<String> _level3Keywords = [
    'suicide', 'end it', 'kill myself', 'don\'t want to live',
    'mar jaun', 'jeena nahi', 'want to die', 'end my life',
    'self harm', 'hurt myself', 'better off dead', 'khatam ho jaun',
    'mar jaana chahta', 'mar jaana chahti', 'maut aa jaye',
    'jaan de dun', 'zinda nahi rehna', 'khud ko khatam',
    'marna chahta hu', 'marna chahti hu', 'jeene ka koi matlab nahi',
    'apni jaan le lu', 'khud ko hurt', 'self-harm',
    'i\'ll die', 'wanna die', 'gonna die', 'let me die',
    'jump off', 'jump from', 'overdose', 'cut myself',
    'slit', 'hang myself', 'drown myself', 'shoot myself',
    'die', 'killing myself', 'take my life', 'suicidal',
    'kood jaun', 'fansi', 'zeher kha lu', 'mar jana hai',
    'marna', 'marna hai', 'mar jaunga', 'mar jaungi',
    'maut', 'khudkushi', 'aatmhatya', 'jaan dena',
    'zinda nahi', 'nahi jeena', 'jee nahi paunga',
    'jee nahi paungi', 'khatam ho jau', 'mit jau',
  ];

  static Map<String, dynamic> analyzeTextForCrisis(String text) {
    final lower = text.toLowerCase();
    int crisisLevel = 0;
    final detectedKeywords = <String>[];

    for (final kw in _level3Keywords) {
      if (lower.contains(kw)) {
        crisisLevel = 3;
        detectedKeywords.add(kw);
      }
    }
    if (crisisLevel < 3) {
      for (final kw in _level2Keywords) {
        if (lower.contains(kw)) {
          crisisLevel = 2;
          detectedKeywords.add(kw);
        }
      }
    }
    if (crisisLevel < 2) {
      for (final kw in _level1Keywords) {
        if (lower.contains(kw)) {
          crisisLevel = 1;
          detectedKeywords.add(kw);
        }
      }
    }

    return {
      'crisisLevel': crisisLevel,
      'keywords': detectedKeywords,
      'isLateNight': _isLateNight(),
      'hourOfDay': DateTime.now().hour,
    };
  }

  static bool _isLateNight() {
    final hour = DateTime.now().hour;
    return hour >= 1 && hour <= 4;
  }

  // ── Ghost metrics (no permissions needed) ─────────────────────
  static Future<void> logGhostMetrics({
    required String mode,
    required String emotion,
    required int wordCount,
    required int timeToWriteSeconds,
    required int crisisLevel,
    int editCount = 0,
  }) async {
    if (userId == null) return;
    try {
      final hour = DateTime.now().hour;
      final isLateNight = _isLateNight();
      final dayOfWeek = DateTime.now().weekday;

      // Log individual session metric
      await _db
          .collection('users')
          .doc(userId)
          .collection('ghost_metrics')
          .add({
        'mode': mode,
        'emotion': emotion,
        'wordCount': wordCount,
        'timeToWriteSeconds': timeToWriteSeconds,
        'editCount': editCount,
        'hourOfDay': hour,
        'dayOfWeek': dayOfWeek,
        'isLateNight': isLateNight,
        'crisisLevel': crisisLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update aggregate ghost metrics on user doc
      final updates = <String, dynamic>{
        'ghost_metrics.totalSessions': FieldValue.increment(1),
      };

      if (isLateNight) {
        updates['ghost_metrics.lateNightEntries'] = FieldValue.increment(1);
      }

      switch (crisisLevel) {
        case 1: updates['ghost_metrics.crisisLevel1Count'] = FieldValue.increment(1); break;
        case 2: updates['ghost_metrics.crisisLevel2Count'] = FieldValue.increment(1); break;
        case 3: updates['ghost_metrics.crisisLevel3Count'] = FieldValue.increment(1); break;
      }

      await _db.collection('users').doc(userId).update(updates);

      // If crisis level 3 — log to separate alerts collection
      if (crisisLevel == 3) {
        await _db.collection('crisis_alerts').add({
          'zenoId': await _getZenoId(),
          'crisisLevel': crisisLevel,
          'hourOfDay': hour,
          'isLateNight': isLateNight,
          'timestamp': FieldValue.serverTimestamp(),
          // NOTE: No text content stored — privacy first
        });
      }
    } catch (e) {
      // Silent fail — ghost metrics are non-critical
    }
  }

  static Future<String> _getZenoId() async {
    if (userId == null) return 'unknown';
    final doc = await _db.collection('users').doc(userId).get();
    return (doc.data()?['zenoId'] as String?) ?? 'unknown';
  }

  // ── Auth ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await cred.user?.updateDisplayName(name.trim());
      final uid = cred.user!.uid;
      final zenoId = _generateZenoId();

      // Anonymous research profile
      await _db.collection('users').doc(uid).set({
        'zenoId': zenoId,
        'university': 'Chandigarh University',
        'joinedAt': FieldValue.serverTimestamp(),
        'zenoPoints': 0,
        'streak': 0,
        'lastEntryDate': null,
        'totalEntries': 0,
        'badges': [],
        'avatar': '',
        'consentGiven': false,
        'consentTimestamp': null,
        'ghost_metrics': {
          'lateNightEntries': 0,
          'totalSessions': 0,
          'crisisLevel1Count': 0,
          'crisisLevel2Count': 0,
          'crisisLevel3Count': 0,
        },
      });

      // PII in separate collection — never used in research
      await _db.collection('pii').doc(uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'username': '@${name.trim().toLowerCase().replaceAll(' ', '')}',
        'zenoId': zenoId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'user': cred.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Something went wrong. Try again.'};
    }
  }

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return {'success': true, 'user': cred.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Something went wrong. Try again.'};
    }
  }

  static Future<void> signOut() async {
    try { await _googleSignIn.signOut(); } catch (_) {}
    await _auth.signOut();
  }

  static Future<Map<String, dynamic>> signInAsGuest() async {
    try {
      final cred = await _auth.signInAnonymously();
      final uid = cred.user!.uid;
      final zenoId = _generateZenoId();

      await _db.collection('users').doc(uid).set({
        'zenoId': zenoId,
        'university': '',
        'joinedAt': FieldValue.serverTimestamp(),
        'zenoPoints': 0,
        'streak': 0,
        'lastEntryDate': null,
        'totalEntries': 0,
        'badges': [],
        'avatar': '',
        'isGuest': true,
        'consentGiven': false,
        'consentTimestamp': null,
        'ghost_metrics': {
          'lateNightEntries': 0,
          'totalSessions': 0,
          'crisisLevel1Count': 0,
          'crisisLevel2Count': 0,
          'crisisLevel3Count': 0,
        },
      }, SetOptions(merge: true));

      await _db.collection('pii').doc(uid).set({
        'name': 'Guest User',
        'email': '',
        'username': '@guest_$zenoId',
        'zenoId': zenoId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return {'success': true, 'user': cred.user};
    } catch (e) {
      return {'success': false, 'error': 'Guest sign-in failed.'};
    }
  }

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'success': false, 'error': 'Cancelled'};
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user!;
      final isNew = userCred.additionalUserInfo?.isNewUser ?? false;

      if (isNew) {
        final zenoId = _generateZenoId();
        await _db.collection('users').doc(user.uid).set({
          'zenoId': zenoId,
          'university': 'Chandigarh University',
          'joinedAt': FieldValue.serverTimestamp(),
          'zenoPoints': 0,
          'streak': 0,
          'lastEntryDate': null,
          'totalEntries': 0,
          'badges': [],
          'avatar': '',
          'consentGiven': false,
          'consentTimestamp': null,
          'ghost_metrics': {
            'lateNightEntries': 0,
            'totalSessions': 0,
            'crisisLevel1Count': 0,
            'crisisLevel2Count': 0,
            'crisisLevel3Count': 0,
          },
        });

        await _db.collection('pii').doc(user.uid).set({
          'name': user.displayName ?? 'Zenora User',
          'email': user.email ?? '',
          'username': (user.displayName ?? 'user')
              .toLowerCase()
              .replaceAll(' ', ''),
          'photoUrl': user.photoURL ?? '',
          'zenoId': zenoId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return {'success': true, 'isNew': isNew};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Consent ───────────────────────────────────────────────────
  static Future<bool> hasGivenConsent() async {
    if (userId == null) return false;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final consent = (doc.data()?['consentGiven'] as bool?) ?? false;
      debugPrint('🔍 consentGiven for ${userId}: $consent');
      debugPrint('🔍 full data: ${doc.data()}');
      return consent;
    } catch (e) {
      debugPrint('🔍 consent error: $e');
      return false;
    }
  }

  static Future<void> recordConsent() async {
    if (userId == null) return;
    await _db.collection('users').doc(userId).update({
      'consentGiven': true,
      'consentTimestamp': FieldValue.serverTimestamp(),
    });

    // Log consent in separate audit collection
    final zenoId = await _getZenoId();
    await _db.collection('consent_audit').add({
      'zenoId': zenoId,
      'consentGiven': true,
      'timestamp': FieldValue.serverTimestamp(),
      'appVersion': '1.0.0',
    });
  }

  // ── User Profile ──────────────────────────────────────────────
  static String _resolveName(Map<String, dynamic> pii, String authName) {
    final piiName = pii['name'] as String?;
    if (piiName != null && piiName.isNotEmpty) return piiName;
    if (authName.isNotEmpty) return authName;
    return 'Zenora User';
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (userId == null) return null;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final data = doc.data() ?? {};

      // Try PII collection first
      Map<String, dynamic> pii = {};
      try {
        final piiDoc = await _db.collection('pii').doc(userId).get();
        pii = piiDoc.data() ?? {};
      } catch (_) {}

      // Fallback to Firebase Auth display name for old accounts
      final authName = _auth.currentUser?.displayName ?? '';
      final authEmail = _auth.currentUser?.email ?? '';

      return {
        ...data,
        'name': _resolveName(pii, authName),
        'email': pii['email'] ?? authEmail,
        'username': pii['username'] ?? (authName.isNotEmpty ? '@${authName.toLowerCase().replaceAll(' ', '')}' : '@zenora_user'),
        'photoUrl': pii['photoUrl'] ?? _auth.currentUser?.photoURL ?? '',
      };
    } catch (e) {
      return null;
    }
  }
  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (userId == null) return;

    // Separate PII from research data
    final piiFields = ['name', 'username', 'email', 'photoUrl'];
    final piiData = <String, dynamic>{};
    final researchData = <String, dynamic>{};

    data.forEach((key, value) {
      if (piiFields.contains(key)) {
        piiData[key] = value;
      } else {
        researchData[key] = value;
      }
    });

    if (piiData.isNotEmpty) {
      await _db.collection('pii').doc(userId).update(piiData);
    }
    if (researchData.isNotEmpty) {
      await _db.collection('users').doc(userId).update(researchData);
    }
  }

  // ── Delete user data (GDPR/right to erasure) ─────────────────
  static Future<void> deleteAllUserData() async {
    if (userId == null) return;
    try {
      // Delete mood entries
      final entries = await _db
          .collection('users').doc(userId)
          .collection('mood_entries').get();
      for (final doc in entries.docs) { await doc.reference.delete(); }

      // Delete ghost metrics
      final metrics = await _db
          .collection('users').doc(userId)
          .collection('ghost_metrics').get();
      for (final doc in metrics.docs) { await doc.reference.delete(); }

      // Delete PII
      await _db.collection('pii').doc(userId).delete();

      // Delete main profile
      await _db.collection('users').doc(userId).delete();

      // Delete Firebase Auth account
      await _auth.currentUser?.delete();
    } catch (e) {
      rethrow;
    }
  }

  // ── Mood Entries ──────────────────────────────────────────────
  static Future<bool> saveMoodEntry({
    required String mode,
    required String emotion,
    required String emotionLabel,
    required String emoji,
    required int points,
    String? preview,
    Map<String, dynamic>? extra,
    int wordCount = 0,
    int timeToWriteSeconds = 0,
    int editCount = 0,
    int crisisLevel = 0,
  }) async {
    if (userId == null) return false;
    try {
      final hour = DateTime.now().hour;
      final isLateNight = _isLateNight();

      await _db
          .collection('users')
          .doc(userId)
          .collection('mood_entries')
          .add({
        'mode': mode,
        'emotion': emotion,
        'emotionLabel': emotionLabel,
        'emoji': emoji,
        'points': points,
        'preview': preview ?? '',
        'extra': extra ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().substring(0, 10),
        // Ghost metrics embedded in entry
        'meta': {
          'hourOfDay': hour,
          'isLateNight': isLateNight,
          'dayOfWeek': DateTime.now().weekday,
          'wordCount': wordCount,
          'timeToWriteSeconds': timeToWriteSeconds,
          'editCount': editCount,
          'crisisLevel': crisisLevel,
        },
      });

      await _updateUserStats(points);

      // Log ghost metrics
      if (wordCount > 0 || crisisLevel > 0) {
        await logGhostMetrics(
          mode: mode,
          emotion: emotion,
          wordCount: wordCount,
          timeToWriteSeconds: timeToWriteSeconds,
          editCount: editCount,
          crisisLevel: crisisLevel,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _updateUserStats(int points) async {
    if (userId == null) return;
    final userRef = _db.collection('users').doc(userId);
    final doc = await userRef.get();
    final data = doc.data() ?? {};

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = data['lastEntryDate'] as String?;

    int streak = (data['streak'] as int?) ?? 0;
    if (lastDate == null) {
      streak = 1;
    } else {
      final last = DateTime.parse(lastDate);
      final diff = DateTime.now().difference(last).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    }

    await userRef.update({
      'zenoPoints': FieldValue.increment(points),
      'totalEntries': FieldValue.increment(1),
      'streak': streak,
      'lastEntryDate': today,
    });
  }

  // ── Get Mood Entries ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMoodEntries(
      {int limit = 50}) async {
    if (userId == null) return [];
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('mood_entries')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getWeekEntries() async {
    if (userId == null) return [];
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('mood_entries')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(weekAgo))
          .orderBy('timestamp', descending: true)
          .get();
      return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Badges ────────────────────────────────────────────────────
  static Future<void> checkAndAwardBadges() async {
    if (userId == null) return;
    final profile = await getUserProfile();
    if (profile == null) return;

    final totalEntries = (profile['totalEntries'] as int?) ?? 0;
    final streak       = (profile['streak'] as int?) ?? 0;
    final earnedBadges = List<String>.from(profile['badges'] ?? []);
    final toAward = <String>[];

    if (totalEntries >= 1  && !earnedBadges.contains('first_entry'))    toAward.add('first_entry');
    if (streak >= 3        && !earnedBadges.contains('streak_3'))        toAward.add('streak_3');
    if (streak >= 7        && !earnedBadges.contains('streak_7'))        toAward.add('streak_7');
    if (streak >= 30       && !earnedBadges.contains('streak_30'))       toAward.add('streak_30');
    if (totalEntries >= 10 && !earnedBadges.contains('journaler'))       toAward.add('journaler');

    if (toAward.isNotEmpty) {
      await _db.collection('users').doc(userId).update({
        'badges': FieldValue.arrayUnion(toAward),
      });
    }
  }

  static String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Yeh email toh pehle se registered hai 😅 (Try logging in)';
      case 'invalid-email':        return 'Bhai yeh toh email address hi galat hai 😤';
      case 'weak-password':        return 'Kam se kam 6 characters ka hona chahiye 💪';
      case 'user-not-found':       return 'User toh mila nahi, pehle sign up karo 👀';
      case 'wrong-password':       return 'Password galat hai, ek baar phir try karo 🔑';
      case 'too-many-requests':    return 'Itne attempts ke baad toh system bhi thak jayega 😭';
      default:                     return 'Authentication failed. Try again.';
    }
  }
}