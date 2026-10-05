import '../../../core/core.dart';

class AdminStaffSettingsScreen extends StatefulWidget {
  const AdminStaffSettingsScreen({super.key});

  @override
  State<AdminStaffSettingsScreen> createState() => _AdminStaffSettingsScreenState();
}

class _AdminStaffSettingsScreenState extends State<AdminStaffSettingsScreen> {
  int _reload = 0;
  Map<String, Set<String>>? _roles;
  bool _rolesDirty = false;

  static const _permissionLabels = {'users': 'Users', 'groups': 'Groups', 'messages': 'Messages', 'subscriptions': 'Subscriptions', 'reports': 'Reports', 'settings': 'Settings'};

  bool get _isSuper => AdminSession.staff.value?.role == 'super_admin';

  void _refresh() => setState(() => _reload++);

  Future<void> _showTempPassword(String name, String? temp) async {
    if (temp == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Temporary password'),
        content: SelectableText('Share this password with $name. They can change it after signing in.\n\n$temp', style: const TextStyle(fontSize: 16)),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
      ),
    );
  }

  Future<void> _invite() async {
    final name = TextEditingController();
    final email = TextEditingController();
    var role = 'moderator';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Add staff'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: 'Name', controller: name),
                const SizedBox(height: 12),
                AppTextField(label: 'Email', controller: email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: [for (final r in const ['super_admin', 'moderator', 'support']) DropdownMenuItem(value: r, child: Text(roleName(r)))],
                  onChanged: (v) => setD(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    final body = {'name': name.text.trim(), 'email': email.text.trim(), 'role': role};
    name.dispose();
    email.dispose();
    if (ok != true || !mounted) return;
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/staff', body), success: 'Staff account created');
    if (r == null) return;
    await _showTempPassword(body['name']!, r['tempPassword'] as String?);
    _refresh();
  }

  Future<void> _edit(Map<String, dynamic> s) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('${s['name']}'),
        children: [
          for (final r in const ['super_admin', 'moderator', 'support'])
            if (r != s['role']) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'role:$r'), child: Text('Change role to ${roleName(r)}')),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'status'), child: Text(s['status'] == 'active' ? 'Suspend account' : 'Activate account')),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'reset'), child: const Text('Reset password')),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'delete'), child: Text('Remove staff', style: TextStyle(color: context.palette.danger))),
        ],
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'delete') {
      if (!await context.confirm(title: 'Remove ${s['name']}?', message: 'They can no longer sign in to the admin panel.', confirmLabel: 'Remove', danger: true)) return;
      if (!mounted) return;
      final r = await runAction(context, () => AdminApi.delete('/staff/${s['id']}'), success: '${s['name']} removed');
      if (r != null) _refresh();
      return;
    }
    final body = <String, Object?>{
      if (action.startsWith('role:')) 'role': action.substring(5),
      if (action == 'status') 'status': s['status'] == 'active' ? 'suspended' : 'active',
      if (action == 'reset') 'resetPassword': true,
    };
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.patch('/staff/${s['id']}', body), success: 'Staff updated');
    if (r == null) return;
    await _showTempPassword('${s['name']}', r['tempPassword'] as String?);
    _refresh();
  }

  Future<void> _saveRoles() async {
    final r = await runAction(
      context,
      () => AdminApi.put('/roles', {
        'roles': {for (final e in _roles!.entries) if (e.key != 'super_admin') e.key: e.value.toList()},
      }),
      success: 'Role permissions saved',
    );
    if (r != null) setState(() => _rolesDirty = false);
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Current password', controller: current, obscure: true),
              const SizedBox(height: 12),
              AppTextField(label: 'New password (8+ characters)', controller: next, obscure: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Change')),
        ],
      ),
    );
    final body = {'current': current.text, 'next': next.text};
    current.dispose();
    next.dispose();
    if (ok != true || !mounted) return;
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/auth/password', body), success: 'Password changed. Other sessions are signed out.');
    if (r != null) await AdminSession.signIn(r);
  }

  @override
  Widget build(BuildContext context) {
    final me = AdminSession.staff.value;
    return AdminAsync<List<dynamic>>(
      reloadKey: _reload,
      load: () async => [await AdminApi.get<List<dynamic>>('/staff'), await AdminApi.get<Map<String, dynamic>>('/roles')],
      builder: (context, data, _) {
        final staff = (data[0] as List).cast<Map<String, dynamic>>();
        final rolesData = data[1] as Map<String, dynamic>;
        final perms = [for (final p in (rolesData['permissions'] as List)) '$p'];
        if (!_rolesDirty) {
          _roles = {for (final e in (rolesData['roles'] as Map).entries) '${e.key}': {for (final p in (e.value as List)) '$p'}};
        }
        return AdminPage(
          title: 'Admin & Staff Settings',
          subtitle: 'Manage staff accounts, roles and permissions',
          onRefresh: _refresh,
          actions: [
            if (_isSuper)
              FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _invite, icon: const Icon(Icons.person_add_alt), label: const Text('Add staff')),
          ],
          children: [
            AdminTable(
              columns: const ['Name', 'Email', 'Role', 'Status', 'Last active', ''],
              rows: [
                for (final s in staff)
                  [
                    NameCell(name: '${s['name']}${s['id'] == me?.id ? ' (you)' : ''}'),
                    Text('${s['email']}'),
                    StatusChip(roleName('${s['role']}'), tone: Tone.dark),
                    StatusChip(capitalize('${s['status']}')),
                    Text(fmtAgo(s['lastActiveAt'])),
                    _isSuper && s['id'] != me?.id ? IconButton(tooltip: 'Manage', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(s)) : const SizedBox(),
                  ],
              ],
            ),
            const SizedBox(height: 16),
            PanelCard(
              title: 'Role permissions',
              action: _isSuper && _rolesDirty ? 'Save' : null,
              onAction: _saveRoles,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [const DataColumn(label: Text('Role')), for (final p in perms) DataColumn(label: Text(_permissionLabels[p] ?? p))],
                  rows: [
                    for (final role in const ['super_admin', 'moderator', 'support'])
                      DataRow(
                        cells: [
                          DataCell(Text(roleName(role), style: const TextStyle(fontWeight: FontWeight.w700))),
                          for (final p in perms)
                            DataCell(
                              Checkbox(
                                value: role == 'super_admin' || (_roles?[role]?.contains(p) ?? false),
                                onChanged: !_isSuper || role == 'super_admin'
                                    ? null
                                    : (v) => setState(() {
                                        final set = _roles!.putIfAbsent(role, () => <String>{});
                                        v! ? set.add(p) : set.remove(p);
                                        _rolesDirty = true;
                                      }),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            PanelCard(
              title: 'My admin account',
              child: Column(
                children: [
                  InfoRow(label: 'Name', value: me?.name ?? '-', icon: Icons.person_outline),
                  InfoRow(label: 'Email', value: me?.email ?? '-', icon: Icons.mail_outline),
                  InfoRow(label: 'Role', value: me?.roleLabel ?? '-', icon: Icons.badge_outlined),
                  AppTile(icon: Icons.password, title: 'Change password', onTap: _changePassword),
                  AppTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    danger: true,
                    onTap: () async {
                      await AdminSession.signOut();
                      if (context.mounted) context.go(AdminRoutes.login);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
