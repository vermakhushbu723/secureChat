import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/widgets/group_tile.dart';
import '../widgets/group_bubble.dart';

class MessageInfoScreen extends StatelessWidget {
  const MessageInfoScreen({super.key, required this.groupId, required this.messageId});

  final String groupId;
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Message Info',
      child: Scaffold(
        appBar: AppBar(title: const Text('Message Info')),
        body: AsyncView<MessageInfoData>(load: () => GroupRepository.info(messageId), builder: (context, info, _) => _Info(info: info)),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.info});

  final MessageInfoData info;

  String _time(DateTime? t) => t == null ? '' : '${formatListTime(t)}${formatListTime(t).contains(':') ? '' : ', ${formatClock(t)}'}';

  Widget _row(BuildContext context, ReceiptRow r, Widget trailing) => ListTile(
    leading: GroupAvatar(name: r.displayName, avatarUrl: r.avatarUrl, size: 40),
    title: Text(r.displayName),
    subtitle: r.at == null ? null : Text(_time(r.at)),
    trailing: trailing,
  );

  @override
  Widget build(BuildContext context) {
    final m = info.message;
    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(color: context.palette.chatBackground, padding: const EdgeInsets.all(16), child: IgnorePointer(child: GroupBubble(message: m))),
          const SectionHeader('Details'),
          GroupedCard(
            children: [
              InfoRow(label: 'Sent by', value: m.isMine ? 'You' : m.senderName, icon: Icons.person_outline),
              InfoRow(label: 'Sent at', value: '${formatDayHeader(m.createdAt).toLowerCase()}, ${formatClock(m.createdAt)}', icon: Icons.schedule),
              InfoRow(label: 'Group', value: info.groupName, icon: Icons.groups_outlined),
              InfoRow(label: 'Visibility', value: '${m.visibility.label} (${m.visibility.levelLabel})', icon: Icons.lock_person_outlined),
              if (m.forwarded) InfoRow(label: 'Forwarded', value: 'Level ${m.forwardDepth} in chain', icon: Icons.shortcut),
              InfoRow(label: 'Copies reached', value: '${m.forwardCount} users', icon: Icons.groups_2_outlined),
              InfoRow(label: 'Type', value: m.type, icon: iconForMessageType(m.sharedType)),
              if (m.permissions.expiresAt != null)
                InfoRow(label: 'Expires', value: '${_time(m.permissions.expiresAt)} ${formatClock(m.permissions.expiresAt!)}', icon: Icons.timer_outlined),
              if (m.viewOnce) const InfoRow(label: 'View once', value: 'Yes', icon: Icons.looks_one_outlined),
            ],
          ),
          if (m.visibility == MessageVisibility.public && !m.unavailable) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SecondaryButton(label: 'Forward chain', icon: Icons.account_tree_outlined, onPressed: () => context.push(AppRoutes.forwardChainOf(m.id))),
            ),
          ],
          if (!info.receiptsVisible)
            const Padding(
              padding: EdgeInsets.all(16),
              child: InfoBanner(icon: Icons.visibility_off_outlined, message: 'Read receipts of a message are visible only to its sender and group admins.'),
            )
          else ...[
            SectionHeader('Read by (${info.readBy.length})'),
            GroupedCard(
              children: [
                if (info.readBy.isEmpty) const ListTile(title: Text('Nobody yet')),
                for (final r in info.readBy) _row(context, r, const Icon(Icons.done_all, size: 18, color: Color(0xFF3B82F6))),
              ],
            ),
            SectionHeader('Delivered to (${info.deliveredTo.length})'),
            GroupedCard(
              children: [
                if (info.deliveredTo.isEmpty) const ListTile(title: Text('Nobody')),
                for (final r in info.deliveredTo) _row(context, r, Icon(Icons.done_all, size: 18, color: context.palette.textSecondary)),
              ],
            ),
            SectionHeader('Pending (${info.pending.length})'),
            GroupedCard(
              children: [
                if (info.pending.isEmpty) const ListTile(title: Text('Everyone received it')),
                for (final r in info.pending) _row(context, r, Icon(Icons.done, size: 18, color: context.palette.textSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
