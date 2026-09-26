import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/data/direct_repository.dart';
import 'group_models.dart';

Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);
List<Map<String, dynamic>> _list(dynamic v) => [for (final e in (v as List? ?? const [])) Map<String, dynamic>.from(e as Map)];

/// Every group server call: REST for reads / management, socket (ack) for chat writes.
class GroupRepository {
  GroupRepository._();

  static final _api = ApiClient.instance;
  static final _ws = SocketService.instance;

  // ---------------------------------------------------------------- groups
  static Future<List<GroupSummary>> groups({String filter = 'all', String? q}) async =>
      _list(await _api.get('/groups', query: {'filter': filter, if (q != null && q.isNotEmpty) 'q': q})).map(GroupSummary.fromJson).toList();

  static Future<GroupStats> stats() async => GroupStats.fromJson(_map(await _api.get('/groups/stats')));

  static Future<GroupDetail> detail(String groupId) async => GroupDetail.fromJson(_map(await _api.get('/groups/$groupId')));

  /// Returns the new group and its first invite link.
  static Future<({GroupDetail group, InviteLinkInfo invite})> create({
    required String name,
    String description = '',
    String category = 'Other',
    String rules = '',
    String? avatarUrl,
    GroupSettings? settings,
    Map<String, dynamic>? invite,
  }) async {
    final data = _map(
      await _api.post(
        '/groups',
        body: {
          'name': name,
          'description': description,
          'category': category,
          'rules': rules,
          'avatarUrl': ?avatarUrl,
          if (settings != null) 'settings': settings.toJson(),
          'invite': ?invite,
        },
      ),
    );
    return (group: GroupDetail.fromJson(_map(data['group'])), invite: InviteLinkInfo.fromJson(_map(data['invite'])));
  }

  static Future<GroupDetail> updateInfo(String groupId, Map<String, dynamic> patch) async =>
      GroupDetail.fromJson(_map(await _api.patch('/groups/$groupId', body: patch)));

  static Future<GroupDetail> updateSettings(String groupId, Map<String, dynamic> settings) async =>
      GroupDetail.fromJson(_map(await _api.patch('/groups/$groupId/settings', body: settings)));

  static Future<void> deleteGroup(String groupId) => _api.delete('/groups/$groupId');

  static Future<void> leave(String groupId) => _api.post('/groups/$groupId/leave');

  static Future<GroupDetail> updateMyState(String groupId, {bool? pinned, bool? archived, int? muteSeconds}) async =>
      GroupDetail.fromJson(
        _map(await _api.patch('/groups/$groupId/me', body: {'pinned': ?pinned, 'archived': ?archived, 'muteSeconds': ?muteSeconds})),
      );

  static Future<void> clearChat(String groupId) => _api.post('/groups/$groupId/clear');

  // --------------------------------------------------------------- members
  static Future<List<GroupMemberInfo>> members(String groupId, {String? q}) async =>
      _list(await _api.get('/groups/$groupId/members', query: {if (q != null && q.isNotEmpty) 'q': q})).map(GroupMemberInfo.fromJson).toList();

  static Future<GroupMemberInfo> member(String groupId, String userId) async =>
      GroupMemberInfo.fromJson(_map(await _api.get('/groups/$groupId/members/$userId')));

  static Future<GroupMemberInfo> updateMember(String groupId, String userId, {String? role, bool? restricted}) async =>
      GroupMemberInfo.fromJson(_map(await _api.patch('/groups/$groupId/members/$userId', body: {'role': ?role, 'restricted': ?restricted})));

  static Future<void> removeMember(String groupId, String userId) => _api.delete('/groups/$groupId/members/$userId');

  static Future<List<JoinRequest>> requests(String groupId) async =>
      _list(await _api.get('/groups/$groupId/requests')).map(JoinRequest.fromJson).toList();

  static Future<void> decideRequest(String groupId, String userId, {required bool approve}) =>
      _api.post('/groups/$groupId/requests/$userId/${approve ? 'approve' : 'decline'}');

  // --------------------------------------------------------------- invites
  static Future<List<InviteLinkInfo>> invites(String groupId) async =>
      _list(await _api.get('/groups/$groupId/invites')).map(InviteLinkInfo.fromJson).toList();

  /// expiry: 1h | 24h | 7d | 30d | never ; maxJoins 0 = unlimited.
  static Future<InviteLinkInfo> newInvite(String groupId, {required String expiry, required int maxJoins, required bool requireApproval}) async =>
      InviteLinkInfo.fromJson(
        _map(await _api.post('/groups/$groupId/invites', body: {'expiry': expiry, 'maxJoins': maxJoins, 'requireApproval': requireApproval})),
      );

