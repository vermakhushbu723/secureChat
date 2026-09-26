import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../widgets/group_bubble.dart';

/// Select one or more messages to forward (only Public messages can be forwarded).
class ForwardSelectionScreen extends StatelessWidget {
  const ForwardSelectionScreen({super.key, required this.groupId, this.preselect});

  final String groupId;
  final String? preselect;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Select messages',
      child: AsyncView(
        load: () => GroupRepository.messages(groupId, limit: 60),
        builder: (context, page, reload) => _Selection(groupId: groupId, messages: page.items.reversed.toList(), preselect: preselect, reload: reload),
      ),
    );
  }
}

class _Selection extends StatefulWidget {
  const _Selection({required this.groupId, required this.messages, this.preselect, required this.reload});

  final String groupId;
  final List<GroupMessage> messages; // newest first
  final String? preselect;
  final Future<void> Function() reload;

  @override
  State<_Selection> createState() => _SelectionState();
}

class _SelectionState extends State<_Selection> {
  late final Set<String> _selected = {?widget.preselect};

  bool _locked(GroupMessage m) => m.isProtected || m.viewOnce || m.unavailable || m.isSystem;

  List<GroupMessage> get _picked => widget.messages.where((m) => _selected.contains(m.id)).toList();

  Future<void> _star() async {
    for (final m in _picked) {
      await GroupRepository.star(m.id, true);
    }
    if (mounted) context.showSnack('${_selected.length} message(s) starred');
  }

  Future<void> _deleteForMe() async {
    final ok = await context.confirm(title: 'Delete ${_selected.length} message(s)?', message: 'They are removed for you only.', confirmLabel: 'Delete', danger: true);
    if (!ok || !mounted) return;
    for (final m in _picked) {
      await GroupRepository.delete(m.id, forEveryone: false);
    }
    if (!mounted) return;
    context.showSnack('Deleted for you');
    setState(() => _selected.clear());
    await widget.reload();
  }

  Future<void> _copy() async {
    final text = _picked.where((m) => m.permissions.canCopy && m.text.isNotEmpty).map((m) => '${m.senderName}: ${m.text}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) context.showSnack('Copied');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.chatBackground,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text('${_selected.length} selected'),
        actions: [
          IconButton(icon: const Icon(Icons.star_border), tooltip: 'Star', onPressed: _selected.isEmpty ? null : _star),
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete for me', onPressed: _selected.isEmpty ? null : _deleteForMe),
          IconButton(icon: const Icon(Icons.copy), tooltip: 'Copy', onPressed: _selected.isEmpty ? null : _copy),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: InfoBanner(icon: Icons.lock_outline, message: 'Only Public messages can be forwarded. Private and Highly Protected messages are locked.'),
          ),
          Expanded(
            child: ResponsiveBody(
              maxWidth: 900,
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                itemCount: widget.messages.length,
                itemBuilder: (_, i) {
                  final m = widget.messages[i];
                  if (m.isSystem) return IgnorePointer(child: GroupBubble(message: m));
                  final locked = _locked(m);
                  final selected = _selected.contains(m.id);
                  return InkWell(
                    onTap: () {
                      if (locked) {
                        if (m.isProtected || m.viewOnce) context.push(AppRoutes.contentRestrictionFor('privateForward'));
                        return;
                      }
                      setState(() => selected ? _selected.remove(m.id) : _selected.add(m.id));
                    },
                    child: Container(
                      color: selected ? context.colors.primary.withValues(alpha: 0.08) : null,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              locked ? Icons.lock_outline : selected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: locked ? context.palette.textSecondary : context.colors.primary,
                            ),
                          ),
                          Expanded(child: IgnorePointer(child: Opacity(opacity: locked ? 0.5 : 1, child: GroupBubble(message: m)))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _selected.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.forwardDestinationOf(widget.groupId, messageIds: _selected.toList())),
              icon: const Icon(Icons.shortcut),
              label: Text('Forward (${_selected.length})'),
            ),
    );
  }
}
