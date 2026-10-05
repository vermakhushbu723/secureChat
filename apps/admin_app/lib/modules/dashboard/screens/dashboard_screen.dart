import '../../../core/core.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: _reload,
      load: () => AdminApi.get('/dashboard'),
      builder: (context, d, _) {
        final s = d['stats'] as Map<String, dynamic>;
        final p = d['pending'] as Map<String, dynamic>;
        final chart = (d['blockedChart'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'Admin Dashboard',
          subtitle: 'Overview for today, ${fmtDate(d['date'])}',
          onRefresh: () => setState(() => _reload++),
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
                StatCard(icon: Icons.people_outline, label: 'Total Users', value: fmtNum(s['totalUsers']), delta: s['totalUsersDelta'] as String?, onTap: () => context.go(AdminRoutes.users)),
                StatCard(icon: Icons.bolt_outlined, label: 'Active Users (7 days)', value: fmtNum(s['activeUsers']), onTap: () => context.go(AdminRoutes.users)),
                StatCard(icon: Icons.hourglass_bottom, label: 'Trial Users', value: fmtNum(s['trialUsers']), onTap: () => context.go(AdminRoutes.trials)),
                StatCard(icon: Icons.workspace_premium_outlined, label: 'Premium Users', value: fmtNum(s['premiumUsers']), onTap: () => context.go(AdminRoutes.subscriptions)),
                StatCard(
                  icon: Icons.groups_outlined,
                  label: 'Active Groups',
                  value: fmtNum(s['activeGroups']),
                  delta: (s['newGroupsThisWeek'] as num? ?? 0) > 0 ? '+${s['newGroupsThisWeek']}' : null,
                  onTap: () => context.go(AdminRoutes.groups),
                ),
                StatCard(icon: Icons.block, label: 'Blocked Users', value: fmtNum(s['blockedUsers']), onTap: () => context.go(AdminRoutes.blockedUsers)),
                StatCard(icon: Icons.share_location, label: 'Location Enabled', value: fmtNum(s['locationEnabled']), onTap: () => context.go(AdminRoutes.locations)),
                StatCard(icon: Icons.flag_outlined, label: 'Open Reports', value: fmtNum(s['openReports']), onTap: () => context.go(AdminRoutes.reports)),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 900;
                final chartCard = PanelCard(
                  title: 'Messages blocked by content filter (last 7 days)',
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SimpleBarChart(
                    values: [for (final x in chart) (x['count'] as num).toDouble()],
                    labels: [for (final x in chart) '${x['day']}'.substring(8)],
                  ),
                );
                final pending = PanelCard(
                  title: 'Pending actions',
                  child: Column(
                    children: [
                      AppTile(
                        icon: Icons.more_time,
                        title: 'Extension requests',
                        trailing: StatusChip('${p['extensionRequests']}', tone: Tone.warning),
                        onTap: () => context.go(AdminRoutes.extensionRequests),
                      ),
                      AppTile(
                        icon: Icons.gavel_outlined,
                        title: 'Blocked messages (24h)',
                        trailing: StatusChip('${p['moderationQueue']}', tone: Tone.danger),
                        onTap: () => context.go(AdminRoutes.moderation),
                      ),
                      AppTile(
                        icon: Icons.flag_outlined,
                        title: 'Abuse reports',
                        trailing: StatusChip('${p['abuseReports']}', tone: Tone.warning),
                        onTap: () => context.go(AdminRoutes.reports),
                      ),
                      AppTile(
                        icon: Icons.account_tree_outlined,
                        title: 'Forward chains flagged',
                        trailing: StatusChip('${p['flaggedChains']}', tone: Tone.danger),
                        onTap: () => context.go(AdminRoutes.forwardChains),
                      ),
                    ],
                  ),
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: chartCard),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: pending),
                    ],
                  );
                }
                return Column(children: [chartCard, const SizedBox(height: 16), pending]);
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
                      for (final r in (d['latestRequests'] as List).cast<Map<String, dynamic>>())
                        ListTile(
                          leading: AppAvatar(initials: initialsOf(r['user'] as String?), size: 36),
                          title: Text('${r['user']}'),
                          subtitle: Text('Wants ${r['kind'] == 'premium' ? 'premium' : '${r['days']} more days'}  |  ${fmtAgo(r['createdAt'])}'),
                          trailing: const StatusChip('Pending'),
                        ),
                      if ((d['latestRequests'] as List).isEmpty) const ListTile(title: Text('No pending requests')),
                    ],
                  ),
                ),
                PanelCard(
                  title: 'Latest blocked messages',
                  action: 'Moderation',
                  onAction: () => context.go(AdminRoutes.moderation),
                  child: Column(
                    children: [
                      for (final b in (d['latestBlocked'] as List).cast<Map<String, dynamic>>())
                        ListTile(
                          leading: const Icon(Icons.gpp_bad_outlined),
                          title: Text('${b['user']} - ${ruleLabels[b['rule']] ?? b['rule']}'),
                          subtitle: Text('${b['group']}  |  ${fmtAgo(b['at'])}'),
                        ),
                      if ((d['latestBlocked'] as List).isEmpty) const ListTile(title: Text('No blocked messages')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
