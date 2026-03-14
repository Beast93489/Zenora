import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Current user ─────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static String? get userId => _auth.currentUser?.uid;
  static bool get isLoggedIn => _auth.currentUser != null;

  // ── Auth ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());
      // Create user profile in Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'username': '@${name.trim().toLowerCase().replaceAll(' ', '')}',
        'university': '',
        'joinedAt': FieldValue.serverTimestamp(),
        'zenoPoints': 0,
        'streak': 0,
        'lastEntryDate': null,
        'totalEntries': 0,
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
        email: email.trim(),
        password: password,
      );
      return {'success': true, 'user': cred.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Something went wrong. Try again.'};
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<Map<String, dynamic>> signInAsGuest() async {
    try {
      final cred = await _auth.signInAnonymously();
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': 'Guest User',
        'email': '',
        'username': '@guest',
        'university': '',
        'joinedAt': FieldValue.serverTimestamp(),
        'zenoPoints': 0,
        'streak': 0,
        'lastEntryDate': null,
        'totalEntries': 0,
        'isGuest': true,
      });
      return {'success': true, 'user': cred.user};
    } catch (e) {
      return {'success': false, 'error': 'Guest sign-in failed.'};
    }
  }

  static String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'This email is already registered.';
      case 'invalid-email':        return 'Please enter a valid email.';
      case 'weak-password':        return 'Password must be at least 6 characters.';
      case 'user-not-found':       return 'No account found with this email.';
      case 'wrong-password':       return 'Incorrect password. Try again.';
      case 'too-many-requests':    return 'Too many attempts. Try again later.';
      default:                     return 'Authentication failed. Try again.';
    }
  }

  // ── User Profile ──────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (userId == null) return null;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (userId == null) return;
    await _db.collection('users').doc(userId).update(data);
  }

  // ── Mood Entries ──────────────────────────────────────────────
  static Future<bool> saveMoodEntry({
    required String mode,        // 'journal', 'emoji', 'vibe', 'weather', etc.
    required String emotion,     // 'joy', 'sadness', 'anger', etc.
    required String emotionLabel,// 'Joyful', 'Sad', etc.
    required String emoji,       // '😊'
    required int points,         // 5 or 10
    String? preview,             // text preview
    Map<String, dynamic>? extra, // any extra mode-specific data
  }) async {
    if (userId == null) return false;
    try {
      // Save the entry
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
      });

      // Update user stats
      await _updateUserStats(points);
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

    // Update streak
    if (lastDate == null) {
      streak = 1;
    } else {
      final last = DateTime.parse(lastDate);
      final diff = DateTime.now().difference(last).inDays;
      if (diff == 1) {
        streak += 1; // consecutive day
      } else if (diff > 1) {
        streak = 1; // streak broken
      }
      // diff == 0 means same day, no streak change
    }

    await userRef.update({
      'zenoPoints': FieldValue.increment(points),
      'totalEntries': FieldValue.increment(1),
      'streak': streak,
      'lastEntryDate': today,
    });
  }

  // ── Get Mood Entries ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMoodEntries({int limit = 50}) async {
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

    if (totalEntries >= 1  && !earnedBadges.contains('first_entry'))
      toAward.add('first_entry');
    if (streak >= 3        && !earnedBadges.contains('streak_3'))
      toAward.add('streak_3');
    if (streak >= 7        && !earnedBadges.contains('streak_7'))
      toAward.add('streak_7');
    if (streak >= 30       && !earnedBadges.contains('streak_30'))
      toAward.add('streak_30');
    if (totalEntries >= 10 && !earnedBadges.contains('journaler'))
      toAward.add('journaler');

    if (toAward.isNotEmpty) {
      await _db.collection('users').doc(userId).update({
        'badges': FieldValue.arrayUnion(toAward),
      });
    }
  }
}