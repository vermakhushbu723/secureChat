import '../../../core/core.dart';
import '../../chat/widgets/group_bubble.dart';
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';

class ForwardedMessageDetailsScreen extends StatelessWidget {
  const ForwardedMessageDetailsScreen({super.key, required this.messageId});

  final String messageId;

  Future<({GroupMessage message, ForwardDetailsData details})> _load() async {
    final results = await Future.wait([GroupRepository.message(messageId), GroupRepository.forwardDetails(messageId)]);
    return (message: results[0] as GroupMessage, details: results[1] as ForwardDetailsData);
  }

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Forwarded Message',
      child: Scaffold(
        appBar: AppBar(title: const Text('Forwarded Message')),
        body: AsyncView(
          load: _load,
          builder: (context, data, _) {
            final d = data.details;
            final m = data.message;
            if (!d.forwarded) {
              return const EmptyState(icon: Icons.edit_outlined, title: 'Original message', message: 'This message was written in this group, not forwarded.');
            }
            return ResponsiveBody(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Container(color: context.palette.chatBackground, padding: const EdgeInsets.all(16), child: IgnorePointer(child: GroupBubble(message: m))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: InfoBanner(
                      icon: Icons.shortcut,
                      title: d.manyTimes ? 'Forwarded many times' : 'Forwarded message',
                      message: 'This message did not start in this group. Verify before acting on it.',
                      tone: d.manyTimes ? Tone.warning : Tone.neutral,
                    ),
                  ),
                  const SectionHeader('Origin'),
                  GroupedCard(
                    children: [
                      InfoRow(label: 'Original sender', value: d.originSender ?? '-', icon: Icons.person_outline),
                      InfoRow(label: 'Original group', value: d.originGroup ?? '-', icon: Icons.groups_outlined),
                      InfoRow(
                        label: 'Original time',
                        value: d.originTime == null ? '-' : '${formatDayHeader(d.originTime!).toLowerCase()}, ${formatClock(d.originTime!)}',
                        icon: Icons.schedule,
                      ),
                    ],
                  ),
                  const SectionHeader('This copy'),
                  GroupedCard(
                    children: [
                      InfoRow(label: 'Forwarded by', value: d.forwardedBy ?? '-', icon: Icons.shortcut),
                      InfoRow(label: 'Position in chain', value: 'Level ${d.level} of ${d.totalLevels}', icon: Icons.account_tree_outlined),
                      InfoRow(label: 'Users reached', value: '${d.usersReached}', icon: Icons.groups_2_outlined),
                      InfoRow(label: 'Privacy', value: '${d.visibility.label} (${d.visibility.levelLabel})', icon: d.visibility.icon),
                      const InfoRow(label: 'Message IDs', value: 'Hidden (system only)', icon: Icons.visibility_off_outlined),
                    ],
                  ),
                  const SectionHeader('What happens on delete'),
                  const GroupedCard(
                    children: [
                      ListTile(leading: Icon(Icons.check), title: Text('If the original is deleted for everyone, this copy is removed')),
                      ListTile(leading: Icon(Icons.check), title: Text('If you delete this copy for everyone, copies forwarded from it are removed')),
                      ListTile(leading: Icon(Icons.history), title: Text('Deletion events are kept in the audit log')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SecondaryButton(label: 'View full forward chain', icon: Icons.account_tree_outlined, onPressed: () => context.push(AppRoutes.forwardChainOf(messageId))),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
