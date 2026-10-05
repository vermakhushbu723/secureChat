import '../../../core/core.dart';
import 'user_list_screen.dart';

class AdminBlockedUsersScreen extends StatefulWidget {
  const AdminBlockedUsersScreen({super.key});

  @override
  State<AdminBlockedUsersScreen> createState() => _AdminBlockedUsersScreenState();
}

class _AdminBlockedUsersScreenState extends State<AdminBlockedUsersScreen> {
  String _q = '';
  String _filter = 'all';
  int _page = 1;
  int _reload = 0;

  Future<void> _unblock(Map<String, dynamic> u) async {
    final r = await runAction(context, () => AdminApi.post('/users/${u['id']}/action', {'action': 'unblock'}), success: '${u['name']} unblocked');
    if (r != null) setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_filter|$_page|$_reload',
      load: () => AdminApi.get('/users/blocked', {'q': _q, 'filter': _filter, 'page': _page}),
      builder: (context, d, _) {
        final users = (d['items'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'Blocked Users',
          subtitle: '${fmtNum(d['total'])} users blocked or suspended by admins',
          onRefresh: () => setState(() => _reload++),
          children: [
            AdminFilterBar(
              hint: 'Search blocked users',
              filters: const {'All': 'all', 'Blocked': 'blocked', 'Suspended': 'suspended'},
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
              columns: const ['User', 'Status', 'Reason', 'Since', 'Until', 'By', 'Action'],
              onRowTap: (i) => context.push(AdminRoutes.userDetailsOf('${users[i]['id']}')),
              emptyText: 'No blocked users',
              rows: [
                for (final u in users)
                  [
                    NameCell(name: '${u['name']}', subtitle: '${u['internalId']}'),
                    StatusChip(statusLabel(u['status'] as String?)),
                    SizedBox(width: 220, child: Text('${(u['moderation'] as Map?)?['reason'] ?? '-'}', overflow: TextOverflow.ellipsis)),
                    Text(fmtDate((u['moderation'] as Map?)?['at'])),
                    Text(u['status'] == 'suspended' ? fmtDate((u['moderation'] as Map?)?['suspendedUntil']) : '-'),
                    Text('${(u['moderation'] as Map?)?['by'] ?? '-'}'),
                    TextButton.icon(onPressed: () => _unblock(u), icon: const Icon(Icons.lock_open, size: 18), label: const Text('Unblock')),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
