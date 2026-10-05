import '../../../core/core.dart';

/// Admin location dashboard: user name, group, current / last shared location,
/// time and status - plus the global member-location visibility rule.
class AdminLocationManagementScreen extends StatefulWidget {
  const AdminLocationManagementScreen({super.key});

  @override
  State<AdminLocationManagementScreen> createState() => _AdminLocationManagementScreenState();
}

class _AdminLocationManagementScreenState extends State<AdminLocationManagementScreen> {
  String? _group;
  String _status = 'all';
  int _page = 1;
  int _reload = 0;

  static Tone _tone(String s) => switch (s) {
    'Live' => Tone.success,
    'Stale' => Tone.warning,
    'Join' => Tone.info,
    _ => Tone.danger,
  };

  Future<void> _save(Map<String, Object?> patch, String done) async {
    final r = await runAction(context, () => AdminApi.put('/settings/location', patch), success: done);
    if (r != null) setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_group|$_status|$_page|$_reload',
      load: () => AdminApi.get('/locations', {'groupId': _group, 'status': _status, 'page': _page}),
      builder: (context, d, _) {
        final s = d['stats'] as Map<String, dynamic>;
        final rows = (d['items'] as List).cast<Map<String, dynamic>>();
        final groups = (d['groups'] as List).cast<Map<String, dynamic>>();
        final cfg = d['settings'] as Map<String, dynamic>;
        final showAdmin = cfg['showToAdmin'] != false;
        final showMembers = cfg['showToMembers'] != false;
        return AdminPage(
          title: 'Location Management',
          subtitle: '${fmtNum((s['live'] as num) + (s['joinOnly'] as num))} users sharing location',
          onRefresh: () => setState(() => _reload++),
          actions: [
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String?>(
                initialValue: _group,
                isExpanded: true,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.groups_outlined)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All groups')),
                  for (final g in groups) DropdownMenuItem(value: '${g['id']}', child: Text('${g['name']} (${locationLabel(g['requirement'] as String?).toLowerCase()})', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() {
                  _group = v;
                  _page = 1;
                }),
              ),
            ),
          ],
          children: [
            ResponsiveGrid(
              minItemWidth: 180,
              children: [
                StatCard(icon: Icons.share_location, label: 'Live location', value: fmtNum(s['live'])),
                StatCard(icon: Icons.place_outlined, label: 'Join location only', value: fmtNum(s['joinOnly'])),
                StatCard(icon: Icons.location_off_outlined, label: 'Location off', value: fmtNum(s['off'])),
                StatCard(icon: Icons.groups_outlined, label: 'Mandatory groups', value: fmtNum(s['mandatoryGroups'])),
              ],
            ),
            const SizedBox(height: 16),
            AdminFilterBar(
              showSearch: false,
              filters: const {'All': 'all', 'Live': 'live', 'Stale (>30 min)': 'stale', 'Join only': 'join'},
              selected: _status,
              onChanged: (v) => setState(() {
                _status = v;
                _page = 1;
              }),
            ),
            if (rows.isEmpty)
              const InfoBanner(icon: Icons.location_off_outlined, message: 'No shared locations for this filter.')
            else
              MapPlaceholder(
                height: 380,
                showControls: true,
                pins: pinsFor([for (final r in rows) (lat: (r['lat'] as num).toDouble(), lng: (r['lng'] as num).toDouble(), label: '${r['user']}'.split(' ').first)]),
              ),
            const SizedBox(height: 16),
            AdminTable(
              total: (d['total'] as num).toInt(),
              page: _page,
              onPage: (p) => setState(() => _page = p),
              columns: const ['User', 'Group', 'Current / last location', 'Time', 'Mode', 'Status', ''],
              emptyText: 'No shared locations',
              rows: [
                for (final r in rows)
                  [
                    Text('${r['user']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${r['group']}'),
                    Text('${r['place'] ?? '${(r['lat'] as num).toStringAsFixed(4)}, ${(r['lng'] as num).toStringAsFixed(4)}'}'),
                    Text(fmtAgo(r['at'])),
                    Text(r['mode'] == 'live' ? 'Live' : 'Join location'),
                    StatusChip('${r['status']}', tone: _tone('${r['status']}')),
                    TextButton(onPressed: () => context.push(AdminRoutes.userLocationOf('${r['userId']}')), child: const Text('History')),
                  ],
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 360,
              children: [
                PanelCard(
                  title: 'Show member location (default for new groups)',
                  child: Column(
                    children: [
                      CheckboxListTile(title: const Text('Admin'), value: showAdmin, onChanged: (v) => _save({'showToAdmin': v}, 'Saved')),
                      CheckboxListTile(
                        title: const Text('Group members'),
                        subtitle: const Text('Only members of the same group'),
                        value: showMembers,
                        onChanged: (v) => _save({'showToMembers': v}, 'Saved'),
                      ),
                      CheckboxListTile(
                        title: const Text('Nobody'),
                        value: !showAdmin && !showMembers,
                        onChanged: (v) => v == true ? _save({'showToAdmin': false, 'showToMembers': false}, 'Location hidden from everyone by default') : _save({'showToAdmin': true}, 'Saved'),
                      ),
                    ],
                  ),
                ),
                PanelCard(
                  title: 'Location privacy',
                  child: Column(
                    children: [
                      const InfoRow(label: 'Mode 1', value: 'No Location', icon: Icons.location_off_outlined),
                      const InfoRow(label: 'Mode 2', value: 'Join Location', icon: Icons.place_outlined),
                      const InfoRow(label: 'Mode 3', value: 'Live - 5 / 10 / 30 min / manual', icon: Icons.share_location),
                      SettingSwitch(
                        icon: Icons.visibility_outlined,
                        title: 'Live status always visible to user',
                        value: cfg['liveStatusVisible'] != false,
                        onChanged: (v) => _save({'liveStatusVisible': v}, 'Saved'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_sweep_outlined),
                        title: const Text('Auto delete location history'),
                        trailing: DropdownButton<int>(
                          value: const [0, 7, 30, 90].contains(cfg['autoDeleteDays']) ? cfg['autoDeleteDays'] as int : 30,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 7, child: Text('After 7 days')),
                            DropdownMenuItem(value: 30, child: Text('After 30 days')),
                            DropdownMenuItem(value: 90, child: Text('After 90 days')),
                            DropdownMenuItem(value: 0, child: Text('Keep 90 days (max)')),
                          ],
                          onChanged: (v) => _save({'autoDeleteDays': v}, 'History retention saved'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
