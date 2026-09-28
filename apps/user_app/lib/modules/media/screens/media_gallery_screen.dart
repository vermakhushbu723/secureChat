import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/state/groups_controller.dart';

/// Media, documents and protected files shared in a group.
class MediaGalleryScreen extends StatelessWidget {
  const MediaGalleryScreen({super.key, this.groupId});

  final String? groupId;

  @override
  Widget build(BuildContext context) => LoginGate(title: 'Media & Files', child: _Gallery(initialGroupId: groupId));
}

class _Gallery extends StatefulWidget {
  const _Gallery({this.initialGroupId});

  final String? initialGroupId;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  late String? _groupId = widget.initialGroupId;

  @override
  void initState() {
    super.initState();
    final list = GroupsController.instance;
    list.ensureStarted();
    if (_groupId == null && list.items.isNotEmpty) _groupId = list.items.first.id;
    list.addListener(_onGroups);
  }

  void _onGroups() {
    final items = GroupsController.instance.items;
    if (_groupId == null && items.isNotEmpty && mounted) setState(() => _groupId = items.first.id);
  }

  @override
  void dispose() {
    GroupsController.instance.removeListener(_onGroups);
    super.dispose();
  }

  void _open(GroupMessage m) {
    final media = m.media;
    if (media?.secure == true && media?.fileId != null) {
      context.push(AppRoutes.secureFileViewerOf(media!.fileId!));
      return;
    }
    switch (m.type) {
      case 'image':
        context.push(AppRoutes.imageViewerOf(m.id));
      case 'video':
        context.push(AppRoutes.videoViewerOf(m.id));
      default:
        context.push(AppRoutes.documentViewerOf(m.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = GroupsController.instance.items;
    final gid = _groupId;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media & Files'),
          bottom: const TabBar(tabs: [Tab(text: 'Media'), Tab(text: 'Docs'), Tab(text: 'Protected')]),
        ),
        body: Column(
          children: [
            if (widget.initialGroupId == null && groups.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DropdownButtonFormField<String>(
                  initialValue: gid,
                  isExpanded: true,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.groups_outlined)),
                  items: [for (final g in groups) DropdownMenuItem(value: g.id, child: Text(g.name, overflow: TextOverflow.ellipsis))],
                  onChanged: (v) => setState(() => _groupId = v),
                ),
              ),
            Expanded(
              child: gid == null
                  ? const EmptyState(icon: Icons.perm_media_outlined, title: 'No groups', message: 'Join or create a group to see shared media.')
                  : TabBarView(
                      key: ValueKey(gid),
                      children: [
                        _Tab(groupId: gid, kind: 'media', onOpen: _open),
                        _Tab(groupId: gid, kind: 'docs', onOpen: _open),
                        _Tab(groupId: gid, kind: 'protected', onOpen: _open),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({required this.groupId, required this.kind, required this.onOpen});

  final String groupId;
  final String kind;
  final void Function(GroupMessage) onOpen;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AsyncView<List<GroupMessage>>(
      load: () => GroupRepository.media(widget.groupId, widget.kind),
      builder: (context, items, reload) {
        if (items.isEmpty) {
          return EmptyState(
            icon: widget.kind == 'protected' ? Icons.enhanced_encryption_outlined : Icons.perm_media_outlined,
            title: 'Nothing here yet',
            message: widget.kind == 'protected' ? 'Private and Highly Protected files appear here.' : 'Shared items appear here.',
          );
        }
        if (widget.kind == 'media') {
          return RefreshIndicator(
            onRefresh: reload,
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 160, mainAxisSpacing: 4, crossAxisSpacing: 4),
              itemCount: items.length,
              itemBuilder: (_, i) => _Thumb(item: items[i], onTap: () => widget.onOpen(items[i])),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: reload,
          child: ResponsiveBody(
            child: ListView(
              children: [
                if (widget.kind == 'protected')
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: InfoBanner(icon: Icons.enhanced_encryption_outlined, message: 'Protected files open only in the secure viewer. Download and external share are disabled.'),
                  ),
                for (final m in items) _FileRow(item: m, onTap: () => widget.onOpen(m)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item, required this.onTap});

  final GroupMessage item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final media = item.media;
    final secure = media?.secure == true;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: context.palette.surfaceAlt,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!secure && item.type == 'image' && media?.previewUrl != null)
              Image.network(media!.previewUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined))
            else
              Center(child: Icon(item.type == 'video' ? Icons.videocam_outlined : Icons.image_outlined, size: 36, color: context.palette.textSecondary)),
            if (item.type == 'video')
              Positioned(
                left: 6,
                bottom: 6,
                child: Row(
                  children: [
                    Icon(Icons.videocam, size: 14, color: context.palette.textSecondary),
                    const SizedBox(width: 2),
                    Text(formatDuration(media?.duration), style: TextStyle(fontSize: 11, color: context.palette.textSecondary)),
                  ],
                ),
              ),
            if (secure) Positioned(right: 6, top: 6, child: Icon(Icons.lock, size: 16, color: context.colors.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.item, required this.onTap});

  final GroupMessage item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final media = item.media;
    final secure = media?.secure == true;
    return ListTile(
      onTap: onTap,
      leading: AppAvatar(icon: secure ? Icons.enhanced_encryption_outlined : iconForMessageType(item.sharedType), size: 44),
      title: Text(media?.name ?? item.previewText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${formatBytes(media?.size ?? 0)}  |  ${formatListTime(item.createdAt)}  |  ${item.senderName}'),
      trailing: secure
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(item.visibility.label, tone: Tone.dark),
                if (media?.fileId != null)
                  IconButton(
                    tooltip: 'File permissions',
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    onPressed: () => context.push(AppRoutes.filePermissionOf(media!.fileId!)),
                  ),
              ],
            )
          : const Icon(Icons.chevron_right),
    );
  }
}
