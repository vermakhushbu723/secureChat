import 'dart:async';

import 'package:file_picker/file_picker.dart';

import '../../../core/core.dart';
import '../data/direct_models.dart';
import '../data/direct_repository.dart';
import '../widgets/dm_avatar.dart';
import 'direct_list_screen.dart';

/// Search messages inside one chat (server side, full text + substring).
class DirectSearchScreen extends StatefulWidget {
  const DirectSearchScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<DirectSearchScreen> createState() => _DirectSearchScreenState();
}

class _DirectSearchScreenState extends State<DirectSearchScreen> {
  Timer? _debounce;
  String _q = '';
  bool _loading = false;
  List<DmMessage> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = v.trim();
      setState(() => _q = q);
      if (q.isEmpty) return setState(() => _results = []);
      setState(() => _loading = true);
      try {
        final r = await DirectRepository.search(widget.conversationId, q);
        if (mounted && q == _q) setState(() => _results = r);
      } on ApiException catch (e) {
        if (mounted) context.showSnack(e.message);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: _changed,
          decoration: const InputDecoration(hintText: 'Search messages', border: InputBorder.none, filled: false),
        ),
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _results.isEmpty
                  ? EmptyState(
                      icon: Icons.search,
                      title: _q.isEmpty ? 'Search this chat' : 'No messages found',
                      message: _q.isEmpty ? 'Type a word from a message.' : 'Try another word.',
                    )
                  : ListView(
                      children: [
                        for (final m in _results)
                          ListTile(
                            leading: Icon(m.isMine ? Icons.north_east : Icons.south_west, size: 18),
                            title: _Highlight(text: previewOf(m), query: _q),
                            subtitle: Text(
                              '${m.isMine ? 'You' : 'Them'}  •  ${formatListTime(m.createdAt)} ${formatClock(m.createdAt)}',
                            ),
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

class _Highlight extends StatelessWidget {
  const _Highlight({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final i = text.toLowerCase().indexOf(query.toLowerCase());
    if (query.isEmpty || i < 0) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: text.substring(i, i + query.length),
            style: TextStyle(
              backgroundColor: context.palette.warning.withValues(alpha: 0.4),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: text.substring(i + query.length)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// All starred messages across 1-to-1 chats.
class StarredMessagesScreen extends StatefulWidget {
  const StarredMessagesScreen({super.key});

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  late Future<List<({DmMessage message, DmUser? peer})>> _future = DirectRepository.starred();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Starred messages')),
      body: ResponsiveBody(
        child: FutureBuilder(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) return EmptyState(icon: Icons.error_outline, title: 'Error', message: '${snap.error}');
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final items = snap.data!;
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.star_border,
                title: 'No starred messages',
                message: 'Long press a message and tap Star to find it here later.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _future = DirectRepository.starred());
                await _future;
              },
              child: ListView(
                children: [
                  for (final (:message, :peer) in items)
                    ListTile(
                      leading: peer == null
                          ? const AppAvatar(icon: Icons.person)
                          : DmAvatar.user(peer, size: 42, showOnline: false),
                      title: Text(message.isMine ? 'You → ${peer?.name ?? ''}' : peer?.name ?? ''),
                      subtitle: Text(previewOf(message), maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Text(formatListTime(message.createdAt), style: const TextStyle(fontSize: 12)),
                      onTap: () => context.openDetail(AppRoutes.directChatOf(message.conversationId)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Archived chats (long press a chat to unarchive).
class ArchivedChatsScreen extends StatefulWidget {
  const ArchivedChatsScreen({super.key});

  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  List<DmConversation>? _items;
  String? _error;
  StreamSubscription<dynamic>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    // Re-read when a chat gets (un)archived from this or another device.
    _sub = SocketService.instance.on('conversation:updated').listen((_) => _load());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final page = await DirectRepository.conversations(archived: true);
      if (mounted) setState(() => _items = page.items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('Archived')),
      body: ResponsiveBody(
        maxWidth: 760,
        child: _error != null
            ? EmptyState(icon: Icons.error_outline, title: 'Error', message: _error!)
            : items == null
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? const EmptyState(
                icon: Icons.archive_outlined,
                title: 'No archived chats',
                message: 'Long press a chat and choose Archive.',
              )
            : ListView(children: [for (final c in items) ConversationTile(conversation: c)]),
      ),
    );
  }
}

/// Last seen / read receipt privacy, profile photo & about, blocked contacts.
class DirectSettingsScreen extends StatefulWidget {
  const DirectSettingsScreen({super.key});

  @override
  State<DirectSettingsScreen> createState() => _DirectSettingsScreenState();
}

class _DirectSettingsScreenState extends State<DirectSettingsScreen> {
  late Future<List<DmUser>> _blocked = DirectRepository.blockedUsers();
  bool _busy = false;

  Future<void> _update(Map<String, dynamic> patch, String done) async {
    setState(() => _busy = true);
    try {
      await AuthService.instance.updateProfile(patch);
      if (mounted) context.showSnack(done);
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePhoto() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;
    setState(() => _busy = true);
    try {
      final media = await DirectRepository.upload(await files.first.readAsBytes(), files.first.name);
      await _update({'avatarUrl': media.thumbUrl ?? media.url}, 'Profile photo updated');
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editAbout(String current) async {
    final c = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About'),
        content: TextField(controller: c, maxLength: 140, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    c.dispose();
    if (value != null) await _update({'about': value}, 'About updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat privacy')),
      body: ValueListenableBuilder<AuthUser?>(
        valueListenable: AuthService.instance.user,
        builder: (context, me, _) {
          if (me == null) return const SizedBox.shrink();
          return ResponsiveBody(
            child: ListView(
              children: [
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      DmAvatar(name: me.name, avatarUrl: me.avatarUrl, size: 104),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          color: Colors.white,
                          icon: const Icon(Icons.photo_camera, size: 18),
                          onPressed: _busy ? null : _changePhoto,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(me.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                GroupedCard(
                  children: [
                    AppTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: me.about,
                      onTap: () => _editAbout(me.about),
                    ),
                  ],
                ),
                const SectionHeader('Privacy'),
                GroupedCard(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.access_time),
                      title: const Text('Show last seen & online'),
                      subtitle: const Text('When off, people see no last seen time for you'),
                      value: me.lastSeenVisible,
                      onChanged: _busy
                          ? null
                          : (v) => _update({
                              'privacy': {'lastSeen': v ? 'everyone' : 'nobody'},
                            }, 'Saved'),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.done_all),
                      title: const Text('Read receipts'),
                      subtitle: const Text('When off, senders do not see blue ticks from you'),
                      value: me.readReceipts,
                      onChanged: _busy
                          ? null
                          : (v) => _update({
                              'privacy': {'readReceipts': v},
                            }, 'Saved'),
                    ),
                  ],
                ),
                const SectionHeader('Blocked contacts'),
                FutureBuilder<List<DmUser>>(
                  future: _blocked,
                  builder: (context, snap) {
                    final users = snap.data;
                    if (users == null) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (users.isEmpty) {
                      return const Padding(padding: EdgeInsets.all(16), child: Text('No blocked contacts'));
                    }
                    return GroupedCard(
                      children: [
                        for (final u in users)
                          ListTile(
                            leading: DmAvatar.user(u, size: 40, showOnline: false),
                            title: Text(u.name),
                            trailing: TextButton(
                              onPressed: () async {
                                await DirectRepository.unblock(u.id);
                                setState(() => _blocked = DirectRepository.blockedUsers());
                              },
                              child: const Text('Unblock'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
