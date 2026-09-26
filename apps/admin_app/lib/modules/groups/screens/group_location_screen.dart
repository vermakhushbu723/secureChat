import '../../../core/core.dart';

class AdminGroupLocationScreen extends StatelessWidget {
  const AdminGroupLocationScreen({super.key, required this.groupId});

  final String groupId;

  static const _pins = [
    MapPin(dx: 0.2, dy: 0.3, label: 'Rahul'),
    MapPin(dx: 0.45, dy: 0.25, label: 'Priya'),
    MapPin(dx: 0.35, dy: 0.65, label: 'Karan'),
    MapPin(dx: 0.7, dy: 0.55, label: 'Sneha'),
    MapPin(dx: 0.85, dy: 0.3, label: 'Vikas'),
  ];

  @override
  Widget build(BuildContext context) {
    final g = MockData.groupById(groupId);
    final members = MockData.users;
    return AdminPage(
      title: 'Group Location',
      subtitle: g.name,
      showBack: true,
      children: [
        ResponsiveGrid(
          minItemWidth: 180,
          children: const [
            StatCard(icon: Icons.share_location, label: 'Sharing live', value: '18'),
            StatCard(icon: Icons.schedule, label: 'Stale (>30 min)', value: '4'),
            StatCard(icon: Icons.location_off_outlined, label: 'Not sharing', value: '2'),
          ],
        ),
        const SizedBox(height: 16),
        const MapPlaceholder(height: 380, showControls: true, pins: _pins),
        const SizedBox(height: 16),
        AdminTable(
          columns: const ['Member', 'Location', 'Last update', 'Status'],
          onRowTap: (i) => context.push(AdminRoutes.userLocationOf(members[i].id)),
          rows: [
            for (final m in members)
              [
                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(m.location),
                Text(m.isOnline ? 'Just now' : '35 min ago'),
                StatusChip(
                  m.status == UserStatus.blocked
                      ? 'Off'
                      : m.isOnline
                      ? 'Live'
                      : 'Stale',
                  tone: m.status == UserStatus.blocked
                      ? Tone.danger
                      : m.isOnline
                      ? Tone.success
                      : Tone.warning,
                ),
              ],
          ],
        ),
      ],
    );
  }
}
