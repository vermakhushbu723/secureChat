import '../../../core/core.dart';

String statusLabel(String? s) => capitalize(s ?? 'active');

/// Admins see full identity (name, login, internal ID) - members never do.
class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  String _q = '';
  String _filter = 'all';
  int _page = 1;
  int _reload = 0;

  static const _filters = {
    'All': 'all',
    'Trial': 'trial',
    'Not claimed': 'unclaimed',
    'Free': 'free',
    'Premium': 'premium',
    'Extended': 'extended',
    'Locked': 'locked',
    'Restricted': 'restricted',
    'Search off': 'search_off',
    'Hidden from search': 'search_hidden',
    'Blocked': 'blocked',
  };

  Future<void> _export() async {
    final bytes = await runAction(context, () => AdminApi.download('/users/export.csv', {'q': _q, 'filter': _filter}));
    if (bytes == null) return;
    await saveFile('securechat-users-${DateTime.now().toIso8601String().substring(0, 10)}.csv', bytes);
    if (mounted) context.showSnack('Exported ${_filter == 'all' ? 'all' : _filter} users');
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_filter|$_page|$_reload',
      load: () => AdminApi.get('/users', {'q': _q, 'filter': _filter, 'page': _page}),
      builder: (context, d, _) {
        final users = (d['items'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'Users',
          subtitle: '${fmtNum(d['total'])} ${_filter == 'all' ? 'registered users' : 'users in this filter'}',
          onRefresh: () => setState(() => _reload++),
          actions: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: _export,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export CSV'),
            ),
          ],
          children: [
            AdminFilterBar(
              hint: 'Search name, user ID, mobile or email',
              filters: _filters,
              selected: _filter,
              onSearch: (q) => setState(() {
                _q = q;
                _page = 1;
              }),
              onChanged: (f) => setState(() {
                _filter = f;
                _page = 1;
              }),
            ),
            AdminTable(
              total: (d['total'] as num).toInt(),
              page: _page,
              onPage: (p) => setState(() => _page = p),
              columns: const ['User', 'User ID', 'Login', 'Access', 'Trial ends', 'Location', 'Warnings', 'Status', ''],
              onRowTap: (i) => context.push(AdminRoutes.userDetailsOf('${users[i]['id']}')),
              emptyText: 'No users match this search',
              rows: [
                for (final u in users)
                  [
                    NameCell(name: '${u['name']}', subtitle: 'shown as "${u['displayName']}"', online: u['online'] == true),
                    Text('${u['internalId']}', style: const TextStyle(fontFamily: 'monospace')),
                    Text('${u['phone'] ?? u['email'] ?? u['username'] ?? '-'}'),
                    StatusChip(accessLabel(u['access'] as String?), tone: accessToneOf(u['access'] as String?)),
                    Text(fmtDate(u['trialEndsAt'])),
                    Icon(u['locationEnabled'] == true ? Icons.location_on : Icons.location_off_outlined, size: 20),
                    Text('${u['warnings']}'),
                    StatusChip(u['restricted'] == true && u['status'] == 'active' ? 'Read only' : statusLabel(u['status'] as String?), tone: u['restricted'] == true && u['status'] == 'active' ? Tone.warning : null),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz),
                      onSelected: context.push,
                      itemBuilder: (_) => [
                        PopupMenuItem(value: AdminRoutes.userDetailsOf('${u['id']}'), child: const Text('View / edit')),
                        PopupMenuItem(value: AdminRoutes.userActivityOf('${u['id']}'), child: const Text('Activity')),
                        PopupMenuItem(value: AdminRoutes.userLocationOf('${u['id']}'), child: const Text('Location')),
                      ],
                    ),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
