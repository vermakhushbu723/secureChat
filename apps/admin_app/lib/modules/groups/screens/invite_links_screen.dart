import '../../../core/core.dart';

/// All invite links: expiry, maximum joins, approval, revoke.
class AdminInviteLinksScreen extends StatefulWidget {
  const AdminInviteLinksScreen({super.key});

  @override
  State<AdminInviteLinksScreen> createState() => _AdminInviteLinksScreenState();
}

class _AdminInviteLinksScreenState extends State<AdminInviteLinksScreen> {
  String _q = '';
  String _filter = 'all';
  int _page = 1;
  int _reload = 0;

  Future<void> _revoke(Map<String, dynamic> l) async {
    final ok = await context.confirm(title: 'Revoke ${l['code']}?', message: 'Nobody can join ${l['groupName']} with this link any more.', confirmLabel: 'Revoke', danger: true);
    if (!ok || !mounted) return;
    final r = await runAction(context, () => AdminApi.post('/invites/${l['code']}/revoke'), success: 'Link ${l['code']} revoked');
    if (r != null) setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_filter|$_page|$_reload',
      load: () => AdminApi.get('/invites', {'q': _q, 'filter': _filter, 'page': _page}),
      builder: (context, d, _) {
        final links = (d['items'] as List).cast<Map<String, dynamic>>();
        final s = d['stats'] as Map<String, dynamic>;
        return AdminPage(
          title: 'Invite Links',
          subtitle: 'Links created by group creators and admins',
          onRefresh: () => setState(() => _reload++),
          children: [
            ResponsiveGrid(
              minItemWidth: 200,
              children: [
                StatCard(icon: Icons.link, label: 'Active links', value: fmtNum(s['active'])),
                StatCard(icon: Icons.group_add_outlined, label: 'Joins today', value: fmtNum(s['joinsToday'])),
                StatCard(icon: Icons.timer_off_outlined, label: 'Expired (7d)', value: fmtNum(s['expired7d'])),
                StatCard(icon: Icons.link_off, label: 'Revoked (7d)', value: fmtNum(s['revoked7d'])),
              ],
            ),
            const SizedBox(height: 16),
            AdminFilterBar(
              hint: 'Search code or group',
              filters: const {'All': 'all', 'Active': 'active', 'Expired': 'expired', 'Revoked': 'revoked', 'Approval on': 'approval'},
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
              columns: const ['Link', 'Group', 'Created by', 'Joins', 'Expires', 'Approval', 'Status', 'Action'],
              emptyText: 'No invite links',
              rows: [
                for (final l in links)
                  [
                    Text('${l['code']}', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                    InkWell(
                      onTap: () => context.push(AdminRoutes.groupDetailsOf('${l['groupId']}')),
                      child: Text('${l['groupName']}', style: TextStyle(color: context.colors.primary)),
                    ),
                    Text('${l['createdBy'] ?? '-'}'),
                    Text((l['maxJoins'] as num) > 0 ? '${l['joins']} / ${l['maxJoins']}' : '${l['joins']} / unlimited'),
                    Text(l['expiresAt'] == null ? 'Never' : fmtDateTime(l['expiresAt'])),
                    Icon(l['requireApproval'] == true ? Icons.how_to_reg : Icons.remove, size: 20),
                    StatusChip('${l['state']}', tone: l['state'] == 'Revoked' ? Tone.danger : l['state'] == 'Full' ? Tone.warning : null),
                    l['state'] == 'Active'
                        ? TextButton.icon(
                            onPressed: () => _revoke(l),
                            icon: Icon(Icons.link_off, size: 18, color: context.palette.danger),
                            label: Text('Revoke', style: TextStyle(color: context.palette.danger)),
                          )
                        : const Text('-'),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
