import '../../../core/core.dart';

/// Admin location dashboard: user name, group, current / last shared location,
/// time and status - plus the global member-location visibility rule.
class AdminLocationManagementScreen extends StatefulWidget {
  const AdminLocationManagementScreen({super.key});

  @override
  State<AdminLocationManagementScreen> createState() => _AdminLocationManagementScreenState();
}

class _AdminLocationManagementScreenState extends State<AdminLocationManagementScreen> {
  String _group = 'All groups';
  bool _showAdmin = true;
  bool _showMembers = true;

  @override
  Widget build(BuildContext context) {
    final groups = [
      'All groups',
      ...MockData.groups.where((g) => g.location != LocationRequirement.off).map((g) => g.name),
    ];
    final records = MockData.locations.where((r) => _group == 'All groups' || r.group == _group).toList();
    return AdminPage(
      title: 'Location Management',
      subtitle: '190 users sharing location',
      actions: [
        SizedBox(
          width: 280,
          child: DropdownButtonFormField<String>(
            initialValue: _group,
            isExpanded: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.groups_outlined)),
            items: [
              for (final g in groups)
                DropdownMenuItem(
                  value: g,
                  child: Text(g, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _group = v!),
          ),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 180,
          children: const [
            StatCard(icon: Icons.share_location, label: 'Live location', value: '142'),
            StatCard(icon: Icons.place_outlined, label: 'Join location only', value: '48'),
            StatCard(icon: Icons.location_off_outlined, label: 'Location off', value: '12,260'),
            StatCard(icon: Icons.groups_outlined, label: 'Mandatory groups', value: '63'),
          ],
        ),
        const SizedBox(height: 16),
        MapPlaceholder(
          height: 380,
          showControls: true,
          pins: [for (final r in records.where((r) => r.status != 'Off')) MapPin(dx: r.dx, dy: r.dy, label: r.user)],
        ),
        const SizedBox(height: 16),
        AdminTable(
          total: 190,
          columns: const ['User', 'Group', 'Current / last location', 'Time', 'Mode', 'Status', ''],
          rows: [
            for (final r in records)
              [
                Text(r.user, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(r.group),
                Text(r.place),
                Text(r.time),
                Text(r.mode.label),
                StatusChip(
                  r.status,
                  tone: r.status == 'Live'
                      ? Tone.success
                      : r.status == 'Stale'
                      ? Tone.warning
                      : Tone.danger,
                ),
                TextButton(
                  onPressed: () => context.push(AdminRoutes.userLocationOf('u1')),
                  child: const Text('History'),
                ),
              ],
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 360,
          children: [
            PanelCard(
              title: 'Show member location (default)',
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Admin'),
                    value: _showAdmin,
                    onChanged: (v) => setState(() => _showAdmin = v!),
                  ),
                  CheckboxListTile(
                    title: const Text('Group members'),
                    subtitle: const Text('Only members of the same group'),
                    value: _showMembers,
                    onChanged: (v) => setState(() => _showMembers = v!),
                  ),
                  CheckboxListTile(
                    title: const Text('Nobody'),
                    value: !_showAdmin && !_showMembers,
                    onChanged: (v) => setState(() {
                      if (v!) {
                        _showAdmin = false;
                        _showMembers = false;
                      }
                    }),
                  ),
                ],
              ),
            ),
            const PanelCard(
              title: 'Location privacy',
              child: Column(
                children: [
                  InfoRow(label: 'Mode 1', value: 'No Location', icon: Icons.location_off_outlined),
                  InfoRow(label: 'Mode 2', value: 'Join Location', icon: Icons.place_outlined),
                  InfoRow(label: 'Mode 3', value: 'Live - 5 / 10 / 30 min / manual', icon: Icons.share_location),
                  AppSwitchTile(
                    icon: Icons.visibility_outlined,
                    title: 'Live status always visible to user',
                    value: true,
                  ),
                  AppSwitchTile(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Auto delete history after 30 days',
                    value: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
