import '../../../core/core.dart';

/// Admin "Search Permissions": who can search users (1-to-1 chats) and group members.
/// Platform switches for everyone, one user at a time, and group member search.
class AdminSearchPermissionsScreen extends StatefulWidget {
  const AdminSearchPermissionsScreen({super.key});

  @override
  State<AdminSearchPermissionsScreen> createState() => _AdminSearchPermissionsScreenState();
}

class _AdminSearchPermissionsScreenState extends State<AdminSearchPermissionsScreen> {
  String _q = '';
  int _page = 1;
  int _reload = 0;

  void _refresh() => setState(() => _reload++);

  Future<void> _setGlobal(String key, bool v) async {
    final what = key == 'userSearch' ? '1-to-1 user search' : 'Group member search';
    if (!v &&
        !await context.confirm(
          title: 'Turn off $what for everyone?',
          message: key == 'userSearch' ? 'Nobody can search people to start a new chat. Existing chats keep working.' : 'Nobody can search members inside any group, group admins included.',
          confirmLabel: 'Turn off',
          danger: true,
        )) {
      return;
    }
    if (!mounted) return;
    final r = await runAction(context, () => AdminApi.put('/search-permissions', {key: v}), success: '$what ${v ? 'on' : 'off'} for everyone');
    if (r != null) _refresh();
  }

