import '../../../core/core.dart';

class AdminGroupLocationScreen extends StatefulWidget {
  const AdminGroupLocationScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<AdminGroupLocationScreen> createState() => _AdminGroupLocationScreenState();
}

class _AdminGroupLocationScreenState extends State<AdminGroupLocationScreen> {
  int _reload = 0;

  static Tone _tone(String s) => switch (s) {
    'Live' => Tone.success,
    'Stale' => Tone.warning,
    'Join' => Tone.info,
    _ => Tone.danger,
  };

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '${widget.groupId}|$_reload',
      load: () => AdminApi.get('/groups/${widget.groupId}/locations'),
      builder: (context, d, _) {
        final g = d['group'] as Map<String, dynamic>;
        final s = d['stats'] as Map<String, dynamic>;
        final members = (d['members'] as List).cast<Map<String, dynamic>>();
        final withLoc = members.where((m) => m['location'] != null).toList();
        return AdminPage(
          title: 'Group Location',
          subtitle: '${g['name']}  |  location ${locationLabel(g['requirement'] as String?).toLowerCase()}, shown to ${visibilityLabel(g['visibility'] as String?).toLowerCase()}',
          showBack: true,
          onRefresh: () => setState(() => _reload++),
          children: [
            ResponsiveGrid(
              minItemWidth: 180,
              children: [
                StatCard(icon: Icons.share_location, label: 'Sharing live', value: fmtNum(s['live'])),
                StatCard(icon: Icons.schedule, label: 'Stale (>30 min)', value: fmtNum(s['stale'])),
                StatCard(icon: Icons.place_outlined, label: 'Join location only', value: fmtNum(s['joinOnly'])),
                StatCard(icon: Icons.location_off_outlined, label: 'Not sharing', value: fmtNum(s['notSharing'])),
              ],
            ),
            const SizedBox(height: 16),
            if (withLoc.isEmpty)
              const InfoBanner(icon: Icons.location_off_outlined, message: 'No member of this group has shared a location yet.')
            else
              MapPlaceholder(
                height: 380,
                showControls: true,
                pins: pinsFor([
                  for (final m in withLoc)
                    (lat: ((m['location'] as Map)['lat'] as num).toDouble(), lng: ((m['location'] as Map)['lng'] as num).toDouble(), label: '${m['displayName']}'),
                ]),
              ),
            const SizedBox(height: 16),
            AdminTable(
              columns: const ['Member', 'Role', 'Location', 'Coordinates', 'Last update', 'Status'],
              onRowTap: (i) => context.push(AdminRoutes.userLocationOf('${members[i]['userId']}')),
              emptyText: 'No members',
              rows: [
                for (final m in members)
                  [
                    Text('${m['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(capitalize('${m['role']}')),
                    Text('${(m['location'] as Map?)?['place'] ?? '-'}'),
                    Text(
                      m['location'] == null ? '-' : '${((m['location'] as Map)['lat'] as num).toStringAsFixed(4)}, ${((m['location'] as Map)['lng'] as num).toStringAsFixed(4)}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    Text(fmtAgo((m['location'] as Map?)?['updatedAt'])),
                    StatusChip(m['status'] == 'Off' ? 'Off' : '${m['status']}', tone: _tone('${m['status']}')),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
