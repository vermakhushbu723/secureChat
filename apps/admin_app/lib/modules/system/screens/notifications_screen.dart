import '../../../core/core.dart';

/// Send broadcast notifications and view history.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _audience = 'all';
  final Set<String> _channels = {'push', 'in_app'};
  int _page = 1;
  int _reload = 0;
  bool _sending = false;

  static const _audiences = {'All users': 'all', 'Trial users': 'trial', 'Premium users': 'premium', 'Expired users': 'expired', 'Group admins': 'group_admins'};
  static const _channelLabels = {'push': 'Push', 'in_app': 'In-app', 'email': 'Email', 'sms': 'SMS'};

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send({DateTime? at}) async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return context.showSnack('Write a title and a message');
    if (_channels.isEmpty) return context.showSnack('Choose at least one channel');
    setState(() => _sending = true);
    final r = await runAction<Map<String, dynamic>>(
      context,
      () => AdminApi.post('/notifications', {
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'audience': _audience,
        'channels': _channels.toList(),
        if (at != null) 'scheduledAt': at.toUtc().toIso8601String(),
      }),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (r == null) return;
    final skipped = (r['skipped'] as List? ?? const []).map((c) => _channelLabels[c] ?? c).join(', ');
    context.showSnack(
      r['status'] == 'scheduled'
          ? 'Scheduled for ${fmtDateTime(r['scheduledAt'])}'
          : 'Sent to ${fmtNum(r['recipients'])} users${skipped.isEmpty ? '' : ' ($skipped not set up, skipped)'}',
    );
    _title.clear();
    _body.clear();
    setState(() => _reload++);
  }

  Future<void> _schedule() async {
    final now = DateTime.now();
    final day = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 90)), initialDate: now);
    if (day == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))));
    if (time == null) return;
    final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    if (at.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      if (mounted) context.showSnack('Pick a time in the future');
      return;
    }
    await _send(at: at);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Notifications',
      subtitle: 'Broadcast messages to users',
      onRefresh: () => setState(() => _reload++),
      children: [
        PanelCard(
          title: 'Compose notification',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(label: 'Title', hint: 'Notification title', controller: _title, maxLength: 80),
              const SizedBox(height: 12),
              AppTextField(label: 'Message', hint: 'Write the message...', controller: _body, maxLines: 3, maxLength: 500),
              const SizedBox(height: 12),
              const Text('Audience', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _audiences.entries)
                    ChoiceChip(label: Text(a.key), selected: _audience == a.value, showCheckmark: false, onSelected: (_) => setState(() => _audience = a.value)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Channels', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in _channelLabels.entries)
                    FilterChip(label: Text(c.value), selected: _channels.contains(c.key), showCheckmark: false, onSelected: (v) => setState(() => v ? _channels.add(c.key) : _channels.remove(c.key))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'In-app shows instantly in the app. Push reaches devices with a push provider. Email needs SMTP. SMS needs an SMS provider (not set up).',
                style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: _sending ? null : _schedule,
                    icon: const Icon(Icons.schedule_send_outlined),
                    label: const Text('Schedule'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: _sending ? null : () => _send(),
                    icon: _sending ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                    label: const Text('Send now'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminAsync<Map<String, dynamic>>(
          reloadKey: '$_page|$_reload',
          load: () => AdminApi.get('/notifications', {'page': _page}),
          builder: (context, d, _) {
            final rows = (d['items'] as List).cast<Map<String, dynamic>>();
            return AdminTable(
              total: (d['total'] as num).toInt(),
              page: _page,
              onPage: (p) => setState(() => _page = p),
              columns: const ['Title', 'Audience', 'Channels', 'Sent on', 'Delivered', 'By', 'Status'],
              emptyText: 'No notifications sent yet',
              rows: [
                for (final n in rows)
                  [
                    SizedBox(width: 220, child: Text('${n['title']}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text(_audiences.entries.firstWhere((e) => e.value == n['audience'], orElse: () => const MapEntry('All users', 'all')).key),
                    Text((n['channels'] as List).map((c) => _channelLabels[c] ?? c).join(', ')),
                    Text(n['status'] == 'scheduled' ? 'At ${fmtDateTime(n['scheduledAt'])}' : fmtDateTime(n['sentAt'] ?? n['createdAt'])),
                    Text(n['status'] == 'sent' ? fmtNum(n['delivered']) : '-'),
                    Text('${n['createdBy'] ?? '-'}'),
                    n['status'] == 'scheduled'
                        ? TextButton(
                            onPressed: () async {
                              final r = await runAction(context, () => AdminApi.post('/notifications/${n['id']}/cancel'), success: 'Scheduled notification cancelled');
                              if (r != null) setState(() => _reload++);
                            },
                            child: const Text('Cancel'),
                          )
                        : StatusChip(capitalize('${n['status']}'), tone: n['status'] == 'sent' ? Tone.success : n['status'] == 'failed' ? Tone.danger : Tone.neutral),
                  ],
              ],
            );
          },
        ),
      ],
    );
  }
}