  Future<Map<String, dynamic>?> _pick(String path, String title, String label) async {
    final q = await askText(context, title: title, label: label, confirm: 'Search');
    if (q == null || q.trim().isEmpty || !mounted) return null;
    final res = await runAction<Map<String, dynamic>>(context, () => AdminApi.get(path, {'q': q.trim(), 'limit': 10}));
    if (res == null || !mounted) return null;
    final items = (res['items'] as List).cast<Map<String, dynamic>>();
    if (items.isEmpty) {
      context.showSnack('Nothing found');
      return null;
    }
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select'),
        children: [
          for (final i in items)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, i),
              child: Text(path == '/users' ? '${i['name']} (${i['internalId']})${i['searchAllowed'] == false ? ' - already off' : ''}' : '${i['name']} (${i['memberCount']} members)'),
            ),
        ],
      ),
    );
  }

  Future<void> _blockUser() async {
    final u = await _pick('/users', 'Turn off search for a user', 'Name, user ID, mobile or email');
    if (u == null || !mounted) return;
    final r = await runAction(context, () => AdminApi.post('/users/${u['id']}/search', {'allowed': false}), success: '${u['name']} can not search any more');
    if (r != null) _refresh();
  }

  Future<void> _setUser(Map<String, dynamic> u, bool allowed) async {
    final r = await runAction(context, () => AdminApi.post('/users/${u['id']}/search', {'allowed': allowed}), success: allowed ? '${u['name']} can search again' : '${u['name']} can not search');
    if (r != null) _refresh();
  }

  Future<void> _hideUser() async {
    final u = await _pick('/users', 'Hide a user from search', 'Name, user ID, mobile or email');
    if (u == null || !mounted) return;
    final r = await runAction(context, () => AdminApi.post('/users/${u['id']}/search-visibility', {'hidden': true}), success: 'Nobody can find ${u['name']} in search now');
    if (r != null) _refresh();
  }

  Future<void> _setHidden(Map<String, dynamic> u, bool hidden) async {
    final r = await runAction(context, () => AdminApi.post('/users/${u['id']}/search-visibility', {'hidden': hidden}), success: hidden ? '${u['name']} hidden from search' : '${u['name']} can be found again');
    if (r != null) _refresh();
  }

  Future<void> _groupOff() async {
    final g = await _pick('/groups', 'Turn off member search in a group', 'Group name or invite code');
    if (g == null || !mounted) return;
    final r = await runAction(context, () => AdminApi.post('/groups/${g['id']}/member-search', {'enabled': false}), success: 'Member search off in ${g['name']}');
    if (r != null) _refresh();
  }

  Future<void> _setGroup(Map<String, dynamic> g, bool enabled) async {
    final r = await runAction(context, () => AdminApi.post('/groups/${g['id']}/member-search', {'enabled': enabled}), success: 'Member search ${enabled ? 'on' : 'off'} in ${g['name']}');
    if (r != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_page|$_reload',
      load: () => AdminApi.get('/search-permissions', {'q': _q, 'page': _page}),
      builder: (context, d, _) {
        final global = d['global'] as Map<String, dynamic>;
        final users = d['users'] as Map<String, dynamic>;
        final userItems = (users['items'] as List).cast<Map<String, dynamic>>();
        final groups = d['groups'] as Map<String, dynamic>;
        final hidden = d['hidden'] as Map<String, dynamic>? ?? const {'total': 0, 'items': []};
        final hiddenItems = (hidden['items'] as List).cast<Map<String, dynamic>>();
        final groupItems = (groups['items'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'Search Permissions',
          subtitle: 'Who can search people for 1-to-1 chats and members inside groups',
          onRefresh: _refresh,
          children: [
            ResponsiveGrid(
              minItemWidth: 200,
              children: [
                StatCard(icon: Icons.person_search_outlined, label: '1-to-1 user search', value: global['userSearch'] == true ? 'On' : 'Off'),
                StatCard(icon: Icons.groups_outlined, label: 'Group member search', value: global['groupMemberSearch'] == true ? 'On' : 'Off'),
                StatCard(icon: Icons.search_off, label: 'Users with search off', value: fmtNum(users['total'])),
                StatCard(icon: Icons.group_off_outlined, label: 'Groups with member search off', value: fmtNum(groups['total'])),
                StatCard(icon: Icons.visibility_off_outlined, label: 'Users hidden from search', value: fmtNum(hidden['total'])),
              ],
            ),
            const SizedBox(height: 16),
            PanelCard(
              title: 'For everyone',
              child: Column(
                children: [
                  SettingSwitch(
                    icon: Icons.person_search_outlined,
                    title: 'Users can search people (1-to-1 chats)',
                    subtitle: 'Off: nobody can find people by name, username or number to start a new chat',
                    value: global['userSearch'] == true,
                    onChanged: (v) => _setGlobal('userSearch', v),
                  ),
                  SettingSwitch(
                    icon: Icons.groups_outlined,
                    title: 'Users can search group members',
                    subtitle: 'Off: nobody can search members inside any group (group admins too)',
                    value: global['groupMemberSearch'] == true,
                    onChanged: (v) => _setGlobal('groupMemberSearch', v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: SectionHeader('Users who can not search', padding: EdgeInsets.fromLTRB(0, 8, 0, 8))),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: _blockUser,
                  icon: const Icon(Icons.person_off_outlined, size: 18),
                  label: const Text('Turn off for a user'),
                ),
              ],
            ),
            AdminFilterBar(hint: 'Search these users', filters: const {}, onSearch: (q) => setState(() {
              _q = q;
              _page = 1;
            })),
            AdminTable(
              total: (users['total'] as num).toInt(),
              page: _page,
              onPage: (p) => setState(() => _page = p),
              columns: const ['User', 'User ID', 'Login', 'Status', ''],
              onRowTap: (i) => context.push(AdminRoutes.userDetailsOf('${userItems[i]['id']}')),
              emptyText: 'Every user can search (unless turned off for everyone above)',
              rows: [
                for (final u in userItems)
                  [
                    NameCell(name: '${u['name']}', subtitle: 'shown as "${u['displayName']}"'),
                    Text('${u['internalId']}', style: const TextStyle(fontFamily: 'monospace')),
                    Text('${u['phone'] ?? u['email'] ?? '-'}'),
                    const StatusChip('Search off', tone: Tone.danger, icon: Icons.search_off),
                    TextButton.icon(onPressed: () => _setUser(u, true), icon: const Icon(Icons.search, size: 18), label: const Text('Allow search')),
                  ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: SectionHeader('Users hidden from search (nobody can find them)', padding: EdgeInsets.fromLTRB(0, 8, 0, 8))),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: _hideUser,
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: const Text('Hide a user'),
                ),
              ],
            ),
            AdminTable(
              total: (hidden['total'] as num).toInt(),
              columns: const ['User', 'User ID', 'Login', 'Status', ''],
              onRowTap: (i) => context.push(AdminRoutes.userDetailsOf('${hiddenItems[i]['id']}')),
              emptyText: 'Nobody is hidden from search',
              rows: [
                for (final u in hiddenItems)
                  [
                    NameCell(name: '${u['name']}', subtitle: 'shown as "${u['displayName']}"'),
                    Text('${u['internalId']}', style: const TextStyle(fontFamily: 'monospace')),
                    Text('${u['phone'] ?? u['email'] ?? '-'}'),
                    const StatusChip('Hidden', tone: Tone.warning, icon: Icons.visibility_off_outlined),
                    TextButton.icon(onPressed: () => _setHidden(u, false), icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('Show in search')),
                  ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: SectionHeader('Groups where members can not search members', padding: EdgeInsets.fromLTRB(0, 8, 0, 8))),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: _groupOff,
                  icon: const Icon(Icons.group_off_outlined, size: 18),
                  label: const Text('Turn off in a group'),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: InfoBanner(icon: Icons.info_outline, message: 'Group admins can also turn this on or off in their group settings. Group owner and admins can always search their own group.'),
            ),
            AdminTable(
              total: (groups['total'] as num).toInt(),
              columns: const ['Group', 'Members', 'Creator', 'Status', ''],
              onRowTap: (i) => context.push(AdminRoutes.groupDetailsOf('${groupItems[i]['id']}')),
              emptyText: 'Member search is on in every group',
              rows: [
                for (final g in groupItems)
                  [
                    Text('${g['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(fmtNum(g['memberCount'])),
                    Text('${g['createdBy']}'),
                    const StatusChip('Member search off', tone: Tone.warning, icon: Icons.search_off),
                    TextButton.icon(onPressed: () => _setGroup(g, true), icon: const Icon(Icons.search, size: 18), label: const Text('Turn on')),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
