import 'dart:async';

import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/widgets/voice_player.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';

/// Secure viewer for Private / Highly Protected files.
/// Secure File Token -> Authenticated App -> Permission Check -> Decrypt/Stream -> Viewer.
/// No download, save, share, open-with, copy or print. Dynamic watermark on top.
class SecureFileViewerScreen extends StatelessWidget {
  const SecureFileViewerScreen({super.key, this.fileId});

  final String? fileId;

  @override
  Widget build(BuildContext context) {
    final id = fileId;
    if (id == null) {
      return const Scaffold(body: EmptyState(icon: Icons.enhanced_encryption_outlined, title: 'No file', message: 'Open a protected file from a chat.'));
    }
    return LoginGate(title: 'Secure Viewer', child: _SecureViewer(fileId: id));
  }
}

class _SecureViewer extends StatefulWidget {
  const _SecureViewer({required this.fileId});

  final String fileId;

  @override
  State<_SecureViewer> createState() => _SecureViewerState();
}

class _SecureViewerState extends State<_SecureViewer> {
  FileTokenData? _token;
  ApiException? _error;
  DateTime? _openedAt;
  Duration _left = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // No screenshots / screen recording while a protected file is open (Android).
    ScreenGuard.protect();
    _open();
  }

  @override
  void dispose() {
    _timer?.cancel();
    ScreenGuard.release();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() {
      _error = null;
      _token = null;
    });
    try {
      final t = await GroupRepository.fileToken(widget.fileId);
      if (!mounted) return;
      _timer?.cancel();
      _openedAt = DateTime.now();
      _left = Duration(seconds: t.expiresIn);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final left = Duration(seconds: t.expiresIn) - DateTime.now().difference(_openedAt!);
        if (!mounted) return;
        setState(() => _left = left.isNegative ? Duration.zero : left);
        if (left.isNegative) _timer?.cancel();
      });
      setState(() => _token = t);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _blocked(String action, String label) {
    GroupRepository.fileEvent(widget.fileId, action);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.block),
        title: Text('$label blocked'),
        content: const Text('This file is protected by the sender. It can only be viewed inside the secure viewer. The attempt has been logged.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final t = _token;
    final expired = t != null && _left == Duration.zero;
    return Scaffold(
      backgroundColor: context.palette.surfaceAlt,
      appBar: AppBar(
        // Only what the viewer needs: sender, date & time, file name, description, "Secure File".
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t == null ? 'Opening secure file...' : (t.senderName.isEmpty ? 'Protected file' : t.senderName),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            if (t?.sentAt != null)
              Text('${formatListTime(t!.sentAt)}, ${formatClock(t.sentAt!)}', style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), tooltip: 'File details', onPressed: () => context.push(AppRoutes.filePermissionOf(widget.fileId))),
        ],
      ),
      body: Column(
        children: [
          if (t != null) _FileHeader(token: t),
          Expanded(child: _body(t, expired)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: context.colors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (final a in const [
                (Icons.file_download_off_outlined, 'Download', 'download_blocked'),
                (Icons.save_alt, 'Save', 'download_blocked'),
                (Icons.share_outlined, 'Share', 'share_blocked'),
                (Icons.open_in_new_off, 'Open with', 'open_with_blocked'),
                (Icons.print_disabled_outlined, 'Print', 'print_blocked'),
                (Icons.content_copy_outlined, 'Copy', 'copy_blocked'),
              ])
                Expanded(
                  child: InkWell(
                    onTap: () => _blocked(a.$3, a.$2),
                    child: Opacity(
                      opacity: 0.4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.$1),
                          const SizedBox(height: 2),
                          Text(a.$2, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
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

  Widget _body(FileTokenData? t, bool expired) {
    final e = _error;
    if (e != null) {
      return EmptyState(
        icon: e.code == 'FILE_REVOKED' || e.code == 'ALREADY_OPENED' ? Icons.delete_forever_outlined : Icons.lock_outline,
        title: switch (e.code) {
          'FILE_REVOKED' => 'File no longer available',
          'ALREADY_OPENED' => 'Already opened',
          'ACCESS_EXPIRED' => 'Access expired',
          'ADMINS_ONLY' => 'Admins only',
          'SUBSCRIPTION_REQUIRED' => 'Premium required',
          _ => 'Access denied',
        },
        message: e.message,
        action: e.code == 'SUBSCRIPTION_REQUIRED'
            ? FilledButton.icon(onPressed: () => context.push(AppRoutes.trialStatus), icon: const Icon(Icons.workspace_premium_outlined), label: const Text('Upgrade'))
            : TextButton.icon(onPressed: _open, icon: const Icon(Icons.refresh), label: const Text('Try again')),
      );
    }
    if (t == null) return const Center(child: CircularProgressIndicator());
    if (expired) {
      return EmptyState(
        icon: Icons.timer_off_outlined,
        title: 'Session expired',
        message: 'Secure tokens are valid for ${t.expiresIn ~/ 60} minutes. Reopen to request a new one.',
        action: FilledButton.icon(onPressed: _open, icon: const Icon(Icons.lock_open_outlined), label: const Text('Reopen')),
      );
    }
    final content = switch (t.kind) {
      'image' => InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Image.network(
            t.streamUrl,
            loadingBuilder: (_, child, p) => p == null ? child : const CircularProgressIndicator(),
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, size: 96),
          ),
        ),
      ),
      'video' => _SecureVideo(url: t.streamUrl),
      'audio' || 'voice' => Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(16)),
          child: VoicePlayer(url: t.streamUrl, color: context.colors.primary, isVoice: t.kind == 'voice'),
        ),
      ),
      _ when t.mimeType.startsWith('text/') || t.mimeType == 'application/json' => _SecureText(url: t.streamUrl),
      _ => _FileCard(t: t),
    };
    if (!t.watermark) return content;
    final now = DateTime.now();
    return WatermarkOverlay(
      name: t.watermarkName,
      userId: t.maskedId,
      timestamp: '${formatListTime(now)}  ${formatClock(now)}',
      child: content,
    );
  }
}

