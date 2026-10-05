import '../../../core/core.dart';

/// Content Control: each rule ON/OFF + blocked message log
/// (count, user, group, date/time, rule triggered, warning count).
class AdminContentModerationScreen extends StatefulWidget {
  const AdminContentModerationScreen({super.key});

  @override
  State<AdminContentModerationScreen> createState() => _AdminContentModerationScreenState();
}

class _AdminContentModerationScreenState extends State<AdminContentModerationScreen> {
  String _q = '';
  String _rule = 'all';
  int _page = 1;
  int _reload = 0;
  Set<String>? _enabled;
  bool _dirty = false;

  Future<void> _save() async {
    final r = await runAction(context, () => AdminApi.put('/settings/content', {'globalRules': _enabled!.toList()}), success: 'Content policy saved');
    if (r != null) setState(() => _dirty = false);
  }

  Future<void> _act(Map<String, dynamic> b, String action) async {
    const labels = {'warn': 'Warning sent', 'restrict_member': 'User restricted in group', 'block_user': 'User blocked', 'suspend_group': 'Group suspended'};
    if (action == 'block_user' && !await context.confirm(title: 'Block ${b['user']}?', message: 'They are signed out and cannot use SecureChat.', confirmLabel: 'Block', danger: true)) return;
    if (!mounted) return;
    if (action == 'suspend_group' && !await context.confirm(title: 'Suspend ${b['group']}?', message: 'Nobody can send messages in this group until it is restored.', confirmLabel: 'Suspend', danger: true)) return;
    if (!mounted) return;
    final r = await runAction(context, () => AdminApi.post('/moderation/action', {'action': action, 'userId': b['userId'], 'groupId': ?b['groupId']}), success: labels[action]);
    if (r != null) setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<List<dynamic>>(
      reloadKey: '$_q|$_rule|$_page|$_reload',
      load: () async => [
        await AdminApi.get<Map<String, dynamic>>('/moderation/log', {'q': _q, 'rule': _rule, 'page': _page}),
        await AdminApi.get<Map<String, dynamic>>('/settings/content'),
      ],
      builder: (context, data, _) {
        final d = data[0] as Map<String, dynamic>;
        final cs = data[1] as Map<String, dynamic>;
        if (!_dirty) _enabled = {for (final r in (cs['globalRules'] as List)) '$r'};
        final s = d['stats'] as Map<String, dynamic>;
        final log = (d['items'] as List).cast<Map<String, dynamic>>();
        final max = (d['maxWarnings'] as num?)?.toInt() ?? 5;
        return AdminPage(
          title: 'Content Moderation',
          subtitle: 'Message processing: Language -> Abuse -> Number -> Spam -> Allowed / Blocked',
          onRefresh: () => setState(() => _reload++),
          actions: [FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _dirty ? _save : null, child: const Text('Save policy'))],
          children: [
            ResponsiveGrid(
              minItemWidth: 200,
              children: [
                StatCard(icon: Icons.gpp_bad_outlined, label: 'Blocked today', value: fmtNum(s['blockedToday'])),
                StatCard(icon: Icons.pin_outlined, label: 'Number / words (today)', value: fmtNum(s['numbers'])),
                StatCard(icon: Icons.do_not_disturb_on_outlined, label: 'Abuse (today)', value: fmtNum(s['abuse'])),
                StatCard(icon: Icons.warning_amber_rounded, label: 'Users with 3+ warnings', value: fmtNum(s['usersWith3Warnings'])),
              ],
            ),
            const SizedBox(height: 16),
            PanelCard(
              title: 'Content Control (global - applies in every group, even when the group turned the rule off)',
              child: Column(
                children: [
                  for (final r in ContentRule.values)
                    SwitchListTile(
                      secondary: Icon(r.icon),
                      title: Text(r.label),
                      subtitle: Text(r.description),
                      value: _enabled!.contains(r.name),
                      onChanged: (v) => setState(() {
                        v ? _enabled!.add(r.name) : _enabled!.remove(r.name);
                        _dirty = true;
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminFilterBar(
              hint: 'Search user or group',
              filters: const {
                'All': 'all',
                'Numbers': 'numbers',
                'Number words': 'numberWords',
                'Abuse': 'abuse',
                'Spam': 'spam',
                'Links': 'links',
                'Contact': 'externalContact',
                'Personal info': 'personalInfo',
                'Blocked keywords': 'keyword',
                'Mobile numbers': 'phone',
              },
              selected: _rule,
              onSearch: (q) => setState(() {
                _q = q;
                _page = 1;
              }),
              onChanged: (r) => setState(() {
                _rule = r;
                _page = 1;
              }),
            ),
            AdminTable(
              total: (d['total'] as num).toInt(),
              page: _page,
              onPage: (p) => setState(() => _page = p),
              columns: const ['Date / time', 'User', 'Group', 'Blocked content', 'Rule triggered', 'Warnings', 'Action'],
              emptyText: 'No blocked messages',
              rows: [
                for (final b in log)
                  [
                    Text(fmtDateTime(b['at'])),
                    InkWell(onTap: () => context.push(AdminRoutes.userDetailsOf('${b['userId']}')), child: Text('${b['user']}', style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.primary))),
                    Text('${b['group']}'),
                    SizedBox(width: 200, child: Text('${b['text']}', overflow: TextOverflow.ellipsis)),
                    StatusChip(ruleLabels[b['rule']] ?? '${b['rule']}', tone: Tone.danger),
                    StatusChip('${b['warnings']} / $max', tone: (b['warnings'] as num) >= 3 ? Tone.danger : Tone.warning),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (a) => _act(b, a),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'warn', child: Text('Send warning')),
                        if (b['groupId'] != null) const PopupMenuItem(value: 'restrict_member', child: Text('Restrict in group')),
                        const PopupMenuItem(value: 'block_user', child: Text('Block user')),
                        if (b['groupId'] != null) const PopupMenuItem(value: 'suspend_group', child: Text('Suspend group')),
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
