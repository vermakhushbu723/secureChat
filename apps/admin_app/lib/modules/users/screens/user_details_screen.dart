import '../../../core/core.dart';
import 'user_list_screen.dart';

/// View / Edit / Block user, trial status, extend trial, free / premium access, location.
class AdminUserDetailsScreen extends StatefulWidget {
  const AdminUserDetailsScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  int _reload = 0;
  final _name = TextEditingController();
  final _displayName = TextEditingController();
  String? _loadedFor;

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _reload++);

  Future<void> _action(String action, {String? label, Map<String, Object?> extra = const {}}) async {
    final r = await runAction(context, () => AdminApi.post('/users/${widget.userId}/action', {'action': action, ...extra}), success: label);
    if (r == null || !mounted) return;
    if (action == 'delete') {
      context.go(AdminRoutes.users);
    } else {
      _refresh();
    }
  }

  Future<void> _setAccess(String access) async {
    int days = 0;
    if (access == 'premium' || access == 'extended' || access == 'trial') {
      final picked = await askDays(context, title: 'Set ${accessLabel(access)} for', options: access == 'premium' ? const [30, 90, 365] : const [7, 15, 30]);
      if (picked == null) return;
      days = picked;
    }
    if (!mounted) return;
    final r = await runAction(context, () => AdminApi.post('/users/access', {'user': widget.userId, 'kind': access, 'days': days}), success: 'Access changed to ${accessLabel(access)}');
    if (r != null) _refresh();
  }

  Future<void> _extendTrial(int days) async {
    final r = await runAction(context, () => AdminApi.post('/trials/${widget.userId}', {'action': 'extend', 'days': days}), success: 'Trial extended by $days days');
    if (r != null) _refresh();
  }

  Future<void> _save() async {
    final r = await runAction(
      context,
      () => AdminApi.patch('/users/${widget.userId}', {'name': _name.text.trim(), 'displayName': _displayName.text.trim()}),
      success: 'User updated',
    );
    if (r != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '${widget.userId}|$_reload',
      load: () => AdminApi.get('/users/${widget.userId}'),
      builder: (context, u, _) {
        if (_loadedFor != '${u['id']}|${u['name']}|${u['displayName']}') {
          _loadedFor = '${u['id']}|${u['name']}|${u['displayName']}';
          _name.text = '${u['name']}';
          _displayName.text = '${u['displayName']}';
        }
        final status = u['status'] as String? ?? 'active';
        final blocked = status == 'blocked' || status == 'suspended';
        final restricted = u['restricted'] == true;
        final stats = u['stats'] as Map<String, dynamic>;
        final mod = u['moderation'] as Map<String, dynamic>?;
        final groups = (u['groups'] as List).cast<Map<String, dynamic>>();
        final access = u['access'] as String?;
        return AdminPage(
          title: 'User Details',
          showBack: true,
          onRefresh: _refresh,
          actions: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => context.push(AdminRoutes.userActivityOf(widget.userId)),
              icon: const Icon(Icons.timeline),
              label: const Text('Activity'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => context.push(AdminRoutes.userLocationOf(widget.userId)),
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Location'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: blocked ? null : context.palette.danger),
              onPressed: () async {
                if (blocked) {
                  if (await context.confirm(title: 'Unblock user?', message: '${u['name']} will regain access.', confirmLabel: 'Unblock')) {
                    await _action('unblock', label: 'User unblocked');
                  }
                  return;
                }
                final reason = await askText(context, title: 'Block ${u['name']}?', label: 'Reason (shown in the blocked list)', confirm: 'Block');
                if (reason != null) await _action('block', label: 'User blocked', extra: {'reason': reason});
              },
              icon: Icon(blocked ? Icons.lock_open : Icons.block),
              label: Text(blocked ? 'Unblock' : 'Block'),
            ),
          ],
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppAvatar(initials: initialsOf(u['name'] as String?), size: 80, inverted: true, online: u['online'] == true),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${u['name']}', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        Text(
                          [u['internalId'], u['phone'], u['email'], if (u['username'] != null) '@${u['username']}'].where((e) => e != null).join('  |  '),
                          style: TextStyle(color: context.palette.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusChip(statusLabel(status)),
                            if (restricted) const StatusChip('Read only', tone: Tone.warning, icon: Icons.volume_off_outlined),
                            if (u['searchAllowed'] == false) const StatusChip('Search off', tone: Tone.danger, icon: Icons.search_off),
                            if (u['searchHidden'] == true) const StatusChip('Hidden from search', tone: Tone.warning, icon: Icons.visibility_off_outlined),
                            StatusChip(accessLabel(access), tone: accessToneOf(access), icon: Icons.workspace_premium_outlined),
                            StatusChip('Shown as "${u['displayName']}"', tone: Tone.neutral, icon: Icons.badge_outlined),
                            StatusChip(capitalize('${u['accountType']}'), tone: Tone.neutral),
                            StatusChip('Joined ${fmtDate(u['createdAt'])}', tone: Tone.neutral, icon: Icons.calendar_today_outlined),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (blocked && mod != null) ...[
              const SizedBox(height: 12),
              InfoBanner(
                icon: Icons.block,
                tone: Tone.danger,
                title: status == 'suspended' ? 'Suspended until ${fmtDateTime(mod['suspendedUntil'])}' : 'Blocked',
                message: '${mod['reason'] ?? 'No reason given'}  |  by ${mod['by'] ?? 'admin'} on ${fmtDateTime(mod['at'])}',
              ),
            ],
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 180,
              children: [
                StatCard(icon: Icons.groups_outlined, label: 'Groups joined', value: fmtNum(stats['groups'])),
                StatCard(icon: Icons.forum_outlined, label: 'Messages sent', value: fmtNum(stats['messages'])),
                StatCard(icon: Icons.gpp_maybe_outlined, label: 'Content warnings', value: fmtNum(stats['warnings'])),
                StatCard(icon: Icons.flag_outlined, label: 'Reports against', value: fmtNum(stats['reportsAgainst'])),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 360,
              children: [
                PanelCard(
                  title: 'Trial & access',
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'Trial',
                        value: access == 'unclaimed' ? 'Not claimed yet' : '${fmtDate(u['trialStartedAt'])} - ${fmtDate(u['trialEndsAt'])}',
                        icon: Icons.hourglass_bottom,
                      ),
                      InfoRow(label: 'Current access', value: '${accessLabel(access)}${u['accessUntil'] == null ? '' : ' until ${fmtDate(u['accessUntil'])}'}', icon: Icons.verified_user_outlined),
                      InfoRow(label: 'Granted by', value: '${u['grantedBy'] ?? '-'}', icon: Icons.person_pin_outlined),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in const ['trial', 'free', 'premium', 'extended', 'locked'])
                              ChoiceChip(label: Text(accessLabel(a)), selected: access == a, showCheckmark: false, onSelected: (_) => _setAccess(a)),
                          ],
                        ),
                      ),
                      AppTile(icon: Icons.more_time, title: 'Extend trial by 7 days', onTap: () => _extendTrial(7)),
                      AppTile(icon: Icons.event_repeat, title: 'Extend trial by 30 days', onTap: () => _extendTrial(30)),
                    ],
                  ),
                ),
                PanelCard(
                  title: 'Edit profile',
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      AppTextField(label: 'Full name', controller: _name),
                      const SizedBox(height: 12),
                      AppTextField(label: 'Display name (shown to members)', controller: _displayName, maxLength: 20),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 40)), onPressed: _save, child: const Text('Save')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PanelCard(
              title: 'Groups (${groups.length})',
              child: Column(
                children: [
                  for (final g in groups)
                    ListTile(
                      onTap: () => context.push(AdminRoutes.groupDetailsOf('${g['id']}')),
                      leading: AppAvatar(initials: initialsOf(g['name'] as String?), size: 36),
                      title: Text('${g['name']}'),
                      subtitle: Text('${g['memberCount']} members  |  ${capitalize('${g['role']}')}  |  location ${locationLabel(g['location'] as String?).toLowerCase()}'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  if (groups.isEmpty) const ListTile(title: Text('Not a member of any group')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PanelCard(
              title: 'Security actions',
              child: Column(
                children: [
                  AppTile(
                    icon: restricted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                    title: restricted ? 'Allow messaging again' : 'Restrict messaging (read only)',
                    onTap: () => _action(restricted ? 'unrestrict' : 'restrict', label: restricted ? 'User can send messages again' : 'User restricted to read only'),
                  ),
                  AppTile(icon: Icons.warning_amber_rounded, title: 'Send warning', onTap: () => _action('warn', label: 'Warning sent')),
                  AppTile(
                    icon: u['searchHidden'] == true ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    title: u['searchHidden'] == true ? 'Show in search again' : 'Hide from search (nobody can find this user)',
                    onTap: () async {
                      final hide = u['searchHidden'] != true;
                      final r = await runAction(context, () => AdminApi.post('/users/${widget.userId}/search-visibility', {'hidden': hide}), success: hide ? 'Hidden from search' : 'Shown in search');
                      if (r != null) _refresh();
                    },
                  ),
                  AppTile(
                    icon: u['searchAllowed'] == false ? Icons.search : Icons.search_off,
                    title: u['searchAllowed'] == false ? 'Allow search (people + group members)' : 'Turn off search (people + group members)',
                    onTap: () async {
                      final allow = u['searchAllowed'] == false;
                      final r = await runAction(context, () => AdminApi.post('/users/${widget.userId}/search', {'allowed': allow}), success: allow ? 'Search allowed' : 'Search turned off');
                      if (r != null) _refresh();
                    },
                  ),
                  AppTile(
                    icon: Icons.logout,
                    title: 'Force logout all devices',
                    onTap: () async {
                      if (await context.confirm(title: 'Log out everywhere?', message: '${u['name']} must sign in again on every device.', confirmLabel: 'Log out')) {
                        await _action('logout', label: 'Sessions revoked');
                      }
                    },
                  ),
                  AppTile(
                    icon: Icons.pause_circle_outline,
                    title: 'Suspend for 7 days',
                    danger: true,
                    onTap: () async {
                      final days = await askDays(context, title: 'Suspend ${u['name']} for', options: const [1, 7, 30]);
                      if (days != null) await _action('suspend', label: 'User suspended for $days days', extra: {'days': days});
                    },
                  ),
                  AppTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete account',
                    danger: true,
                    onTap: () async {
                      final ok = await context.confirm(
                        title: 'Delete ${u['name']}?',
                        message: 'The account is closed and the mobile number, email and profile are removed. This cannot be undone.',
                        confirmLabel: 'Delete',
                        danger: true,
                      );
                      if (ok) await _action('delete', label: 'Account deleted');
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
