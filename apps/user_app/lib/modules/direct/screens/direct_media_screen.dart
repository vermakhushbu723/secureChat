import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';
import '../data/direct_models.dart';
import '../data/direct_repository.dart';
import '../widgets/media_viewers.dart';
import '../widgets/voice_player.dart';

/// Media | Docs | Audio | Links shared in one chat.
class DirectMediaScreen extends StatelessWidget {
  const DirectMediaScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media, links and docs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Media'),
              Tab(text: 'Docs'),
              Tab(text: 'Audio'),
              Tab(text: 'Links'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final kind in const ['media', 'docs', 'audio', 'links'])
              _MediaTab(conversationId: conversationId, kind: kind),
          ],
        ),
      ),
    );
  }
}

class _MediaTab extends StatefulWidget {
  const _MediaTab({required this.conversationId, required this.kind});

  final String conversationId;
  final String kind;

  @override
  State<_MediaTab> createState() => _MediaTabState();
}

class _MediaTabState extends State<_MediaTab> with AutomaticKeepAliveClientMixin {
  late final Future<List<DmMessage>> _future = DirectRepository.media(widget.conversationId, widget.kind);

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<DmMessage>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) return EmptyState(icon: Icons.error_outline, title: 'Error', message: '${snap.error}');
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.perm_media_outlined,
            title: 'Nothing here yet',
            message: 'Shared items appear here.',
          );
        }
        return switch (widget.kind) {
          'media' => GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final m = items[i];
              final video = m.type == DmType.video;
              return GestureDetector(
                onTap: () => video
                    ? VideoPlayerPage.open(context, m.media!.fullUrl)
                    : ImageViewerPage.open(context, m.media!.fullUrl),
                child: video
                    ? Container(
                        color: Colors.black87,
                        child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                      )
                    : Image.network(m.media!.previewUrl, fit: BoxFit.cover),
              );
            },
          ),
          'docs' => ListView(
            children: [
              for (final m in items)
                ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined, size: 32),
                  title: Text(m.media?.name ?? 'File'),
                  subtitle: Text('${formatBytes(m.media?.size ?? 0)}  •  ${formatListTime(m.createdAt)}'),
                  onTap: () => openExternal(context, m.media!.fullUrl),
                ),
            ],
          ),
          'audio' => ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final m in items)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: VoicePlayer(
                      url: m.media!.fullUrl,
                      duration: m.media!.duration,
                      color: context.colors.onSurface,
                      isVoice: m.type == DmType.voice,
                    ),
                  ),
                ),
            ],
          ),
          _ => ListView(
            children: [
              for (final m in items)
                for (final link in RegExp(r'https?://[^\s]+').allMatches(m.text).map((x) => x.group(0)!))
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(m.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
                  ),
            ],
          ),
        };
      },
    );
  }
}
