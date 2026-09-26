import '../../../core/core.dart';

/// Terms / Privacy / Content policy documents.
class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  static const _docs = {
    'Terms': [
      ('1. Acceptance', 'By creating an account you agree to these terms and to use the service lawfully.'),
      (
        '2. Group communication only',
        'The service provides group chat only. Direct 1-to-1 chat, calls and personal contact are not available.',
      ),
      (
        '3. Trial & access',
        'New users get a ${AppStrings.trialDays}-day free chat trial. After expiry chat is locked until the admin approves an extension or a plan is active.',
      ),
      (
        '4. Invite links',
        'Group creators and admins control invite links, including expiry, maximum joins and revocation.',
      ),
      ('5. Termination', 'Accounts or groups violating the content policy may be restricted or blocked.'),
    ],
    'Privacy': [
      (
        'Minimum data',
        'Name, profile photo, internal user ID, login credentials, account status, trial dates and subscription status.',
      ),
      (
        'Identity protection',
        'Other members see only your display (starting) name. Mobile number, email and user ID are never shown.',
      ),
      (
        'Location',
        'Collected only for groups that need it, after your permission. Live location always shows a visible status.',
      ),
      (
        'Protected files',
        'Private files are encrypted, streamed through secure tokens and never exposed as public URLs.',
      ),
      ('Audit', 'Security events such as deletions and admin actions are kept in audit logs.'),
    ],
    'Content Policy': [
      (
        'Numbers',
        'Digits (1, 12, 9876543210), number words (ONE, TWO, HUNDRED) and mixed formats (ONE1, NINETY9, T H R E E) are blocked.',
      ),
      ('Abuse', 'Abusive or profane language is blocked before sending.'),
      (
        'Spam & links',
        'Spam, links, external contact IDs and personal information are blocked when enabled by the admin.',
      ),
      (
        'Protected content',
        'Private content cannot be forwarded, copied, shared or downloaded. Capturing it may lead to suspension.',
      ),
      ('Warnings', 'Blocked messages count as warnings. Repeated violations may restrict or block the account.'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _docs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Terms & Policies'),
          bottom: TabBar(tabs: [for (final k in _docs.keys) Tab(text: k)]),
        ),
        body: TabBarView(
          children: [
            for (final entry in _docs.entries)
              ResponsiveBody(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      entry.key == 'Terms'
                          ? 'Terms of Service'
                          : entry.key == 'Privacy'
                          ? 'Privacy Policy'
                          : 'Content Policy',
                      style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text('Last updated: 01 Sep 2026', style: TextStyle(color: context.palette.textSecondary)),
                    const SizedBox(height: 20),
                    for (final s in entry.value) ...[
                      Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(s.$2, style: const TextStyle(height: 1.5)),
                      const SizedBox(height: 18),
                    ],
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Questions? Contact legal@securechat.app',
                      style: TextStyle(color: context.palette.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
