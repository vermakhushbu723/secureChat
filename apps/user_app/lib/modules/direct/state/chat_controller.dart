import 'dart:async';
import 'dart:typed_data';

import '../../../core/core.dart';
import '../data/direct_models.dart';
import '../data/direct_repository.dart';
import 'conversations_controller.dart';

/// State of one open 1-to-1 chat: history, optimistic sending, receipts,
/// typing and every message action. Created by the chat screen.
class ChatController extends ChangeNotifier {
  ChatController(this.conversationId);

  final String conversationId;
  final _list = ConversationsController.instance;
  final List<StreamSubscription<dynamic>> _subs = [];

  DmConversation? conversation;
  final List<DmMessage> messages = []; // oldest -> newest
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = false;
  String? error;

  DmMessage? replyTo;
  DmMessage? editing;

  String? peerTyping; // 'text' | 'recording'
  Timer? _peerTypingTimer;

  bool _typingSent = false;
  DateTime _typingSentAt = DateTime(0);
  Timer? _typingStopTimer;
  String? _lastReadSent;
  bool _disposed = false;

  String get me => AuthService.instance.userId ?? '';
  DmUser? get peer => conversation?.peer;
  bool get canSend => conversation != null && !conversation!.isBlocked && !conversation!.blockedMe;

  // ================================================================ lifecycle
  Future<void> init() async {
    _list.openConversationId = conversationId;
    final ws = SocketService.instance;
    _subs.addAll([
      ws.on('message:new').where(_mine).listen((j) => _onNew(DmMessage.fromJson(j))),
      ws.on('message:updated').where(_mine).listen((j) => _replace(DmMessage.fromJson(j))),
      ws.on('message:removed').where(_mine).listen((j) {
        messages.removeWhere((m) => m.id == j['messageId']);
        _notify();
      }),
      ws.on('message:status').where(_mine).listen(_onStatus),
      ws.on('typing').where(_mine).listen(_onTyping),
      ws.on('presence').listen(_onPresence),
      ws.on('conversation:updated').where((j) => j['id'] == conversationId).listen((j) {
        conversation = DmConversation.fromJson(j);
        _notify();
      }),
      ws.on('conversation:cleared').where(_mine).listen((_) {
        messages.clear();
        _notify();
      }),
      ws.on('user:blocked').listen((j) {
        if (conversation?.peer.id != j['userId']) return;
        conversation = conversation!.copyWith(isBlocked: j['blocked'] == true);
        _notify();
      }),
      ws.on('ready').listen((_) => _resync()),
    ]);

    try {
      conversation = _list.byId(conversationId) ?? await DirectRepository.conversation(conversationId);
      _notify();
      final page = await DirectRepository.messages(conversationId);
      messages
        ..clear()
        ..addAll(page.items);
      hasMore = page.hasMore;
      markRead();
      // Fresh presence + block state for the header.
      unawaited(_refreshPeer());
      unawaited(DirectRepository.subscribePresence([conversation!.peer.id]).catchError((_) {}));
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      _notify();
    }
  }

  bool _mine(Map<String, dynamic> j) => (j['conversationId'] ?? j['id']) == conversationId;

  Future<void> _refreshPeer() async {
    final c = conversation;
    if (c == null) return;
    try {
      final fresh = await DirectRepository.getUser(c.peer.id);
      conversation = c.copyWith(peer: fresh, isBlocked: fresh.isBlocked);
      _notify();
    } on ApiException {
      // Header keeps the cached profile.
    }
  }

