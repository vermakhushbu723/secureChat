import '../../../core/core.dart';

/// Admin decision on trial extension requests:
/// [Approve 7 Days] [Approve 30 Days] [Premium] [Reject]
class AdminExtensionRequestsScreen extends StatelessWidget {
  const AdminExtensionRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Extension Requests',
      subtitle: '8 pending requests',
      children: [
        const AdminFilterBar(hint: 'Search user or ID', filters: ['Pending', 'Approved', 'Rejected', 'All']),
        for (final r in MockData.extensionRequests)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppAvatar(initials: r.user[0], size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('User: ${r.user}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                '${MockData.userById(r.userId).internalId}  |  Trial expired: ${r.trialExpired}',
                                style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(r.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Text('Reason: ${r.reason}'),
                        Text('Requested: ${r.requested}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('On ${r.date}', style: TextStyle(color: context.palette.textSecondary)),
                      ],
                    ),
                    if (r.status == 'Pending') ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                            onPressed: () => context.showSnack('Approved 7 days for ${r.user}'),
                            child: const Text('Approve 7 Days'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                            onPressed: () => context.showSnack('Approved 30 days for ${r.user}'),
                            child: const Text('Approve 30 Days'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                            onPressed: () => context.showSnack('Premium granted to ${r.user}'),
                            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                            label: const Text('Premium'),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              foregroundColor: context.palette.danger,
                            ),
                            onPressed: () => context.showSnack('Request rejected - chat stays locked'),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
