import 'dart:async';

import '../../../core/core.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';

/// App-wide group list: realtime last message, unread counts, typing,
/// membership changes, join requests and delivery receipts.
class GroupsController extends ChangeNotifier {
  GroupsController._();

  static final instance = GroupsController._();

  /// Snack bars for group events anywhere in the app (set by the app).
  static GlobalKey<ScaffoldMessengerState>? messengerKey;

  final List<GroupSummary> _items = [];
  final Map<String, Map<String, (String, String)>> _typing = {}; // groupId -> userId -> (name, kind)
  final Map<String, Timer> _typingTimers = {};
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _reloadDebounce;

  GroupStats stats = const GroupStats();
  bool loading = false;
  String? error;
  String? _startedFor;

  /// Group chat currently on screen (its messages don't count as unread).
  String? openGroupId;

  List<GroupSummary> get items => List.unmodifiable(_items);
  int get totalUnread => _items.fold(0, (s, g) => s + (g.muted ? 0 : g.unreadCount));

  GroupSummary? byId(String id) => _items.where((g) => g.id == id).firstOrNull;

  /// "Rahul is typing..." for the chat list / header.
  String? typingLabel(String groupId) {
    final t = _typing[groupId];
    if (t == null || t.isEmpty) return null;
    final (name, kind) = t.values.first;
    final more = t.length > 1 ? ' +${t.length - 1}' : '';
    return kind == 'recording' ? '$name$more is recording...' : '$name$more is typing...';
  }

  void ensureStarted() {
    final uid = AuthService.instance.userId;
    if (uid == null || _startedFor == uid) return;
    _stop();
    _startedFor = uid;
    final ws = SocketService.instance;
    _subs.addAll([
      ws.on('ready').listen((_) => load()),
      ws.on('group:message:new').listen(_onMessage),
      ws.on('group:message:updated').listen(_onUpdated),
      ws.on('group:read').listen((j) => _patch(j['groupId'] as String, (g) => g.copyWith(unreadCount: (j['unreadCount'] as num).toInt()))),
      for (final e in const ['group:updated', 'group:me', 'group:joined', 'group:member:joined', 'group:member:left', 'group:cleared'])
        ws.on(e).listen((_) => scheduleReload()),
      ws.on('group:removed').listen(_onRemoved),
      ws.on('group:typing').listen(_onTyping),
      ws.on('group:join_request').listen((j) => _snack('${j['displayName'] ?? 'Someone'} wants to join ${j['groupName'] ?? 'your group'}')),
      ws.on('group:request:declined').listen((j) => _snack('Your request to join ${j['groupName'] ?? 'the group'} was declined')),
    ]);
    AuthService.instance.user.addListener(_onAuthChanged);
    load();
  }

  void _onAuthChanged() {
    if (AuthService.instance.userId != null) return;
    _stop();
    _items.clear();
    stats = const GroupStats();
    notifyListeners();
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
      final results = await Future.wait([GroupRepository.groups(), GroupRepository.stats()]);
      _items
        ..clear()
        ..addAll(results[0] as List<GroupSummary>);
      stats = results[1] as GroupStats;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 350), load);
  }

  void remove(String groupId) {
    _items.removeWhere((g) => g.id == groupId);
    notifyListeners();
  }

  void _patch(String id, GroupSummary Function(GroupSummary) fn) {
    final i = _items.indexWhere((g) => g.id == id);
    if (i < 0) return;
    _items[i] = fn(_items[i]);
    _sort();
    notifyListeners();
  }

  void _sort() {
    _items.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return (b.lastMessageAt ?? DateTime(1970)).compareTo(a.lastMessageAt ?? DateTime(1970));
    });
  }

  void _snack(String text) {
    messengerKey?.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  // -------------------------------------------------------------- events
  void _onMessage(Map<String, dynamic> j) {
    final m = GroupMessage.fromJson(j);
    final g = byId(m.groupId);
    if (g == null) return scheduleReload();
    final incoming = !m.isMine && !m.isSystem;
    // Every message that reaches this device is delivered (✓✓ for the sender).
    if (!m.isMine) GroupRepository.markDelivered(m.groupId, m.id);
    _typing[m.groupId]?.remove(m.senderId);
    final bump = incoming && openGroupId != m.groupId;
    _patch(
      m.groupId,
      (g) => g.copyWith(
        lastMessage: GroupLastMessage(
          id: m.id,
          senderId: m.senderId,
          senderName: m.isSystem ? null : m.senderName,
          type: m.type,
          text: m.isProtected && !m.isSystem ? '🔒 ${m.previewText}' : m.previewText,
          createdAt: m.createdAt,
        ),
        lastMessageAt: m.createdAt,
        unreadCount: bump ? g.unreadCount + 1 : null,
      ),
    );
    if (bump && !g.muted && !m.silent) _snack('${g.name} - ${m.senderName}: ${m.previewText}');
  }

  void _onUpdated(Map<String, dynamic> j) {
    final m = GroupMessage.fromJson(j);
    final g = byId(m.groupId);
    if (g?.lastMessage?.id != m.id) return;
    _patch(
      m.groupId,
      (g) => g.copyWith(
        lastMessage: GroupLastMessage(
          id: m.id,
          senderId: m.senderId,
          senderName: m.senderName,
          type: m.type,
          text: m.previewText,
          deleted: m.deleted,
          createdAt: m.createdAt,
        ),
      ),
    );
  }

  void _onRemoved(Map<String, dynamic> j) {
    final id = j['groupId'] as String;
    final g = byId(id);
    remove(id);
    final reason = j['reason'];
    if (g != null && reason == 'removed') _snack('You were removed from ${g.name}');
    if (g != null && reason == 'deleted') _snack('${g.name} was deleted');
    scheduleReload();
  }

  void _onTyping(Map<String, dynamic> j) {
    final gid = j['groupId'] as String;
    final uid = j['userId'] as String;
    final key = '$gid:$uid';
    _typingTimers.remove(key)?.cancel();
    if (j['isTyping'] == true) {
      (_typing[gid] ??= {})[uid] = ('${j['displayName'] ?? 'Someone'}', '${j['kind'] ?? 'text'}');
      _typingTimers[key] = Timer(const Duration(seconds: 6), () {
        _typing[gid]?.remove(uid);
        notifyListeners();
      });
    } else {
      _typing[gid]?.remove(uid);
    }
    notifyListeners();
  }
}
