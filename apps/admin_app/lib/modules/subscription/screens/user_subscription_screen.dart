import '../../../core/core.dart';

/// User-wise and group-wise access (Trial / Free / Premium / Extended / Locked).
class AdminUserSubscriptionScreen extends StatefulWidget {
  const AdminUserSubscriptionScreen({super.key});

  @override
  State<AdminUserSubscriptionScreen> createState() => _AdminUserSubscriptionScreenState();
}

class _AdminUserSubscriptionScreenState extends State<AdminUserSubscriptionScreen> {
  String _q = '';
  String _filter = 'all';
  int _page = 1;
  String _groupQ = '';
  int _groupPage = 1;
  int _reload = 0;

  void _refresh() => setState(() => _reload++);

  Future<void> _change(Map<String, dynamic> u) async {
    final access = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Set access for ${u['name']}'),
        children: [
          for (final a in const ['trial', 'free', 'premium', 'extended', 'locked'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, a),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [Expanded(child: Text(accessLabel(a))), if (u['access'] == a) const Icon(Icons.check, size: 18)]),
              ),
            ),
        ],
      ),
    );
    if (access == null || !mounted) return;
    var days = 0;
    if (access != 'free' && access != 'locked') {
      final picked = await askDays(context, title: '${accessLabel(access)} for', options: access == 'premium' ? const [30, 90, 365] : const [7, 15, 30]);
      if (picked == null) return;
      days = picked;
    }
    if (!mounted) return;
    final r = await runAction(context, () => AdminApi.post('/users/access', {'user': u['id'], 'kind': access, 'days': days}), success: '${u['name']}: ${accessLabel(access)} access');
    if (r != null) _refresh();
  }

  Future<void> _changeGroup(Map<String, dynamic> g) async {
    final premium = g['premiumApproved'] == true;
    int? days;
    if (!premium) {
      days = await askDays(context, title: 'Premium for every member of ${g['name']}', options: const [30, 90, 365]);
      if (days == null) return;
    } else if (!await context.confirm(title: 'Back to per user access?', message: 'Members of ${g['name']} need their own trial or premium again.', confirmLabel: 'Remove premium')) {
      return;
    }
    if (!mounted) return;
    final r = await runAction(
      context,
      () => AdminApi.post('/groups/${g['id']}/access', {'premium': !premium, 'days': ?days, 'freeAccess': !premium}),
      success: premium ? '${g['name']}: per user access' : '${g['name']}: premium for all members ($days days)',
    );
    if (r != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<List<dynamic>>(
      reloadKey: '$_q|$_filter|$_page|$_groupQ|$_groupPage|$_reload',
      load: () async => [
        await AdminApi.get<Map<String, dynamic>>('/access', {'q': _q, 'filter': _filter, 'page': _page}),
        await AdminApi.get<Map<String, dynamic>>('/access/groups', {'q': _groupQ, 'page': _groupPage}),
      ],
      builder: (context, data, _) {
        final d = data[0] as Map<String, dynamic>;
        final gd = data[1] as Map<String, dynamic>;
        final c = d['counts'] as Map<String, dynamic>;
        final users = (d['items'] as List).cast<Map<String, dynamic>>();
        final groups = (gd['items'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'User Access & Subscriptions',
          subtitle: 'Free / Premium / Extended access, user-wise and group-wise',
          onRefresh: _refresh,
          children: [
            ResponsiveGrid(
              minItemWidth: 180,
              children: [
                StatCard(icon: Icons.workspace_premium_outlined, label: 'Premium', value: fmtNum(c['premium'])),
                StatCard(icon: Icons.card_giftcard_outlined, label: 'Free', value: fmtNum(c['free'])),
                StatCard(icon: Icons.more_time, label: 'Extended', value: fmtNum(c['extended'])),
                StatCard(icon: Icons.hourglass_bottom, label: 'Trial', value: fmtNum(c['trial'])),
                StatCard(icon: Icons.lock_clock_outlined, label: 'Locked', value: fmtNum(c['locked'])),
              ],
            ),
            const SizedBox(height: 16),
            const SectionHeader('User-wise access', padding: EdgeInsets.fromLTRB(0, 8, 0, 8)),
            AdminFilterBar(
              hint: 'Search user',
              filters: const {'All': 'all', 'Trial': 'trial', 'Not claimed': 'unclaimed', 'Free': 'free', 'Premium': 'premium', 'Extended': 'extended', 'Locked': 'locked'},
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
              columns: const ['User', 'User ID', 'Access', 'Valid till', 'Granted by', ''],
              onRowTap: (i) => context.push(AdminRoutes.userDetailsOf('${users[i]['id']}')),
              emptyText: 'No users',
              rows: [
                for (final u in users)
                  [
                    Text('${u['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${u['internalId']}', style: const TextStyle(fontFamily: 'monospace')),
                    StatusChip(accessLabel(u['access'] as String?), tone: accessToneOf(u['access'] as String?)),
                    Text(u['access'] == 'free' ? 'No end date' : fmtDate(u['accessUntil'])),
                    Text('${u['grantedBy'] ?? (u['access'] == 'trial' ? 'Free trial' : '-')}'),
                    TextButton(onPressed: () => _change(u), child: const Text('Change')),
                  ],
              ],
            ),
            const SectionHeader('Group-wise access', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
            AdminFilterBar(hint: 'Search group', filters: const {}, onSearch: (q) => setState(() {
              _groupQ = q;
              _groupPage = 1;
            })),
            AdminTable(
              total: (gd['total'] as num).toInt(),
              page: _groupPage,
              onPage: (p) => setState(() => _groupPage = p),
              columns: const ['Group', 'Members', 'Access for all members', 'Until', ''],
              onRowTap: (i) => context.push(AdminRoutes.groupDetailsOf('${groups[i]['id']}')),
              emptyText: 'No groups',
              rows: [
                for (final g in groups)
                  [
                    Text('${g['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(fmtNum(g['memberCount'])),
                    StatusChip(g['premiumApproved'] == true ? 'Premium' : 'Per user', tone: g['premiumApproved'] == true ? Tone.success : Tone.neutral),
                    Text(g['premiumApproved'] == true ? (g['premiumUntil'] == null ? 'No end date' : fmtDate(g['premiumUntil'])) : '-'),
                    TextButton(onPressed: () => _changeGroup(g), child: const Text('Change')),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
