import '../../../core/core.dart';

/// All invite links: expiry, maximum joins, approval, revoke.
class AdminInviteLinksScreen extends StatelessWidget {
  const AdminInviteLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final links = MockData.inviteLinks;
    return AdminPage(
      title: 'Invite Links',
      subtitle: 'Links created by group creators and admins',
      children: [
        ResponsiveGrid(
          minItemWidth: 200,
          children: const [
            StatCard(icon: Icons.link, label: 'Active links', value: '612'),
            StatCard(icon: Icons.group_add_outlined, label: 'Joins today', value: '1,148'),
            StatCard(icon: Icons.timer_off_outlined, label: 'Expired (7d)', value: '233'),
            StatCard(icon: Icons.link_off, label: 'Revoked (7d)', value: '41'),
          ],
        ),
        const SizedBox(height: 16),
        const AdminFilterBar(
          hint: 'Search code or group',
          filters: ['All', 'Active', 'Expired', 'Revoked', 'Approval on'],
        ),
        AdminTable(
          total: 1284,
          columns: const ['Link', 'Group', 'Created by', 'Joins', 'Expires', 'Approval', 'Status', 'Action'],
          rows: [
            for (final l in links)
              [
                Text(
                  l.url,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                ),
                Text(l.group),
                Text(l.createdBy),
                Text(l.maxJoins > 0 ? '${l.joins} / ${l.maxJoins}' : '${l.joins} / unlimited'),
                Text(l.expires),
                Icon(l.approval ? Icons.how_to_reg : Icons.remove, size: 20),
                StatusChip(l.status, tone: l.status == 'Revoked' ? Tone.danger : null),
                l.status == 'Active'
                    ? TextButton.icon(
                        onPressed: () => context.showSnack('Link ${l.code} revoked'),
                        icon: Icon(Icons.link_off, size: 18, color: context.palette.danger),
                        label: Text('Revoke', style: TextStyle(color: context.palette.danger)),
                      )
                    : const Text('-'),
              ],
          ],
        ),
      ],
    );
  }
}
