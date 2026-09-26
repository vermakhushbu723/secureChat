import '../../../core/core.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/widgets/group_tile.dart';

/// Forward only to groups the user is an authorized member of.
/// Every copy stays linked to the original (forward chain).
class ForwardDestinationScreen extends StatelessWidget {
  const ForwardDestinationScreen({super.key, required this.groupId, this.messageIds = const []});

  final String groupId;
  final List<String> messageIds;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Forward to group',
      child: Scaffold(
        appBar: AppBar(title: const Text('Forward to group')),
        body: AsyncView<List<GroupSummary>>(
          load: GroupRepository.groups,
          builder: (context, groups, _) => _Destinations(groupId: groupId, messageIds: messageIds, groups: groups),
        ),
      ),
    );
  }
}

class _Destinations extends StatefulWidget {
  const _Destinations({required this.groupId, required this.messageIds, required this.groups});

  final String groupId;
  final List<String> messageIds;
  final List<GroupSummary> groups;

  @override
  State<_Destinations> createState() => _DestinationsState();
}

class _DestinationsState extends State<_Destinations> {
  final Set<String> _targets = {};
  String _query = '';
  bool _sending = false;

  Future<void> _forward() async {
    if (widget.messageIds.isEmpty) return context.showSnack('No messages selected');
    setState(() => _sending = true);
    try {
      final copies = await GroupRepository.forward(widget.messageIds, _targets.toList());
      if (!mounted) return;
      context.showSnack('Forwarded ${copies.length} message(s) to ${_targets.length} group(s) - chain tracked');
      context.go(AppRoutes.groupChatOf(widget.groupId));
    } on ApiException catch (e) {
      if (!mounted) return;
      e.code == 'FORWARD_NOT_ALLOWED' ? context.push(AppRoutes.contentRestrictionFor('privateForward')) : context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.groups
        .where((g) => g.id != widget.groupId && (_query.isEmpty || g.name.toLowerCase().contains(_query.toLowerCase())))
        .toList();
    return ResponsiveBody(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppSearchField(hint: 'Search your groups', onChanged: (v) => setState(() => _query = v.trim())),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: InfoBanner(
                    icon: Icons.account_tree_outlined,
                    message: 'Every forwarded copy stays linked to the original message. If it is deleted for everyone, all copies are removed.',
                  ),
                ),
                SectionHeader('Your groups (${groups.length})'),
                if (groups.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No other groups to forward to')),
                for (final g in groups)
                  Builder(
                    builder: (context) {
                      final allowed = g.isActive && g.messageMode != 'private';
                      final selected = _targets.contains(g.id);
                      void toggle() => setState(() => selected ? _targets.remove(g.id) : _targets.add(g.id));
                      return ListTile(
                        enabled: allowed,
                        onTap: allowed ? toggle : null,
                        leading: GroupAvatar(name: g.name, avatarUrl: g.avatarUrl, size: 44),
                        title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          allowed
                              ? '${g.memberCount} members'
                              : !g.isActive
                              ? 'Group ${g.statusLabel.toLowerCase()}'
                              : 'Forwarding not allowed in private-only group',
                        ),
                        trailing: allowed ? Checkbox(value: selected, onChanged: (_) => toggle()) : const Icon(Icons.block, size: 18),
                      );
                    },
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: context.palette.divider))),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _targets.isEmpty ? 'No group selected' : '${widget.messageIds.length} message(s) -> ${_targets.length} group(s)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton.filled(
                    color: Colors.white,
                    icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                    onPressed: _targets.isEmpty || _sending ? null : _forward,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