  /// After a reconnect: fetch everything newer than the last message we have.
  Future<void> _resync() async {
    final synced = messages.where((m) => !m.isPending);
    if (synced.isEmpty) return;
    try {
      var after = synced.last.id;
      while (true) {
        final page = await DirectRepository.messages(conversationId, after: after, limit: 100);
        for (final m in page.items) {
          _onNew(m, fromSync: true);
        }
        if (!page.hasMore || page.items.isEmpty) break;
        after = page.items.last.id;
      }
      markRead();
    } on ApiException {
      // Next reconnect retries.
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || messages.isEmpty) return;
    loadingMore = true;
    _notify();
    try {
      final oldest = messages.firstWhere((m) => !m.isPending);
      final page = await DirectRepository.messages(conversationId, before: oldest.id);
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
    if (_typingSent) DirectRepository.typing(conversationId, isTyping: false);
    _typingStopTimer?.cancel();
    _peerTypingTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    if (_list.openConversationId == conversationId) _list.openConversationId = null;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ============================================================ socket events
  void _onNew(DmMessage m, {bool fromSync = false}) {
    final byClient = messages.indexWhere((x) => x.clientMsgId.isNotEmpty && x.clientMsgId == m.clientMsgId);
    final byId = messages.indexWhere((x) => x.id == m.id);
    if (byClient >= 0) {
      messages[byClient] = _keepBetterStatus(messages[byClient], m);
    } else if (byId >= 0) {
      messages[byId] = m;
    } else {
      messages.add(m);
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    if (!m.isMine) {
      peerTyping = null;
      if (!fromSync) markRead();
    }
    _notify();
  }

  DmMessage _keepBetterStatus(DmMessage old, DmMessage fresh) =>
      old.status.index > fresh.status.index && old.status != DeliveryStatus.failed
      ? fresh.copyWith(status: old.status)
      : fresh;

  void _replace(DmMessage m) {
    final i = messages.indexWhere((x) => x.id == m.id);
    if (i < 0) return;
    // Receipts may arrive before the update; never downgrade the ticks.
    messages[i] = _keepBetterStatus(messages[i], m);
    _notify();
  }

  void _onStatus(Map<String, dynamic> j) {
    final upTo = j['upToMessageId'] as String;
    final status = statusOf(j['status'] as String?);
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (!m.isMine || m.isPending || m.id.compareTo(upTo) > 0) continue;
      if (m.status.index < status.index) messages[i] = m.copyWith(status: status);
    }
    _notify();
  }

  void _onTyping(Map<String, dynamic> j) {
    _peerTypingTimer?.cancel();
    peerTyping = j['isTyping'] == true ? (j['kind'] as String? ?? 'text') : null;
    if (peerTyping != null) {
      _peerTypingTimer = Timer(const Duration(seconds: 6), () {
        peerTyping = null;
        _notify();
      });
    }
    _notify();
  }

  void _onPresence(Map<String, dynamic> j) {
    final c = conversation;
    if (c == null || j['userId'] != c.peer.id) return;
    conversation = c.copyWith(
      peer: c.peer.copyWith(
        online: j['online'] == true,
        lastSeenAt: j['lastSeenAt'] == null ? null : DateTime.tryParse('${j['lastSeenAt']}')?.toLocal(),
      ),
    );
    _notify();
  }

  // ================================================================ receipts
  void markRead() {
    for (final m in messages.reversed) {
      if (m.isMine || m.isPending) continue;
      if (_lastReadSent == m.id) return;
      _lastReadSent = m.id;
      DirectRepository.markRead(conversationId, m.id);
      return;
    }
  }

  // ================================================================== typing
  /// Call on every keystroke; throttled start + debounced stop.
  void onComposerChanged(String text) {
    if (!canSend) return;
    _typingStopTimer?.cancel();
    if (text.trim().isEmpty) return setTyping(false);
    if (!_typingSent || DateTime.now().difference(_typingSentAt) > const Duration(seconds: 3)) {
      setTyping(true);
    }
    _typingStopTimer = Timer(const Duration(milliseconds: 2500), () => setTyping(false));
  }

  void setTyping(bool typing, {String kind = 'text'}) {
    if (!typing && !_typingSent) return;
    _typingSent = typing;
    _typingSentAt = DateTime.now();
    DirectRepository.typing(conversationId, isTyping: typing, kind: kind);
  }

  // ================================================================= sending
  void setReply(DmMessage? m) {
    replyTo = m;
    editing = null;
    _notify();
  }

  void startEdit(DmMessage? m) {
    editing = m;
    replyTo = null;
    _notify();
  }

  DmMessage _pending(
    DmType type, {
    String text = '',
    Uint8List? bytes,
    String? name,
    DmLocation? location,
    DmContact? contact,
  }) {
    final reply = replyTo;
    replyTo = null;
    return DmMessage(
      id: '',
      conversationId: conversationId,
      clientMsgId: newClientMsgId(),
      senderId: me,
      type: type,
      text: text,
      location: location,
      contact: contact,
      replyTo: reply == null
          ? null
          : DmReply(id: reply.id, senderId: reply.senderId, type: reply.type, text: previewOf(reply)),
      status: DeliveryStatus.pending,
      createdAt: DateTime.now(),
      localBytes: bytes,
      localName: name,
    );
  }

  Future<void> sendText(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    setTyping(false);
    final edit = editing;
    if (edit != null) {
      editing = null;
      _notify();
      return editMessage(edit, text);
    }
    final m = _pending(DmType.text, text: text);
    await _deliver(m, {'type': 'text', 'text': text});
  }

  Future<void> sendLocation(DmLocation location) async {
    final m = _pending(DmType.location, location: location);
    await _deliver(m, {'type': 'location', 'location': location.toJson()});
  }

  Future<void> sendContact(DmContact contact) async {
    final m = _pending(DmType.contact, contact: contact);
    await _deliver(m, {'type': 'contact', 'contact': contact.toJson()});
  }

  /// Upload then send. The bubble shows the local preview + progress meanwhile.
  Future<void> sendFile(Uint8List bytes, String name, DmType type, {String caption = '', double? duration}) async {
    var m = _pending(type, text: caption, bytes: bytes, name: name);
    _upsertLocal(m);
    try {
      final media = await DirectRepository.upload(
        bytes,
        name,
        kind: type == DmType.voice ? 'voice' : null,
        duration: duration,
        onProgress: (p) {
          m = m.copyWith(uploadProgress: p);
          _upsertLocal(m);
        },
      );
      m = m.copyWith(media: media, uploadProgress: 1);
      await _deliver(m, {'type': type.name, 'text': caption, 'media': media.toJson()});
    } on ApiException catch (e) {
      _upsertLocal(m.copyWith(status: DeliveryStatus.failed, error: e.message));
    }
  }

  Future<void> _deliver(DmMessage m, Map<String, dynamic> payload) async {
    final reply = m.replyTo;
    _upsertLocal(m.copyWith(status: DeliveryStatus.pending));
    try {
      final saved = await DirectRepository.send({
        ...payload,
        'conversationId': conversationId,
        'clientMsgId': m.clientMsgId,
        if (reply != null) 'replyToId': reply.id,
      });
      _onNew(saved);
    } on ApiException catch (e) {
      _upsertLocal(m.copyWith(status: DeliveryStatus.failed, error: e.message));
    }
  }

  void _upsertLocal(DmMessage m) {
    final i = messages.indexWhere((x) => x.clientMsgId == m.clientMsgId);
    if (i >= 0) {
      // A realtime echo may already have replaced the pending bubble.
      if (!messages[i].isPending && m.isPending) return;
      messages[i] = m;
    } else {
      messages.add(m);
    }
    _notify();
  }

  Future<void> retry(DmMessage m) async {
    if (m.status != DeliveryStatus.failed) return;
    if (m.isMedia && m.media == null && m.localBytes != null) {
      messages.removeWhere((x) => x.clientMsgId == m.clientMsgId);
      return sendFile(m.localBytes!, m.localName ?? 'file', m.type, caption: m.text);
    }
    await _deliver(m, {
      'type': m.type.name,
      'text': m.text,
      if (m.media != null) 'media': m.media!.toJson(),
      if (m.location != null) 'location': m.location!.toJson(),
      if (m.contact != null) 'contact': m.contact!.toJson(),
    });
  }

  void discard(DmMessage m) {
    messages.removeWhere((x) => x.clientMsgId == m.clientMsgId && x.isPending);
    _notify();
  }

  // ================================================================= actions
  Future<void> editMessage(DmMessage m, String text) async => _replace(await DirectRepository.edit(m.id, text));

  Future<void> deleteMessage(DmMessage m, {required bool forEveryone}) async {
    await DirectRepository.delete(m.id, forEveryone: forEveryone);
    if (!forEveryone) {
      messages.removeWhere((x) => x.id == m.id);
      _notify();
    }
  }

  /// Same emoji again removes the reaction (toggle).
  Future<void> react(DmMessage m, String emoji) async {
    final next = m.myReaction(me) == emoji ? null : emoji;
    _replace(await DirectRepository.react(m.id, next));
  }

  Future<void> toggleStar(DmMessage m) async => _replace(await DirectRepository.star(m.id, !m.starred));

  Future<void> forward(DmMessage m, List<String> userIds) => DirectRepository.forward(m.id, userIds);

  // ============================================================ chat settings
  Future<void> setMuted(bool muted) async {
    conversation = await DirectRepository.updateSettings(conversationId, muteSeconds: muted ? -1 : 0);
    _list.upsert(conversation!);
    _notify();
  }

  Future<void> setBlocked(bool blocked) async {
    final c = conversation!;
    blocked ? await DirectRepository.block(c.peer.id) : await DirectRepository.unblock(c.peer.id);
    conversation = c.copyWith(isBlocked: blocked);
    _notify();
  }

  Future<void> clearChat() async {
    await DirectRepository.clearChat(conversationId);
    messages.clear();
    _notify();
  }
}