  static Future<InviteLinkInfo> resetInvites(String groupId, {required String expiry, required int maxJoins, required bool requireApproval}) async =>
      InviteLinkInfo.fromJson(
        _map(await _api.post('/groups/$groupId/invites/reset', body: {'expiry': expiry, 'maxJoins': maxJoins, 'requireApproval': requireApproval})),
      );

  static Future<void> revokeInvite(String groupId, String code) => _api.delete('/groups/$groupId/invites/$code');

  static Future<InvitePreview> invitePreview(String code) async => InvitePreview.fromJson(_map(await _api.get('/invites/$code')));

  /// Returns `(status: active|pending, groupId)`.
  static Future<({String status, String groupId})> join(String code, {DmLocation? location, String? shareMode}) async {
    final data = _map(
      await _api.post(
        '/invites/$code/join',
        body: {
          if (location != null) 'location': {'lat': location.lat, 'lng': location.lng, 'place': ?location.name},
          'shareMode': ?shareMode,
        },
      ),
    );
    return (status: data['status'] as String, groupId: data['groupId'] as String);
  }

  /// Accepts a full invite URL or just the code.
  static String? codeFrom(String input) {
    final m = RegExp(r'([A-Za-z]{3}-[A-Za-z0-9]{6})').firstMatch(input.trim());
    return m?.group(1)?.toUpperCase();
  }

  // -------------------------------------------------------------- messages
  static Future<({List<GroupMessage> items, bool hasMore})> messages(String groupId, {String? before, String? after, int limit = 40}) async {
    final data = _map(await _api.get('/groups/$groupId/messages', query: {'before': ?before, 'after': ?after, 'limit': '$limit'}));
    return (items: _list(data['items']).map(GroupMessage.fromJson).toList(), hasMore: data['hasMore'] == true);
  }

  static Future<GroupMessage> message(String messageId) async => GroupMessage.fromJson(_map(await _api.get('/group-messages/$messageId')));

  /// filter: all | text | photos | docs | voice | protected
  static Future<List<GroupMessage>> search(String groupId, {String q = '', String filter = 'all'}) async =>
      _list(await _api.get('/groups/$groupId/search', query: {'q': q, 'filter': filter})).map(GroupMessage.fromJson).toList();

  /// kind: media | docs | protected | audio | links
  static Future<List<GroupMessage>> media(String groupId, String kind) async =>
      _list(await _api.get('/groups/$groupId/media', query: {'kind': kind})).map(GroupMessage.fromJson).toList();

  static Future<List<({GroupMessage message, String groupName})>> starred() async => [
    for (final j in _list(await _api.get('/group-messages/starred'))) (message: GroupMessage.fromJson(j), groupName: j['groupName'] as String? ?? ''),
  ];

  static Future<MessageInfoData> info(String messageId) async => MessageInfoData.fromJson(_map(await _api.get('/group-messages/$messageId/info')));

  static Future<({ForwardNode tree, ChainTotals totals})> chain(String messageId) async {
    final data = _map(await _api.get('/group-messages/$messageId/chain'));
    return (tree: chainNodeOf(_map(data['tree'])), totals: ChainTotals.fromJson(_map(data['totals'])));
  }

  static Future<ForwardDetailsData> forwardDetails(String messageId) async =>
      ForwardDetailsData.fromJson(_map(await _api.get('/group-messages/$messageId/forward-details')));

  static Future<DeletePreviewData> deletePreview(String messageId) async =>
      DeletePreviewData.fromJson(_map(await _api.get('/group-messages/$messageId/delete-preview')));

  static Future<DeletionStatusData> deletionStatus(String messageId) async =>
      DeletionStatusData.fromJson(_map(await _api.get('/group-messages/$messageId/deletion')));

  static Future<GroupMessage> openViewOnce(String messageId) async => GroupMessage.fromJson(_map(await _api.post('/group-messages/$messageId/open')));

  // Realtime writes (socket with ack)
  static Future<GroupMessage> send(Map<String, dynamic> payload) async =>
      GroupMessage.fromJson(_map(await _ws.request('group:message:send', payload)));

  static Future<GroupMessage> edit(String messageId, String text) async =>
      GroupMessage.fromJson(_map(await _ws.request('group:message:edit', {'messageId': messageId, 'text': text})));

  static Future<int> delete(String messageId, {required bool forEveryone, bool chain = true}) async {
    final data = _map(await _ws.request('group:message:delete', {'messageId': messageId, 'scope': forEveryone ? 'everyone' : 'me', 'chain': chain}));
    return (data['deleted'] as num?)?.toInt() ?? 0;
  }

