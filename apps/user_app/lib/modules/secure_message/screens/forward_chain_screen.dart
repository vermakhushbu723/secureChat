import '../../../core/core.dart';
import '../../chat/widgets/chat_input_bar.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';

/// Forward chain of a public message: A -> B -> C -> many users.
/// Users see names and counts; internal message IDs stay hidden.
class ForwardChainScreen extends StatelessWidget {
  const ForwardChainScreen({super.key, required this.messageId});

  final String messageId;

  Future<({GroupMessage message, ForwardNode tree, ChainTotals totals})> _load() async {
    final results = await Future.wait([GroupRepository.message(messageId), GroupRepository.chain(messageId)]);
    final chain = results[1] as ({ForwardNode tree, ChainTotals totals});
    return (message: results[0] as GroupMessage, tree: chain.tree, totals: chain.totals);
  }

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Forward Chain',
      child: Scaffold(
        appBar: AppBar(title: const Text('Forward Chain')),
        body: AsyncView(
          load: _load,
          builder: (context, data, _) => FormPage(
            items: [
              MessagePreviewCard(message: data.message.toChatMessage()),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Count(value: '${data.totals.usersReached}', label: 'Users reached'),
                  const SizedBox(width: 10),
                  _Count(value: '${data.totals.forwards}', label: 'Forwards'),
                  const SizedBox(width: 10),
                  _Count(value: '${data.totals.groups}', label: 'Groups'),
                ],
              ),
              const SectionHeader('Chain', padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
              ChainTree(node: data.tree),
              const SizedBox(height: 8),
              const InfoBanner(
                icon: Icons.account_tree_outlined,
                message: 'Every copy is linked to the original message. Deleting a message for everyone also removes every copy forwarded from it.',
              ),
            ],
            bottom: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Details',
                    icon: Icons.info_outline,
                    onPressed: data.message.forwarded ? () => context.push(AppRoutes.forwardedDetailsOf(messageId)) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Delete chain',
                    icon: Icons.delete_sweep_outlined,
                    danger: true,
                    onPressed: data.message.unavailable ? null : () => context.push(AppRoutes.deleteForEveryoneOf(messageId)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
