import '../../../core/core.dart';
import '../data/direct_models.dart';

/// Shows a view once message on top of the chat. Screenshots are blocked (Android)
/// and the content is gone once this overlay is closed.
Future<void> showViewOnce(BuildContext context, DmMessage m) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierColor: Colors.black,
    builder: (_) => Dialog.fullscreen(backgroundColor: Colors.black, child: _ViewOnce(message: m)),
  );
}

class _ViewOnce extends StatefulWidget {
  const _ViewOnce({required this.message});

  final DmMessage message;

  @override
  State<_ViewOnce> createState() => _ViewOnceState();
}

class _ViewOnceState extends State<_ViewOnce> {
  @override
  void initState() {
    super.initState();
    ScreenGuard.protect();
  }

  @override
  void dispose() {
    ScreenGuard.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final media = m.media;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Close', onPressed: () => Navigator.of(context).pop()),
        title: const Text('View once'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: media != null && m.type == DmType.image && media.url.isNotEmpty
                  ? InteractiveViewer(maxScale: 5, child: Image.network(media.fullUrl, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64)))
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(m.text.isEmpty ? (media?.name ?? 'Message') : m.text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.5)),
                    ),
            ),
          ),
          if (media != null && m.text.isNotEmpty && m.type == DmType.image)
            Padding(padding: const EdgeInsets.all(16), child: Text(m.text, style: const TextStyle(color: Colors.white70))),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('This message can be viewed only once. It disappears when you close it.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
