import 'package:shared/shared.dart';

import '../moderation/blocked_terms.dart';
import '../moderation/phone_guard.dart';

/// Why [text] can not be sent ('direct' = 1-to-1, 'groups'), or null when it can:
/// mobile numbers / digits (always on for everyone) and admin Blocked Keywords.
String? sendBlockReason(String text, String where) {
  if (text.trim().isEmpty) return null;
  if (PhoneGuard.blocks(text)) return 'Numbers and mobile numbers are not allowed.';
  final term = BlockedTerms.instance.find(text, where);
  if (term != null) return '"$term" is not allowed. Remove it to send.';
  return null;
}

/// Shown above the composer while the text can not be sent.
class BlockedTextBar extends StatelessWidget {
  const BlockedTextBar({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final danger = context.palette.danger;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.block, size: 18, color: danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Can not send. ', style: TextStyle(color: danger, fontWeight: FontWeight.w700)),
                  TextSpan(text: message, style: TextStyle(color: danger)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// For screens without the live bar (captions, reply, full composer): true = blocked, a message was shown.
bool cannotSend(BuildContext context, String text, String where) {
  final reason = sendBlockReason(text, where);
  if (reason == null) return false;
  context.showSnack('Can not send. $reason');
  return true;
}

DateTime? _lastNumberNotice;

/// Shown when a typed / pasted number was removed from the message box (at most every 2 s).
void showNumberRemoved(BuildContext context) {
  final now = DateTime.now();
  if (_lastNumberNotice != null && now.difference(_lastNumberNotice!) < const Duration(seconds: 2)) return;
  _lastNumberNotice = now;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.phonelink_erase, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text("Phone numbers can't be sent. The number was removed from your message.")),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );
}
