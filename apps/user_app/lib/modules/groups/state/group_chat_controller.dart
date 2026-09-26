import 'dart:async';
import 'dart:typed_data';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../secure_message/state/message_draft.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import 'groups_controller.dart';

/// Result of a send attempt the UI must react to (content filter).
class SendBlocked {
  const SendBlocked({required this.code, required this.message, this.rule, this.warnings, this.maxWarnings});

  factory SendBlocked.from(ApiException e) => SendBlocked(
    code: e.code,
    message: e.message,
    rule: e.detailsMap['rule'] as String?,
    warnings: (e.detailsMap['warnings'] as num?)?.toInt(),
    maxWarnings: (e.detailsMap['maxWarnings'] as num?)?.toInt(),
  );

  final String code;
  final String message;
  final String? rule;
  final int? warnings;
  final int? maxWarnings;

  bool get isContent => code == 'CONTENT_BLOCKED';

  String get restrictionRoute => AppRoutes.contentRestrictionFor(rule ?? 'abuse', warnings: warnings, maxWarnings: maxWarnings);
}

/// State of one open group chat.
class GroupChatController extends ChangeNotifier {
  GroupChatController(this.groupId);

  final String groupId;
  final _list = GroupsController.instance;
  final List<StreamSubscription<dynamic>> _subs = [];

  GroupDetail? detail;
  final List<GroupMessage> messages = []; // oldest -> newest
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = false;
  String? error;
  String? removedReason; // removed | deleted | left

  GroupMessage? replyTo;
  GroupMessage? editing;

  final Map<String, (String, String)> typing = {}; // userId -> (name, kind)
  final Map<String, Timer> _typingTimers = {};
  bool _typingSent = false;
  DateTime _typingSentAt = DateTime(0);
  Timer? _typingStopTimer;
  String? _lastReadSent;
  bool _disposed = false;

  String get me => AuthService.instance.userId ?? '';
  bool get canSend => detail != null && detail!.me.canSend && removedReason == null && detail!.summary.isActive;
  bool get isAdmin => detail?.me.isAdmin ?? false;

  /// Security level the composer should send with (group mode can force it).
  MessageVisibility visibilityFor(MessageVisibility chosen) => switch (detail?.settings.messageMode) {
    'public' => MessageVisibility.public,
    'private' => MessageVisibility.private,
    _ => chosen,
  };

  String? get typingText {
    if (typing.isEmpty) return null;
    final (name, kind) = typing.values.first;
    final more = typing.length > 1 ? ' and ${typing.length - 1} more' : '';
    return kind == 'recording' ? '$name$more is recording audio...' : '$name$more is typing...';
  }

