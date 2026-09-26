import '../../../core/core.dart';

/// Send broadcast notifications and view history.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  String _audience = 'All users';
  final Set<String> _channels = {'Push'};

  static const _history = [
    ('Scheduled maintenance', 'All users', 'Push, Email', '22 Sep 2026', '12,480'),
    ('Trial ending reminder', 'Trial users', 'Push', '21 Sep 2026', '312'),
    ('New feature: secure viewer', 'Premium users', 'Push, In-app', '15 Sep 2026', '5,540'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Notifications',
      subtitle: 'Broadcast messages to users',
      children: [
        PanelCard(
          title: 'Compose notification',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppTextField(label: 'Title', hint: 'Notification title'),
              const SizedBox(height: 12),
              const AppTextField(label: 'Message', hint: 'Write the message...', maxLines: 3),
              const SizedBox(height: 12),
              const Text('Audience', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in const ['All users', 'Trial users', 'Premium users', 'Expired users', 'Group admins'])
                    ChoiceChip(
                      label: Text(a),
                      selected: _audience == a,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _audience = a),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Channels', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in const ['Push', 'In-app', 'Email', 'SMS'])
                    FilterChip(
                      label: Text(c),
                      selected: _channels.contains(c),
                      showCheckmark: false,
                      onSelected: (v) => setState(() => v ? _channels.add(c) : _channels.remove(c)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => context.showSnack('Notification scheduled'),
                    icon: const Icon(Icons.schedule_send_outlined),
                    label: const Text('Schedule'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => context.showSnack('Sent to $_audience'),
                    icon: const Icon(Icons.send),
                    label: const Text('Send now'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminTable(
          columns: const ['Title', 'Audience', 'Channels', 'Sent on', 'Delivered'],
          rows: [
            for (final h in _history)
              [
                Text(h.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(h.$2),
                Text(h.$3),
                Text(h.$4),
                Text(h.$5),
              ],
          ],
        ),
      ],
    );
  }
}
