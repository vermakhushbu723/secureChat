import 'package:video_player/video_player.dart';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/widgets/media_viewers.dart' show openExternal;
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../widgets/dark_viewer_scaffold.dart';
import 'image_viewer_screen.dart' show ViewerAction;

/// Public video of a group message (protected videos use the secure viewer).
class VideoViewerScreen extends StatelessWidget {
  const VideoViewerScreen({super.key, this.messageId});

  final String? messageId;

  @override
  Widget build(BuildContext context) {
    final id = messageId;
    if (id == null) return const Scaffold(body: EmptyState(icon: Icons.videocam_off_outlined, title: 'No video', message: 'Open a video from a chat.'));
    return LoginGate(
      title: 'Video',
      child: AsyncView<GroupMessage>(load: () => GroupRepository.message(id), builder: (context, m, _) => _VideoView(m: m)),
    );
  }
}

class _VideoView extends StatefulWidget {
  const _VideoView({required this.m});

  final GroupMessage m;

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final url = widget.m.media?.fullUrl;
    if (widget.m.media?.secure == true && widget.m.media?.fileId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pushReplacement(AppRoutes.secureFileViewerOf(widget.m.media!.fileId!)));
      return;
    }
    if (url == null) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = c;
    c.initialize().then((_) {
      if (mounted) setState(() {});
      c.play();
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
    c.addListener(() => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => formatDuration(d.inSeconds);

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final c = _controller;
    final v = c?.value;
    return DarkViewerScaffold(
      title: m.isMine ? 'You' : m.senderName,
      subtitle: '${formatListTime(m.createdAt)}, ${formatClock(m.createdAt)}  |  ${m.visibility.label}',
      actions: [
        if (m.permissions.canForward)
          IconButton(icon: const Icon(Icons.shortcut), tooltip: 'Forward', onPressed: () => context.push(AppRoutes.forwardSelectionOf(m.groupId, preselect: m.id))),
      ],
      body: Center(
        child: _failed
            ? const Text('This video cannot be played here', style: TextStyle(color: Colors.white70))
            : v == null || !v.isInitialized
            ? const CircularProgressIndicator(color: Colors.white)
            : GestureDetector(
                onTap: () => v.isPlaying ? c.pause() : c.play(),
                child: AspectRatio(
                  aspectRatio: v.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(c!),
                      if (!v.isPlaying) const Icon(Icons.play_circle_fill, color: Colors.white70, size: 72),
                    ],
                  ),
                ),
              ),
      ),
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c != null && v != null && v.isInitialized) ...[
                VideoProgressIndicator(c, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.white)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(v.volume == 0 ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                      onPressed: () => c.setVolume(v.volume == 0 ? 1 : 0),
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: () => c.seekTo(v.position - const Duration(seconds: 10)),
                    ),
                    IconButton(
                      icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      onPressed: () => v.isPlaying ? c.pause() : c.play(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () => c.seekTo(v.position + const Duration(seconds: 10)),
                    ),
                    const Spacer(),
                    Text('${_fmt(v.position)} / ${_fmt(v.duration)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ViewerAction(
                    icon: m.permissions.allowDownload ? Icons.download_outlined : Icons.file_download_off_outlined,
                    label: 'Save',
                    onTap: () => m.permissions.allowDownload && m.media?.fullUrl != null
                        ? openExternal(context, m.media!.fullUrl!)
                        : context.showSnack('The sender turned off downloads for this video'),
                  ),
                  ViewerAction(icon: Icons.info_outline, label: 'Info', onTap: () => context.push(AppRoutes.messageInfoOf(m.groupId, m.id))),
                  ViewerAction(icon: Icons.more_horiz, label: 'Options', onTap: () => context.push(AppRoutes.messageOptionsOf(m.groupId, m.id))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
