import '../../../core/core.dart';

class AdminGroupMembersScreen extends StatefulWidget {
  const AdminGroupMembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<AdminGroupMembersScreen> createState() => _AdminGroupMembersScreenState();
}

class _AdminGroupMembersScreenState extends State<AdminGroupMembersScreen> {
  String _q = '';
  String _role = 'all';
  int _reload = 0;

  void _refresh() => setState(() => _reload++);

  Future<void> _add() async {
    final user = await askText(context, title: 'Add member', label: 'User ID, mobile number or email', hint: 'SC-4F2A9C', confirm: 'Add');
    if (user == null || user.trim().isEmpty || !mounted) return;
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/groups/${widget.groupId}/members', {'user': user.trim()}));
    if (r == null || !mounted) return;
    context.showSnack('${r['name']} added to ${r['group']}');
    _refresh();
  }

  Future<void> _update(Map<String, dynamic> m, Map<String, Object?> body, String done) async {
    final r = await runAction(context, () => AdminApi.patch('/groups/${widget.groupId}/members/${m['id']}', body), success: done);
    if (r != null) _refresh();
  }

  Future<void> _remove(Map<String, dynamic> m) async {
    final ok = await context.confirm(title: 'Remove ${m['name']}?', message: 'They leave the group and lose access to its messages.', confirmLabel: 'Remove', danger: true);
    if (!ok || !mounted) return;
    final r = await runAction(context, () => AdminApi.delete('/groups/${widget.groupId}/members/${m['id']}'), success: '${m['name']} removed');
    if (r != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<List<dynamic>>(
      reloadKey: '${widget.groupId}|$_q|$_role|$_reload',
      load: () async => [
        await AdminApi.get<List<dynamic>>('/groups/${widget.groupId}/members', {'q': _q, 'role': _role}),
        await AdminApi.get<Map<String, dynamic>>('/groups/${widget.groupId}'),
      ],
      builder: (context, data, _) {
        final members = (data[0] as List).cast<Map<String, dynamic>>();
        final g = data[1] as Map<String, dynamic>;
        return AdminPage(
          title: 'Group Members',
          subtitle: '${g['name']}  |  ${fmtNum(g['memberCount'])} members',
          showBack: true,
          onRefresh: _refresh,
          actions: [
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: _add,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add member'),
            ),
          ],
          children: [
            AdminFilterBar(
              hint: 'Search members',
              filters: const {'All': 'all', 'Owner': 'owner', 'Admin': 'admin', 'Member': 'member'},
              selected: _role,
              onSearch: (q) => setState(() => _q = q),
              onChanged: (r) => setState(() => _role = r),
            ),
            AdminTable(
              columns: const ['Member', 'Role', 'Joined', 'Login', 'Location', 'Status', 'Actions'],
              onRowTap: (i) => context.push(AdminRoutes.userDetailsOf('${members[i]['id']}')),
              emptyText: 'No members found',
              rows: [
                for (final m in members)
                  [
                    NameCell(name: '${m['name']}', subtitle: 'shown as "${m['displayName']}"', online: m['online'] == true),
                    StatusChip(capitalize('${m['role']}'), tone: m['role'] == 'member' ? Tone.neutral : Tone.dark),
                    Text(fmtDate(m['joinedAt'])),
                    Text('${m['phone'] ?? m['email'] ?? '-'}'),
                    Text(m['location'] == null ? 'Not shared' : '${(m['location'] as Map)['place'] ?? capitalize('${(m['location'] as Map)['mode']}')}'),
                    StatusChip(m['memberRestricted'] == true ? 'Muted' : capitalize('${m['status'] ?? 'active'}'), tone: m['memberRestricted'] == true ? Tone.warning : null),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (m['role'] != 'owner')
                          IconButton(
                            tooltip: m['role'] == 'admin' ? 'Remove admin' : 'Make admin',
                            icon: Icon(m['role'] == 'admin' ? Icons.remove_moderator_outlined : Icons.admin_panel_settings_outlined),
                            onPressed: () => _update(m, {'role': m['role'] == 'admin' ? 'member' : 'admin'}, m['role'] == 'admin' ? '${m['name']} is now a member' : '${m['name']} is now an admin'),
                          ),
                        IconButton(
                          tooltip: m['memberRestricted'] == true ? 'Unmute' : 'Mute (read only)',
                          icon: Icon(m['memberRestricted'] == true ? Icons.volume_up_outlined : Icons.volume_off_outlined),
                          onPressed: () => _update(m, {'restricted': m['memberRestricted'] != true}, m['memberRestricted'] == true ? '${m['name']} can send again' : '${m['name']} muted'),
                        ),
                        if (m['role'] != 'owner')
                          IconButton(
                            tooltip: 'Remove',
                            icon: Icon(Icons.person_remove_outlined, color: context.palette.danger),
                            onPressed: () => _remove(m),
                          ),
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
