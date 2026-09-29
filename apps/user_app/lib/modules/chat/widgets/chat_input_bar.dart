import '../../../core/core.dart';
import '../../secure_message/state/message_draft.dart';

/// Opens the privacy sheet: Public / Private / Highly Protected in plain words, plus the
/// options for the next message (disappearing, view once, saving, screenshots, silent).
/// Used by group and 1-to-1 chats. Options are kept in [MessageDraft].
Future<MessageVisibility?> pickVisibility(BuildContext context, MessageVisibility current, {bool allowChange = true}) {
  return showModalBottomSheet<MessageVisibility>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _PrivacySheet(current: current, allowChange: allowChange),
  );
}

class _PrivacySheet extends StatefulWidget {
  const _PrivacySheet({required this.current, required this.allowChange});

  final MessageVisibility current;
  final bool allowChange;

  @override
  State<_PrivacySheet> createState() => _PrivacySheetState();
}

class _PrivacySheetState extends State<_PrivacySheet> {
  late MessageVisibility _level = widget.current;
  final _draft = MessageDraft.instance;

  static const _levels = {
    MessageVisibility.public: (
      'Normal message',
      'The other person can see it, save it, forward it and copy it.',
      ['See', 'Save', 'Forward', 'Copy', 'Screenshot'],
      <String>[],
    ),
    MessageVisibility.private: (
      'Only for this chat',
      'They can see it, but cannot save, forward, copy or screenshot it.',
      ['See'],
      ['Save', 'Forward', 'Copy', 'Screenshot'],
    ),
    MessageVisibility.highlyProtected: (
      'Most secure',
      'Opens only in the secure viewer with their name as a watermark. Nothing can be saved, shared or recorded.',
      ['See in secure viewer'],
      ['Save', 'Forward', 'Copy', 'Screenshot', 'Record'],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: ListenableBuilder(
        listenable: _draft,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Who can do what with your message?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                widget.allowChange ? 'Choose a privacy level for the messages you send.' : 'The group admin fixed the privacy level for this group.',
                style: TextStyle(color: p.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              for (final v in MessageVisibility.values) _levelCard(context, v),
              const SizedBox(height: 8),
              const Text('Options for the next message', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Disappears', style: TextStyle(color: p.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in const [('never', 'Never'), ('view_once', 'View once'), ('1h', 'After 1 hour'), ('24h', 'After 24 hours'), ('7d', 'After 7 days')])
                    ChoiceChip(
                      label: Text(e.$2),
                      selected: _draft.expiry == e.$1,
                      showCheckmark: false,
                      onSelected: (_) => _draft.update(expiry: e.$1),
                    ),
                ],
              ),
              if (_level == MessageVisibility.public) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.download_outlined),
                  title: const Text('Allow saving'),
                  subtitle: const Text('The other person can download photos and files'),
                  value: _draft.allowDownload,
                  onChanged: (v) => _draft.update(allowDownload: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.screenshot_outlined),
                  title: const Text('Allow screenshots'),
                  value: _draft.allowScreenshot,
                  onChanged: (v) => _draft.update(allowScreenshot: v),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_off_outlined),
                title: const Text('Send silently'),
                subtitle: const Text('No notification sound for the other person'),
                value: _draft.silent,
                onChanged: (v) => _draft.update(silent: v),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context, _level)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelCard(BuildContext context, MessageVisibility v) {
    final p = context.palette;
    final info = _levels[v]!;
    final selected = v == _level;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? p.activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.allowChange ? () => setState(() => _level = v) : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? context.colors.primary : p.divider, width: selected ? 1.6 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(v.icon, color: selected ? context.colors.primary : null),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: v.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            TextSpan(text: '  -  ${info.$1}', style: TextStyle(color: p.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? context.colors.primary : p.textMuted),
                  ],
                ),
                const SizedBox(height: 6),
                Text(info.$2, style: TextStyle(color: p.textSecondary, height: 1.35)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in info.$3) _Tag(text: a, allowed: true),
                    for (final b in info.$4) _Tag(text: b, allowed: false),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.allowed});

  final String text;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    final color = allowed ? context.palette.success : context.palette.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(allowed ? Icons.check : Icons.close, size: 13, color: color),
          const SizedBox(width: 3),
          Text(allowed ? text : 'No $text', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
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
