import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a crisis helpline dialog when crisis level >= 2.
/// Call this after emotion analysis in text-based modes (Journal, Voice).
void showCrisisDialog(BuildContext context, int crisisLevel) {
  if (crisisLevel < 2) return;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CrisisAlertDialog(crisisLevel: crisisLevel),
  );
}

class _CrisisAlertDialog extends StatelessWidget {
  final int crisisLevel;
  const _CrisisAlertDialog({required this.crisisLevel});

  static const _helplines = [
    {
      'name': 'iCall',
      'number': '9152987821',
      'desc': 'Mon–Sat, 8am–10pm',
      'emoji': '📞',
    },
    {
      'name': 'Vandrevala Foundation',
      'number': '18602662345',
      'desc': '24/7, multilingual',
      'emoji': '🫂',
    },
    {
      'name': 'AASRA',
      'number': '9820466627',
      'desc': '24/7 crisis support',
      'emoji': '💙',
    },
  ];

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSevere = crisisLevel >= 3;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSevere
                ? [const Color(0xFF3D0000), const Color(0xFF1A0000)]
                : [const Color(0xFF1A0533), const Color(0xFF0F0F1E)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSevere
                ? const Color(0xFFE74C3C).withValues(alpha: 0.6)
                : const Color(0xFF9B59F5).withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isSevere ? '🆘' : '💜', style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 12),
            Text(
              isSevere
                  ? 'You matter. Please reach out.'
                  : 'We noticed you might be going through a tough time.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have to face this alone. Trained counselors are just a call away — free, confidential, no judgment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ..._helplines.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _call(h['number']!),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: Row(
                        children: [
                          Text(h['emoji']!,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h['name']!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                Text(h['desc']!,
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF27AE60).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.call,
                                    color: Color(0xFF27AE60), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  h['number']!.length > 10
                                      ? '${h['number']!.substring(0, 5)}...'
                                      : h['number']!,
                                  style: const TextStyle(
                                      color: Color(0xFF27AE60), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'I\'m okay, thanks 🙏',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
