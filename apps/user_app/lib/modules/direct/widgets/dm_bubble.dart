import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../data/direct_models.dart';
import 'linkified_text.dart';
import 'media_viewers.dart';
import 'voice_player.dart';

/// Read ticks: sky blue stays visible on the indigo sent bubble.
const _readBlue = Color(0xFF53BDEB);
const _linkOnIn = Color(0xFF53BDEB); // WhatsApp link blue, readable on both bubbles

/// One chat bubble for any message type.
class DmBubble extends StatelessWidget {
  const DmBubble({
    super.key,
    required this.message,
    required this.peerName,
    this.onLongPress,
    this.onRetry,
    this.onReactionTap,
    this.highlight = false,
  });

  final DmMessage message;
  final String peerName;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetry;
  final VoidCallback? onReactionTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final m = message;
    final mine = m.isMine;
    final sticker = m.type == DmType.sticker && !m.deleted;
    final bg = sticker ? Colors.transparent : (mine ? p.bubbleOut : p.bubbleIn);
    final fg = mine ? p.bubbleOutText : p.bubbleInText;
    // Timestamps: #9CA3AF on received, translucent white on sent (design system).
    final sub = mine ? fg.withValues(alpha: 0.75) : p.textMuted;

    final bubble = LayoutBuilder(
      builder: (context, c) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: (c.maxWidth * 0.7).clamp(0, 560)),
        child: Container(
          margin: EdgeInsets.only(top: 3, bottom: m.reactions.isEmpty ? 3 : 22),
          padding: sticker ? const EdgeInsets.all(4) : const EdgeInsets.fromLTRB(9, 6, 9, 5),
          decoration: BoxDecoration(
            color: highlight ? Color.alphaBlend(context.colors.primary.withValues(alpha: 0.15), bg) : bg,
            // WhatsApp shape: 8px corners, square corner on the sender side at the top.
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(mine ? 8 : 0),
              topRight: Radius.circular(mine ? 0 : 8),
              bottomLeft: const Radius.circular(8),
              bottomRight: const Radius.circular(8),
            ),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 1, offset: Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m.forwarded && !m.deleted) _Forwarded(count: m.forwardCount, color: sub),
              if (m.replyTo != null && !m.deleted) _ReplyQuote(reply: m.replyTo!, peerName: peerName, fg: fg, sub: sub),
              _Content(message: m, fg: fg, sub: sub),
              const SizedBox(height: 2),
              _Footer(message: m, sub: sub, onRetry: onRetry, onMenu: m.isPending ? null : onLongPress),
            ],
          ),
        ),
      ),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: m.isPending ? null : onLongPress,
        onSecondaryTap: m.isPending ? null : onLongPress, // right click on web / desktop
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            bubble,
            if (m.reactions.isNotEmpty && !m.deleted)
              Positioned(
                bottom: 0,
                right: mine ? 10 : null,
                left: mine ? null : 10,
                child: _Reactions(reactions: m.reactions, onTap: onReactionTap),
              ),
          ],
        ),
      ),
    );
  }
}

class _Forwarded extends StatelessWidget {
  const _Forwarded({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(count > 4 ? Icons.fast_forward_rounded : Icons.shortcut, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            count > 4 ? 'Forwarded many times' : 'Forwarded',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: color),
          ),
        ],
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.reply, required this.peerName, required this.fg, required this.sub});

  final DmReply reply;
  final String peerName;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    final mine = reply.senderId == AuthService.instance.userId;
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: fg, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mine ? 'You' : peerName,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: fg),
          ),
          const SizedBox(height: 2),
          Text(
            reply.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: sub),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.message, required this.fg, required this.sub});

  final DmMessage message;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m.deleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 16, color: sub),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              m.isMine ? 'You deleted this message' : 'This message was deleted',
              style: TextStyle(fontStyle: FontStyle.italic, color: sub),
            ),
          ),
        ],
      );
    }
    final caption = m.text.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 5),
            child: LinkifiedText(
              m.text,
              style: TextStyle(color: fg, fontSize: 14, height: 20 / 14),
              linkColor: _linkOnIn,
            ),
          );

    switch (m.type) {
      case DmType.text:
        return LinkifiedText(
          m.text,
          style: TextStyle(color: fg, fontSize: 14, height: 20 / 14),
          linkColor: _linkOnIn,
        );
      case DmType.image:
      case DmType.sticker:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ImageThumb(message: m, sticker: m.type == DmType.sticker),
            ?caption,
          ],
        );
      case DmType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _VideoThumb(message: m, fg: fg),
            ?caption,
          ],
        );
      case DmType.voice:
      case DmType.audio:
        if (m.media == null) return _Uploading(message: m, fg: fg, icon: Icons.mic);
        return VoicePlayer(
          url: m.media!.fullUrl,
          duration: m.media!.duration,
          color: fg,
          isVoice: m.type == DmType.voice,
        );
      case DmType.file:
        return _FileTile(message: m, fg: fg, sub: sub);
      case DmType.location:
        return _LocationCard(location: m.location!, fg: fg, sub: sub);
      case DmType.contact:
        return _ContactCard(contact: m.contact!, fg: fg, sub: sub);
    }
  }
}

class _Uploading extends StatelessWidget {
  const _Uploading({required this.message, required this.fg, required this.icon});

