import '../../../core/core.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final byRule = <ContentRule, int>{};
    for (final b in MockData.blockedMessages) {
      byRule[b.rule] = (byRule[b.rule] ?? 0) + 1;
    }
    return AdminPage(
      title: 'Reports & Analytics',
      subtitle: 'Last 14 days',
      actions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.showSnack('Report export queued'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export CSV'),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 200,
          children: const [
            StatCard(icon: Icons.person_add_alt, label: 'New users (14d)', value: '1,842', delta: '+9%'),
            StatCard(icon: Icons.forum_outlined, label: 'Messages (14d)', value: '3.9M', delta: '+12%'),
            StatCard(icon: Icons.trending_up, label: 'Trial to paid', value: '38%', delta: '+3%'),
            StatCard(icon: Icons.gpp_bad_outlined, label: 'Blocked rate', value: '0.16%', delta: '-0.02%'),
          ],
        ),
        const SizedBox(height: 16),
        const ResponsiveGrid(
          minItemWidth: 420,
          children: [
            PanelCard(
              title: 'New users per day',
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SimpleBarChart(
                values: [102, 118, 96, 131, 140, 122, 99, 128, 150, 162, 141, 155, 170, 128],
                labels: ['11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24'],
              ),
            ),
            PanelCard(
              title: 'Messages per day (thousands)',
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SimpleBarChart(
                values: [240, 252, 238, 266, 281, 270, 244, 273, 289, 301, 296, 310, 322, 284],
                labels: ['11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24'],
                unit: 'K',
              ),
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
                values: [for (final r in ContentRule.values) (byRule[r] ?? 0) * 100.0 + 20],
                labels: const ['Num', 'Words', 'Abuse', 'Spam', 'Link', 'Contact', 'Info'],
              ),
            ),
            PanelCard(
              title: 'Access mix',
              child: Column(
                children: [
                  for (final a in const [
                    ('Premium', 3850),
                    ('Free', 4210),
                    ('Trial', 1250),
                    ('Extended', 612),
                    ('Locked', 2528),
                  ])
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Row(
                        children: [
                          SizedBox(width: 80, child: Text(a.$1)),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: a.$2 / 12450, minHeight: 10),
                            ),
                          ),
                          SizedBox(width: 64, child: Text('${a.$2}', textAlign: TextAlign.right)),
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
          columns: const ['Group', 'Members', 'Messages (14d)', 'Blocked', 'Reports', 'Location'],
          rows: [
            for (final g in MockData.groups)
              [
                Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${g.memberCount}'),
                Text('${g.memberCount * 91}'),
                Text('${g.memberCount ~/ 4}'),
                Text('${g.unread}'),
                Text(g.location.label),
              ],
          ],
        ),
      ],
    );
  }
}
