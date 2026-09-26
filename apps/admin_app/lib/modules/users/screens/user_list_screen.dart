import '../../../core/core.dart';

String userStatusLabel(UserStatus s) => s.name[0].toUpperCase() + s.name.substring(1);

Tone accessTone(AccessType a) => switch (a) {
  AccessType.premium => Tone.success,
  AccessType.free || AccessType.extended => Tone.info,
  AccessType.trial => Tone.warning,
  AccessType.locked => Tone.danger,
};

/// Admins see full identity (name, login, internal ID) - members never do.
class AdminUserListScreen extends StatelessWidget {
  const AdminUserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [MockData.currentUser, ...MockData.users];
    return AdminPage(
      title: 'Users',
      subtitle: '12,450 registered users',
      actions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.showSnack('Export queued - you will get a download link'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export'),
        ),
      ],
      children: [
        const AdminFilterBar(
          hint: 'Search name, user ID, mobile or email',
          filters: ['All', 'Trial', 'Free', 'Premium', 'Extended', 'Locked', 'Blocked'],
        ),
        AdminTable(
          total: 12450,
          columns: const ['User', 'User ID', 'Login', 'Access', 'Trial ends', 'Location', 'Warnings', 'Status', ''],
          onRowTap: (i) => context.push(AdminRoutes.userDetailsOf(users[i].id)),
          rows: [
            for (final u in users)
              [
                Row(
                  children: [
                    AppAvatar(initials: u.initials, size: 32, online: u.isOnline),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          'shown as "${u.displayName}"',
                          style: TextStyle(fontSize: 11, color: context.palette.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(u.internalId, style: const TextStyle(fontFamily: 'monospace')),
                Text(u.phone),
                StatusChip(u.access.label, tone: accessTone(u.access)),
                Text(u.trialEnd),
                Icon(u.locationEnabled ? Icons.location_on : Icons.location_off_outlined, size: 20),
                Text('${u.warnings}'),
                StatusChip(userStatusLabel(u.status)),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: context.push,
                  itemBuilder: (_) => [
                    PopupMenuItem(value: AdminRoutes.userDetailsOf(u.id), child: const Text('View / edit')),
                    PopupMenuItem(value: AdminRoutes.userActivityOf(u.id), child: const Text('Activity')),
                    PopupMenuItem(value: AdminRoutes.userLocationOf(u.id), child: const Text('Location')),
                  ],
                ),
              ],
          ],
        ),
      ],
    );
  }
}
