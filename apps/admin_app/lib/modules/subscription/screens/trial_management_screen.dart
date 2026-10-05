import '../../../core/core.dart';

/// Configure: default trial, trial extension, free / premium extension,
/// extension duration, user-wise and group-wise access.
class AdminTrialManagementScreen extends StatefulWidget {
  const AdminTrialManagementScreen({super.key});

  @override
  State<AdminTrialManagementScreen> createState() => _AdminTrialManagementScreenState();
}

class _AdminTrialManagementScreenState extends State<AdminTrialManagementScreen> {
  String _q = '';
  String _filter = 'all';
  int _page = 1;
  int _reload = 0;
  Map<String, dynamic>? _settings;
  bool _dirty = false;

  void _set(String key, Object value) => setState(() {
    _settings = {...?_settings, key: value};
    _dirty = true;
  });

  Future<void> _save() async {
    final s = _settings;
    if (s == null) return;
    final r = await runAction<Map<String, dynamic>>(
      context,
      () => AdminApi.put('/settings/subscription', {
        for (final k in const ['trialDays', 'afterExpiry', 'remindBeforeExpiry', 'allowExtensionRequests', 'freeExtension', 'premiumExtension', 'defaultExtensionDays', 'maxExtensions']) k: s[k],
      }),
      success: 'Trial settings saved',
    );
    if (r != null) setState(() => _dirty = false);
  }

  Future<void> _act(Map<String, dynamic> u, String action) async {
    int? days;
    if (action == 'premium') {
      days = await askDays(context, title: 'Premium for ${u['name']}', options: const [30, 90, 365]);
      if (days == null) return;
    }
    if (!mounted) return;
    if (action == 'end' && !await context.confirm(title: 'End trial?', message: 'Chat is locked for ${u['name']} until they get premium or an extension.', confirmLabel: 'End trial', danger: true)) return;
    if (!mounted) return;
    final ext = (_settings?['defaultExtensionDays'] as num?)?.toInt() ?? 7;
    final r = await runAction(
      context,
      () => AdminApi.post('/trials/${u['id']}', {'action': action, if (action != 'end') 'days': action == 'extend' ? ext : days}),
      success: {'extend': 'Trial extended by $ext days', 'premium': 'Premium granted for $days days', 'end': 'Trial ended'}[action],
    );
    if (r != null) setState(() => _reload++);
  }

  Widget _dropdown<T>(T value, List<T> items, String Function(T) label, ValueChanged<T> onChanged) => DropdownButton<T>(
    isExpanded: true,
    value: items.contains(value) ? value : items.first,
    underline: const SizedBox(),
    items: [for (final i in items) DropdownMenuItem(value: i, child: Text(label(i)))],
    onChanged: (v) => onChanged(v as T),
  );

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_filter|$_page|$_reload',
      load: () => AdminApi.get('/trials', {'q': _q, 'filter': _filter, 'page': _page}),
      builder: (context, d, _) {
        if (!_dirty) _settings = Map<String, dynamic>.from(d['settings'] as Map);
        final s = _settings!;
        final st = d['stats'] as Map<String, dynamic>;
        final users = (d['items'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'Trial Management',
          subtitle: '${fmtNum(st['active'])} users on trial',
          onRefresh: () => setState(() => _reload++),
          actions: [
            FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _dirty ? _save : null, child: const Text('Save settings')),
          ],
          children: [
            ResponsiveGrid(
              minItemWidth: 200,
              children: [
                StatCard(icon: Icons.hourglass_bottom, label: 'Active trials', value: fmtNum(st['active'])),
                StatCard(icon: Icons.warning_amber_rounded, label: 'Expiring in 2 days', value: fmtNum(st['expiring'])),
                StatCard(icon: Icons.hourglass_disabled_outlined, label: 'Expired (30d)', value: fmtNum(st['expired30'])),
                StatCard(icon: Icons.trending_up, label: 'Trial to paid', value: '${st['trialToPaid']}%'),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 380,
              children: [
                PanelCard(
                  title: 'Default trial',
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: const Text('Free chat trial for new users'),
                        subtitle: _dropdown<int>((s['trialDays'] as num).toInt(), const [3, 7, 14, 30], (d) => '$d days', (v) => _set('trialDays', v)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock_clock_outlined),
                        title: const Text('After expiry'),
                        subtitle: _dropdown<String>('${s['afterExpiry']}', const ['locked', 'limited'], (v) => v == 'locked' ? 'Chat locked (read only)' : 'Limited (text only)', (v) => _set('afterExpiry', v)),
                      ),
                      SettingSwitch(icon: Icons.notifications_active_outlined, title: 'Remind 2 days before expiry', value: s['remindBeforeExpiry'] == true, onChanged: (v) => _set('remindBeforeExpiry', v)),
                    ],
                  ),
                ),
                PanelCard(
                  title: 'Extensions',
                  child: Column(
                    children: [
                      SettingSwitch(icon: Icons.more_time, title: 'Allow trial extension requests', value: s['allowExtensionRequests'] == true, onChanged: (v) => _set('allowExtensionRequests', v)),
                      SettingSwitch(icon: Icons.card_giftcard_outlined, title: 'Free extension', value: s['freeExtension'] == true, onChanged: (v) => _set('freeExtension', v)),
                      SettingSwitch(icon: Icons.workspace_premium_outlined, title: 'Premium extension', value: s['premiumExtension'] == true, onChanged: (v) => _set('premiumExtension', v)),
                      ListTile(
                        leading: const Icon(Icons.timelapse),
                        title: const Text('Default extension duration'),
                        subtitle: _dropdown<int>((s['defaultExtensionDays'] as num).toInt(), const [7, 15, 30], (d) => '$d days', (v) => _set('defaultExtensionDays', v)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.repeat),
                        title: const Text('Extensions per user'),
                        subtitle: _dropdown<int>((s['maxExtensions'] as num).toInt(), const [1, 2, 3, 5, 0], (d) => d == 0 ? 'Unlimited' : 'Max $d', (v) => _set('maxExtensions', v)),
                      ),
                    ],
                  ),
                ),
                PanelCard(
                  title: 'Access scope',
                  child: Column(
                    children: [
                      AppTile(icon: Icons.manage_accounts_outlined, title: 'User-wise access', subtitle: 'Override trial for a single user', onTap: () => context.go(AdminRoutes.subscriptions)),
                      AppTile(icon: Icons.groups_outlined, title: 'Group-wise access', subtitle: 'Give all members of a group premium access', onTap: () => context.go(AdminRoutes.subscriptions)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminFilterBar(
              hint: 'Search trial users',
              filters: const {'Active': 'all', 'Expiring': 'expiring', 'Expired (30d)': 'expired', 'Not claimed': 'unclaimed'},
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
              columns: const ['User', 'User ID', 'Started', 'Ends', 'Access', 'Actions'],
              onRowTap: (i) => context.push(AdminRoutes.userDetailsOf('${users[i]['id']}')),
              emptyText: 'No users in this list',
              rows: [
                for (final u in users)
                  [
                    Text('${u['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${u['internalId']}', style: const TextStyle(fontFamily: 'monospace')),
                    Text(fmtDate(u['trialStartedAt'])),
                    Text(fmtDate(u['trialEndsAt'])),
                    StatusChip(accessLabel(u['access'] as String?), tone: accessToneOf(u['access'] as String?)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(onPressed: () => _act(u, 'extend'), child: const Text('Extend')),
                        TextButton(onPressed: () => _act(u, 'premium'), child: const Text('Premium')),
                        TextButton(onPressed: () => _act(u, 'end'), child: Text('End', style: TextStyle(color: context.palette.danger))),
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
