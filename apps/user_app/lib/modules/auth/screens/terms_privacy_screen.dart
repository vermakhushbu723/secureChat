import '../../../core/core.dart';

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key, this.from});

  final String? from;

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  bool _terms = false;
  bool _privacy = false;
  bool _content = false;

  static const _points = [
    (
      Icons.forum_outlined,
      'Group chat only',
      'Private 1-to-1 chats never show your mobile number or email to the other person.',
    ),
    (
      Icons.visibility_off_outlined,
      'Identity protection',
      'Members see only your starting name. Number, email and ID stay hidden.',
    ),
    (
      Icons.gpp_maybe_outlined,
      'Content rules',
      'Numbers, number words, abusive language, links and contact details are blocked before sending.',
    ),
    (
      Icons.lock_outline,
      'Protected content',
      'Private messages cannot be forwarded, copied or downloaded. Files open only in the secure viewer.',
    ),
    (
      Icons.location_on_outlined,
      'Location only when required',
      'Some groups require location to join. You are always asked for permission first.',
    ),
    (
      Icons.workspace_premium_outlined,
      '${AppStrings.trialDays}-day free trial',
      'After the trial you can request an extension or choose a plan.',
    ),
  ];

  Future<void> _accept() async {
    Session.access.value = AccessType.trial;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const FeatureIcon(Icons.celebration_outlined, size: 72),
        title: const Text('${AppStrings.trialDays}-Day Free Trial Activated'),
        content: Text(
          'Your trial runs from ${MockData.currentUser.trialStart} to ${MockData.currentUser.trialEnd}. Enjoy full chat access.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Start Chatting'),
          ),
        ],
      ),
    );
    if (mounted) context.go(widget.from ?? AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _terms && _privacy && _content;
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Privacy')),
      body: FormPage(
        items: [
          Text('Before you continue', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Please read how ${AppStrings.appName} works and protects you.',
            style: TextStyle(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 20),
          for (final p in _points)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(icon: p.$1, size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(p.$3, style: TextStyle(color: context.palette.textSecondary, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.policies),
            icon: const Icon(Icons.article_outlined),
            label: const Text('Read full Terms, Privacy & Content Policy'),
          ),
          const Divider(),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            title: const Text('I accept the Terms of Service'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _privacy,
            onChanged: (v) => setState(() => _privacy = v ?? false),
            title: const Text('I accept the Privacy Policy'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _content,
            onChanged: (v) => setState(() => _content = v ?? false),
            title: const Text('I agree to the Content Policy and message filtering'),
          ),
        ],
        bottom: PrimaryButton(label: 'Accept & Start Free Trial', onPressed: canContinue ? _accept : null),
      ),
    );
  }
}