  // ============================================================ lifecycle
  Future<void> init() async {
    _list.openGroupId = groupId;
    final ws = SocketService.instance;
    bool mine(Map<String, dynamic> j) => j['groupId'] == groupId;
    _subs.addAll([
      ws.on('group:message:new').where(mine).listen((j) => _onNew(GroupMessage.fromJson(j))),
      ws.on('group:message:updated').where(mine).listen((j) => _onUpdated(GroupMessage.fromJson(j))),
      ws.on('group:message:removed').where(mine).listen((j) {
        messages.removeWhere((m) => m.id == j['messageId']);
        _notify();
      }),
      ws.on('group:status').where(mine).listen(_onStatus),
      ws.on('group:typing').where(mine).listen(_onTyping),
      for (final e in const ['group:updated', 'group:me', 'group:member:updated']) ws.on(e).where(mine).listen((_) => refreshDetail()),
      ws.on('group:cleared').where(mine).listen((_) {
        messages.clear();
        _notify();
      }),
      ws.on('group:removed').where(mine).listen((j) {
        removedReason = '${j['reason'] ?? 'removed'}';
        _notify();
      }),
      ws.on('ready').listen((_) => _resync()),
    ]);
    try {
      detail = await GroupRepository.detail(groupId);
      _notify();
      final page = await GroupRepository.messages(groupId);
      messages
        ..clear()
        ..addAll(page.items);
      hasMore = page.hasMore;
      markRead();
    } on ApiException catch (e) {
      error = e.message;
      if (e.code == 'NOT_MEMBER') removedReason = 'removed';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> refreshDetail() async {
    try {
      detail = await GroupRepository.detail(groupId);
      _notify();
    } on ApiException catch (e) {
      if (e.code == 'NOT_MEMBER') {
        removedReason ??= 'removed';
        _notify();
      }
    }
  }

  Future<void> _resync() async {
    final synced = messages.where((m) => !m.isPending);
    if (synced.isEmpty) return;
    try {
      var after = synced.last.id;
      while (true) {
        final page = await GroupRepository.messages(groupId, after: after, limit: 100);
        for (final m in page.items) {
          _onNew(m, fromSync: true);
        }
        if (!page.hasMore || page.items.isEmpty) break;
        after = page.items.last.id;
      }
      markRead();
      await refreshDetail();
    } on ApiException {
      // retried on the next reconnect
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || messages.isEmpty) return;
    loadingMore = true;
    _notify();
    try {
      final oldest = messages.firstWhere((m) => !m.isPending);
      final page = await GroupRepository.messages(groupId, before: oldest.id);
      messages.insertAll(0, page.items.where((m) => !messages.any((x) => x.id == m.id)));
      hasMore = page.hasMore;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loadingMore = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_typingSent) GroupRepository.typing(groupId, isTyping: false);
    _typingStopTimer?.cancel();
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    for (final s in _subs) {
      s.cancel();
    }
    if (_list.openGroupId == groupId) _list.openGroupId = null;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // =============================================================== events
  void _onNew(GroupMessage m, {bool fromSync = false}) {
    final byClient = messages.indexWhere((x) => x.clientMsgId.isNotEmpty && x.clientMsgId == m.clientMsgId);
    final byId = messages.indexWhere((x) => x.id == m.id);
    if (byClient >= 0) {
      messages[byClient] = _keepStatus(messages[byClient], m);
    } else if (byId >= 0) {
      messages[byId] = m;
    } else {
      messages.add(m);
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    typing.remove(m.senderId);
    if (!m.isMine && !fromSync) markRead();
    if (m.withheldReason == 'admins_only' && isAdmin) unawaited(_refetch(m.id));
    if (m.isSystem) unawaited(refreshDetail());
    _notify();
  }

  GroupMessage _keepStatus(GroupMessage old, GroupMessage fresh) =>
      old.status.index > fresh.status.index && old.status != DeliveryStatus.failed ? fresh.copyWith(status: old.status) : fresh;

  void _onUpdated(GroupMessage m) {
    final i = messages.indexWhere((x) => x.id == m.id);
    if (i < 0) return;
    // Room broadcasts carry no per-viewer data: keep my ticks and star.
    final old = messages[i];
    messages[i] = _keepStatus(old, m.isMine ? m : m.copyWith(starred: old.starred));
    if (m.withheldReason == 'admins_only' && isAdmin) unawaited(_refetch(m.id));
    _notify();
  }

  Future<void> _refetch(String id) async {
    try {
      final fresh = await GroupRepository.message(id);
      final i = messages.indexWhere((x) => x.id == id);
      if (i >= 0) messages[i] = fresh;
      _notify();
    } on ApiException {
      // keep withheld version
    }
  }

  void _onStatus(Map<String, dynamic> j) {
    final read = j['readUpTo'] as String?;
    final delivered = j['deliveredUpTo'] as String?;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (!m.isMine || m.isPending || m.isSystem) continue;
      final next = read != null && m.id.compareTo(read) <= 0
          ? DeliveryStatus.read
          : delivered != null && m.id.compareTo(delivered) <= 0
          ? DeliveryStatus.delivered
          : null;
      if (next != null && next.index > m.status.index) messages[i] = m.copyWith(status: next);
    }
    _notify();
  }

  void _onTyping(Map<String, dynamic> j) {
    final uid = j['userId'] as String;
    _typingTimers.remove(uid)?.cancel();
    if (j['isTyping'] == true) {
      typing[uid] = ('${j['displayName'] ?? 'Someone'}', '${j['kind'] ?? 'text'}');
      _typingTimers[uid] = Timer(const Duration(seconds: 6), () {
        typing.remove(uid);
        _notify();
      });
    } else {
      typing.remove(uid);
    }
    _notify();
  }

  // ============================================================== receipts
  void markRead() {
    for (final m in messages.reversed) {
      if (m.isMine || m.isPending) continue;
      if (_lastReadSent == m.id) return;
      _lastReadSent = m.id;
      GroupRepository.markRead(groupId, m.id);
      return;
    }
  }

  // ================================================================ typing
  void onComposerChanged(String text) {
    if (!canSend) return;
    _typingStopTimer?.cancel();
    if (text.trim().isEmpty) return setTyping(false);
    if (!_typingSent || DateTime.now().difference(_typingSentAt) > const Duration(seconds: 3)) setTyping(true);
    _typingStopTimer = Timer(const Duration(milliseconds: 2500), () => setTyping(false));
  }

  void setTyping(bool value, {String kind = 'text'}) {
    if (!value && !_typingSent) return;
    _typingSent = value;
    _typingSentAt = DateTime.now();
    GroupRepository.typing(groupId, isTyping: value, kind: kind);
  }

  // ================================================================ sending
  void setReply(GroupMessage? m) {
    replyTo = m;
    editing = null;
    _notify();
  }

  void startEdit(GroupMessage? m) {
    editing = m;
    replyTo = null;
    _notify();
  }

  GroupMessage _pending(String type, MessageVisibility visibility, {String text = '', Uint8List? bytes, String? name, DmLocation? location, DmContact? contact}) {
    final reply = replyTo;
    replyTo = null;
    final user = AuthService.instance.user.value;
    return GroupMessage(
      id: '',
      groupId: groupId,
      clientMsgId: newClientMsgId(),
      senderId: me,
      senderName: user?.name.split(' ').first ?? 'You',
      type: type,
      text: text,
      location: location,
      contact: contact,
      visibility: visibility,
      replyTo: reply == null ? null : GroupReply(id: reply.id, senderId: reply.senderId, senderName: reply.senderName, type: reply.type, text: reply.previewText),
      status: DeliveryStatus.pending,
      createdAt: DateTime.now(),
      localBytes: bytes,
      localName: name,
    );
  }

  /// Returns a [SendBlocked] when the server refused the message.
  Future<SendBlocked?> sendText(String raw, {required MessageVisibility visibility}) async {
    final text = raw.trim();
    if (text.isEmpty) return null;
    setTyping(false);
    final edit = editing;
    if (edit != null) {
      editing = null;
      _notify();
      try {
        _onUpdated(await GroupRepository.edit(edit.id, text));
        return null;
      } on ApiException catch (e) {
        return SendBlocked.from(e);
      }
    }
    final v = visibilityFor(visibility);
    return _deliver(_pending('text', v, text: text), {'type': 'text', 'text': text}, v);
  }

  Future<SendBlocked?> sendLocation(DmLocation location, {bool live = false}) {
    final v = visibilityFor(MessageVisibility.public);
    return _deliver(
      _pending('location', v, location: location),
      {'type': 'location', 'location': {...location.toJson(), 'live': live}},
      v,
    );
  }

  Future<SendBlocked?> sendContact(DmContact contact) {
    final v = visibilityFor(MessageVisibility.public);
    return _deliver(_pending('contact', v, contact: contact), {'type': 'contact', 'contact': contact.toJson()}, v);
  }

  /// Protected levels upload an encrypted file (no public URL).
  Future<SendBlocked?> sendFile(Uint8List bytes, String name, String type, {required MessageVisibility visibility, String caption = '', double? duration}) async {
    final v = visibilityFor(visibility);
    var m = _pending(type, v, text: caption, bytes: bytes, name: name);
    _upsertLocal(m);
    try {
      final media = await GroupRepository.upload(
        bytes,
        name,
        secure: v != MessageVisibility.public,
        kind: type == 'voice' ? 'voice' : null,
        duration: duration,
        onProgress: (p) {
          m = m.copyWith(uploadProgress: p);
          _upsertLocal(m);
        },
      );
      m = m.copyWith(media: media, uploadProgress: 1);
      return _deliver(m, {'type': type, 'text': caption, 'media': media.toSendJson()}, v);
    } on ApiException catch (e) {
      _upsertLocal(m.copyWith(status: DeliveryStatus.failed, error: e.message));
      return SendBlocked.from(e);
    }
  }

  Future<SendBlocked?> _deliver(GroupMessage m, Map<String, dynamic> payload, MessageVisibility v) async {
    final draft = MessageDraft.instance;
    _upsertLocal(m.copyWith(status: DeliveryStatus.pending));
    try {
      final saved = await GroupRepository.send({
        ...payload,
        ...draft.payload(v),
        'groupId': groupId,
        'clientMsgId': m.clientMsgId,
        if (m.replyTo != null) 'replyToId': m.replyTo!.id,
      });
      draft.resetAfterSend();
      _onNew(saved);
      return null;
    } on ApiException catch (e) {
      if (e.code == 'CONTENT_BLOCKED' || e.status == 403) {
        // Refused by policy: drop the bubble, the UI explains why.
        messages.removeWhere((x) => x.clientMsgId == m.clientMsgId);
        _notify();
      } else {
        _upsertLocal(m.copyWith(status: DeliveryStatus.failed, error: e.message));
      }
      return SendBlocked.from(e);
    }
  }

  void _upsertLocal(GroupMessage m) {
    final i = messages.indexWhere((x) => x.clientMsgId == m.clientMsgId);
    if (i >= 0) {
      if (!messages[i].isPending && m.isPending) return;
      messages[i] = m;
    } else {
      messages.add(m);
    }
    _notify();
  }

  Future<SendBlocked?> retry(GroupMessage m) async {
    if (m.status != DeliveryStatus.failed) return null;
    messages.removeWhere((x) => x.clientMsgId == m.clientMsgId);
    _notify();
    if (m.isMedia && m.localBytes != null) {
      return sendFile(m.localBytes!, m.localName ?? 'file', m.type, visibility: m.visibility, caption: m.text);
    }
    if (m.type == 'location' && m.location != null) return sendLocation(m.location!);
    if (m.type == 'contact' && m.contact != null) return sendContact(m.contact!);
    return sendText(m.text, visibility: m.visibility);
  }

  void discard(GroupMessage m) {
    messages.removeWhere((x) => x.clientMsgId == m.clientMsgId && x.isPending);
    _notify();
  }

  // ================================================================ actions
  Future<void> react(GroupMessage m, String emoji) async {
    final next = m.myReaction(me) == emoji ? null : emoji;
    _onUpdated(await GroupRepository.react(m.id, next));
  }

  Future<void> toggleStar(GroupMessage m) async => _onUpdated(await GroupRepository.star(m.id, !m.starred));

  Future<void> deleteForMe(GroupMessage m) async {
    await GroupRepository.delete(m.id, forEveryone: false);
    messages.removeWhere((x) => x.id == m.id);
    _notify();
  }

  /// View once: reveals the content one time (server records it).
  Future<GroupMessage> openViewOnce(GroupMessage m) async {
    final revealed = await GroupRepository.openViewOnce(m.id);
    final i = messages.indexWhere((x) => x.id == m.id);
    if (i >= 0 && !m.isMine) messages[i] = m.copyWith(withheld: true, opened: true);
    _notify();
    return revealed;
  }

  Future<void> setMuted(bool muted) async {
    detail = await GroupRepository.updateMyState(groupId, muteSeconds: muted ? -1 : 0);
    _list.scheduleReload();
    _notify();
  }

  Future<void> clearChat() async {
    await GroupRepository.clearChat(groupId);
    messages.clear();
    _notify();
  }
}
