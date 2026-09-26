import '../../../core/core.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';

/// Progress of Delete-for-Everyone across a forward chain.
/// Message status: ACTIVE -> DELETED_FOR_EVERYONE -> all linked copies DELETED.
class ChainDeletionStatusScreen extends StatelessWidget {
  const ChainDeletionStatusScreen({super.key, required this.messageId});

  final String messageId;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Chain Deletion Status',
      child: Scaffold(
        appBar: AppBar(title: const Text('Chain Deletion Status')),
        body: AsyncView<DeletionStatusData>(
          load: () => GroupRepository.deletionStatus(messageId),
          builder: (context, s, reload) {
            final deletedLocations = s.locations.where((l) => l.status == 'Deleted').length;
            final progress = s.locations.isEmpty ? 1.0 : deletedLocations / s.locations.length;
            return RefreshIndicator(
              onRefresh: reload,
              child: FormPage(
                items: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.delete_sweep_outlined, size: 28),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Removing linked copies', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                              Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress, minHeight: 10)),
                          const SizedBox(height: 10),
                          Text(
                            '${s.copiesRemoved} of ${s.totalCopies} copies removed  |  ${s.usersCleared} users cleared  |  by ${s.deletedBy}',
                            style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SectionHeader('Message status', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < s.statusFlow.length; i++) ...[
                        StatusChip(s.statusFlow[i], tone: i == 0 ? Tone.neutral : Tone.danger),
                        if (i < s.statusFlow.length - 1) Icon(Icons.arrow_forward, size: 16, color: context.palette.textSecondary),
                      ],
                    ],
                  ),
                  const SectionHeader('Locations', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < s.locations.length; i++) ...[
                          if (i > 0) const Divider(indent: 72),
                          ListTile(
                            leading: AppAvatar(icon: s.locations[i].status == 'Deleted' ? Icons.check : Icons.chat_bubble_outline, size: 40),
                            title: Text(s.locations[i].groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${s.locations[i].label}\n${s.locations[i].users} users'),
                            isThreeLine: true,
                            trailing: StatusChip(s.locations[i].status, tone: s.locations[i].status == 'Deleted' ? Tone.danger : Tone.neutral),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                bottom: PrimaryButton(label: 'Done', onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home)),
              ),
            );
          },
        ),
      ),
    );
  }
}
