import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/widgets/dm_bubble.dart' show MessageMenuButton, StatusTicks;
import '../../direct/widgets/linkified_text.dart';
import '../../direct/widgets/media_viewers.dart';
import '../../direct/widgets/voice_player.dart';
import '../../groups/data/group_models.dart';

const _linkOnIn = Color(0xFF53BDEB); // WhatsApp link blue, readable on both bubbles

/// Stable per-member name colour in group chats (like WhatsApp).
Color senderColor(String userId) {
  const colors = [
    Color(0xFF06CF9C), Color(0xFFFFA97A), Color(0xFF53BDEB), Color(0xFFFF72A1), Color(0xFFA5B337),
    Color(0xFFC792EA), Color(0xFFFFBC38), Color(0xFF25D366), Color(0xFFFC9775), Color(0xFF7F66FF),
  ];
  var h = 0;
  for (final c in userId.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return colors[h % colors.length];
}

/// One group chat bubble for any message type (and system events).
class GroupBubble extends StatelessWidget {
  const GroupBubble({
    super.key,
    required this.message,
    this.onMenu,
    this.onRetry,
    this.onOpenViewOnce,
    this.onReactionTap,
    this.showSender = true,
  });

  final GroupMessage message;
  final VoidCallback? onMenu;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenViewOnce;
  final VoidCallback? onReactionTap;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m.isSystem) return _SystemPill(m.text);
    final p = context.palette;
    final mine = m.isMine;
    final bg = mine ? p.bubbleOut : p.bubbleIn;
    final fg = mine ? p.bubbleOutText : p.bubbleInText;
    final sub = mine ? fg.withValues(alpha: 0.75) : p.textMuted;

    final bubble = LayoutBuilder(
      builder: (context, c) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: (c.maxWidth * 0.7).clamp(0, 560)),
        child: Container(
          margin: EdgeInsets.only(top: 3, bottom: m.reactions.isEmpty ? 3 : 22),
          padding: const EdgeInsets.fromLTRB(9, 6, 9, 5),
          decoration: BoxDecoration(
            color: bg,
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
              // Display (starting) name only - never phone / id.
              if (showSender && !mine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    m.senderName,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: senderColor(m.senderId)),
                  ),
                ),
              if (m.forwarded && !m.unavailable) _Forwarded(depth: m.forwardDepth, color: sub),
              if (m.replyTo != null && !m.unavailable) _ReplyQuote(reply: m.replyTo!, fg: fg, sub: sub),
              _Content(message: m, fg: fg, sub: sub, onOpenViewOnce: onOpenViewOnce),
              const SizedBox(height: 3),
              _Footer(message: m, sub: sub, onRetry: onRetry, onMenu: m.isPending ? null : onMenu),
            ],
          ),
        ),
      ),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: m.isPending ? null : onMenu,
        onSecondaryTap: m.isPending ? null : onMenu,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            bubble,
            if (m.reactions.isNotEmpty && !m.unavailable)
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

class _SystemPill extends StatelessWidget {
  const _SystemPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: context.palette.activeBg, borderRadius: BorderRadius.circular(10)),
        child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
      ),
    );
  }
}

class _Forwarded extends StatelessWidget {
  const _Forwarded({required this.depth, required this.color});

