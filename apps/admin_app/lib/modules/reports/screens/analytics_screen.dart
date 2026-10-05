import '../../../core/core.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int _days = 14;
  int _reload = 0;

  Future<void> _export() async {
    final bytes = await runAction(context, () => AdminApi.download('/analytics/export.csv', {'days': _days}));
    if (bytes == null) return;
    await saveFile('securechat-analytics-${_days}d.csv', bytes);
    if (mounted) context.showSnack('Analytics exported');
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_days|$_reload',
      load: () => AdminApi.get('/analytics', {'days': _days}),
      builder: (context, a, _) {
        final k = a['kpis'] as Map<String, dynamic>;
        final newUsers = (a['newUsers'] as List).cast<Map<String, dynamic>>();
        final messages = (a['messages'] as List).cast<Map<String, dynamic>>();
        final byRule = a['blockedByRule'] as Map<String, dynamic>;
        final mix = a['accessMix'] as Map<String, dynamic>;
        final mixTotal = mix.values.fold<num>(0, (s, v) => s + (v as num));
        final groups = (a['groups'] as List).cast<Map<String, dynamic>>();
        String label(Map<String, dynamic> x) => '${x['day']}'.substring(8);
        return AdminPage(
          title: 'Reports & Analytics',
          subtitle: 'Last $_days days',
          onRefresh: () => setState(() => _reload++),
          actions: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [ButtonSegment(value: 7, label: Text('7d')), ButtonSegment(value: 14, label: Text('14d')), ButtonSegment(value: 30, label: Text('30d')), ButtonSegment(value: 90, label: Text('90d'))],
              selected: {_days},
              onSelectionChanged: (s) => setState(() => _days = s.first),
            ),
            OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _export, icon: const Icon(Icons.download_outlined), label: const Text('Export CSV')),
          ],
          children: [
            ResponsiveGrid(
              minItemWidth: 200,
              children: [
                StatCard(icon: Icons.person_add_alt, label: 'New users (${_days}d)', value: fmtNum(k['newUsers'])),
                StatCard(icon: Icons.forum_outlined, label: 'Messages (${_days}d)', value: fmtNum(k['messages'])),
                StatCard(icon: Icons.trending_up, label: 'Trial to paid', value: '${k['trialToPaid']}%'),
                StatCard(icon: Icons.gpp_bad_outlined, label: 'Blocked rate', value: '${k['blockedRate']}%'),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 420,
              children: [
                PanelCard(
                  title: 'New users per day',
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SimpleBarChart(values: [for (final x in newUsers) (x['count'] as num).toDouble()], labels: [for (final x in newUsers) label(x)]),
                ),
                PanelCard(
                  title: 'Messages per day (groups + direct)',
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SimpleBarChart(values: [for (final x in messages) (x['count'] as num).toDouble()], labels: [for (final x in messages) label(x)]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 420,
              children: [
                PanelCard(
                  title: 'Blocked messages by rule',
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SimpleBarChart(
                    values: [for (final r in ContentRule.values) ((byRule[r.name] as num?) ?? 0).toDouble()],
                    labels: const ['Num', 'Words', 'Abuse', 'Spam', 'Link', 'Contact', 'Info'],
                  ),
                ),
                PanelCard(
                  title: 'Access mix',
                  child: Column(
                    children: [
                      for (final key in const ['premium', 'free', 'extended', 'trial', 'unclaimed', 'locked'])
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                          child: Row(
                            children: [
                              SizedBox(width: 120, child: Text(accessLabel(key))),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(value: mixTotal == 0 ? 0 : ((mix[key] as num?) ?? 0) / mixTotal, minHeight: 10),
                                ),
                              ),
                              SizedBox(width: 64, child: Text(fmtNum(mix[key]), textAlign: TextAlign.right)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminTable(
              columns: ['Group', 'Members', 'Messages (${_days}d)', 'Blocked', 'Reports', 'Location'],
              onRowTap: (i) => context.push(AdminRoutes.groupDetailsOf('${groups[i]['id']}')),
              emptyText: 'No group messages in this period',
              rows: [
                for (final g in groups)
                  [
                    Text('${g['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(fmtNum(g['members'])),
                    Text(fmtNum(g['messages'])),
                    Text(fmtNum(g['blocked'])),
                    Text(fmtNum(g['reports'])),
                    Text(locationLabel(g['location'] as String?)),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
