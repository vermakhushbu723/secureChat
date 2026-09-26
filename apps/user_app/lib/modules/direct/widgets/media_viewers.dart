import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/core.dart';

Future<void> openExternal(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) context.showSnack('Could not open file');
}

/// Full screen, zoomable image.
class ImageViewerPage extends StatelessWidget {
  const ImageViewerPage({super.key, required this.url, this.title});

  final String url;
  final String? title;

  static Future<void> open(BuildContext context, String url, {String? title}) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ImageViewerPage(url: url, title: title),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title ?? 'Photo'),
        actions: [
          IconButton(
            tooltip: 'Open / download',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => openExternal(context, url),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.network(
            url,
            loadingBuilder: (_, child, p) => p == null ? child : const CircularProgressIndicator(color: Colors.white),
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}

/// Full screen video player with play / pause and seek bar.
class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key, required this.url});

  final String url;

  static Future<void> open(BuildContext context, String url) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => VideoPlayerPage(url: url)));

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final VideoPlayerController _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
          _controller.play();
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
    _controller.addListener(() => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _controller.value;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Video'),
        actions: [
          IconButton(
            tooltip: 'Open / download',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => openExternal(context, widget.url),
          ),
        ],
      ),
      body: Center(
        child: _failed
            ? const Text('This video cannot be played here', style: TextStyle(color: Colors.white70))
            : !v.isInitialized
            ? const CircularProgressIndicator(color: Colors.white)
            : GestureDetector(
                onTap: () => v.isPlaying ? _controller.pause() : _controller.play(),
                child: AspectRatio(
                  aspectRatio: v.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      if (!v.isPlaying) const Icon(Icons.play_circle_fill, color: Colors.white70, size: 72),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: VideoProgressIndicator(_controller, allowScrubbing: true),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