  final int depth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final many = depth >= 4;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(many ? Icons.fast_forward_rounded : Icons.shortcut, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              many ? 'Forwarded many times' : 'Forwarded',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.reply, required this.fg, required this.sub});

  final GroupReply reply;
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
          Text(mine ? 'You' : reply.senderName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: fg)),
          const SizedBox(height: 2),
          Text(reply.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: sub)),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.message, required this.fg, required this.sub, this.onOpenViewOnce});

  final GroupMessage message;
  final Color fg;
  final Color sub;
  final VoidCallback? onOpenViewOnce;

  Widget _italic(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: sub),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: TextStyle(fontStyle: FontStyle.italic, color: sub))),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m.deleted) return _italic(Icons.block, m.isMine ? 'You deleted this message' : 'This message was deleted');
    if (m.expired) return _italic(Icons.timer_off_outlined, 'This message expired');
    if (m.withheld) {
      if (m.withheldReason == 'admins_only') return _italic(Icons.admin_panel_settings_outlined, 'Protected file - admins only');
      if (m.withheldReason == 'opened') return _italic(Icons.visibility_off_outlined, 'Opened');
      return InkWell(
        onTap: onOpenViewOnce,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.looks_one_outlined, color: fg),
              const SizedBox(width: 8),
              Text(m.isMedia ? 'View once file - tap to open' : 'View once message - tap to view', style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    final textStyle = TextStyle(color: fg, fontSize: 14, height: 20 / 14);
    final caption = m.text.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 5),
            child: m.permissions.canCopy
                ? LinkifiedText(m.text, style: textStyle, linkColor: _linkOnIn)
                : Text(m.text, style: textStyle),
          );

    switch (m.type) {
      case 'text':
        return m.permissions.canCopy
            ? LinkifiedText(m.text, style: textStyle, linkColor: _linkOnIn)
            : Text(m.text, style: textStyle); // protected: plain, not selectable
      case 'image':
      case 'video':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [_Visual(message: m, fg: fg, sub: sub), ?caption],
        );
      case 'voice':
      case 'audio':
        if (m.media?.secure == true) return _SecureTile(message: m, fg: fg, sub: sub);
        if (m.media?.fullUrl == null) return _Uploading(message: m, fg: fg);
        return VoicePlayer(url: m.media!.fullUrl!, duration: m.media!.duration, color: fg, isVoice: m.type == 'voice');
      case 'file':
        return m.media?.secure == true ? _SecureTile(message: m, fg: fg, sub: sub) : _FileTile(message: m, fg: fg, sub: sub);
      case 'location':
        return _LocationCard(location: m.location!, fg: fg, sub: sub);
      case 'contact':
        return _ContactCard(contact: m.contact!, fg: fg, sub: sub, canCopy: m.permissions.canCopy);
      default:
        return Text(m.text, style: textStyle);
    }
  }
}

class _Uploading extends StatelessWidget {
  const _Uploading({required this.message, required this.fg});

  final GroupMessage message;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Icon(Icons.upload, color: fg),
          const SizedBox(width: 10),
          Expanded(child: LinearProgressIndicator(value: message.uploadProgress, color: fg)),
        ],
      ),
    );
  }
}

/// Image / video. Protected media never shows a preview - it opens in the secure viewer.
class _Visual extends StatelessWidget {
  const _Visual({required this.message, required this.fg, required this.sub});

  final GroupMessage message;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final media = m.media;
    final secure = media?.secure == true || (m.isPending && m.isProtected);
    final video = m.type == 'video';
    final w = media?.width;
    final h = media?.height;
    final ratio = (w != null && h != null && h > 0) ? (w / h).clamp(0.6, 1.8) : 4 / 3;

    Widget inner;
    if (secure) {
      inner = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            m.isPending
                ? CircularProgressIndicator(value: m.uploadProgress, color: sub)
                : Icon(Icons.lock_outline, size: 40, color: sub),
            const SizedBox(height: 6),
            Text(m.isPending ? 'Encrypting & uploading...' : 'Tap to open in secure viewer', style: TextStyle(color: sub, fontSize: 12)),
          ],
        ),
      );
    } else if (m.localBytes != null && media == null) {
      inner = Stack(
        fit: StackFit.expand,
        children: [
          if (!video) Image.memory(m.localBytes!, fit: BoxFit.cover) else const ColoredBox(color: Colors.black87),
          Center(child: CircularProgressIndicator(value: m.uploadProgress, color: Colors.white)),
        ],
      );
    } else if (video) {
      inner = Container(
        color: Colors.black87,
        child: Stack(
          children: [
            const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 56)),
            Positioned(
              left: 8,
              bottom: 6,
              child: Text(
                media?.duration != null ? formatDuration(media!.duration) : formatBytes(media?.size ?? 0),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    } else {
      inner = Image.network(
        media?.previewUrl ?? '',
        fit: BoxFit.cover,
        loadingBuilder: (_, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
      );
    }

    return GestureDetector(
      onTap: m.isPending
          ? null
          : () {
              if (secure && media?.fileId != null) {
                context.push(AppRoutes.secureFileViewerOf(media!.fileId!));
              } else {
                context.push(video ? AppRoutes.videoViewerOf(m.id) : AppRoutes.imageViewerOf(m.id));
              }
            },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 260,
          height: secure ? 150 : 260 / ratio,
          child: ColoredBox(color: fg.withValues(alpha: 0.08), child: inner),
        ),
      ),
    );
  }
}

