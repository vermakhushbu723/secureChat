import '../../../core/core.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Admin Dashboard',
      subtitle: 'Overview for today, 24 Sep 2026',
      actions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.go(AdminRoutes.analytics),
          icon: const Icon(Icons.insights_outlined),
          label: const Text('Analytics'),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 200,
          children: [
            StatCard(
              icon: Icons.people_outline,
              label: 'Total Users',
              value: '12,450',
              delta: '+4.2%',
              onTap: () => context.go(AdminRoutes.users),
            ),
            StatCard(
              icon: Icons.bolt_outlined,
              label: 'Active Users',
              value: '8,240',
              delta: '+2.8%',
              onTap: () => context.go(AdminRoutes.users),
            ),
            StatCard(
              icon: Icons.hourglass_bottom,
              label: 'Trial Users',
              value: '1,250',
              onTap: () => context.go(AdminRoutes.trials),
            ),
            StatCard(
              icon: Icons.workspace_premium_outlined,
              label: 'Premium Users',
              value: '3,850',
              delta: '+1.4%',
              onTap: () => context.go(AdminRoutes.subscriptions),
            ),
            StatCard(
              icon: Icons.groups_outlined,
              label: 'Active Groups',
              value: '420',
              delta: '+12',
              onTap: () => context.go(AdminRoutes.groups),
            ),
            StatCard(
              icon: Icons.block,
              label: 'Blocked Users',
              value: '85',
              onTap: () => context.go(AdminRoutes.blockedUsers),
            ),
            StatCard(
              icon: Icons.share_location,
              label: 'Location Enabled',
              value: '190',
              onTap: () => context.go(AdminRoutes.locations),
            ),
            StatCard(
              icon: Icons.flag_outlined,
              label: 'Open Reports',
              value: '37',
              onTap: () => context.go(AdminRoutes.reports),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 900;
            const chart = PanelCard(
              title: 'Messages blocked by content filter (last 7 days)',
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SimpleBarChart(
                values: [412, 388, 455, 501, 470, 530, 612],
                labels: ['18', '19', '20', '21', '22', '23', '24'],
              ),
            );
            final pending = PanelCard(
              title: 'Pending actions',
              child: Column(
                children: [
                  AppTile(
                    icon: Icons.more_time,
                    title: 'Extension requests',
                    trailing: const StatusChip('8', tone: Tone.warning),
                    onTap: () => context.go(AdminRoutes.extensionRequests),
                  ),
                  AppTile(
                    icon: Icons.gavel_outlined,
                    title: 'Moderation queue',
                    trailing: const StatusChip('15', tone: Tone.danger),
                    onTap: () => context.go(AdminRoutes.moderation),
                  ),
                  AppTile(
                    icon: Icons.flag_outlined,
                    title: 'Abuse reports',
                    trailing: const StatusChip('37', tone: Tone.warning),
                    onTap: () => context.go(AdminRoutes.reports),
                  ),
                  AppTile(
                    icon: Icons.account_tree_outlined,
                    title: 'Forward chains flagged',
                    trailing: const StatusChip('4', tone: Tone.danger),
                    onTap: () => context.go(AdminRoutes.forwardChains),
                  ),
                ],
              ),
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 3, child: chart),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: pending),
                ],
              );
            }
            return Column(children: [chart, const SizedBox(height: 16), pending]);
          },
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 360,
          children: [
            PanelCard(
              title: 'Latest extension requests',
              action: 'Review',
              onAction: () => context.go(AdminRoutes.extensionRequests),
              child: Column(
                children: [
                  for (final r in MockData.extensionRequests.take(3))
                    ListTile(
                      leading: AppAvatar(initials: r.user[0], size: 36),
                      title: Text(r.user),
                      subtitle: Text('Trial expired ${r.trialExpired}  |  wants ${r.requested}'),
                      trailing: StatusChip(r.status),
                    ),
                ],
              ),
            ),
            PanelCard(
              title: 'Latest blocked messages',
              action: 'Moderation',
              onAction: () => context.go(AdminRoutes.moderation),
              child: Column(
                children: [
                  for (final b in MockData.blockedMessages.take(3))
                    ListTile(
                      leading: Icon(b.rule.icon),
                      title: Text('${b.user} - ${b.rule.label}'),
                      subtitle: Text('${b.group}  |  ${b.time}'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
