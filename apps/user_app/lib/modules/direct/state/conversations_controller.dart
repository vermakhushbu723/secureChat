import 'dart:async';

import '../../../core/core.dart';
import '../data/direct_models.dart';
import '../data/direct_repository.dart';

/// App-wide state of the 1-to-1 chat list. Lives as long as the session and
/// keeps the list, unread badges, presence and typing in sync over the socket.
class ConversationsController extends ChangeNotifier {
  ConversationsController._();

  static final instance = ConversationsController._();

  /// Shows "new message" banners anywhere in the app.
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  final List<DmConversation> _items = [];
  final Map<String, String> _typing = {}; // conversationId -> 'text' | 'recording'
  final Map<String, Timer> _typingTimers = {};
  final List<StreamSubscription<dynamic>> _subs = [];

  bool loading = false;
  String? error;
  String? _nextCursor;
  bool _loadingMore = false;
  String? _startedFor;

  /// Chat currently on screen: its messages do not bump the unread counter.
  String? openConversationId;

  List<DmConversation> get items => List.unmodifiable(_items);
  bool get hasMore => _nextCursor != null;
  int get totalUnread => _items.fold(0, (s, c) => s + (c.muted ? 0 : c.unreadCount));
  String? typingIn(String conversationId) => _typing[conversationId];

  DmConversation? byId(String id) {
    for (final c in _items) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Idempotent. Restarts automatically when another account logs in.
  void ensureStarted() {
    final uid = AuthService.instance.userId;
    if (uid == null || _startedFor == uid) return;
    _stop();
    _startedFor = uid;
    final ws = SocketService.instance;
    _subs.addAll([
      ws.on('ready').listen((_) => load()),
      ws.on('message:new').listen(_onMessage),
      ws.on('message:updated').listen(_onMessageUpdated),
      ws.on('message:status').listen(_onStatus),
      ws.on('conversation:updated').listen((j) => upsert(DmConversation.fromJson(j))),
      ws
          .on('conversation:read')
          .listen(
            (j) => _patch(
              j['conversationId'] as String,
              (c) => c.copyWith(unreadCount: (j['unreadCount'] as num).toInt()),
            ),
          ),
      ws
          .on('conversation:cleared')
          .listen(
            (j) => _patch(j['conversationId'] as String, (c) => c.copyWith(clearLastMessage: true, unreadCount: 0)),
          ),
      ws.on('conversation:removed').listen((j) => remove(j['conversationId'] as String)),
      ws.on('presence').listen(_onPresence),
      ws.on('typing').listen(_onTyping),
      ws.on('user:blocked').listen((j) {
        for (final c in _items.where((c) => c.peer.id == j['userId']).toList()) {
          _patch(c.id, (c) => c.copyWith(isBlocked: j['blocked'] == true));
        }
      }),
    ]);
    AuthService.instance.user.addListener(_onAuthChanged);
    load();
  }

  void _onAuthChanged() {
    if (AuthService.instance.userId == null) {
      _stop();
      _items.clear();
      notifyListeners();
    }
  }

  void _stop() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    AuthService.instance.user.removeListener(_onAuthChanged);
    _startedFor = null;
  }

  Future<void> load() async {
    if (!AuthService.instance.isLoggedIn) return;
    loading = _items.isEmpty;
    error = null;
    notifyListeners();
    try {
      final page = await DirectRepository.conversations();
      _items
        ..clear()
        ..addAll(page.items);
      _nextCursor = page.nextCursor;
      _sort();
      unawaited(DirectRepository.subscribePresence(_items.map((c) => c.peer.id).toList()).catchError((_) {}));
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    _loadingMore = true;
    try {
      final page = await DirectRepository.conversations(cursor: cursor);
      for (final c in page.items) {
        if (byId(c.id) == null) _items.add(c);
      }
      _nextCursor = page.nextCursor;
      _sort();
      notifyListeners();
    } finally {
      _loadingMore = false;
    }
  }

  void upsert(DmConversation c) {
    _items.removeWhere((e) => e.id == c.id);
    if (!c.archived) _items.add(c);
    _sort();
    notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void _patch(String id, DmConversation Function(DmConversation) fn) {
    final i = _items.indexWhere((c) => c.id == id);
    if (i < 0) return;
    _items[i] = fn(_items[i]);
    _sort();
    notifyListeners();
  }

  void _sort() {
    _items.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      final at = a.lastMessageAt ?? DateTime(1970);
      final bt = b.lastMessageAt ?? DateTime(1970);
      return bt.compareTo(at);
    });
  }

