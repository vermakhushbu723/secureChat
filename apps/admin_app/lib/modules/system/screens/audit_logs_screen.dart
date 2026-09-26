import '../../../core/core.dart';

class AdminAuditLogsScreen extends StatelessWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = MockData.auditLogs;
    return AdminPage(
      title: 'Audit Logs',
      subtitle: 'Every admin and staff action is recorded',
      actions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () {},
          icon: const Icon(Icons.date_range),
          label: const Text('Last 7 days'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.showSnack('Exporting CSV...'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export CSV'),
        ),
      ],
      children: [
        const AdminFilterBar(
          hint: 'Search actor, action or target',
          filters: ['All', 'Users', 'Groups', 'Messages', 'Settings'],
        ),
        AdminTable(
          columns: const ['Time', 'Actor', 'Action', 'Target', 'IP address'],
          rows: [
            for (final l in logs)
              [
                Text(l.time),
                Row(
                  children: [
                    AppAvatar(initials: l.actor.split(' ').map((e) => e[0]).join(), size: 28),
                    const SizedBox(width: 8),
                    Text(l.actor),
                  ],
                ),
                Text(l.action, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(l.target),
                Text(l.ip, style: const TextStyle(fontFamily: 'monospace')),
              ],
          ],
        ),
      ],
    );
  }
}
