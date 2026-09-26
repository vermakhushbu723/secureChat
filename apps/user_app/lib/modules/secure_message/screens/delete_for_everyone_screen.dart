import '../../../core/core.dart';
import '../../chat/widgets/chat_input_bar.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';

/// Delete for everyone - chain aware.
/// Original deleted  -> whole chain removed.
/// Middle copy deleted -> that copy and everything forwarded from it removed.
class DeleteForEveryoneScreen extends StatelessWidget {
  const DeleteForEveryoneScreen({super.key, required this.messageId});

  final String messageId;

  Future<({GroupMessage message, DeletePreviewData preview})> _load() async {
    final results = await Future.wait([GroupRepository.message(messageId), GroupRepository.deletePreview(messageId)]);
    return (message: results[0] as GroupMessage, preview: results[1] as DeletePreviewData);
  }

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Delete for Everyone',
      child: Scaffold(
        appBar: AppBar(title: const Text('Delete for Everyone')),
        body: AsyncView(load: _load, builder: (context, data, _) => _Delete(messageId: messageId, m: data.message, p: data.preview)),
      ),
    );
  }
}

class _Delete extends StatefulWidget {
  const _Delete({required this.messageId, required this.m, required this.p});

  final String messageId;
  final GroupMessage m;
  final DeletePreviewData p;

  @override
  State<_Delete> createState() => _DeleteState();
}

class _DeleteState extends State<_Delete> {
  late bool _chain = true;
  bool _deleting = false;

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      final n = await GroupRepository.delete(widget.messageId, forEveryone: true, chain: _chain || widget.p.chainRequired);
      if (!mounted) return;
      context.showSnack(n > 1 ? 'Deleted for everyone - $n copies removed' : 'Deleted for everyone');
      context.pushReplacement(AppRoutes.chainDeletionStatusOf(widget.messageId));
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final chain = _chain || p.chainRequired;
    final copies = chain ? p.copiesAffected : 1;
    return FormPage(
      items: [
        const Center(child: FeatureIcon(Icons.delete_forever_outlined, tone: Tone.danger)),
        const SizedBox(height: 20),
        Text('Delete this message for everyone?', textAlign: TextAlign.center, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          p.isOriginal
              ? 'You are deleting the original message. Every forwarded copy in the chain will be removed.'
              : 'You are deleting a forwarded copy. It will be removed along with every copy forwarded from it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        MessagePreviewCard(message: widget.m.toChatMessage()),
        const SizedBox(height: 16),
        if (!p.canDelete) ...[
          InfoBanner(icon: Icons.block, tone: Tone.danger, message: p.reason ?? 'This message can no longer be deleted for everyone.'),
          const SizedBox(height: 16),
        ],
        Card(
          child: Column(
            children: [
              InfoRow(label: 'Scope', value: p.isOriginal ? 'Entire chain' : 'This copy + downstream', icon: Icons.account_tree_outlined),
              const Divider(indent: 16),
              InfoRow(label: 'Copies affected', value: '$copies', icon: Icons.groups_2_outlined),
              const Divider(indent: 16),
              InfoRow(label: 'Users affected', value: '${chain ? p.usersAffected : '-'}', icon: Icons.people_outline),
              const Divider(indent: 16),
              const InfoRow(label: 'Status change', value: 'ACTIVE -> DELETED', icon: Icons.sync_alt),
            ],
          ),
        ),
        const SectionHeader('Chain preview', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
        ChainTree(node: p.tree, deletedFrom: chain ? widget.messageId : null),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: chain,
          onChanged: p.chainRequired ? null : (v) => setState(() => _chain = v ?? false),
          title: const Text('Also delete linked forwarded copies'),
          subtitle: Text(p.chainRequired ? 'Required by group policy: chain deletion enabled' : 'Optional in this group'),
        ),
        const InfoBanner(
          icon: Icons.history,
          message: 'The content becomes unavailable for all affected users. The deletion event is kept in the security audit log.',
        ),
      ],
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Delete for everyone',
            danger: true,
            icon: Icons.delete_forever_outlined,
            loading: _deleting,
            onPressed: !p.canDelete || _deleting ? null : _delete,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        ],
      ),
    );
  }
}
