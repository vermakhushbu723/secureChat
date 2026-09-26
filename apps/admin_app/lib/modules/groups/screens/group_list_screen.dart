import '../../../core/core.dart';

class AdminGroupListScreen extends StatelessWidget {
  const AdminGroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = MockData.groups;
    return AdminPage(
      title: 'Groups',
      subtitle: '420 active groups',
      actions: [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.push(AdminRoutes.groupCreate),
          icon: const Icon(Icons.add),
          label: const Text('Create group'),
        ),
      ],
      children: [
        const AdminFilterBar(
          hint: 'Search group name or invite code',
          filters: ['All', 'Location mandatory', 'Location optional', 'Private mode', 'Suspended'],
        ),
        AdminTable(
          total: 420,
          columns: const ['Group', 'Members', 'Location', 'Member location', 'Message mode', 'Creator', 'Status', ''],
          onRowTap: (i) => context.push(AdminRoutes.groupDetailsOf(groups[i].id)),
          rows: [
            for (final g in groups)
              [
                Row(
                  children: [
                    AppAvatar(initials: g.initials, size: 32),
                    const SizedBox(width: 10),
                    Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Text('${g.memberCount}'),
                StatusChip(g.location.label, tone: g.locationRequired ? Tone.warning : Tone.neutral),
                Text(switch (g.locationVisibility) {
                  LocationVisibility.adminOnly => 'Admin only',
                  LocationVisibility.groupMembers => 'Admin + members',
                  LocationVisibility.nobody => 'Nobody',
                }),
                Text(g.messageMode),
                Text(g.createdBy),
                StatusChip(g.status),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (v) => v == 'delete'
                      ? context.confirm(
                          title: 'Delete ${g.name}?',
                          message: 'All messages and files will be removed.',
                          confirmLabel: 'Delete',
                          danger: true,
                        )
                      : context.push(v),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: AdminRoutes.groupDetailsOf(g.id), child: const Text('View')),
                    PopupMenuItem(value: AdminRoutes.groupEditOf(g.id), child: const Text('Edit')),
                    PopupMenuItem(value: AdminRoutes.groupMembersOf(g.id), child: const Text('Members')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
          ],
        ),
      ],
    );
  }
}
