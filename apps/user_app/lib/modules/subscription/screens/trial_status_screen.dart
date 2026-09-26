import '../../../core/core.dart';

/// Account Activated -> 7 Days Free Trial (Day 1 ... Day 7) -> Trial Expired.
class TrialStatusScreen extends StatelessWidget {
  const TrialStatusScreen({super.key});

  static const _features = [
    'Create and join groups',
    'Public, Private & Highly Protected messages',
    'Secure file viewer',
    'Group location features',
  ];

  @override
  Widget build(BuildContext context) {
    const used = Session.trialDayUsed;
    const total = AppStrings.trialDays;
    final user = MockData.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Free Trial')),
      body: FormPage(
        items: [
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: used / total,
                    strokeWidth: 12,
                    backgroundColor: context.palette.surfaceAlt,
                    strokeCap: StrokeCap.round,
                  ),
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${total - used}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800)),
                        Text('days left'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Trial ends on ${user.trialEnd}',
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          // Day 1 ... Day 7 timeline
          Row(
            children: [
              for (var d = 1; d <= total; d++)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: d <= used ? context.colors.primary : context.palette.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('D$d', style: TextStyle(fontSize: 11, color: context.palette.textSecondary)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                InfoRow(label: 'Account activated', value: user.trialStart, icon: Icons.verified_outlined),
                InfoRow(label: 'Trial ends', value: user.trialEnd, icon: Icons.event_outlined),
                const InfoRow(label: 'Access', value: 'Full chat access', icon: Icons.lock_open_outlined),
              ],
            ),
          ),
          const SectionHeader('Included in your trial', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: Column(
              children: [
                for (final f in _features) ListTile(leading: const Icon(Icons.check_circle_outline), title: Text(f)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const InfoBanner(
            icon: Icons.info_outline,
            message:
                'When the trial ends chat becomes locked. You can request an extension from the admin or choose a plan.',
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.trialExpired),
            child: const Text('Preview: trial expired screen'),
          ),
        ],
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: 'View Plans',
              icon: Icons.workspace_premium_outlined,
              onPressed: () => context.push(AppRoutes.plans),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push(AppRoutes.extensionRequest),
              child: const Text('Request trial extension'),
            ),
          ],
        ),
      ),
    );
  }
}