  // ------------------------------------------------------------ socket events
  Future<void> _onMessage(Map<String, dynamic> json) async {
    final m = DmMessage.fromJson(json);
    final incoming = !m.isMine;
    // Every message that reaches this device counts as delivered (✓✓).
    if (incoming) DirectRepository.markDelivered(m.conversationId, m.id);

    final existing = byId(m.conversationId);
    if (existing == null) {
      try {
        upsert(await DirectRepository.conversation(m.conversationId));
      } on ApiException {
        return;
      }
    } else {
      final bump = incoming && openConversationId != m.conversationId;
      _patch(
        m.conversationId,
        (c) => c.copyWith(
          lastMessage: DmLastMessage.of(m),
          lastMessageAt: m.createdAt,
          unreadCount: bump ? c.unreadCount + 1 : null,
        ),
      );
    }
    _typing.remove(m.conversationId);

    final conv = byId(m.conversationId);
    if (incoming && conv != null && !conv.muted && openConversationId != m.conversationId) {
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${conv.peer.name}: ${previewOf(m)}', maxLines: 2, overflow: TextOverflow.ellipsis),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    }
  }

  void _onMessageUpdated(Map<String, dynamic> json) {
    final m = DmMessage.fromJson(json);
    final c = byId(m.conversationId);
    if (c?.lastMessage?.id != m.id) return;
    _patch(
      m.conversationId,
      (c) => c.copyWith(
        lastMessage: c.lastMessage!.copyWith(text: previewOf(m), deleted: m.deleted),
      ),
    );
  }

  void _onStatus(Map<String, dynamic> j) {
    final c = byId(j['conversationId'] as String);
    final last = c?.lastMessage;
    if (c == null || last == null || last.senderId != AuthService.instance.userId) return;
    if (last.id.compareTo(j['upToMessageId'] as String) > 0) return;
    final status = statusOf(j['status'] as String?);
    if (status.index <= last.status.index) return;
    _patch(c.id, (c) => c.copyWith(lastMessage: last.copyWith(status: status)));
  }

  void _onPresence(Map<String, dynamic> j) {
    final uid = j['userId'] as String;
    final online = j['online'] == true;
    final lastSeen = j['lastSeenAt'] == null ? null : DateTime.tryParse('${j['lastSeenAt']}')?.toLocal();
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].peer.id != uid) continue;
      _items[i] = _items[i].copyWith(
        peer: _items[i].peer.copyWith(online: online, lastSeenAt: lastSeen),
      );
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void _onTyping(Map<String, dynamic> j) {
    final id = j['conversationId'] as String;
    _typingTimers.remove(id)?.cancel();
    if (j['isTyping'] == true) {
      _typing[id] = j['kind'] as String? ?? 'text';
      // Safety net if the "stop" event is lost.
      _typingTimers[id] = Timer(const Duration(seconds: 6), () {
        _typing.remove(id);
        notifyListeners();
      });
    } else {
      _typing.remove(id);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- actions
  Future<void> setPinned(DmConversation c, bool pinned) async =>
      upsert(await DirectRepository.updateSettings(c.id, pinned: pinned));

  Future<void> setMuted(DmConversation c, bool muted) async =>
      upsert(await DirectRepository.updateSettings(c.id, muteSeconds: muted ? -1 : 0));

  Future<void> setArchived(DmConversation c, bool archived) async =>
      upsert(await DirectRepository.updateSettings(c.id, archived: archived));

  Future<void> deleteChat(DmConversation c) async {
    await DirectRepository.deleteChat(c.id);
    remove(c.id);
  }
}