  final DmMessage message;
  final Color fg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: LinearProgressIndicator(value: message.uploadProgress, color: fg),
          ),
        ],
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.message, this.sticker = false});

  final DmMessage message;
  final bool sticker;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final media = m.media;
    final w = media?.width;
    final h = media?.height;
    final ratio = (w != null && h != null && h > 0) ? (w / h).clamp(0.6, 1.8) : 4 / 3;
    final size = sticker ? 140.0 : 260.0;

    Widget image;
    if (m.localBytes != null && media == null) {
      image = Image.memory(m.localBytes!, fit: BoxFit.cover);
    } else if (media != null) {
      image = Image.network(
        media.previewUrl,
        fit: sticker ? BoxFit.contain : BoxFit.cover,
        loadingBuilder: (_, child, p) =>
            p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
      );
    } else {
      image = const Center(child: Icon(Icons.image_outlined, size: 40));
    }

    return GestureDetector(
      onTap: media == null ? null : () => ImageViewerPage.open(context, media.fullUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          height: size / ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.black12, child: image),
              if (m.isPending && m.uploadProgress != null && m.uploadProgress! < 1)
                Center(
                  child: CircularProgressIndicator(value: m.uploadProgress, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoThumb extends StatelessWidget {
  const _VideoThumb({required this.message, required this.fg});

  final DmMessage message;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final media = message.media;
    return GestureDetector(
      onTap: media == null ? null : () => VideoPlayerPage.open(context, media.fullUrl),
      child: Container(
        width: 260,
        height: 160,
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: Stack(
          children: [
            Center(
              child: message.isPending
                  ? CircularProgressIndicator(value: message.uploadProgress, color: Colors.white)
                  : const Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
            ),
            Positioned(
              left: 8,
              bottom: 6,
              child: Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    media?.duration != null ? formatDuration(media!.duration) : formatBytes(media?.size ?? 0),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.message, required this.fg, required this.sub});

  final DmMessage message;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    final media = message.media;
    final name = media?.name ?? message.localName ?? 'File';
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : 'FILE';
    return InkWell(
      onTap: media == null ? null : () => openExternal(context, media.fullUrl),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: fg.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(ext == 'PDF' ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined, color: fg, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  if (message.isPending && media == null)
                    LinearProgressIndicator(value: message.uploadProgress, color: fg)
                  else
                    Text('$ext  •  ${formatBytes(media?.size ?? 0)}', style: TextStyle(color: sub, fontSize: 12)),
                ],
              ),
            ),
            if (media != null) Icon(Icons.download_rounded, color: sub),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location, required this.fg, required this.sub});

  final DmLocation location;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openExternal(context, location.mapsUrl),
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 120,
              child: MapPlaceholder(radius: 8, pins: [MapPin(dx: 0.5, dy: 0.55, label: 'Pin', isMe: true)]),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: fg),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location.name ?? 'Shared location',
                    style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Text(
              location.address ?? '${location.lat.toStringAsFixed(5)}, ${location.lng.toStringAsFixed(5)}',
              style: TextStyle(color: sub, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.fg, required this.sub});

  final DmContact contact;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(initials: initialsOf(contact.name), size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                    ),
                    Text(contact.phone, style: TextStyle(color: sub, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: sub.withValues(alpha: 0.3)),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: contact.phone));
              if (context.mounted) context.showSnack('Number copied');
            },
            icon: Icon(Icons.copy, size: 16, color: fg),
            label: Text('Copy number', style: TextStyle(color: fg)),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.message, required this.sub, this.onRetry, this.onMenu});

  final DmMessage message;
  final Color sub;
  final VoidCallback? onRetry;

  /// Opens the message actions (reply, react, edit, delete...).
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final m = message;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (m.starred) ...[Icon(Icons.star_rounded, size: 13, color: sub), const SizedBox(width: 3)],
        if (m.edited && !m.deleted) ...[
          Text(
            'Edited',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: sub),
          ),
          const SizedBox(width: 5),
        ],
        Text(formatClock(m.createdAt), style: TextStyle(fontSize: 11, color: sub)),
        if (m.isMine && !m.deleted) ...[
          const SizedBox(width: 3),
          StatusTicks(status: m.status, color: sub, onRetry: onRetry),
        ],
        if (onMenu != null) MessageMenuButton(color: sub, onTap: onMenu!),
      ],
    );
  }
}

/// 🕓 pending, ✓ sent, ✓✓ delivered, blue ✓✓ read, ⚠ failed (tap to retry).
class StatusTicks extends StatelessWidget {
  const StatusTicks({super.key, required this.status, required this.color, this.onRetry, this.size = 15});

  final DeliveryStatus status;
  final Color color;
  final VoidCallback? onRetry;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      DeliveryStatus.pending => Icon(Icons.schedule, size: size - 2, color: color),
      DeliveryStatus.sent => Icon(Icons.done, size: size, color: color),
      DeliveryStatus.delivered => Icon(Icons.done_all, size: size, color: color),
      DeliveryStatus.read => Icon(Icons.done_all, size: size, color: _readBlue),
      DeliveryStatus.failed => GestureDetector(
        onTap: onRetry,
        child: Icon(Icons.error_outline, size: size, color: context.palette.danger),
      ),
    };
  }
}

class _Reactions extends StatelessWidget {
  const _Reactions({required this.reactions, this.onTap});

  final List<DmReaction> reactions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.palette.divider),
        ),
        child: Text(
          [for (final e in counts.entries) e.value > 1 ? '${e.key}${e.value}' : e.key].join(' '),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

/// Small ⋮ in the bubble footer that opens the message actions menu
/// (long press / right click keep working too).
class MessageMenuButton extends StatelessWidget {
  const MessageMenuButton({super.key, required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Message options',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(Icons.more_vert, size: 16, color: color),
        ),
      ),
    );
  }
}