class _SecureVideo extends StatefulWidget {
  const _SecureVideo({required this.url});

  final String url;

  @override
  State<_SecureVideo> createState() => _SecureVideoState();
}

class _SecureVideoState extends State<_SecureVideo> {
  late final VideoPlayerController _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _c.initialize().then((_) => mounted ? setState(() {}) : null).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
    _c.addListener(() => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _c.value;
    if (_failed) return const Center(child: Text('This video cannot be played here'));
    if (!v.isInitialized) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () => v.isPlaying ? _c.pause() : _c.play(),
              child: AspectRatio(
                aspectRatio: v.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [VideoPlayer(_c), if (!v.isPlaying) const Icon(Icons.play_circle_fill, color: Colors.white70, size: 72)],
                ),
              ),
            ),
          ),
        ),
        VideoProgressIndicator(_c, allowScrubbing: true),
      ],
    );
  }
}

/// Text shown without selection so it cannot be copied.
class _SecureText extends StatelessWidget {
  const _SecureText({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Response<String>>(
      future: Dio().get<String>(url, options: Options(responseType: ResponseType.plain)),
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('Could not load this file'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ResponsiveBody(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(8)),
                child: Text(snap.data!.data ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.t});

  final FileTokenData t;

  @override
  Widget build(BuildContext context) {
    final ext = t.name.contains('.') ? t.name.split('.').last.toUpperCase() : 'FILE';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 180,
              decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8)]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(ext == 'PDF' ? Icons.picture_as_pdf_outlined : Icons.description_outlined, size: 56, color: context.colors.primary),
                  const SizedBox(height: 8),
                  Text(ext, style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('${formatBytes(t.size)}  |  ${t.mimeType}', style: TextStyle(color: context.palette.textSecondary)),
            const SizedBox(height: 16),
            const SizedBox(
              width: 360,
              child: InfoBanner(
                icon: Icons.info_outline,
                message: 'Inline preview for this format is not available. The file stays encrypted on the server and cannot be downloaded.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// File name, the sender's description (if any) and the "Secure File" badge.
class _FileHeader extends StatelessWidget {
  const _FileHeader({required this.token});

  final FileTokenData token;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      color: context.colors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insert_drive_file_outlined, size: 18, color: p.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text(token.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: p.activeBg, borderRadius: BorderRadius.circular(12)),
                child: const Text('🔒 Secure File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (token.caption.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(token.caption, style: TextStyle(color: p.textSecondary, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
