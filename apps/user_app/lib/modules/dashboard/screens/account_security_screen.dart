import '../../../core/core.dart';

class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key});

  static const _sessions = [
    (Icons.phone_android, 'Android - SecureChat App', 'Indore - Active now', true),
    (Icons.laptop_windows, 'Chrome on Windows (PWA)', 'Indore - 2 hours ago', false),
    (Icons.tablet_mac, 'Safari on iPad', 'Bhopal - 3 days ago', false),
  ];

  /// Delete my account (Google Play: deletion inside the app). Signs out afterwards.
  static Future<void> _deleteAccount(BuildContext context) async {
    final ok = await context.confirm(
      title: 'Delete your account?',
      message:
          'Your profile, mobile number, email, password, devices and location history are deleted and you leave every group. '
          'Messages you already sent stay with the people who got them, shown as "Deleted user". This cannot be undone.',
      confirmLabel: 'Delete account',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    final done = await runAction(context, () => ApiClient.instance.post('/users/me/delete', body: {'confirm': 'DELETE'}), done: 'Your account was deleted');
    if (!done || !context.mounted) return;
    await AuthService.instance.logout();
    if (context.mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account & Security')),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: InfoBanner(
                icon: Icons.verified_user_outlined,
                title: 'Security score: Good',
                message: 'Turn on 2-step verification to make your account stronger.',
              ),
            ),
            const SectionHeader('Login'),
            GroupedCard(
              children: [
                AppTile(
                  icon: Icons.phone_iphone,
                  title: 'Change Number',
                  subtitle: MockData.currentUser.phone,
                  onTap: () {},
                ),
                AppTile(
                  icon: Icons.password,
                  title: 'Change Password',
                  subtitle: 'Last changed 2 months ago',
                  onTap: () {},
                ),
                const AppSwitchTile(
                  icon: Icons.pin_outlined,
                  title: '2-Step Verification',
                  subtitle: 'Ask for a PIN when registering again',
                ),
                const AppSwitchTile(
                  icon: Icons.fingerprint,
                  title: 'App Lock',
                  subtitle: 'Use fingerprint / face to open',
                  value: true,
                ),
              ],
            ),
            const SectionHeader('Alerts'),
            const GroupedCard(
              children: [
                AppSwitchTile(
                  icon: Icons.notification_important_outlined,
                  title: 'Login alerts',
                  subtitle: 'Notify me on new device login',
                  value: true,
                ),
                AppSwitchTile(
                  icon: Icons.screenshot_monitor_outlined,
                  title: 'Screenshot alerts',
                  subtitle: 'Notify when someone captures protected content',
                  value: true,
                ),
              ],
            ),
            SectionHeader(
              'Active sessions',
              action: 'Logout all',
              onAction: () => context.showSnack('Logged out from other devices'),
            ),
            GroupedCard(
              children: [
                for (final s in _sessions)
                  ListTile(
                    leading: Icon(s.$1),
                    title: Text(s.$2),
                    subtitle: Text(s.$3),
                    trailing: s.$4
                        ? const StatusChip('This device', tone: Tone.success)
                        : IconButton(icon: const Icon(Icons.logout), onPressed: () {}),
                  ),
              ],
            ),
            const SectionHeader('Danger zone'),
            GroupedCard(
              children: [
                AppTile(
                  icon: Icons.download_outlined,
                  title: 'Request account data',
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Request account data'),
                      content: const Text('Email support@prosecurely.online from the email address of your account (or write your mobile number). We send a copy of your profile and account data within 30 days.'),
                      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                    ),
                  ),
                ),
                AppTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete my account',
                  subtitle: 'Removes your profile, number, email and location history',
                  danger: true,
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
