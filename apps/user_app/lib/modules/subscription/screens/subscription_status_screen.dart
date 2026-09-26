import '../../../core/core.dart';

class SubscriptionStatusScreen extends StatelessWidget {
  const SubscriptionStatusScreen({super.key});

  static const _payments = [
    ('24 Sep 2026', 'Premium - Monthly', 'Rs 299', 'Paid'),
    ('24 Aug 2026', 'Premium - Monthly', 'Rs 299', 'Paid'),
    ('24 Jul 2026', 'Premium - Monthly', 'Rs 299', 'Failed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Subscription')),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.workspace_premium, color: context.colors.onPrimary, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        'Premium',
                        style: TextStyle(color: context.colors.onPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      const StatusChip('Active'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Rs 299 / month', style: TextStyle(color: context.colors.onPrimary, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'Next billing on 24 Oct 2026',
                    style: TextStyle(color: context.colors.onPrimary.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
            const SectionHeader('Current access', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
            Card(
              child: ValueListenableBuilder<AccessType>(
                valueListenable: Session.access,
                builder: (_, a, _) => Column(
                  children: [
                    InfoRow(label: 'Access type', value: a.label, icon: Icons.verified_user_outlined),
                    InfoRow(
                      label: 'Chat',
                      value: a == AccessType.locked ? 'Locked / read only' : 'Enabled',
                      icon: Icons.forum_outlined,
                    ),
                    const InfoRow(
                      label: 'Granted by',
                      value: 'Admin approval',
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeader('Access history', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.play_circle_outline),
                    title: Text('7-day free trial'),
                    subtitle: Text('20 Sep - 27 Sep 2026'),
                    trailing: StatusChip('Active'),
                  ),
                  ListTile(
                    leading: Icon(Icons.more_time),
                    title: Text('Extension request - 7 days'),
                    subtitle: Text('10 Aug 2026'),
                    trailing: StatusChip('Approved'),
                  ),
                  ListTile(
                    leading: Icon(Icons.workspace_premium_outlined),
                    title: Text('Premium upgrade'),
                    subtitle: Text('24 Sep 2026'),
                    trailing: StatusChip('Paid'),
                  ),
                ],
              ),
            ),
            const SectionHeader('Usage', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Usage(label: 'Secure storage', value: '4.2 GB of 20 GB', progress: 0.21),
                    SizedBox(height: 16),
                    _Usage(label: 'Groups', value: '5 of Unlimited', progress: 0.05),
                    SizedBox(height: 16),
                    _Usage(label: 'Members in largest group', value: '32 of 500', progress: 0.064),
                  ],
                ),
              ),
            ),
            const SectionHeader('Manage', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
            Card(
              child: Column(
                children: [
                  const AppSwitchTile(icon: Icons.autorenew, title: 'Auto renew', value: true),
                  const Divider(indent: 56),
                  AppTile(icon: Icons.swap_horiz, title: 'Change plan', onTap: () => context.push(AppRoutes.plans)),
                  const Divider(indent: 56),
                  AppTile(
                    icon: Icons.hourglass_bottom,
                    title: 'Trial details',
                    onTap: () => context.push(AppRoutes.trialStatus),
                  ),
                  const Divider(indent: 56),
                  AppTile(
                    icon: Icons.cancel_outlined,
                    title: 'Cancel subscription',
                    danger: true,
                    onTap: () => context.confirm(
                      title: 'Cancel subscription?',
                      message: 'You will keep Premium until 24 Oct 2026.',
                      confirmLabel: 'Cancel plan',
                      danger: true,
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader('Payment history', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < _payments.length; i++) ...[
                    if (i > 0) const Divider(indent: 56),
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(_payments[i].$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${_payments[i].$1}  |  ${_payments[i].$3}'),
                      trailing: StatusChip(_payments[i].$4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Usage extends StatelessWidget {
  const _Usage({required this.label, required this.value, required this.progress});

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(value, style: TextStyle(color: context.palette.textSecondary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, minHeight: 8),
        ),
      ],
    );
  }
}
