import '../../../core/core.dart';
import '../../users/screens/user_list_screen.dart';

/// User-wise and group-wise access (Trial / Free / Premium / Extended / Locked).
class AdminUserSubscriptionScreen extends StatelessWidget {
  const AdminUserSubscriptionScreen({super.key});

  Future<void> _grant(BuildContext context, String who) async {
    final picked = await showDialog<AccessType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Set access for $who'),
        children: [
          for (final a in AccessType.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, a),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(a.label)),
            ),
        ],
      ),
    );
    if (picked != null && context.mounted) context.showSnack('$who: ${picked.label} access');
  }

  @override
  Widget build(BuildContext context) {
    final users = MockData.users;
    return AdminPage(
      title: 'User Access & Subscriptions',
      subtitle: 'Free / Premium / Extended access, user-wise and group-wise',
      children: [
        ResponsiveGrid(
          minItemWidth: 200,
          children: const [
            StatCard(icon: Icons.workspace_premium_outlined, label: 'Premium', value: '3,850'),
            StatCard(icon: Icons.card_giftcard_outlined, label: 'Free', value: '4,210'),
            StatCard(icon: Icons.more_time, label: 'Extended', value: '612'),
            StatCard(icon: Icons.lock_clock_outlined, label: 'Locked', value: '2,528'),
          ],
        ),
        const SizedBox(height: 16),
        const SectionHeader('User-wise access', padding: EdgeInsets.fromLTRB(0, 8, 0, 8)),
        const AdminFilterBar(hint: 'Search user', filters: ['All', 'Trial', 'Free', 'Premium', 'Extended', 'Locked']),
        AdminTable(
          total: 12450,
          columns: const ['User', 'User ID', 'Access', 'Valid till', 'Granted by', ''],
          onRowTap: (i) => context.push(AdminRoutes.userDetailsOf(users[i].id)),
          rows: [
            for (final u in users)
              [
                Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(u.internalId, style: const TextStyle(fontFamily: 'monospace')),
                StatusChip(u.access.label, tone: accessTone(u.access)),
                Text(u.access == AccessType.locked ? '-' : '24 Oct 2026'),
                Text(u.access == AccessType.premium ? 'Payment' : 'Admin approval'),
                TextButton(onPressed: () => _grant(context, u.name), child: const Text('Change')),
              ],
          ],
        ),
        const SectionHeader('Group-wise access', padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
        AdminTable(
          columns: const ['Group', 'Members', 'Access for all members', ''],
          rows: [
            for (final g in MockData.groups.take(4))
              [
                Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${g.memberCount}'),
                StatusChip(g.id == 'g2' ? 'Premium' : 'Per user', tone: g.id == 'g2' ? Tone.success : Tone.neutral),
                TextButton(onPressed: () => _grant(context, g.name), child: const Text('Change')),
              ],
          ],
        ),
      ],
    );
  }
}
