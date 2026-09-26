import '../../../core/core.dart';
import '../data/direct_models.dart';
import '../data/direct_repository.dart';
import '../state/conversations_controller.dart';
import '../widgets/dm_avatar.dart';
import '../widgets/media_viewers.dart';

/// Profile of the other person + chat settings (mute, block, clear, delete).
class DirectContactInfoScreen extends StatefulWidget {
  const DirectContactInfoScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<DirectContactInfoScreen> createState() => _DirectContactInfoScreenState();
}

class _DirectContactInfoScreenState extends State<DirectContactInfoScreen> {
  DmConversation? _conv;
  DmUser? _peer;
  List<DmMessage> _media = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final conv = await DirectRepository.conversation(widget.conversationId);
      final results = await Future.wait([
        DirectRepository.getUser(conv.peer.id),
        DirectRepository.media(conv.id, 'media'),
      ]);
      if (!mounted) return;
      setState(() {
        _conv = conv;
        _peer = results[0] as DmUser;
        _media = (results[1] as List<DmMessage>).take(12).toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _run(Future<void> Function() fn, String done) async {
    try {
      await fn();
      if (mounted) context.showSnack(done);
      await _load();
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conv = _conv;
    final peer = _peer;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.error_outline, title: 'Error', message: _error!),
      );
    }
    if (conv == null || peer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final list = ConversationsController.instance;
    final hidden = peer.isBlocked || conv.blockedMe;
    return Scaffold(
      appBar: AppBar(title: const Text('Contact info')),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: peer.avatarUrl == null
                    ? null
                    : () => ImageViewerPage.open(context, ApiConfig.mediaUrl(peer.avatarUrl!), title: peer.name),
                child: DmAvatar.user(peer, size: 120, showOnline: false),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(peer.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            ),
            if (peer.username != null)
              Center(
                child: Text('@${peer.username}', style: TextStyle(color: context.palette.textSecondary)),
              ),
            if (!hidden)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(lastSeenLabel(peer), style: TextStyle(color: context.palette.textSecondary)),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Action(icon: Icons.chat_bubble_outline, label: 'Message', onTap: () => context.pop()),
                _Action(
                  icon: Icons.search,
                  label: 'Search',
                  onTap: () => context.push(AppRoutes.directSearchOf(conv.id)),
                ),
                _Action(
                  icon: conv.muted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                  label: conv.muted ? 'Unmute' : 'Mute',
                  onTap: () => _run(() => list.setMuted(conv, !conv.muted), conv.muted ? 'Unmuted' : 'Muted'),
                ),
              ],
            ),
            if (peer.about.isNotEmpty)
              GroupedCard(
                children: [ListTile(title: Text(peer.about), subtitle: const Text('About'))],
              ),
            GroupedCard(
              children: [
                AppTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Media, links and docs',
                  onTap: () => context.push(AppRoutes.directMediaOf(conv.id)),
                ),
                if (_media.isNotEmpty)
                  SizedBox(
                    height: 88,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      children: [
                        for (final m in _media)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => m.type == DmType.video
                                  ? VideoPlayerPage.open(context, m.media!.fullUrl)
                                  : ImageViewerPage.open(context, m.media!.fullUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: m.type == DmType.video
                                    ? Container(
                                        width: 76,
                                        color: Colors.black87,
                                        child: const Icon(Icons.play_arrow, color: Colors.white),
                                      )
                                    : Image.network(m.media!.previewUrl, width: 76, height: 76, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                AppTile(
                  icon: Icons.star_border,
                  title: 'Starred messages',
                  onTap: () => context.push(AppRoutes.starredMessages),
                ),
              ],
            ),
            GroupedCard(
              children: [
                AppTile(
                  icon: Icons.archive_outlined,
                  title: conv.archived ? 'Unarchive chat' : 'Archive chat',
                  onTap: () =>
                      _run(() => list.setArchived(conv, !conv.archived), conv.archived ? 'Unarchived' : 'Archived'),
                ),
                AppTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear chat',
                  onTap: () async {
                    if (await context.confirm(
                      title: 'Clear chat?',
                      message: 'Messages are removed for you only.',
                      confirmLabel: 'Clear',
                      danger: true,
                    )) {
                      await _run(() => DirectRepository.clearChat(conv.id), 'Chat cleared');
                    }
                  },
                ),
                AppTile(
                  icon: Icons.block,
                  title: peer.isBlocked ? 'Unblock ${peer.name}' : 'Block ${peer.name}',
                  danger: true,
                  onTap: () async {
                    if (peer.isBlocked) return _run(() => DirectRepository.unblock(peer.id), 'Unblocked');
                    if (await context.confirm(
                      title: 'Block ${peer.name}?',
                      message: 'They will not be able to message you or see your online status.',
                      confirmLabel: 'Block',
                      danger: true,
                    )) {
                      await _run(() => DirectRepository.block(peer.id), 'Blocked');
                    }
                  },
                ),
                AppTile(
                  icon: Icons.thumb_down_outlined,
                  title: 'Report ${peer.name}',
                  danger: true,
                  onTap: () => context.push(AppRoutes.reportUserOf(peer.id)),
                ),
                AppTile(
                  icon: Icons.delete_outline,
                  title: 'Delete chat',
                  danger: true,
                  onTap: () async {
                    if (await context.confirm(
                      title: 'Delete chat?',
                      message: 'The chat is removed for you only.',
                      confirmLabel: 'Delete',
                      danger: true,
                    )) {
                      try {
                        await list.deleteChat(conv);
                        if (context.mounted) context.go(AppRoutes.directChats);
                      } on ApiException catch (e) {
                        if (context.mounted) context.showSnack(e.message);
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.palette.divider),
          ),
          child: Column(children: [Icon(icon), const SizedBox(height: 6), Text(label)]),
        ),
      ),
    );
  }
}