/// Protected document / audio: opens only in the secure viewer.
class _SecureTile extends StatelessWidget {
  const _SecureTile({required this.message, required this.fg, required this.sub});

  final GroupMessage message;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    final media = message.media;
    return InkWell(
      onTap: media?.fileId == null ? null : () => context.push(AppRoutes.secureFileViewerOf(media!.fileId!)),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: fg.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(message.type == 'file' ? Icons.enhanced_encryption_outlined : Icons.lock_outline, color: fg, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media?.name ?? (message.type == 'file' ? 'Protected document' : 'Protected audio'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                  ),
                  Text('${formatBytes(media?.size ?? 0)}  |  Opens in app only', style: TextStyle(color: sub, fontSize: 12)),
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

  final GroupMessage message;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    final media = message.media;
    final name = media?.name ?? message.localName ?? 'Document';
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : 'FILE';
    return InkWell(
      onTap: media?.fullUrl == null ? null : () => context.push(AppRoutes.documentViewerOf(message.id)),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: fg.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(ext == 'PDF' ? Icons.picture_as_pdf_outlined : Icons.description_outlined, color: fg, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
                  if (message.isPending && media == null)
                    LinearProgressIndicator(value: message.uploadProgress, color: fg)
                  else
                    Text('$ext  |  ${formatBytes(media?.size ?? 0)}', style: TextStyle(color: sub, fontSize: 12)),
                ],
              ),
            ),
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
            const SizedBox(height: 120, child: MapPlaceholder(radius: 8, pins: [MapPin(dx: 0.5, dy: 0.55, label: 'Pin', isMe: true)])),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: fg),
                const SizedBox(width: 4),
                Expanded(child: Text(location.name ?? 'Shared location', style: TextStyle(color: fg, fontWeight: FontWeight.w600))),
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
  const _ContactCard({required this.contact, required this.fg, required this.sub, required this.canCopy});

  final DmContact contact;
  final Color fg;
  final Color sub;
  final bool canCopy;

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
                    Text(contact.name, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                    Text(contact.phone, style: TextStyle(color: sub, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (canCopy) ...[
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
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.message, required this.sub, this.onRetry, this.onMenu});

  final GroupMessage message;
  final Color sub;
  final VoidCallback? onRetry;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final m = message;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!m.unavailable && m.isProtected) ...[
          SecurityBadge(m.visibility, compact: true, color: sub),
          const SizedBox(width: 3),
          Flexible(
            child: Text(m.visibility.label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: sub)),
          ),
          const SizedBox(width: 6),
        ],
        if (!m.unavailable && m.permissions.expiresAt != null) ...[
          Tooltip(
            message: 'Disappears ${formatListTime(m.permissions.expiresAt)} ${formatClock(m.permissions.expiresAt!)}',
            child: Icon(Icons.timer_outlined, size: 13, color: sub),
          ),
          const SizedBox(width: 3),
        ],
        if (m.silent) ...[Icon(Icons.notifications_off_outlined, size: 13, color: sub), const SizedBox(width: 3)],
        if (m.starred) ...[Icon(Icons.star_rounded, size: 13, color: sub), const SizedBox(width: 3)],
        if (m.edited && !m.unavailable) ...[
          Text('Edited', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: sub)),
          const SizedBox(width: 5),
        ],
        Text(formatClock(m.createdAt), style: TextStyle(fontSize: 11, color: sub)),
        if (m.isMine && !m.unavailable) ...[const SizedBox(width: 3), StatusTicks(status: m.status, color: sub, onRetry: onRetry)],
        if (onMenu != null && !m.unavailable) MessageMenuButton(color: sub, onTap: onMenu!),
      ],
    );
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
        child: Text([for (final e in counts.entries) e.value > 1 ? '${e.key}${e.value}' : e.key].join(' '), style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
