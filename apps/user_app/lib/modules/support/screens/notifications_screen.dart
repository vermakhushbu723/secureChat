import '../../../core/core.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'all';

  static const _filters = [
    ('all', 'All'),
    ('message', 'Messages'),
    ('group', 'Groups'),
    ('security', 'Security'),
    ('subscription', 'Billing'),
  ];

  void _open(BuildContext context, AppNotification n) {
    final route = switch (n.kind) {
      'message' => AppRoutes.groupChatOf('g1'),
      'group' => AppRoutes.groupInfoOf('g3'),
      'subscription' when n.id == 'n5' => AppRoutes.subscriptionStatus,
      'security' => AppRoutes.contentRestrictionFor(ContentRule.numbers.name),
      'subscription' => AppRoutes.trialStatus,
      _ => AppRoutes.accountSecurity,
    };
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final items = MockData.notifications.where((n) => _filter == 'all' || n.kind == _filter).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all read',
            onPressed: () => context.showSnack('All notifications marked as read'),
          ),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push(AppRoutes.settings)),
        ],
      ),
      body: ResponsiveBody(
        maxWidth: 760,
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  label: Text(_filters[i].$2),
                  selected: _filter == _filters[i].$1,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = _filters[i].$1),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: 'No notifications',
                      message: 'You are all caught up.',
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(indent: 72),
                      itemBuilder: (_, i) {
                        final n = items[i];
                        return ListTile(
                          onTap: () => _open(context, n),
                          tileColor: n.isRead ? null : context.palette.surfaceAlt.withValues(alpha: 0.6),
                          leading: AppAvatar(icon: iconForNotification(n.kind), size: 44, inverted: !n.isRead),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700),
                                ),
                              ),
                              Text(n.time, style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
                            ],
                          ),
                          subtitle: Text(n.body),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