  static Future<GroupMessage> react(String messageId, String? emoji) async =>
      GroupMessage.fromJson(_map(await _ws.request('group:message:react', {'messageId': messageId, 'emoji': emoji})));

  static Future<GroupMessage> star(String messageId, bool starred) async =>
      GroupMessage.fromJson(_map(await _ws.request('group:message:star', {'messageId': messageId, 'starred': starred})));

  static Future<List<GroupMessage>> forward(List<String> messageIds, List<String> toGroupIds) async => [
    for (final j in _list(await _ws.request('group:message:forward', {'messageIds': messageIds, 'toGroupIds': toGroupIds, 'clientMsgId': newClientMsgId()})))
      GroupMessage.fromJson(j),
  ];

  static void markRead(String groupId, String upTo) => _ws.emit('group:read', {'groupId': groupId, 'upToMessageId': upTo});

  static void markDelivered(String groupId, String upTo) => _ws.emit('group:delivered', {'groupId': groupId, 'upToMessageId': upTo});

  static void typing(String groupId, {required bool isTyping, String kind = 'text'}) =>
      _ws.emit('group:typing', {'groupId': groupId, 'isTyping': isTyping, 'kind': kind});

  /// Upload for a group message. [secure] = encrypted, no public URL (protected levels).
  static Future<GroupMedia> upload(Uint8List bytes, String filename, {required bool secure, String? kind, double? duration, void Function(double)? onProgress}) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename, contentType: DirectRepository.mimeOf(filename)),
      'secure': '$secure',
      'kind': ?kind,
      if (duration != null) 'duration': duration.toStringAsFixed(1),
    });
    final data = await _api.upload('/media/upload', form, onProgress: onProgress == null ? null : (s, t) => t > 0 ? onProgress(s / t) : null);
    return GroupMedia.fromJson(_map(data));
  }

  // ----------------------------------------------------------------- files
  static Future<FileInfoData> fileInfo(String fileId) async => FileInfoData.fromJson(_map(await _api.get('/files/$fileId')));

  static Future<FileTokenData> fileToken(String fileId) async => FileTokenData.fromJson(_map(await _api.post('/files/$fileId/token')));

  static Future<List<AccessLogEntry>> accessLog(String fileId) async =>
      _list(await _api.get('/files/$fileId/access-log')).map(AccessLogEntry.fromJson).toList();

  static Future<FileInfoData> updateFilePermissions(String fileId, Map<String, dynamic> patch) async =>
      FileInfoData.fromJson(_map(await _api.patch('/files/$fileId/permissions', body: patch)));

  /// Logs a blocked action (download / share / print / copy / open with / screenshot).
  static Future<void> fileEvent(String fileId, String action) async {
    try {
      await _api.post('/files/$fileId/events', body: {'action': action});
    } on ApiException {
      // logging is best effort
    }
  }

  // -------------------------------------------------------------- location
  static Future<GroupLocationsData> groupLocations(String groupId) async =>
      GroupLocationsData.fromJson(_map(await _api.get('/groups/$groupId/locations')));

  static Future<MyLocationData> myLocation() async => MyLocationData.fromJson(_map(await _api.get('/location/me')));

  static Future<MyLocationData> updateLocationSettings({required String mode, int intervalMin = 10, int? liveForMinutes}) async =>
      MyLocationData.fromJson(
        _map(await _api.put('/location/settings', body: {'mode': mode, 'intervalMin': intervalMin, 'liveForMinutes': liveForMinutes})),
      );

  static Future<void> updateLocation({required double lat, required double lng, String? place, double? accuracy, String source = 'manual'}) =>
      _api.post('/location/update', body: {'lat': lat, 'lng': lng, 'place': ?place, 'accuracy': ?accuracy, 'source': source});

  static Future<({List<LocationHistoryEntry> items, int updates})> history(String range) async {
    final data = _map(await _api.get('/location/history', query: {'range': range}));
    return (items: _list(data['items']).map(LocationHistoryEntry.fromJson).toList(), updates: (_map(data['stats'])['updates'] as num?)?.toInt() ?? 0);
  }

  static Future<void> clearHistory() => _api.delete('/location/history');

  // --------------------------------------------------------------- reports
  static Future<void> report({required String type, String? messageId, String? userId, String? groupId, required List<String> reasons, String details = '', bool alsoBlock = false}) =>
      _api.post(
        '/reports',
        body: {
          'type': type,
          'messageId': ?messageId,
          'userId': ?userId,
          'groupId': ?groupId,
          'reasons': reasons,
          'details': details,
          'alsoBlock': alsoBlock,
        },
      );

  static Future<List<UserReport>> myReports() async => _list(await _api.get('/reports/mine')).map(UserReport.fromJson).toList();
}
