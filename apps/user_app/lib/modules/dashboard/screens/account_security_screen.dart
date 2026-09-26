import '../../../core/core.dart';

class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key});

  static const _sessions = [
    (Icons.phone_android, 'Android - SecureChat App', 'Indore - Active now', true),
    (Icons.laptop_windows, 'Chrome on Windows (PWA)', 'Indore - 2 hours ago', false),
    (Icons.tablet_mac, 'Safari on iPad', 'Bhopal - 3 days ago', false),
  ];

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
                AppTile(icon: Icons.download_outlined, title: 'Request account data', onTap: () {}),
                AppTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete my account',
                  danger: true,
                  onTap: () => context.confirm(
                    title: 'Delete account?',
                    message: 'All your groups, messages and files will be permanently removed.',
                    confirmLabel: 'Delete',
                    danger: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
