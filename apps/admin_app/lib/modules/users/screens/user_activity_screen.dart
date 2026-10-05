import '../../../core/core.dart';

class AdminUserActivityScreen extends StatefulWidget {
  const AdminUserActivityScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserActivityScreen> createState() => _AdminUserActivityScreenState();
}

class _AdminUserActivityScreenState extends State<AdminUserActivityScreen> {
  int _days = 7;
  String _type = 'all';
  int _reload = 0;

  static const _icons = {
    'login': Icons.login,
    'gpp_maybe': Icons.gpp_maybe_outlined,
    'flag': Icons.flag_outlined,
    'group_add': Icons.group_add_outlined,
    'delete': Icons.delete_outline,
    'person_remove': Icons.person_remove_outlined,
    'admin': Icons.admin_panel_settings_outlined,
    'settings': Icons.settings_outlined,
    'link': Icons.link,
    'how_to_reg': Icons.how_to_reg_outlined,
    'upload_file': Icons.upload_file_outlined,
    'share_location': Icons.share_location,
    'shortcut': Icons.shortcut,
  };

  @override
  Widget build(BuildContext context) {
    return AdminAsync<List<dynamic>>(
      reloadKey: '${widget.userId}|$_days|$_type|$_reload',
      load: () async => [
        await AdminApi.get<Map<String, dynamic>>('/users/${widget.userId}/activity', {'days': _days, 'type': _type}),
        await AdminApi.get<Map<String, dynamic>>('/users/${widget.userId}'),
      ],
      builder: (context, data, _) {
        final a = data[0] as Map<String, dynamic>;
        final u = data[1] as Map<String, dynamic>;
        final s = a['stats'] as Map<String, dynamic>;
        final events = (a['events'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'User Activity',
          subtitle: '${u['name']}  |  ${u['internalId']}',
          showBack: true,
          onRefresh: () => setState(() => _reload++),
          actions: [
            PopupMenuButton<int>(
              initialValue: _days,
              onSelected: (d) => setState(() => _days = d),
              itemBuilder: (_) => [for (final d in const [1, 7, 30, 90]) PopupMenuItem(value: d, child: Text(d == 1 ? 'Last 24 hours' : 'Last $d days'))],
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: null,
                icon: const Icon(Icons.date_range),
                label: Text(_days == 1 ? 'Last 24 hours' : 'Last $_days days'),
              ),
            ),
          ],
          children: [
            ResponsiveGrid(
              minItemWidth: 180,
              children: [
                StatCard(icon: Icons.login, label: 'Logins', value: fmtNum(s['logins'])),
                StatCard(icon: Icons.forum_outlined, label: 'Messages', value: fmtNum(s['messages'])),
                StatCard(icon: Icons.shortcut, label: 'Forwards', value: fmtNum(s['forwards'])),
                StatCard(icon: Icons.gpp_maybe_outlined, label: 'Violations', value: fmtNum(s['violations'])),
              ],
            ),
            const SizedBox(height: 16),
            AdminFilterBar(
              showSearch: false,
              filters: const {'All': 'all', 'Auth': 'auth', 'Messages': 'messages', 'Files': 'files', 'Security': 'security'},
              selected: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            PanelCard(
              title: 'Timeline',
              child: Column(
                children: [
                  for (final e in events)
                    ListTile(
                      leading: AppAvatar(icon: _icons[e['icon']] ?? Icons.history, size: 40),
                      title: Text('${e['title']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: (e['detail'] as String?)?.isNotEmpty == true ? Text('${e['detail']}') : null,
                      trailing: Text(fmtDateTime(e['at']), style: TextStyle(color: context.palette.textSecondary, fontSize: 12)),
                    ),
                  if (events.isEmpty) const ListTile(title: Text('No activity in this period')),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
