import '../../../core/core.dart';

class AdminUserActivityScreen extends StatelessWidget {
  const AdminUserActivityScreen({super.key, required this.userId});

  final String userId;

  static const _events = [
    (Icons.login, 'Logged in', 'Chrome on Windows  |  103.21.44.10', '24 Sep, 10:02 AM'),
    (Icons.send_outlined, 'Sent 14 messages', 'Project Alpha Team', '24 Sep, 10:15 AM'),
    (Icons.shortcut, 'Forwarded a message', 'To Field Operations', '24 Sep, 10:22 AM'),
    (Icons.upload_file_outlined, 'Uploaded protected file', 'Project_Plan_v2.pdf', '24 Sep, 10:40 AM'),
    (Icons.gpp_maybe_outlined, 'Blocked by number filter', 'Message contained phone number', '24 Sep, 11:05 AM'),
    (Icons.share_location, 'Started location sharing', 'Field Operations', '24 Sep, 11:30 AM'),
    (Icons.logout, 'Logged out', 'Android app', '23 Sep, 09:44 PM'),
  ];

  @override
  Widget build(BuildContext context) {
    final u = MockData.userById(userId);
    return AdminPage(
      title: 'User Activity',
      subtitle: u.name,
      showBack: true,
      actions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () {},
          icon: const Icon(Icons.date_range),
          label: const Text('Last 7 days'),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 180,
          children: const [
            StatCard(icon: Icons.login, label: 'Logins', value: '18'),
            StatCard(icon: Icons.forum_outlined, label: 'Messages', value: '342'),
            StatCard(icon: Icons.shortcut, label: 'Forwards', value: '21'),
            StatCard(icon: Icons.gpp_maybe_outlined, label: 'Violations', value: '3'),
          ],
        ),
        const SizedBox(height: 16),
        const AdminFilterBar(hint: 'Search activity', filters: ['All', 'Auth', 'Messages', 'Files', 'Security']),
        PanelCard(
          title: 'Timeline',
          child: Column(
            children: [
              for (final e in _events)
                ListTile(
                  leading: AppAvatar(icon: e.$1, size: 40),
                  title: Text(e.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(e.$3),
                  trailing: Text(e.$4, style: TextStyle(color: context.palette.textSecondary, fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
