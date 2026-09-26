import '../../../core/core.dart';
import '../../users/screens/user_list_screen.dart';

class AdminGroupMembersScreen extends StatelessWidget {
  const AdminGroupMembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final g = MockData.groupById(groupId);
    final members = MockData.users;
    String role(MemberRole r) => r.name[0].toUpperCase() + r.name.substring(1);
    return AdminPage(
      title: 'Group Members',
      subtitle: g.name,
      showBack: true,
      actions: [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () {},
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add member'),
        ),
      ],
      children: [
        const AdminFilterBar(hint: 'Search members', filters: ['All', 'Owner', 'Admin', 'Member']),
        AdminTable(
          columns: const ['Member', 'Role', 'Joined', 'Location', 'Status', 'Actions'],
          onRowTap: (i) => context.push(AdminRoutes.userDetailsOf(members[i].id)),
          rows: [
            for (final m in members)
              [
                Row(
                  children: [
                    AppAvatar(initials: m.initials, size: 32, online: m.isOnline),
                    const SizedBox(width: 10),
                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                StatusChip(role(m.role), tone: m.role == MemberRole.member ? Tone.neutral : Tone.dark),
                Text(m.joinedOn),
                Text(m.location),
                StatusChip(userStatusLabel(m.status)),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Make admin',
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      onPressed: () {},
                    ),
                    IconButton(tooltip: 'Mute', icon: const Icon(Icons.volume_off_outlined), onPressed: () {}),
                    IconButton(
                      tooltip: 'Remove',
                      icon: Icon(Icons.person_remove_outlined, color: context.palette.danger),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
          ],
        ),
      ],
    );
  }
}
