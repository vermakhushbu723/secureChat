import '../../core/core.dart';

/// Calls tab. Voice / video calling is not built yet: the tab is in place so the
/// navigation matches WhatsApp (Chats | Calls | Profile).
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text('Calls', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SizedBox(height: 96),
          Icon(Icons.phone_in_talk_outlined, size: 72, color: p.textMuted),
          const SizedBox(height: 16),
          Text('No calls yet', textAlign: TextAlign.center, style: context.text.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Voice and video calls are coming soon. Until then, chat with your contacts and groups from the Chats tab.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
