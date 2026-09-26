import '../../../core/core.dart';
import 'user_list_screen.dart';

class AdminBlockedUsersScreen extends StatelessWidget {
  const AdminBlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = MockData.users
        .where((u) => u.status == UserStatus.blocked || u.status == UserStatus.suspended)
        .toList();
    const reasons = ['Abusive language (3 reports)', 'Leaked protected content'];
    const dates = ['20 Sep 2026', '18 Sep 2026'];
    return AdminPage(
      title: 'Blocked Users',
      subtitle: 'Users blocked or suspended by admins',
      children: [
        const AdminFilterBar(hint: 'Search blocked users', filters: ['All', 'Blocked', 'Suspended']),
        AdminTable(
          columns: const ['User', 'Status', 'Reason', 'Since', 'By', 'Action'],
          onRowTap: (i) => context.push(AdminRoutes.userDetailsOf(users[i].id)),
          rows: [
            for (var i = 0; i < users.length; i++)
              [
                Row(
                  children: [
                    AppAvatar(initials: users[i].initials, size: 32),
                    const SizedBox(width: 10),
                    Text(users[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                StatusChip(userStatusLabel(users[i].status)),
                Text(reasons[i % reasons.length]),
                Text(dates[i % dates.length]),
                const Text('Super Admin'),
                TextButton.icon(
                  onPressed: () => context.showSnack('${users[i].name} unblocked'),
                  icon: const Icon(Icons.lock_open, size: 18),
                  label: const Text('Unblock'),
                ),
              ],
          ],
        ),
      ],
    );
  }
}
