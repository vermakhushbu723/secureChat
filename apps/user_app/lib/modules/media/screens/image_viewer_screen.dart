import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/widgets/media_viewers.dart' show openExternal;
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../widgets/dark_viewer_scaffold.dart';

/// Public image of a group message. Protected images use the secure viewer.
class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, this.messageId});

  final String? messageId;

  @override
  Widget build(BuildContext context) {
    final id = messageId;
    if (id == null) return const Scaffold(body: EmptyState(icon: Icons.image_not_supported_outlined, title: 'No image', message: 'Open an image from a chat.'));
    return LoginGate(
      title: 'Photo',
      child: AsyncView<GroupMessage>(load: () => GroupRepository.message(id), builder: (context, m, reload) => _Viewer(m: m, reload: reload)),
    );
  }
}

class _Viewer extends StatelessWidget {
  const _Viewer({required this.m, required this.reload});

  final GroupMessage m;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final url = m.media?.fullUrl;
    if (m.media?.secure == true && m.media?.fileId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pushReplacement(AppRoutes.secureFileViewerOf(m.media!.fileId!)));
    }
    return DarkViewerScaffold(
      title: m.isMine ? 'You' : m.senderName,
      subtitle: '${formatListTime(m.createdAt)}, ${formatClock(m.createdAt)}',
      actions: [
        IconButton(
          icon: Icon(m.starred ? Icons.star : Icons.star_border),
          tooltip: m.starred ? 'Unstar' : 'Star',
          onPressed: () async {
            await runAction(context, () => GroupRepository.star(m.id, !m.starred), done: m.starred ? 'Unstarred' : 'Starred');
            await reload();
          },
        ),
        if (m.permissions.canForward)
          IconButton(icon: const Icon(Icons.shortcut), tooltip: 'Forward', onPressed: () => context.push(AppRoutes.forwardSelectionOf(m.groupId, preselect: m.id))),
        PopupMenuButton<String>(
          iconColor: Colors.white,
          onSelected: context.push,
          itemBuilder: (_) => [
            PopupMenuItem(value: AppRoutes.mediaGalleryOf(m.groupId), child: const Text('All media')),
            PopupMenuItem(value: AppRoutes.messageInfoOf(m.groupId, m.id), child: const Text('Message info')),
          ],
        ),
      ],
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: url == null
              ? const Icon(Icons.image_outlined, size: 96, color: Colors.white38)
              : Image.network(
                  url,
                  loadingBuilder: (_, child, p) => p == null ? child : const CircularProgressIndicator(color: Colors.white),
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, size: 96, color: Colors.white38),
                ),
        ),
      ),
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                [if (m.text.isNotEmpty) m.text, m.visibility.label].join(' - '),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ViewerAction(
                    icon: m.permissions.allowDownload ? Icons.download_outlined : Icons.file_download_off_outlined,
                    label: 'Save',
                    onTap: () => m.permissions.allowDownload && url != null
                        ? openExternal(context, url)
                        : context.showSnack('The sender turned off downloads for this photo'),
                  ),
                  ViewerAction(
                    icon: Icons.link,
                    label: 'Copy link',
                    onTap: () {
                      if (url == null) return;
                      Clipboard.setData(ClipboardData(text: url));
                      context.showSnack('Link copied');
                    },
                  ),
                  ViewerAction(icon: Icons.info_outline, label: 'Info', onTap: () => context.push(AppRoutes.messageInfoOf(m.groupId, m.id))),
                  ViewerAction(icon: Icons.delete_outline, label: 'Delete', onTap: () => context.push(AppRoutes.messageOptionsOf(m.groupId, m.id))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ViewerAction extends StatelessWidget {
  const ViewerAction({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
