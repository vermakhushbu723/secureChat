import '../../../core/core.dart';

/// Opens a sheet to choose Public / Private / Highly Protected.
Future<MessageVisibility?> pickVisibility(BuildContext context, MessageVisibility current) {
  return showModalBottomSheet<MessageVisibility>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select message privacy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            for (final v in MessageVisibility.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(ctx, v),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: v == current ? ctx.colors.primary : ctx.palette.divider,
                        width: v == current ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(v.icon),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${v.label}  (${v.levelLabel})',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(v == current ? Icons.radio_button_checked : Icons.radio_button_off),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SecurityRulesList(visibility: v),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Composer bar with privacy selector. Runs the content filter before send.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    this.onAttach,
    this.onCamera,
    this.onMic,
    this.onExpand,
    this.onSend,
    this.onBlocked,
    this.hint = 'Type a message',
    this.autofocus = false,
    this.showPrivacy = true,
  });

  final VoidCallback? onAttach;
  final VoidCallback? onCamera;
  final VoidCallback? onMic;
  final VoidCallback? onExpand;
  final void Function(String text, MessageVisibility visibility)? onSend;

  /// Called with the triggered rule when the content filter blocks a message.
  final ValueChanged<ContentRule>? onBlocked;
  final String hint;
  final bool autofocus;
  final bool showPrivacy;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;
  MessageVisibility _visibility = Session.defaultVisibility.value;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    final rule = ContentFilter.check(text);
    if (rule != null) {
      widget.onBlocked?.call(rule);
      return;
    }
    widget.onSend?.call(text, _visibility);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    // White bar with top border; #F1F5F9 pill input; 44px indigo send button.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.palette.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: context.palette.surfaceAlt, borderRadius: BorderRadius.circular(22)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.showPrivacy)
                        IconButton(
                          tooltip: 'Privacy: ${_visibility.label}',
                          icon: Icon(_visibility.icon),
                          onPressed: () async {
                            final v = await pickVisibility(context, _visibility);
                            if (v != null) setState(() => _visibility = v);
                          },
                        ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: widget.autofocus,
                          minLines: 1,
                          maxLines: 5,
                          onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                          decoration: InputDecoration(
                            hintText: widget.showPrivacy ? '${widget.hint} (${_visibility.label})' : widget.hint,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.fromLTRB(widget.showPrivacy ? 0 : 18, 14, 0, 14),
                          ),
                        ),
                      ),
                      if (widget.onExpand != null)
                        IconButton(
                          icon: const Icon(Icons.open_in_full, size: 20),
                          onPressed: widget.onExpand,
                          tooltip: 'Composer',
                        ),
                      if (widget.onAttach != null)
                        IconButton(icon: const Icon(Icons.attach_file), onPressed: widget.onAttach),
                      if (!_hasText && widget.onCamera != null)
                        IconButton(icon: const Icon(Icons.photo_camera_outlined), onPressed: widget.onCamera),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton.filled(
                  color: Colors.white,
                  icon: Icon(_hasText || widget.onMic == null ? Icons.send : Icons.mic_none),
                  onPressed: () => _hasText || widget.onMic == null ? _send() : widget.onMic?.call(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the input bar when the trial expired.
class LockedInputBar extends StatelessWidget {
  const LockedInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: context.palette.danger),
            const SizedBox(width: 10),
            const Expanded(child: Text('Your free trial has expired. Chat is read only.')),
            TextButton(onPressed: () => context.push(AppRoutes.trialExpired), child: const Text('Unlock')),
          ],
        ),
      ),
    );
  }
}

/// Compact preview of a message, used on option / reply / report screens.
class MessagePreviewCard extends StatelessWidget {
  const MessagePreviewCard({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: context.colors.primary, width: 4)),
      ),
      child: Row(
        children: [
          Icon(iconForMessageType(message.type), color: context.palette.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.isMine ? 'You' : message.senderName, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(message.text, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SecurityBadge(message.visibility),
        ],
      ),
    );
  }
}
