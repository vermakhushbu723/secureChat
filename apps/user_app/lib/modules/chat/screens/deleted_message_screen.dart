import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../widgets/group_bubble.dart';

class DeletedMessageScreen extends StatelessWidget {
  const DeletedMessageScreen({super.key, required this.groupId, required this.messageId});

  final String groupId;
  final String messageId;

  Future<({GroupMessage message, DeletionStatusData status})> _load() async {
    final results = await Future.wait([GroupRepository.message(messageId), GroupRepository.deletionStatus(messageId)]);
    return (message: results[0] as GroupMessage, status: results[1] as DeletionStatusData);
  }

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Deleted Message',
      child: Scaffold(
        appBar: AppBar(title: const Text('Deleted Message')),
        body: AsyncView(
          load: _load,
          builder: (context, data, _) {
            final s = data.status;
            return FormPage(
              items: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: context.palette.chatBackground, borderRadius: BorderRadius.circular(12)),
                  child: IgnorePointer(child: GroupBubble(message: data.message)),
                ),
                const SizedBox(height: 24),
                const Center(child: FeatureIcon(Icons.delete_sweep_outlined, tone: Tone.neutral, size: 80)),
                const SizedBox(height: 16),
                Text('This message was deleted for everyone', textAlign: TextAlign.center, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  s.copiesRemoved > 1
                      ? 'The content is no longer available on any device. Forwarded copies were removed as well.'
                      : 'The content is no longer available on any device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Column(
                    children: [
                      InfoRow(label: 'Deleted by', value: s.deletedBy, icon: Icons.person_outline),
                      const Divider(indent: 16),
                      InfoRow(
                        label: 'Deleted at',
                        value: s.deletedAt == null ? '-' : '${formatDayHeader(s.deletedAt!).toLowerCase()}, ${formatClock(s.deletedAt!)}',
                        icon: Icons.schedule,
                      ),
                      const Divider(indent: 16),
                      InfoRow(label: 'Copies removed', value: '${s.copiesRemoved} of ${s.totalCopies}', icon: Icons.account_tree_outlined),
                      const Divider(indent: 16),
                      InfoRow(label: 'Reason', value: s.reason, icon: Icons.info_outline),
                    ],
                  ),
                ),
              ],
              bottom: SecondaryButton(
                label: 'View chain deletion status',
                icon: Icons.checklist,
                onPressed: () => context.push(AppRoutes.chainDeletionStatusOf(messageId)),
              ),
            );
          },
        ),
      ),
    );
  }
}
