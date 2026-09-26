import '../../../core/core.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onTap,
    this.onLongPress,
    this.showSender = true,
    this.maxWidthFactor = 0.7,
  });

  final ChatMessage message;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showSender;
  final double maxWidthFactor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mine = message.isMine;
    final bg = mine ? p.bubbleOut : p.bubbleIn;
    final fg = mine ? p.bubbleOutText : p.bubbleInText;
    final sub = mine ? fg.withValues(alpha: 0.75) : p.textMuted;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: LayoutBuilder(
          builder: (context, c) => ConstrainedBox(
            constraints: BoxConstraints(maxWidth: (c.maxWidth * maxWidthFactor).clamp(0, 520)),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: bg,
                // Sent 16/16/4/16, received 16/16/16/4 with a 1px border.
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
                border: mine ? null : Border.all(color: p.bubbleInBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender: display (starting) name only - never number or ID.
                  if (showSender && !mine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        message.senderName,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: fg),
                      ),
                    ),
                  if (message.isForwarded && !message.isDeleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shortcut, size: 14, color: sub),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              message.forwardCount > 4 ? 'Forwarded many times' : 'Forwarded',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: sub),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.replyTo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: fg, width: 3)),
                      ),
                      child: Text(
                        message.replyTo!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: sub),
                      ),
                    ),
                  _content(context, fg, sub),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!message.isDeleted && message.visibility != MessageVisibility.public) ...[
                        SecurityBadge(message.visibility, compact: true, color: sub),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            message.visibility.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: sub),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(message.time, style: TextStyle(fontSize: 11, color: sub)),
                      if (mine && !message.isDeleted) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.done_all, size: 15, color: sub),
                      ],
                      if (onLongPress != null && !message.isDeleted)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: onLongPress,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.more_vert, size: 16, color: sub),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Color fg, Color sub) {
    if (message.isDeleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 16, color: sub),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'This message was deleted',
              style: TextStyle(fontStyle: FontStyle.italic, color: sub),
            ),
          ),
        ],
      );
    }
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.text,
          style: TextStyle(color: fg, fontSize: 14, height: 20 / 14),
        );
      case MessageType.image:
      case MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: 240,
              decoration: BoxDecoration(color: fg.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      message.isProtected
                          ? Icons.lock_outline
                          : message.type == MessageType.image
                          ? Icons.image_outlined
                          : Icons.play_circle_outline,
                      size: 44,
                      color: sub,
                    ),
                  ),
                  if (message.isProtected)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10,
                      child: Text(
                        'Tap to open in secure viewer',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: sub, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(message.text, style: TextStyle(color: fg)),
          ],
        );
      case MessageType.document:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: fg.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                message.isProtected ? Icons.enhanced_encryption_outlined : Icons.description_outlined,
                color: fg,
                size: 30,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fileName ?? 'Document',
                      style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${message.fileSize ?? ''}${message.isProtected ? '  |  Opens in app only' : ''}',
                      style: TextStyle(color: sub, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case MessageType.voice:
        return SizedBox(
          width: 220,
          child: Row(
            children: [
              Icon(Icons.play_arrow_rounded, color: fg, size: 32),
              Expanded(
                child: Row(
                  children: List.generate(
                    22,
                    (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: 6.0 + (i * 7 % 18),
                        decoration: BoxDecoration(color: sub, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(message.duration ?? '0:00', style: TextStyle(color: sub, fontSize: 12)),
            ],
          ),
        );
      case MessageType.location:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 240,
              height: 120,
              child: MapPlaceholder(radius: 8, pins: [MapPin(dx: 0.5, dy: 0.6, label: 'Live', isMe: true)]),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share_location, size: 16, color: fg),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(message.text, style: TextStyle(color: fg)),
                ),
              ],
            ),
          ],
        );
    }
  }
}

/// Small date / system pill shown in the chat stream.
class ChatDatePill extends StatelessWidget {
  const ChatDatePill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(8)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
        ),
      ),
    );
  }
}
