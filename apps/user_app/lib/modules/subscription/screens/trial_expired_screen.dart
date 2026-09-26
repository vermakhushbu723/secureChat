import '../../../core/core.dart';

/// Trial Expired -> Request Extension / View Plans -> Admin decision.
class TrialExpiredScreen extends StatelessWidget {
  const TrialExpiredScreen({super.key});

  static const _locked = [
    (Icons.send_outlined, 'Sending messages'),
    (Icons.group_add_outlined, 'Creating new groups'),
    (Icons.upload_file_outlined, 'Sending files and media'),
    (Icons.share_location, 'Live location sharing'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              Session.access.value = AccessType.locked;
              context.go(AppRoutes.home);
            },
            child: const Text('Continue read only'),
          ),
        ],
      ),
      body: FormPage(
        items: [
          const MessageBlock(
            icon: Icons.hourglass_disabled_outlined,
            tone: Tone.danger,
            title: 'Trial Expired',
            message: 'Your ${AppStrings.trialDays}-day free trial has expired. Your groups and messages are safe.',
          ),
          const SectionHeader('Chat locked / limited', padding: EdgeInsets.fromLTRB(0, 28, 0, 8)),
          Card(
            child: Column(
              children: [
                for (final l in _locked)
                  ListTile(
                    leading: Icon(l.$1),
                    title: Text(l.$2),
                    trailing: Icon(Icons.lock_outline, color: context.palette.textSecondary),
                  ),
                const ListTile(
                  leading: Icon(Icons.visibility_outlined),
                  title: Text('Reading existing messages'),
                  trailing: StatusChip('Allowed'),
                ),
              ],
            ),
          ),
          const SectionHeader('What happens next', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.more_time),
                  title: Text('Request extension'),
                  subtitle: Text('Admin reviews your request'),
                ),
                ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Approved'),
                  subtitle: Text('Free, Premium or extended access is activated'),
                ),
                ListTile(
                  leading: Icon(Icons.cancel_outlined),
                  title: Text('Rejected'),
                  subtitle: Text('Chat stays locked / limited'),
                ),
              ],
            ),
          ),
        ],
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: 'Request Extension',
              icon: Icons.more_time,
              onPressed: () => context.push(AppRoutes.extensionRequest),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'View Available Plans',
              icon: Icons.workspace_premium_outlined,
              onPressed: () => context.push(AppRoutes.plans),
            ),
          ],
        ),
      ),
    );
  }
}
