import '../../../core/core.dart';

class AdminUserLocationScreen extends StatefulWidget {
  const AdminUserLocationScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserLocationScreen> createState() => _AdminUserLocationScreenState();
}

class _AdminUserLocationScreenState extends State<AdminUserLocationScreen> {
  int _reload = 0;

  static String _mode(String? m) => switch (m) {
    'live' => 'Live location',
    'join' => 'Join location only',
    _ => 'No location',
  };

  static String _coords(Map<String, dynamic> p) => '${(p['lat'] as num).toStringAsFixed(4)}, ${(p['lng'] as num).toStringAsFixed(4)}';

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '${widget.userId}|$_reload',
      load: () => AdminApi.get('/users/${widget.userId}/location'),
      builder: (context, d, _) {
        final current = d['current'] as Map<String, dynamic>?;
        final sharing = d['sharing'] as Map<String, dynamic>;
        final history = (d['history'] as List).cast<Map<String, dynamic>>();
        final first = '${d['name']}'.split(' ').first;
        final points = [
          for (final h in history.take(12).toList().reversed) (lat: (h['lat'] as num).toDouble(), lng: (h['lng'] as num).toDouble(), label: fmtDateTime(h['at']).split(', ').last),
        ];
        if (current != null && points.isNotEmpty) {
          points[points.length - 1] = (lat: points.last.lat, lng: points.last.lng, label: first);
        }
        return AdminPage(
          title: 'User Location',
          subtitle: '${d['name']}',
          showBack: true,
          onRefresh: () => setState(() => _reload++),
          children: [
            if (points.isEmpty)
              const InfoBanner(icon: Icons.location_off_outlined, message: 'This user has not shared a location yet.')
            else
              MapPlaceholder(height: 360, showControls: true, pins: pinsFor(points, meLabel: first)),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 260,
              children: [
                PanelCard(
                  title: 'Current',
                  child: Column(
                    children: [
                      InfoRow(label: 'Place', value: '${current?['place'] ?? current?['group'] ?? '-'}', icon: Icons.place_outlined),
                      InfoRow(label: 'Coordinates', value: current == null ? '-' : _coords(current), icon: Icons.gps_fixed),
                      InfoRow(label: 'Accuracy', value: current?['accuracy'] == null ? '-' : '+/- ${(current!['accuracy'] as num).round()} m', icon: Icons.radar),
                      InfoRow(label: 'Updated', value: fmtAgo(current?['at']), icon: Icons.update),
                    ],
                  ),
                ),
                PanelCard(
                  title: 'Sharing',
                  child: Column(
                    children: [
                      InfoRow(label: 'Status', value: sharing['live'] == true ? 'Sharing live' : _mode(sharing['mode'] as String?), icon: Icons.share_location),
                      InfoRow(label: 'Groups', value: '${sharing['groupsRequiring']} require location, ${sharing['groupsWithLocation']} use it', icon: Icons.groups_outlined),
                      InfoRow(label: 'Update interval', value: sharing['intervalMin'] == 0 ? 'Manual' : 'Every ${sharing['intervalMin']} min', icon: Icons.schedule),
                      if (sharing['liveUntil'] != null) InfoRow(label: 'Live until', value: fmtDateTime(sharing['liveUntil']), icon: Icons.timer_outlined),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminTable(
              columns: const ['Time', 'Place', 'Coordinates', 'Group', 'Source'],
              emptyText: 'No location history',
              rows: [
                for (final h in history)
                  [
                    Text(fmtDateTime(h['at'])),
                    Text('${h['place'] ?? '-'}'),
                    Text(_coords(h), style: const TextStyle(fontFamily: 'monospace')),
                    Text('${h['group'] ?? '-'}'),
                    Text(capitalize('${h['source']}')),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
