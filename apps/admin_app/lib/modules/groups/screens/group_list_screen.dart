import '../../../core/core.dart';

/// Deletes a group after confirmation. Returns true when deleted.
Future<bool> confirmDeleteGroup(BuildContext context, String id, String name) async {
  final ok = await context.confirm(
    title: 'Delete $name?',
    message: 'All members lose access and every invite link is revoked. This cannot be undone.',
    confirmLabel: 'Delete',
    danger: true,
  );
  if (!ok || !context.mounted) return false;
  return await runAction(context, () => AdminApi.delete('/groups/$id'), success: '$name deleted') != null;
}

class AdminGroupListScreen extends StatefulWidget {
  const AdminGroupListScreen({super.key});

  @override
  State<AdminGroupListScreen> createState() => _AdminGroupListScreenState();
}

class _AdminGroupListScreenState extends State<AdminGroupListScreen> {
  String _q = '';
  String _filter = 'all';
  int _page = 1;
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_filter|$_page|$_reload',
      load: () => AdminApi.get('/groups', {'q': _q, 'filter': _filter, 'page': _page}),
      builder: (context, d, _) {
        final groups = (d['items'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'Groups',
          subtitle: '${fmtNum(d['total'])} groups',
          onRefresh: () => setState(() => _reload++),
          actions: [
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () async {
                await context.push(AdminRoutes.groupCreate);
                if (mounted) setState(() => _reload++);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create group'),
            ),
          ],
          children: [
            AdminFilterBar(
              hint: 'Search group name or invite code',
              filters: const {
                'All': 'all',
                'Location mandatory': 'location_mandatory',
                'Location optional': 'location_optional',
                'Private mode': 'private',
                'Premium': 'premium',
                'Suspended': 'suspended',
              },
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
              columns: const ['Group', 'Members', 'Location', 'Member location', 'Message mode', 'Creator', 'Plan', 'Status', ''],
              onRowTap: (i) => context.push(AdminRoutes.groupDetailsOf('${groups[i]['id']}')),
              emptyText: 'No groups found',
              rows: [
                for (final g in groups)
                  [
                    NameCell(name: '${g['name']}', subtitle: 'Created ${fmtDate(g['createdAt'])}'),
                    Text(fmtNum(g['memberCount'])),
                    StatusChip(locationLabel(g['location'] as String?), tone: g['location'] == 'mandatory' ? Tone.warning : Tone.neutral),
                    Text(visibilityLabel(g['locationVisibility'] as String?)),
                    Text(messageModeLabel(g['messageMode'] as String?)),
                    Text('${(g['createdBy'] as Map)['name']}'),
                    StatusChip((g['premium'] as Map?)?['active'] == true ? 'Premium' : 'Per user', tone: (g['premium'] as Map?)?['active'] == true ? Tone.success : Tone.neutral),
                    StatusChip(capitalize('${g['status']}')),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (v) async {
                        if (v == 'delete') {
                          if (await confirmDeleteGroup(context, '${g['id']}', '${g['name']}')) setState(() => _reload++);
                        } else {
                          await context.push(v);
                          if (mounted) setState(() => _reload++);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: AdminRoutes.groupDetailsOf('${g['id']}'), child: const Text('View')),
                        PopupMenuItem(value: AdminRoutes.groupEditOf('${g['id']}'), child: const Text('Edit')),
                        PopupMenuItem(value: AdminRoutes.groupMembersOf('${g['id']}'), child: const Text('Members')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
