import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/screens/direct_list_screen.dart' show ConversationTile;
import '../../direct/state/conversations_controller.dart';
import '../../groups/data/group_models.dart';
import '../../groups/state/groups_controller.dart';
import '../../groups/widgets/group_tile.dart';

/// Chats tab (WhatsApp style): groups and 1-to-1 chats in one list, newest
/// first, pinned on top. Search on top and filters All / Unread / Groups / Personal.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Filter { all, unread, groups, personal }

/// One row of the combined list.
sealed class _Chat {
  const _Chat();
  String get key;
  DateTime? get at;
  bool get pinned;
  int get unread;
  bool matches(String q);
}

class _GroupChat extends _Chat {
  const _GroupChat(this.g);
  final GroupSummary g;
  @override
  String get key => 'g${g.id}';
  @override
  DateTime? get at => g.lastMessageAt;
  @override
  bool get pinned => g.pinned;
  @override
  int get unread => g.unreadCount;
  @override
  bool matches(String q) =>
      g.name.toLowerCase().contains(q) || (g.lastMessage?.preview(AuthService.instance.userId).toLowerCase().contains(q) ?? false);
}

class _DirectChat extends _Chat {
  const _DirectChat(this.c);
  final DmConversation c;
  @override
  String get key => 'd${c.id}';
  @override
  DateTime? get at => c.lastMessageAt;
  @override
  bool get pinned => c.pinned;
  @override
  int get unread => c.unreadCount;
  @override
  bool matches(String q) => c.peer.name.toLowerCase().contains(q) || (c.lastMessage?.text.toLowerCase().contains(q) ?? false);
}

class _HomeScreenState extends State<HomeScreen> {
  final _groups = GroupsController.instance;
  final _direct = ConversationsController.instance;
  final _scroll = ScrollController();
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _direct.loadMore();
    });
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() => Future.wait([_groups.load(), _direct.load()]);

  List<_Chat> _rows() {
    final q = _search.text.trim().toLowerCase();
    final rows = <_Chat>[
      if (_filter != _Filter.personal) ..._groups.items.map(_GroupChat.new),
      if (_filter != _Filter.groups) ..._direct.items.where((c) => !c.archived).map(_DirectChat.new),
    ].where((r) => (_filter != _Filter.unread || r.unread > 0) && (q.isEmpty || r.matches(q))).toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    rows.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return (b.at ?? epoch).compareTo(a.at ?? epoch);
    });
    return rows;
  }

  void _newChat() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetTile(icon: Icons.person_add_alt_1_outlined, title: 'New chat', subtitle: 'Message someone privately', route: AppRoutes.newDirectChat),
            _SheetTile(icon: Icons.group_add_outlined, title: 'New group', subtitle: 'Create a group', route: AppRoutes.createGroup),
            _SheetTile(icon: Icons.link, title: 'Join group with link', subtitle: 'Paste an invite link or code', route: AppRoutes.joinGroup),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: AppStrings.appName,
      child: ListenableBuilder(
        listenable: Listenable.merge([_groups, _direct]),
        builder: (context, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _groups.ensureStarted();
            _direct.ensureStarted();
          });
          return _scaffold(context);
        },
      ),
    );
  }

  Widget _scaffold(BuildContext context) {
    final p = context.palette;
    final rows = _rows();
    final unreadChats = [..._groups.items.where((g) => g.unreadCount > 0), ..._direct.items.where((c) => !c.archived && c.unreadCount > 0)].length;
    final loading = (_groups.loading && _groups.items.isEmpty) || (_direct.loading && _direct.items.isEmpty);
    final error = _groups.error ?? _direct.error;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text(AppStrings.appName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.group_add_outlined), tooltip: 'New group', onPressed: () => context.push(AppRoutes.createGroup)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (r) => r == AppRoutes.settings ? context.openDetail(r) : context.push(r),
            itemBuilder: (_) => const [
              PopupMenuItem(value: AppRoutes.createGroup, child: Text('New group')),
              PopupMenuItem(value: AppRoutes.newDirectChat, child: Text('New chat')),
              PopupMenuItem(value: AppRoutes.joinGroup, child: Text('Join with link')),
              PopupMenuItem(value: AppRoutes.starredMessages, child: Text('Starred messages')),
              PopupMenuItem(value: AppRoutes.archivedChats, child: Text('Archived chats')),
              PopupMenuItem(value: AppRoutes.settings, child: Text('Settings')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-chats',
        tooltip: 'New chat',
        onPressed: _newChat,
        child: const Icon(Icons.add_comment_outlined),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, size: 22),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(icon: const Icon(Icons.close, size: 20), onPressed: _search.clear),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _FilterChip(label: 'All', selected: _filter == _Filter.all, onTap: () => setState(() => _filter = _Filter.all)),
                    _FilterChip(
                      label: unreadChats > 0 ? 'Unread $unreadChats' : 'Unread',
                      selected: _filter == _Filter.unread,
                      onTap: () => setState(() => _filter = _Filter.unread),
                    ),
                    _FilterChip(label: 'Groups', selected: _filter == _Filter.groups, onTap: () => setState(() => _filter = _Filter.groups)),
                    _FilterChip(label: 'Personal', selected: _filter == _Filter.personal, onTap: () => setState(() => _filter = _Filter.personal)),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _SocketStatus()),
            if (error != null)
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: InfoBanner(icon: Icons.cloud_off, message: error))),
            if (loading)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
            else if (rows.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: _search.text.isNotEmpty
                      ? 'No results'
                      : switch (_filter) {
                          _Filter.unread => 'No unread chats',
                          _Filter.groups => 'No groups yet',
                          _Filter.personal => 'No personal chats yet',
                          _Filter.all => 'No chats yet',
                        },
                  message: _search.text.isNotEmpty ? 'No chat matches "${_search.text.trim()}".' : 'Tap the button below to start a chat or create a group.',
                ),
              )
            else
              SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => switch (rows[i]) {
                  _GroupChat(:final g) => SelectedHighlight(
                    key: ValueKey('g${g.id}'),
                    location: AppRoutes.groupChatOf(g.id),
                    child: GroupTile(group: g, onTap: () => context.openDetail(AppRoutes.groupChatOf(g.id))),
                  ),
                  _DirectChat(:final c) => ConversationTile(key: ValueKey('d${c.id}'), conversation: c),
                },
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 13, color: p.textMuted),
                    const SizedBox(width: 6),
                    Text('Your personal messages are secured', style: TextStyle(fontSize: 12, color: p.textMuted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// WhatsApp filter pill: outlined when off, green tint when on.
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        color: selected ? p.activeBg : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: selected ? Colors.transparent : p.divider)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? (dark ? AppColors.activeBg : AppColors.primaryDark) : p.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({required this.icon, required this.title, required this.subtitle, required this.route});

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: AppColors.primary, foregroundColor: Colors.white, child: Icon(icon, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        context.push(route);
      },
    );
  }
}

class _SocketStatus extends StatelessWidget {
  const _SocketStatus();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SocketService.instance.connected,
      builder: (context, connected, _) => connected
          ? const SizedBox.shrink()
          : const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 4), child: InfoBanner(icon: Icons.sync, message: 'Connecting...')),
    );
  }
}
