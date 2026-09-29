import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/core.dart';
import 'direct_models.dart';

List<Map<String, dynamic>> _list(dynamic data) => [
  for (final e in (data as List? ?? const [])) Map<String, dynamic>.from(e as Map),
];

Map<String, dynamic> _map(dynamic data) => Map<String, dynamic>.from(data as Map);

/// All 1-to-1 chat server calls: REST for reads, socket (with ack) for writes.
class DirectRepository {
  DirectRepository._();

  static final _api = ApiClient.instance;
  static final _ws = SocketService.instance;

  // ------------------------------------------------------------------ users
  static Future<List<DmUser>> searchUsers(String q) async =>
      _list(await _api.get('/users/search', query: {'q': q})).map(DmUser.fromJson).toList();

  static Future<DmUser> getUser(String id) async => DmUser.fromJson(_map(await _api.get('/users/$id')));

  /// View once: reveals the message for the receiver (only once).
  static Future<DmMessage> openViewOnce(String messageId) async => DmMessage.fromJson(_map(await _api.post('/messages/$messageId/open')));

  static Future<void> block(String userId) => _api.post('/users/$userId/block');

  static Future<void> unblock(String userId) => _api.delete('/users/$userId/block');

  static Future<List<DmUser>> blockedUsers() async =>
      _list(await _api.get('/users/blocked')).map(DmUser.fromJson).toList();

  static Future<void> subscribePresence(List<String> userIds) async {
    if (userIds.isEmpty) return;
    await _ws.request('presence:subscribe', {'userIds': userIds.take(200).toList()});
  }

  // ---------------------------------------------------------- conversations
  static Future<DmConversation> openWith(String userId) async =>
      DmConversation.fromJson(_map(await _api.post('/conversations', body: {'userId': userId})));

  static Future<({List<DmConversation> items, String? nextCursor})> conversations({
    bool archived = false,
    String? cursor,
  }) async {
    final data = _map(
      await _api.get('/conversations', query: {'archived': '$archived', 'cursor': ?cursor, 'limit': '30'}),
    );
    return (
      items: _list(data['items']).map(DmConversation.fromJson).toList(),
      nextCursor: data['nextCursor'] as String?,
    );
  }

  static Future<DmConversation> conversation(String id) async =>
      DmConversation.fromJson(_map(await _api.get('/conversations/$id')));

  static Future<DmConversation> updateSettings(String id, {bool? pinned, bool? archived, int? muteSeconds}) async =>
      DmConversation.fromJson(
        _map(
          await _api.patch(
            '/conversations/$id',
            body: {'pinned': ?pinned, 'archived': ?archived, 'muteSeconds': ?muteSeconds},
          ),
        ),
      );

  static Future<void> clearChat(String id) => _api.post('/conversations/$id/clear');

  static Future<void> deleteChat(String id) => _api.delete('/conversations/$id');

  // --------------------------------------------------------------- messages
  static Future<({List<DmMessage> items, bool hasMore})> messages(
    String conversationId, {
    String? before,
    String? after,
    int limit = 30,
  }) async {
    final data = _map(
      await _api.get(
        '/conversations/$conversationId/messages',
        query: {'before': ?before, 'after': ?after, 'limit': '$limit'},
      ),
    );
    return (items: _list(data['items']).map(DmMessage.fromJson).toList(), hasMore: data['hasMore'] == true);
  }

  static Future<List<DmMessage>> search(String conversationId, String q) async =>
      _list(await _api.get('/conversations/$conversationId/search', query: {'q': q})).map(DmMessage.fromJson).toList();

  /// kind: media | docs | audio | links
  static Future<List<DmMessage>> media(String conversationId, String kind) async => _list(
    await _api.get('/conversations/$conversationId/media', query: {'kind': kind}),
  ).map(DmMessage.fromJson).toList();

  static Future<List<({DmMessage message, DmUser? peer})>> starred() async => [
    for (final j in _list(await _api.get('/messages/starred')))
      (message: DmMessage.fromJson(j), peer: j['peer'] is Map ? DmUser.fromJson(_map(j['peer'])) : null),
  ];

  static Future<Map<String, dynamic>> messageInfo(String messageId) async =>
      _map(await _api.get('/messages/$messageId/info'));

  /// Uploads a file and returns the media object to attach to a message.
  static Future<DmMedia> upload(
    Uint8List bytes,
    String filename, {
    String? kind,
    double? duration,
    bool secure = false,
    void Function(double progress)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename, contentType: mimeOf(filename)),
      // Private / Highly Protected: stored encrypted, never gets a public URL.
      if (secure) 'secure': 'true',
      'kind': ?kind,
      if (duration != null) 'duration': duration.toStringAsFixed(1),
    });
    final data = await _api.upload(
      '/media/upload',
      form,
      onProgress: onProgress == null ? null : (sent, total) => total > 0 ? onProgress(sent / total) : null,
    );
    return DmMedia.fromJson(_map(data));
  }

  // ------------------------------------------------------ realtime (socket)
  static Future<DmMessage> send(Map<String, dynamic> payload) async =>
      DmMessage.fromJson(_map(await _ws.request('message:send', payload)));

  static Future<DmMessage> edit(String messageId, String text) async =>
      DmMessage.fromJson(_map(await _ws.request('message:edit', {'messageId': messageId, 'text': text})));

  static Future<void> delete(String messageId, {required bool forEveryone}) =>
      _ws.request('message:delete', {'messageId': messageId, 'scope': forEveryone ? 'everyone' : 'me'});

  static Future<DmMessage> react(String messageId, String? emoji) async =>
      DmMessage.fromJson(_map(await _ws.request('message:react', {'messageId': messageId, 'emoji': emoji})));

  static Future<DmMessage> star(String messageId, bool starred) async =>
      DmMessage.fromJson(_map(await _ws.request('message:star', {'messageId': messageId, 'starred': starred})));

  static Future<void> forward(String messageId, List<String> toUserIds) =>
      _ws.request('message:forward', {'messageId': messageId, 'toUserIds': toUserIds, 'clientMsgId': newClientMsgId()});

  static void markRead(String conversationId, String upToMessageId) =>
      _ws.emit('conversation:read', {'conversationId': conversationId, 'upToMessageId': upToMessageId});

  static void markDelivered(String conversationId, String upToMessageId) =>
      _ws.emit('message:delivered', {'conversationId': conversationId, 'upToMessageId': upToMessageId});

  static void typing(String conversationId, {required bool isTyping, String kind = 'text'}) =>
      _ws.emit('typing', {'conversationId': conversationId, 'isTyping': isTyping, 'kind': kind});

  static DioMediaType mimeOf(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'mp3': 'audio/mpeg',
      'ogg': 'audio/ogg',
      'opus': 'audio/ogg',
      'wav': 'audio/wav',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'zip': 'application/zip',
    };
    return DioMediaType.parse(map[ext] ?? 'application/octet-stream');
  }
}
