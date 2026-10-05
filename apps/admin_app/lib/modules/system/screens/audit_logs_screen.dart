import '../../../core/core.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  String _q = '';
  String _category = 'all';
  int _days = 7;
  int _page = 1;
  int _reload = 0;

  Future<void> _export() async {
    final bytes = await runAction(context, () => AdminApi.download('/audit-logs/export.csv', {'q': _q, 'category': _category, 'days': _days}));
    if (bytes == null) return;
    await saveFile('securechat-audit-logs.csv', bytes);
    if (mounted) context.showSnack('Audit log exported');
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_category|$_days|$_page|$_reload',
      load: () => AdminApi.get('/audit-logs', {'q': _q, 'category': _category, 'days': _days, 'page': _page}),
      builder: (context, d, _) {
        final logs = (d['items'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'Audit Logs',
          subtitle: 'Every admin and staff action is recorded',
          onRefresh: () => setState(() => _reload++),
          actions: [
            PopupMenuButton<int>(
              initialValue: _days,
              onSelected: (v) => setState(() {
                _days = v;
                _page = 1;
              }),
              itemBuilder: (_) => [for (final v in const [1, 7, 30, 90, 365]) PopupMenuItem(value: v, child: Text(v == 1 ? 'Last 24 hours' : 'Last $v days'))],
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: null,
                icon: const Icon(Icons.date_range),
                label: Text(_days == 1 ? 'Last 24 hours' : 'Last $_days days'),
              ),
            ),
            OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _export, icon: const Icon(Icons.download_outlined), label: const Text('Export CSV')),
          ],
          children: [
            AdminFilterBar(
              hint: 'Search actor, action, target or IP',
              filters: const {
                'All': 'all',
                'Users': 'users',
                'Groups': 'groups',
                'Messages': 'messages',
                'Subscriptions': 'subscriptions',
                'Reports': 'reports',
                'Settings': 'settings',
                'Staff': 'staff',
                'Sign in': 'auth',
              },
              selected: _category,
              onSearch: (q) => setState(() {
                _q = q;
                _page = 1;
              }),
              onChanged: (c) => setState(() {
                _category = c;
                _page = 1;
              }),
            ),
            AdminTable(
              total: (d['total'] as num).toInt(),
              page: _page,
              onPage: (p) => setState(() => _page = p),
              columns: const ['Time', 'Actor', 'Action', 'Target', 'Category', 'IP address'],
              emptyText: 'No admin actions in this period',
              rows: [
                for (final l in logs)
                  [
                    Text(fmtDateTime(l['at'])),
                    NameCell(name: '${l['actor']}'),
                    SizedBox(width: 260, child: Text('${l['action']}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('${l['target'] ?? '-'}'),
                    StatusChip(capitalize('${l['category']}'), tone: Tone.neutral),
                    Text('${l['ip'] ?? '-'}', style: const TextStyle(fontFamily: 'monospace')),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
