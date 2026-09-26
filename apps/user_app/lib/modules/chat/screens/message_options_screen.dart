import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../direct/widgets/message_actions.dart' show pickEmoji, quickReactions;
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../widgets/group_bubble.dart';

/// Options change with the message privacy:
/// Public  -> Reply, Forward, Copy, Delete for Me, Delete for Everyone, Report
/// Private -> Reply, Forward (disabled), Delete for Me, Delete for Everyone*, Report
/// Pops with 'edit' / 'reply' so the chat can open the composer in that mode.
class MessageOptionsScreen extends StatelessWidget {
  const MessageOptionsScreen({super.key, required this.groupId, required this.messageId});

  final String groupId;
  final String messageId;

  Future<({GroupMessage message, GroupDetail detail})> _load() async {
    final results = await Future.wait([GroupRepository.message(messageId), GroupRepository.detail(groupId)]);
    return (message: results[0] as GroupMessage, detail: results[1] as GroupDetail);
  }

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Message Options',
      child: Scaffold(
        backgroundColor: context.palette.chatBackground,
        appBar: AppBar(
          title: const Text('Message Options'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        ),
        body: AsyncView(load: _load, builder: (context, data, _) => _Options(groupId: groupId, m: data.message, detail: data.detail)),
      ),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({required this.groupId, required this.m, required this.detail});

  final String groupId;
  final GroupMessage m;
  final GroupDetail detail;

  static const _editWindow = Duration(minutes: 15);
  static const _deleteWindow = Duration(minutes: 60);

  @override
  Widget build(BuildContext context) {
    final v = m.visibility;
    final me = AuthService.instance.userId ?? '';
    final sec = detail.settings;
    final age = DateTime.now().difference(m.createdAt);
    final canForward = !m.unavailable && !m.viewOnce && ((v == MessageVisibility.public && sec.publicForwarding) || (v == MessageVisibility.private && sec.privateForwarding && m.media == null));
    final canEdit = m.isMine && !m.unavailable && const ['text', 'image', 'video'].contains(m.type) && age < _editWindow && detail.me.canSend;
    final canDeleteAll = !m.unavailable && (detail.me.isAdmin || (m.isMine && (sec.deleteForEveryoneUnlimited || age < _deleteWindow)));

    Widget blocked(IconData icon, String title, String reason) => ListTile(
      enabled: false,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(decoration: TextDecoration.lineThrough)),
      subtitle: Text(reason),
      trailing: const Icon(Icons.block, size: 18),
    );

    Future<void> react(String emoji) async {
      var e = emoji;
      if (e == '+') {
        final picked = await pickEmoji(context);
        if (picked == null || !context.mounted) return;
        e = picked;
      }
      final next = m.myReaction(me) == e ? null : e;
      if (await runAction(context, () => GroupRepository.react(m.id, next)) && context.mounted) context.pop();
    }

    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IgnorePointer(child: GroupBubble(message: m)),
          const SizedBox(height: 8),
          Row(
            children: [
              SecurityBadge(v),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  v == MessageVisibility.public ? 'Forwarding allowed and tracked' : 'Protected content - forward and copy disabled',
                  style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
          if (!m.unavailable && detail.me.canSend) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final e in quickReactions)
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => react(e),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: m.myReaction(me) == e ? context.palette.activeBg : null),
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    IconButton(tooltip: 'More reactions', icon: const Icon(Icons.add_reaction_outlined), onPressed: () => react('+')),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (!m.unavailable && detail.me.canSend)
                  AppTile(
                    icon: Icons.reply,
                    title: 'Reply',
                    showChevron: false,
                    onTap: () => context.pushReplacement(AppRoutes.replyOf(groupId, m.id)),
                  ),
                if (canEdit) ...[
                  const Divider(indent: 56),
                  AppTile(icon: Icons.edit_outlined, title: 'Edit', showChevron: false, onTap: () => context.pop('edit')),
                ],
                const Divider(indent: 56),
                if (canForward)
                  AppTile(
                    icon: Icons.shortcut,
                    title: 'Forward',
                    showChevron: false,
                    onTap: () => context.pushReplacement(AppRoutes.forwardSelectionOf(groupId, preselect: m.id)),
                  )
                else
                  InkWell(
                    onTap: () => context.pushReplacement(AppRoutes.contentRestrictionFor('privateForward')),
                    child: blocked(Icons.shortcut, 'Forward', m.viewOnce ? 'View once message' : '${v.label} message'),
                  ),
                const Divider(indent: 56),
                if (m.permissions.canCopy && m.text.isNotEmpty && !m.unavailable)
                  AppTile(
                    icon: Icons.copy,
                    title: 'Copy',
                    showChevron: false,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: m.text));
                      context.showSnack('Copied');
                      context.pop();
                    },
                  )
                else
                  blocked(Icons.copy, 'Copy', v == MessageVisibility.public ? 'Nothing to copy' : 'Copy disabled for ${v.label.toLowerCase()} content'),
                if (m.isProtected) ...[
                  const Divider(indent: 56),
                  blocked(Icons.ios_share, 'Share / Export', 'External share disabled'),
                ],
                const Divider(indent: 56),
                AppTile(
                  icon: m.starred ? Icons.star : Icons.star_border,
                  title: m.starred ? 'Unstar' : 'Star',
                  showChevron: false,
                  onTap: () async {
                    if (await runAction(context, () => GroupRepository.star(m.id, !m.starred), done: m.starred ? 'Unstarred' : 'Starred') && context.mounted) {
                      context.pop();
                    }
                  },
                ),
                const Divider(indent: 56),
                AppTile(icon: Icons.info_outline, title: 'Message info', onTap: () => context.pushReplacement(AppRoutes.messageInfoOf(groupId, m.id))),
                if (v == MessageVisibility.public && sec.trackForwardChain && !m.unavailable) ...[
                  const Divider(indent: 56),
                  AppTile(icon: Icons.account_tree_outlined, title: 'View forward chain', onTap: () => context.push(AppRoutes.forwardChainOf(m.id))),
                ],
                if (m.forwarded && !m.unavailable) ...[
                  const Divider(indent: 56),
                  AppTile(icon: Icons.shortcut, title: 'Forwarded message details', onTap: () => context.push(AppRoutes.forwardedDetailsOf(m.id))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                AppTile(
                  icon: Icons.delete_outline,
                  title: 'Delete for me',
                  danger: true,
                  showChevron: false,
                  onTap: () async {
                    if (await runAction(context, () => GroupRepository.delete(m.id, forEveryone: false), done: 'Deleted for you') && context.mounted) {
                      context.pop();
                    }
                  },
                ),
                const Divider(indent: 56),
                if (canDeleteAll)
                  AppTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete for everyone',
                    subtitle: m.forwarded || v == MessageVisibility.public ? 'Linked forwarded copies are also removed' : null,
                    danger: true,
                    onTap: () => context.pushReplacement(AppRoutes.deleteForEveryoneOf(m.id)),
                  )
                else if (m.unavailable)
                  AppTile(icon: Icons.checklist, title: 'Deletion details', onTap: () => context.pushReplacement(AppRoutes.deletedMessageOf(groupId, m.id)))
                else
                  ListTile(
                    enabled: false,
                    leading: const Icon(Icons.delete_forever_outlined),
                    title: const Text('Delete for everyone'),
                    subtitle: Text(m.isMine ? 'Too late to delete for everyone' : 'Only the sender or a group admin can delete for everyone'),
                  ),
                if (!m.isMine && !m.unavailable) ...[
                  const Divider(indent: 56),
                  AppTile(icon: Icons.flag_outlined, title: 'Report', danger: true, onTap: () => context.pushReplacement(AppRoutes.reportMessageOf(groupId, m.id))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
