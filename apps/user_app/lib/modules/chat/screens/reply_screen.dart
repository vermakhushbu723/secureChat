import '../../../core/core.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/state/group_sender.dart';
import '../widgets/chat_input_bar.dart' show MessagePreviewCard, pickVisibility;
import '../widgets/group_bubble.dart';

class ReplyScreen extends StatelessWidget {
  const ReplyScreen({super.key, required this.groupId, required this.messageId});

  final String groupId;
  final String messageId;

  Future<({GroupMessage message, List<GroupMessage> thread, GroupDetail detail})> _load() async {
    final m = await GroupRepository.message(messageId);
    final results = await Future.wait([
      GroupRepository.messages(groupId, after: _before(m.id), limit: 6),
      GroupRepository.detail(groupId),
    ]);
    final page = results[0] as ({List<GroupMessage> items, bool hasMore});
    return (message: m, thread: page.items, detail: results[1] as GroupDetail);
  }

  /// A few messages before the replied one for context (ids are time ordered).
  static String _before(String id) {
    final secs = int.parse(id.substring(0, 8), radix: 16) - 1800;
    return '${secs.toRadixString(16).padLeft(8, '0')}0000000000000000';
  }

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Reply',
      child: Scaffold(
        backgroundColor: context.palette.chatBackground,
        appBar: AppBar(title: const Text('Reply')),
        body: AsyncView(load: _load, builder: (context, data, _) => _Reply(groupId: groupId, m: data.message, thread: data.thread, detail: data.detail)),
      ),
    );
  }
}

class _Reply extends StatefulWidget {
  const _Reply({required this.groupId, required this.m, required this.thread, required this.detail});

  final String groupId;
  final GroupMessage m;
  final List<GroupMessage> thread;
  final GroupDetail detail;

  @override
  State<_Reply> createState() => _ReplyState();
}

class _ReplyState extends State<_Reply> {
  final _text = TextEditingController();
  late MessageVisibility _visibility = Session.defaultVisibility.value;
  bool _sending = false;

  MessageVisibility get _effective => switch (widget.detail.settings.messageMode) {
    'public' => MessageVisibility.public,
    'private' => MessageVisibility.private,
    _ => _visibility,
  };

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final blocked = await GroupSender.text(widget.groupId, _text.text, _effective, replyToId: widget.m.id);
    if (!mounted) return;
    setState(() => _sending = false);
    if (await GroupSender.handle(context, blocked, sent: '${_effective.label} reply sent') && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.detail.me.canSend;
    return Column(
      children: [
        Expanded(
          child: ResponsiveBody(
            maxWidth: 900,
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                for (final c in widget.thread.where((x) => !x.unavailable))
                  Opacity(opacity: c.id == widget.m.id ? 1 : 0.45, child: IgnorePointer(child: GroupBubble(message: c))),
                if (!widget.thread.any((x) => x.id == widget.m.id)) IgnorePointer(child: GroupBubble(message: widget.m)),
              ],
            ),
          ),
        ),
        Container(
          color: context.colors.surface,
          child: ResponsiveBody(
            maxWidth: 900,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  Expanded(child: MessagePreviewCard(message: widget.m.toChatMessage())),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
                ],
              ),
            ),
          ),
        ),
        ResponsiveBody(
          maxWidth: 900,
          child: SafeArea(
            top: false,
            child: Container(
              color: context.colors.surface,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: !canSend
                  ? Text(widget.detail.me.sendBlockedMessage ?? 'You cannot send messages here.', style: TextStyle(color: context.palette.textSecondary))
                  : Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: context.palette.surfaceAlt, borderRadius: BorderRadius.circular(22)),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Privacy: ${_effective.label}',
                                  icon: Icon(_effective.icon),
                                  onPressed: widget.detail.settings.messageMode != 'user_select'
                                      ? null
                                      : () async {
                                          final v = await pickVisibility(context, _visibility);
                                          if (v != null) setState(() => _visibility = v);
                                        },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _text,
                                    autofocus: true,
                                    minLines: 1,
                                    maxLines: 5,
                                    onSubmitted: (_) => _send(),
                                    decoration: InputDecoration(
                                      hintText: 'Reply (${_effective.label})',
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton.filled(color: Colors.white, icon: const Icon(Icons.send), onPressed: _sending ? null : _send),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
