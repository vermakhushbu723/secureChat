import 'dart:typed_data';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _list(dynamic v) => [for (final e in (v as List? ?? const [])) _map(e)];

// ---------------------------------------------------------------------------
// Enum mapping (server strings <-> shared enums)
// ---------------------------------------------------------------------------
MessageVisibility visibilityOf(String? v) => switch (v) {
  'private' => MessageVisibility.private,
  'highly_protected' => MessageVisibility.highlyProtected,
  _ => MessageVisibility.public,
};

String visibilityValue(MessageVisibility v) => switch (v) {
  MessageVisibility.public => 'public',
  MessageVisibility.private => 'private',
  MessageVisibility.highlyProtected => 'highly_protected',
};

LocationRequirement requirementOf(String? v) =>
    LocationRequirement.values.firstWhere((r) => r.name == v, orElse: () => LocationRequirement.off);

LocationVisibility locVisibilityOf(String? v) =>
    LocationVisibility.values.firstWhere((r) => r.name == v, orElse: () => LocationVisibility.adminOnly);

MemberRole roleOf(String? v) => MemberRole.values.firstWhere((r) => r.name == v, orElse: () => MemberRole.member);

ContentRule? contentRuleOf(String? v) => ContentRule.values.where((r) => r.name == v).firstOrNull;

/// 'public' | 'private' | 'user_select' -> UI label.
String messageModeLabel(String mode) => switch (mode) {
  'public' => 'Public',
  'private' => 'Private',
  _ => 'User can select',
};

String messageModeValue(String label) => switch (label) {
  'Public' => 'public',
  'Private' => 'private',
  _ => 'user_select',
};

String groupInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'G';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

// ---------------------------------------------------------------------------
// Group list / detail
// ---------------------------------------------------------------------------
class GroupLastMessage {
  const GroupLastMessage({required this.id, required this.text, this.senderId, this.senderName, this.type = 'text', this.deleted = false, this.createdAt});

  factory GroupLastMessage.fromJson(Map<String, dynamic> j) => GroupLastMessage(
    id: '${j['id']}',
    senderId: j['senderId'] as String?,
    senderName: j['senderName'] as String?,
    type: j['type'] as String? ?? 'text',
    text: j['text'] as String? ?? '',
    deleted: j['deleted'] == true,
    createdAt: _date(j['createdAt']),
  );

  final String id;
  final String? senderId;
  final String? senderName;
  final String type;
  final String text;
  final bool deleted;
  final DateTime? createdAt;

  /// "Rahul: Hello everyone" (system messages without prefix).
  String preview(String? myId) {
    if (type == 'system' || senderName == null) return text;
    return '${senderId == myId ? 'You' : senderName}: $text';
  }
}

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'Other',
    this.avatarUrl,
    this.memberCount = 0,
    this.status = 'active',
    this.role = MemberRole.member,
    this.createdByMe = false,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.muted = false,
    this.pinned = false,
    this.archived = false,
    this.location = LocationRequirement.off,
    this.locationVisibility = LocationVisibility.adminOnly,
    this.messageMode = 'user_select',
  });

  factory GroupSummary.fromJson(Map<String, dynamic> j) => GroupSummary(
    id: j['id'] as String,
    name: j['name'] as String? ?? 'Group',
    description: j['description'] as String? ?? '',
    category: j['category'] as String? ?? 'Other',
    avatarUrl: j['avatarUrl'] as String?,
    memberCount: (j['memberCount'] as num?)?.toInt() ?? 0,
    status: j['status'] as String? ?? 'active',
    role: roleOf(j['role'] as String?),
    createdByMe: j['createdByMe'] == true,
    lastMessage: j['lastMessage'] is Map ? GroupLastMessage.fromJson(_map(j['lastMessage'])) : null,
    lastMessageAt: _date(j['lastMessageAt']),
    unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
    muted: j['muted'] == true,
    pinned: j['pinned'] == true,
    archived: j['archived'] == true,
    location: requirementOf(j['location'] as String?),
    locationVisibility: locVisibilityOf(j['locationVisibility'] as String?),
    messageMode: j['messageMode'] as String? ?? 'user_select',
  );

  final String id;
  final String name;
  final String description;
  final String category;
  final String? avatarUrl;
  final int memberCount;
  final String status;
  final MemberRole role;
  final bool createdByMe;
  final GroupLastMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool muted;
  final bool pinned;
  final bool archived;
  final LocationRequirement location;
  final LocationVisibility locationVisibility;
  final String messageMode;

  String get initials => groupInitials(name);
  bool get isAdmin => role == MemberRole.owner || role == MemberRole.admin;
  bool get isActive => status == 'active';
  String get statusLabel => status == 'active' ? 'Active' : status == 'suspended' ? 'Suspended' : 'Deleted';
  String get messageModeText => messageModeLabel(messageMode);

  GroupSummary copyWith({GroupLastMessage? lastMessage, DateTime? lastMessageAt, int? unreadCount, int? memberCount}) =>
      GroupSummary(
        id: id,
        name: name,
        description: description,
        category: category,
        avatarUrl: avatarUrl,
        memberCount: memberCount ?? this.memberCount,
        status: status,
        role: role,
        createdByMe: createdByMe,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        muted: muted,
        pinned: pinned,
        archived: archived,
        location: location,
        locationVisibility: locationVisibility,
        messageMode: messageMode,
      );
}

/// Every group setting in one editable object (Group Settings + Security screens).
class GroupSettings {
  GroupSettings({
    this.locationRequirement = LocationRequirement.off,
    this.shareMode = LocationShareMode.join,
    this.liveIntervalMin = 10,
    this.locationVisibility = LocationVisibility.adminOnly,
    this.whoCanSend = 'all',
    this.messageMode = 'user_select',
    this.membersCanEditInfo = false,
    this.membersCanSendMedia = true,
    Set<ContentRule>? contentRules,
    this.approveNewMembers = false,
    this.restrictNewMembers = false,
    this.muteGroup = false,
    this.freeAccess = false,
    this.memberSearch = true,
    this.publicForwarding = true,
    this.privateForwarding = false,
    this.trackForwardChain = true,
    this.openInAppOnly = true,
    this.downloadDisabled = true,
    this.externalShareDisabled = true,
    this.copyDisabledProtected = true,
    this.screenshotProtection = true,
    this.screenRecordingProtection = true,
    this.dynamicWatermark = true,
    this.chainDeletion = true,
    this.deleteForEveryoneUnlimited = false,
  }) : contentRules = contentRules ?? {...ContentRule.values};

  factory GroupSettings.fromJson(Map<String, dynamic> j) {
    final loc = _map(j['location']);
    final msg = _map(j['messages']);
    final mem = _map(j['members']);
    final sec = _map(j['security']);
    bool b(Map<String, dynamic> m, String k, bool d) => m[k] is bool ? m[k] as bool : d;
    return GroupSettings(
      locationRequirement: requirementOf(loc['requirement'] as String?),
      shareMode: loc['shareMode'] == 'live' ? LocationShareMode.live : LocationShareMode.join,
      liveIntervalMin: (loc['liveIntervalMin'] as num?)?.toInt() ?? 10,
      locationVisibility: locVisibilityOf(loc['visibility'] as String?),
      whoCanSend: msg['whoCanSend'] as String? ?? 'all',
      messageMode: msg['messageMode'] as String? ?? 'user_select',
      membersCanEditInfo: b(msg, 'membersCanEditInfo', false),
      membersCanSendMedia: b(msg, 'membersCanSendMedia', true),
      contentRules: {
        for (final r in (j['contentRules'] as List? ?? ContentRule.values.map((e) => e.name).toList()))
          ?contentRuleOf('$r'),
      },
      approveNewMembers: b(mem, 'approveNewMembers', false),
      restrictNewMembers: b(mem, 'restrictNewMembers', false),
      muteGroup: b(mem, 'muteGroup', false),
      freeAccess: b(mem, 'freeAccess', false),
      memberSearch: b(mem, 'memberSearch', true),
      publicForwarding: b(sec, 'publicForwarding', true),
      privateForwarding: b(sec, 'privateForwarding', false),
      trackForwardChain: b(sec, 'trackForwardChain', true),
      openInAppOnly: b(sec, 'openInAppOnly', true),
      downloadDisabled: b(sec, 'downloadDisabled', true),
      externalShareDisabled: b(sec, 'externalShareDisabled', true),
      copyDisabledProtected: b(sec, 'copyDisabledProtected', true),
      screenshotProtection: b(sec, 'screenshotProtection', true),
      screenRecordingProtection: b(sec, 'screenRecordingProtection', true),
      dynamicWatermark: b(sec, 'dynamicWatermark', true),
      chainDeletion: b(sec, 'chainDeletion', true),
      deleteForEveryoneUnlimited: b(sec, 'deleteForEveryoneUnlimited', false),
    );
  }

  LocationRequirement locationRequirement;
  LocationShareMode shareMode;
  int liveIntervalMin;
  LocationVisibility locationVisibility;
  String whoCanSend;
  String messageMode;
  bool membersCanEditInfo;
  bool membersCanSendMedia;
  Set<ContentRule> contentRules;
  bool approveNewMembers;
  bool restrictNewMembers;
  bool muteGroup;

  /// Creator option: members without premium can reply and open protected files
  /// while the group is premium.
  bool freeAccess;

  /// Members can search the member list (owner / admins always can).
  bool memberSearch;
  bool publicForwarding;
  bool privateForwarding;
  bool trackForwardChain;
  bool openInAppOnly;
  bool downloadDisabled;
  bool externalShareDisabled;
  bool copyDisabledProtected;
  bool screenshotProtection;
  bool screenRecordingProtection;
  bool dynamicWatermark;
  bool chainDeletion;
  bool deleteForEveryoneUnlimited;

  Map<String, dynamic> toJson() => {
    'location': {
      'requirement': locationRequirement.name,
      'shareMode': shareMode == LocationShareMode.live ? 'live' : 'join',
      'liveIntervalMin': liveIntervalMin,
      'visibility': locationVisibility.name,
    },
    'messages': {
      'whoCanSend': whoCanSend,
      'messageMode': messageMode,
      'membersCanEditInfo': membersCanEditInfo,
      'membersCanSendMedia': membersCanSendMedia,
    },
    'contentRules': [for (final r in ContentRule.values) if (contentRules.contains(r)) r.name],
    'members': {'approveNewMembers': approveNewMembers, 'restrictNewMembers': restrictNewMembers, 'muteGroup': muteGroup, 'freeAccess': freeAccess, 'memberSearch': memberSearch},
    'security': securityJson(),
  };

  Map<String, dynamic> securityJson() => {
    'publicForwarding': publicForwarding,
    'privateForwarding': privateForwarding,
    'trackForwardChain': trackForwardChain,
    'openInAppOnly': openInAppOnly,
    'downloadDisabled': downloadDisabled,
    'externalShareDisabled': externalShareDisabled,
    'copyDisabledProtected': copyDisabledProtected,
    'screenshotProtection': screenshotProtection,
    'screenRecordingProtection': screenRecordingProtection,
    'dynamicWatermark': dynamicWatermark,
    'chainDeletion': chainDeletion,
    'deleteForEveryoneUnlimited': deleteForEveryoneUnlimited,
  };
}

class GroupMe {
  const GroupMe({
    required this.userId,
    required this.role,
    this.restricted = false,
    this.canSend = true,
    this.sendBlockedCode,
    this.sendBlockedMessage,
    this.canSendMedia = true,
    this.canEditInfo = false,
    this.locationPlace,
    this.locationShared = false,
    this.canOpenProtected = true,
    this.plan = 'trial',
    this.canSearchMembers = true,
    this.memberSearchBlockedReason,
    this.pendingRequests = 0,
    this.pendingNames = const [],
  });

  factory GroupMe.fromJson(Map<String, dynamic> j) {
    final reason = _map(j['sendBlockedReason']);
    final loc = _map(j['location']);
    return GroupMe(
      userId: j['userId'] as String? ?? '',
      role: roleOf(j['role'] as String?),
      restricted: j['restricted'] == true,
      canSend: j['canSend'] != false,
      sendBlockedCode: reason['code'] as String?,
      sendBlockedMessage: reason['message'] as String?,
      canSendMedia: j['canSendMedia'] != false,
      canEditInfo: j['canEditInfo'] == true,
      locationPlace: loc['place'] as String?,
      locationShared: loc['lat'] != null && loc['mode'] != 'none',
      canOpenProtected: j['canOpenProtected'] != false,
      plan: j['plan'] as String? ?? 'trial',
      canSearchMembers: j['canSearchMembers'] != false,
      memberSearchBlockedReason: j['memberSearchBlockedReason'] as String?,
      pendingRequests: (_map(j['pendingRequests'])['count'] as num?)?.toInt() ?? 0,
      pendingNames: [for (final n in (_map(j['pendingRequests'])['names'] as List? ?? const [])) '$n'],
    );
  }

  final String userId;
  final MemberRole role;
  final bool restricted;
  final bool canSend;
  final String? sendBlockedCode;
  final String? sendBlockedMessage;
  final bool canSendMedia;
  final bool canEditInfo;
  final String? locationPlace;
  final bool locationShared;

  /// Own trial / premium, or the group's premium when the creator allows it.
  final bool canOpenProtected;

  /// My plan: trial | premium | extended | locked.
  final String plan;

  /// Search Permissions: admin / group admin can turn member search off.
  final bool canSearchMembers;
  final String? memberSearchBlockedReason;

  /// Group admins: join requests waiting for approval (first names for the chat header).
  final int pendingRequests;
  final List<String> pendingNames;

  bool get isAdmin => role == MemberRole.owner || role == MemberRole.admin;
  bool get isOwner => role == MemberRole.owner;
}

class GroupDetail {
  GroupDetail({
    required this.summary,
    required this.settings,
    required this.me,
    this.rules = '',
    this.createdByName = 'Member',
    this.createdAt,
    this.premiumActive = false,
    this.premiumSource,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> j) => GroupDetail(
    summary: GroupSummary.fromJson(j),
    settings: GroupSettings.fromJson(_map(j['settings'])),
    me: GroupMe.fromJson(_map(j['me'])),
    rules: j['rules'] as String? ?? '',
    createdByName: _map(j['createdBy'])['displayName'] as String? ?? 'Member',
    createdAt: _date(j['createdAt']),
    premiumActive: _map(j['premium'])['active'] == true,
    premiumSource: _map(j['premium'])['source'] as String?,
  );

  final GroupSummary summary;
  final GroupSettings settings;
  final GroupMe me;
  final String rules;
  final String createdByName;
  final DateTime? createdAt;

  /// Premium group: the creator has premium ('owner') or the admin approved it ('approved').
  final bool premiumActive;
  final String? premiumSource;

  String get id => summary.id;
  String get name => summary.name;
}

class GroupStats {
  const GroupStats({this.groups = 0, this.unread = 0, this.protectedFiles = 0});

  factory GroupStats.fromJson(Map<String, dynamic> j) => GroupStats(
    groups: (j['groups'] as num?)?.toInt() ?? 0,
    unread: (j['unread'] as num?)?.toInt() ?? 0,
    protectedFiles: (j['protectedFiles'] as num?)?.toInt() ?? 0,
  );

  final int groups;
  final int unread;
  final int protectedFiles;
}

// ---------------------------------------------------------------------------
// Members, requests, invites
// ---------------------------------------------------------------------------
class GroupMemberInfo {
  const GroupMemberInfo({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.role = MemberRole.member,
    this.restricted = false,
    this.joinedAt,
    this.online = false,
    this.lastSeenAt,
    this.isMe = false,
    this.locationShared = false,
    this.groupName,
    this.isBlocked = false,
    this.sharedMediaCount = 0,
    this.locationPlace,
    this.locationLat,
    this.locationLng,
    this.locationUpdatedAt,
    this.canSeeLocation = false,
    this.canManage = false,
    this.phone,
    this.email,
    this.about = '',
    this.accountType = 'personal',
    this.businessAddress,
  });

  factory GroupMemberInfo.fromJson(Map<String, dynamic> j) {
    final loc = _map(j['location']);
    return GroupMemberInfo(
      userId: j['userId'] as String,
      displayName: j['displayName'] as String? ?? 'Member',
      avatarUrl: j['avatarUrl'] as String?,
      role: roleOf(j['role'] as String?),
      restricted: j['restricted'] == true,
      joinedAt: _date(j['joinedAt']),
      online: j['online'] == true,
      lastSeenAt: _date(j['lastSeenAt']),
      isMe: j['isMe'] == true,
      locationShared: j['locationShared'] == true,
      groupName: j['groupName'] as String?,
      isBlocked: j['isBlocked'] == true,
      sharedMediaCount: (j['sharedMediaCount'] as num?)?.toInt() ?? 0,
      locationPlace: loc['place'] as String?,
      locationLat: (loc['lat'] as num?)?.toDouble(),
      locationLng: (loc['lng'] as num?)?.toDouble(),
      locationUpdatedAt: _date(loc['updatedAt']),
      canSeeLocation: j['canSeeLocation'] == true || loc['lat'] != null,
      canManage: j['canManage'] == true,
      phone: j['phone'] as String?,
      email: j['email'] as String?,
      about: j['about'] as String? ?? '',
      accountType: j['accountType'] as String? ?? 'personal',
      businessAddress: j['businessAddress'] as String?,
    );
  }

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final MemberRole role;
  final bool restricted;
  final DateTime? joinedAt;
  final bool online;
  final DateTime? lastSeenAt;
  final bool isMe;
  final bool locationShared;
  final String? groupName;
  final bool isBlocked;
  final int sharedMediaCount;
  final String? locationPlace;
  final double? locationLat;
  final double? locationLng;
  final DateTime? locationUpdatedAt;

  /// Group setting lets me see this member's location (group admin, or members when allowed).
  final bool canSeeLocation;
  final bool canManage;

  /// Only present when the member turned on "Show mobile number & email".
  final String? phone;
  final String? email;
  final String about;
  final String accountType;
  final String? businessAddress;

  bool get hasLocation => locationLat != null && locationLng != null;

  String get presence {
    if (online) return 'online';
    final t = lastSeenAt;
    if (t == null) return 'last seen recently';
    return 'last seen ${formatListTime(t)}${formatListTime(t).contains(':') ? '' : ' at ${formatClock(t)}'}';
  }
}

String roleLabel(MemberRole r) => switch (r) {
  MemberRole.owner => 'Creator',
  MemberRole.admin => 'Admin',
  MemberRole.member => '',
};

class JoinRequest {
  const JoinRequest({required this.userId, required this.displayName, this.avatarUrl, this.requestedAt, this.locationShared = false});

  factory JoinRequest.fromJson(Map<String, dynamic> j) => JoinRequest(
    userId: j['userId'] as String,
    displayName: j['displayName'] as String? ?? 'Member',
    avatarUrl: j['avatarUrl'] as String?,
    requestedAt: _date(j['requestedAt']),
    locationShared: j['locationShared'] == true,
  );

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime? requestedAt;
  final bool locationShared;
}

class InviteLinkInfo {
  const InviteLinkInfo({
    required this.code,
    required this.url,
    this.expiresAt,
    this.maxJoins = 0,
    this.joins = 0,
    this.requireApproval = false,
    this.state = 'Active',
    this.createdBy,
  });

  factory InviteLinkInfo.fromJson(Map<String, dynamic> j) => InviteLinkInfo(
    code: j['code'] as String,
    url: j['url'] as String? ?? '',
    expiresAt: _date(j['expiresAt']),
    maxJoins: (j['maxJoins'] as num?)?.toInt() ?? 0,
    joins: (j['joins'] as num?)?.toInt() ?? 0,
    requireApproval: j['requireApproval'] == true,
    state: j['state'] as String? ?? 'Active',
    createdBy: j['createdBy'] as String?,
  );

  final String code;
  final String url;
  final DateTime? expiresAt;
  final int maxJoins;
  final int joins;
  final bool requireApproval;
  final String state;
  final String? createdBy;

  bool get isActive => state == 'Active';

  String get expiryLabel {
    final t = expiresAt;
    if (t == null) return 'never';
    final left = t.difference(DateTime.now());
    if (left.isNegative) return 'expired';
    if (left.inDays >= 1) return 'in ${left.inDays} day${left.inDays > 1 ? 's' : ''}';
    if (left.inHours >= 1) return 'in ${left.inHours} h';
    return 'in ${left.inMinutes.clamp(1, 59)} min';
  }
}

class InvitePreview {
  const InvitePreview({
    required this.code,
    required this.state,
    required this.groupId,
    required this.name,
    this.description = '',
    this.avatarUrl,
    this.memberCount = 0,
    this.createdBy = 'Member',
    this.location = LocationRequirement.off,
    this.shareMode = LocationShareMode.join,
    this.locationVisibility = LocationVisibility.adminOnly,
    this.messageMode = 'user_select',
    this.requireApproval = false,
    this.membership,
    this.rules = '',
    this.permissions = const [],
  });

  factory InvitePreview.fromJson(Map<String, dynamic> j) {
    final g = _map(j['group']);
    return InvitePreview(
      code: j['code'] as String,
      state: j['state'] as String? ?? 'Active',
      groupId: g['id'] as String,
      name: g['name'] as String? ?? 'Group',
      description: g['description'] as String? ?? '',
      avatarUrl: g['avatarUrl'] as String?,
      memberCount: (g['memberCount'] as num?)?.toInt() ?? 0,
      createdBy: g['createdBy'] as String? ?? 'Member',
      location: requirementOf(g['location'] as String?),
      shareMode: g['locationShareMode'] == 'live' ? LocationShareMode.live : LocationShareMode.join,
      locationVisibility: locVisibilityOf(g['locationVisibility'] as String?),
      messageMode: g['messageMode'] as String? ?? 'user_select',
      requireApproval: j['requireApproval'] == true,
      membership: j['membership'] as String?,
      rules: g['rules'] as String? ?? '',
      permissions: [
        for (final x in (j['permissions'] as List? ?? const []))
          (key: '${(x as Map)['key']}', title: '${x['title']}', detail: '${x['detail'] ?? ''}'),
      ],
    );
  }

  final String code;
  final String state;
  final String groupId;
  final String name;
  final String description;
  final String? avatarUrl;
  final int memberCount;
  final String createdBy;
  final LocationRequirement location;
  final LocationShareMode shareMode;
  final LocationVisibility locationVisibility;
  final String messageMode;
  final bool requireApproval;
  final String? membership;
  final String rules;

  /// Group rules / permissions the member accepts before joining.
  final List<({String key, String title, String detail})> permissions;

  String get initials => groupInitials(name);
  bool get usable => state == 'Active';
}

// ---------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------
class GroupMedia {
  const GroupMedia({
    this.url,
    this.thumbUrl,
    this.secure = false,
    this.fileId,
    this.withheld = false,
    this.mimeType = 'application/octet-stream',
    this.name,
    this.size = 0,
    this.width,
    this.height,
    this.duration,
  });

  factory GroupMedia.fromJson(Map<String, dynamic> j) => GroupMedia(
    url: j['url'] as String?,
    thumbUrl: j['thumbUrl'] as String?,
    secure: j['secure'] == true,
    fileId: j['fileId'] as String? ?? j['secureFileId'] as String?,
    withheld: j['withheld'] == true,
    mimeType: j['mimeType'] as String? ?? 'application/octet-stream',
    name: j['name'] as String?,
    size: (j['size'] as num?)?.toInt() ?? 0,
    width: (j['width'] as num?)?.toInt(),
    height: (j['height'] as num?)?.toInt(),
    duration: (j['duration'] as num?)?.toDouble(),
  );

  final String? url;
  final String? thumbUrl;
  final bool secure;
  final String? fileId;
  final bool withheld;
  final String mimeType;
  final String? name;
  final int size;
  final int? width;
  final int? height;
  final double? duration;

  String? get fullUrl => url == null ? null : ApiConfig.mediaUrl(url!);
  String? get previewUrl => url == null ? null : ApiConfig.mediaUrl(thumbUrl ?? url!);

  /// Payload for `media` when sending (upload response shape).
  Map<String, dynamic> toSendJson() => secure
      ? {'secureFileId': fileId, 'mimeType': mimeType, 'size': size, 'name': ?name, 'duration': ?duration}
      : {
          'url': url,
          'thumbUrl': ?thumbUrl,
          'mimeType': mimeType,
          'size': size,
          'name': ?name,
          'width': ?width,
          'height': ?height,
          'duration': ?duration,
        };
}

class GroupPermissions {
  const GroupPermissions({
    this.allowDownload = true,
    this.allowScreenshot = true,
    this.allowShare = false,
    this.allowPrint = false,
    this.canForward = true,
    this.canCopy = true,
    this.watermark = false,
    this.whoCanView = 'members',
    this.viewOnce = false,
    this.expiresAt,
    this.accessExpiresAt,
  });

  factory GroupPermissions.fromJson(Map<String, dynamic> j) => GroupPermissions(
    allowDownload: j['allowDownload'] == true,
    allowScreenshot: j['allowScreenshot'] == true,
    allowShare: j['allowShare'] == true,
    allowPrint: j['allowPrint'] == true,
    canForward: j['canForward'] == true,
    canCopy: j['canCopy'] == true,
    watermark: j['watermark'] == true,
    whoCanView: j['whoCanView'] as String? ?? 'members',
    viewOnce: j['viewOnce'] == true,
    expiresAt: _date(j['expiresAt']),
    accessExpiresAt: _date(j['accessExpiresAt']),
  );

  final bool allowDownload;
  final bool allowScreenshot;
  final bool allowShare;
  final bool allowPrint;
  final bool canForward;
  final bool canCopy;
  final bool watermark;
  final String whoCanView;
  final bool viewOnce;
  final DateTime? expiresAt;
  final DateTime? accessExpiresAt;
}

class GroupReply {
  const GroupReply({required this.id, required this.senderId, required this.senderName, required this.type, required this.text});

  factory GroupReply.fromJson(Map<String, dynamic> j) => GroupReply(
    id: j['id'] as String,
    senderId: j['senderId'] as String? ?? '',
    senderName: j['senderName'] as String? ?? 'Member',
    type: j['type'] as String? ?? 'text',
    text: j['text'] as String? ?? '',
  );

  final String id;
  final String senderId;
  final String senderName;
  final String type;
  final String text;
}

class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.clientMsgId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.createdAt,
    this.senderAvatar,
    this.text = '',
    this.media,
    this.location,
    this.contact,
    this.visibility = MessageVisibility.public,
    this.permissions = const GroupPermissions(),
    this.viewOnce = false,
    this.opened = false,
    this.withheld = false,
    this.withheldReason,
    this.silent = false,
    this.replyTo,
    this.forwarded = false,
    this.forwardDepth = 0,
    this.forwardCount = 0,
    this.reactions = const [],
    this.edited = false,
    this.deleted = false,
    this.expired = false,
    this.deletedReason,
    this.starred = false,
    this.status = DeliveryStatus.sent,
    this.systemEvent,
    this.localBytes,
    this.localName,
    this.uploadProgress,
    this.error,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> j) => GroupMessage(
    id: j['id'] as String,
    groupId: j['groupId'] as String,
    clientMsgId: j['clientMsgId'] as String? ?? '',
    senderId: j['senderId'] as String,
    senderName: j['senderName'] as String? ?? 'Member',
    senderAvatar: j['senderAvatar'] as String?,
    type: j['type'] as String? ?? 'text',
    text: j['text'] as String? ?? '',
    media: j['media'] is Map ? GroupMedia.fromJson(_map(j['media'])) : null,
    location: j['location'] is Map ? DmLocation.fromJson(_map(j['location'])) : null,
    contact: j['contact'] is Map ? DmContact.fromJson(_map(j['contact'])) : null,
    visibility: visibilityOf(j['visibility'] as String?),
    permissions: GroupPermissions.fromJson(_map(j['permissions'])),
    viewOnce: j['viewOnce'] == true,
    opened: j['opened'] == true,
    withheld: j['withheld'] == true,
    withheldReason: j['withheldReason'] as String?,
    silent: j['silent'] == true,
    replyTo: j['replyTo'] is Map ? GroupReply.fromJson(_map(j['replyTo'])) : null,
    forwarded: j['forwarded'] == true,
    forwardDepth: (j['forwardDepth'] as num?)?.toInt() ?? 0,
    forwardCount: (j['forwardCount'] as num?)?.toInt() ?? 0,
    reactions: [for (final r in _list(j['reactions'])) DmReaction('${r['userId']}', '${r['emoji']}')],
    edited: j['edited'] == true,
    deleted: j['deleted'] == true,
    expired: j['expired'] == true,
    deletedReason: j['deletedReason'] as String?,
    starred: j['starred'] == true,
    status: j['status'] == null ? DeliveryStatus.sent : statusOf(j['status'] as String?),
    systemEvent: _map(j['system'])['event'] as String?,
    createdAt: _date(j['createdAt']) ?? DateTime.now(),
  );

  final String id;
  final String groupId;
  final String clientMsgId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String type;
  final String text;
  final GroupMedia? media;
  final DmLocation? location;
  final DmContact? contact;
  final MessageVisibility visibility;
  final GroupPermissions permissions;
  final bool viewOnce;
  final bool opened;
  final bool withheld;
  final String? withheldReason;
  final bool silent;
  final GroupReply? replyTo;
  final bool forwarded;
  final int forwardDepth;
  final int forwardCount;
  final List<DmReaction> reactions;
  final bool edited;
  final bool deleted;
  final bool expired;
  final String? deletedReason;
  final bool starred;
  final DeliveryStatus status;
  final String? systemEvent;
  final DateTime createdAt;

  // Local only (optimistic sending / upload progress)
  final Uint8List? localBytes;
  final String? localName;
  final double? uploadProgress;
  final String? error;

  bool get isPending => id.isEmpty;
  bool get isMine => senderId == AuthService.instance.userId;
  bool get isSystem => type == 'system';
  bool get isProtected => visibility != MessageVisibility.public;
  bool get isMedia => const ['image', 'video', 'audio', 'voice', 'file'].contains(type);
  bool get unavailable => deleted || expired;
  String get key => clientMsgId.isNotEmpty ? clientMsgId : id;

  String? myReaction(String userId) => reactions.where((r) => r.userId == userId).firstOrNull?.emoji;

  /// Shared [ChatMessage] (for existing preview widgets).
  MessageType get sharedType => switch (type) {
    'image' => MessageType.image,
    'video' => MessageType.video,
    'file' => MessageType.document,
    'voice' || 'audio' => MessageType.voice,
    'location' => MessageType.location,
    _ => MessageType.text,
  };

  String get previewText {
    if (deleted) return 'This message was deleted';
    if (expired) return 'Message expired';
    if (withheld) return viewOnce ? (withheldReason == 'opened' ? 'Opened' : 'View once message') : 'Protected file (admins only)';
    return switch (type) {
      'image' => text.isNotEmpty ? '📷 $text' : '📷 Photo',
      'video' => text.isNotEmpty ? '🎥 $text' : '🎥 Video',
      'audio' => '🎵 Audio',
      'voice' => '🎤 Voice message',
      'file' => '📄 ${media?.name ?? 'Document'}',
      'location' => '📍 ${location?.name ?? 'Location'}',
      'contact' => '👤 ${contact?.name ?? 'Contact'}',
      _ => text,
    };
  }

  ChatMessage toChatMessage() => ChatMessage(
    id: id,
    senderId: senderId,
    senderName: senderName,
    text: previewText,
    time: formatClock(createdAt),
    type: sharedType,
    visibility: visibility,
    isMine: isMine,
    isForwarded: forwarded,
    forwardCount: forwardDepth,
    isDeleted: deleted,
    replyTo: replyTo?.text,
    fileName: media?.name,
    fileSize: media == null ? null : formatBytes(media!.size),
    duration: media?.duration == null ? null : formatDuration(media!.duration),
  );

  GroupMessage copyWith({
    String? id,
    String? text,
    GroupMedia? media,
    List<DmReaction>? reactions,
    bool? starred,
    DeliveryStatus? status,
    double? uploadProgress,
    String? error,
    bool? withheld,
    bool? opened,
  }) => GroupMessage(
    id: id ?? this.id,
    groupId: groupId,
    clientMsgId: clientMsgId,
    senderId: senderId,
    senderName: senderName,
    senderAvatar: senderAvatar,
    type: type,
    text: text ?? this.text,
    media: media ?? this.media,
    location: location,
    contact: contact,
    visibility: visibility,
    permissions: permissions,
    viewOnce: viewOnce,
    opened: opened ?? this.opened,
    withheld: withheld ?? this.withheld,
    withheldReason: withheldReason,
    silent: silent,
    replyTo: replyTo,
    forwarded: forwarded,
    forwardDepth: forwardDepth,
    forwardCount: forwardCount,
    reactions: reactions ?? this.reactions,
    edited: edited,
    deleted: deleted,
    expired: expired,
    deletedReason: deletedReason,
    starred: starred ?? this.starred,
    status: status ?? this.status,
    systemEvent: systemEvent,
    createdAt: createdAt,
    localBytes: localBytes,
    localName: localName,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    error: error,
  );
}

// ---------------------------------------------------------------------------
// Message level screens
// ---------------------------------------------------------------------------
class ReceiptRow {
  const ReceiptRow({required this.userId, required this.displayName, this.avatarUrl, this.at});

  factory ReceiptRow.fromJson(Map<String, dynamic> j) => ReceiptRow(
    userId: j['userId'] as String,
    displayName: j['displayName'] as String? ?? 'Member',
    avatarUrl: j['avatarUrl'] as String?,
    at: _date(j['at']),
  );

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime? at;
}

class MessageInfoData {
  const MessageInfoData({required this.message, required this.groupName, this.receiptsVisible = false, this.readBy = const [], this.deliveredTo = const [], this.pending = const []});

  factory MessageInfoData.fromJson(Map<String, dynamic> j) => MessageInfoData(
    message: GroupMessage.fromJson(_map(j['message'])),
    groupName: j['groupName'] as String? ?? '',
    receiptsVisible: j['receiptsVisible'] == true,
    readBy: _list(j['readBy']).map(ReceiptRow.fromJson).toList(),
    deliveredTo: _list(j['deliveredTo']).map(ReceiptRow.fromJson).toList(),
    pending: _list(j['pending']).map(ReceiptRow.fromJson).toList(),
  );

  final GroupMessage message;
  final String groupName;
  final bool receiptsVisible;
  final List<ReceiptRow> readBy;
  final List<ReceiptRow> deliveredTo;
  final List<ReceiptRow> pending;
}

/// Converts the server forward tree to the shared [ForwardNode] used by [ChainTree].
ForwardNode chainNodeOf(Map<String, dynamic> j) => ForwardNode(
  messageId: j['messageId'] as String,
  parentId: j['parentId'] as String?,
  from: j['from'] as String? ?? 'Member',
  to: j['to'] as String? ?? 'Group',
  time: _date(j['time']) == null ? '' : formatClock(_date(j['time'])!),
  deleted: j['deleted'] == true,
  recipients: (j['recipients'] as num?)?.toInt() ?? 1,
  children: [for (final c in _list(j['children'])) chainNodeOf(c)],
);

class ChainTotals {
  const ChainTotals({this.usersReached = 0, this.forwards = 0, this.groups = 1, this.maxDepth = 0});

  factory ChainTotals.fromJson(Map<String, dynamic> j) => ChainTotals(
    usersReached: (j['usersReached'] as num?)?.toInt() ?? 0,
    forwards: (j['forwards'] as num?)?.toInt() ?? 0,
    groups: (j['groups'] as num?)?.toInt() ?? 1,
    maxDepth: (j['maxDepth'] as num?)?.toInt() ?? 0,
  );

  final int usersReached;
  final int forwards;
  final int groups;
  final int maxDepth;
}

class DeletePreviewData {
  const DeletePreviewData({required this.canDelete, required this.isOriginal, required this.chainRequired, required this.copiesAffected, required this.tree, required this.totals, this.reason, this.usersAffected = 0});

  factory DeletePreviewData.fromJson(Map<String, dynamic> j) => DeletePreviewData(
    canDelete: j['canDelete'] == true,
    reason: j['reason'] as String?,
    isOriginal: j['isOriginal'] == true,
    chainRequired: j['chainRequired'] == true,
    copiesAffected: (j['copiesAffected'] as num?)?.toInt() ?? 1,
    usersAffected: (j['usersAffected'] as num?)?.toInt() ?? 0,
    tree: chainNodeOf(_map(j['tree'])),
    totals: ChainTotals.fromJson(_map(j['totals'])),
  );

  final bool canDelete;
  final String? reason;
  final bool isOriginal;
  final bool chainRequired;
  final int copiesAffected;
  final int usersAffected;
  final ForwardNode tree;
  final ChainTotals totals;
}

class DeletionLocation {
  const DeletionLocation({required this.groupName, required this.label, required this.status, required this.users});

  factory DeletionLocation.fromJson(Map<String, dynamic> j) => DeletionLocation(
    groupName: j['groupName'] as String? ?? 'Group',
    label: j['label'] as String? ?? '',
    status: j['status'] as String? ?? 'Deleted',
    users: (j['users'] as num?)?.toInt() ?? 0,
  );

  final String groupName;
  final String label;
  final String status;
  final int users;
}

class DeletionStatusData {
  const DeletionStatusData({required this.deletedBy, required this.reason, required this.copiesRemoved, required this.totalCopies, required this.statusFlow, required this.locations, this.deletedAt, this.usersCleared = 0});

  factory DeletionStatusData.fromJson(Map<String, dynamic> j) => DeletionStatusData(
    deletedBy: j['deletedBy'] as String? ?? 'Member',
    deletedAt: _date(j['deletedAt']),
    reason: j['reason'] as String? ?? '',
    copiesRemoved: (j['copiesRemoved'] as num?)?.toInt() ?? 0,
    totalCopies: (j['totalCopies'] as num?)?.toInt() ?? 0,
    usersCleared: (j['usersCleared'] as num?)?.toInt() ?? 0,
    statusFlow: [for (final s in (j['statusFlow'] as List? ?? const [])) '$s'],
    locations: _list(j['locations']).map(DeletionLocation.fromJson).toList(),
  );

  final String deletedBy;
  final DateTime? deletedAt;
  final String reason;
  final int copiesRemoved;
  final int totalCopies;
  final int usersCleared;
  final List<String> statusFlow;
  final List<DeletionLocation> locations;
}

class ForwardDetailsData {
  const ForwardDetailsData({required this.forwarded, this.originSender, this.originGroup, this.originTime, this.forwardedBy, this.level = 0, this.totalLevels = 0, this.usersReached = 0, this.visibility = MessageVisibility.public, this.manyTimes = false});

  factory ForwardDetailsData.fromJson(Map<String, dynamic> j) {
    final o = _map(j['origin']);
    final c = _map(j['copy']);
    return ForwardDetailsData(
      forwarded: j['forwarded'] == true,
      originSender: o['senderName'] as String?,
      originGroup: o['groupName'] as String?,
      originTime: _date(o['time']),
      forwardedBy: c['forwardedBy'] as String?,
      level: (c['level'] as num?)?.toInt() ?? 0,
      totalLevels: (c['totalLevels'] as num?)?.toInt() ?? 0,
      usersReached: (c['usersReached'] as num?)?.toInt() ?? 0,
      visibility: visibilityOf(j['visibility'] as String?),
      manyTimes: j['manyTimes'] == true,
    );
  }

  final bool forwarded;
  final String? originSender;
  final String? originGroup;
  final DateTime? originTime;
  final String? forwardedBy;
  final int level;
  final int totalLevels;
  final int usersReached;
  final MessageVisibility visibility;
  final bool manyTimes;
}

// ---------------------------------------------------------------------------
// Protected files
// ---------------------------------------------------------------------------
class FileTokenData {
  const FileTokenData({
    required this.streamUrl,
    required this.name,
    required this.mimeType,
    required this.kind,
    required this.size,
    required this.visibility,
    required this.watermarkName,
    required this.maskedId,
    required this.watermark,
    this.expiresIn = 1800,
    this.senderName = '',
    this.sentAt,
    this.caption = '',
    this.screenshotProtection = true,
  });

  factory FileTokenData.fromJson(Map<String, dynamic> j) {
    final w = _map(j['watermark']);
    return FileTokenData(
      streamUrl: ApiConfig.mediaUrl(j['streamPath'] as String),
      name: j['name'] as String? ?? 'file',
      mimeType: j['mimeType'] as String? ?? 'application/octet-stream',
      kind: j['kind'] as String? ?? 'file',
      size: (j['size'] as num?)?.toInt() ?? 0,
      visibility: visibilityOf(j['visibility'] as String?),
      watermarkName: w['name'] as String? ?? '',
      maskedId: w['maskedId'] as String? ?? '',
      watermark: w['enabled'] == true,
      expiresIn: (j['expiresIn'] as num?)?.toInt() ?? 1800,
      senderName: j['senderName'] as String? ?? '',
      sentAt: _date(j['sentAt']),
      caption: j['caption'] as String? ?? '',
      screenshotProtection: j['screenshotProtection'] != false,
    );
  }

  final String streamUrl;
  final String name;
  final String mimeType;
  final String kind;
  final int size;
  final MessageVisibility visibility;
  final String watermarkName;
  final String maskedId;
  final bool watermark;
  final int expiresIn;

  /// Secure viewer header: who sent it, when, and the description they added.
  final String senderName;
  final DateTime? sentAt;
  final String caption;
  final bool screenshotProtection;
}

class FileInfoData {
  const FileInfoData({
    required this.fileId,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.kind,
    required this.groupName,
    required this.visibility,
    required this.permissions,
    required this.revoked,
    required this.canManage,
    this.message,
    this.direct = false,
    this.senderName = '',
    this.sentAt,
    this.caption = '',
  });

  factory FileInfoData.fromJson(Map<String, dynamic> j) => FileInfoData(
    fileId: j['fileId'] as String,
    name: j['name'] as String? ?? 'file',
    size: (j['size'] as num?)?.toInt() ?? 0,
    mimeType: j['mimeType'] as String? ?? '',
    kind: j['kind'] as String? ?? 'file',
    groupName: j['groupName'] as String? ?? '',
    visibility: visibilityOf(j['visibility'] as String?),
    permissions: GroupPermissions.fromJson(_map(j['permissions'])),
    revoked: j['revoked'] == true,
    canManage: j['canManage'] == true,
    message: j['message'] is Map ? GroupMessage.fromJson(_map(j['message'])) : null,
    direct: j['direct'] == true,
    senderName: j['senderName'] as String? ?? '',
    sentAt: _date(j['sentAt']),
    caption: j['caption'] as String? ?? '',
  );

  final String fileId;
  final String name;
  final int size;
  final String mimeType;
  final String kind;
  final String groupName;
  final MessageVisibility visibility;
  final GroupPermissions permissions;
  final bool revoked;
  final bool canManage;

  /// Group message the file belongs to (null for 1-to-1 chats).
  final GroupMessage? message;

  /// File sent in a 1-to-1 chat (no group permissions to manage).
  final bool direct;
  final String senderName;
  final DateTime? sentAt;
  final String caption;
}

class AccessLogEntry {
  const AccessLogEntry({required this.displayName, required this.action, this.at});

  factory AccessLogEntry.fromJson(Map<String, dynamic> j) =>
      AccessLogEntry(displayName: j['displayName'] as String? ?? 'Member', action: j['action'] as String? ?? '', at: _date(j['at']));

  final String displayName;
  final String action;
  final DateTime? at;

  String get label => switch (action) {
    'uploaded' => 'Uploaded - encrypted, token issued',
    'token_issued' => 'Opened secure viewer',
    'viewed' => 'Viewed in secure viewer',
    'denied' => 'Access denied',
    'download_blocked' => 'Download attempt blocked',
    'share_blocked' => 'Share attempt blocked',
    'print_blocked' => 'Print attempt blocked',
    'copy_blocked' => 'Copy attempt blocked',
    'open_with_blocked' => 'Open with attempt blocked',
    'screenshot_attempt' => 'Screenshot attempt',
    _ => action,
  };
}

// ---------------------------------------------------------------------------
// Location & reports
// ---------------------------------------------------------------------------
class MemberLocation {
  const MemberLocation({required this.userId, required this.displayName, required this.status, this.avatarUrl, this.role = MemberRole.member, this.isMe = false, this.lat, this.lng, this.place, this.updatedAt});

  factory MemberLocation.fromJson(Map<String, dynamic> j) => MemberLocation(
    userId: j['userId'] as String,
    displayName: j['displayName'] as String? ?? 'Member',
    avatarUrl: j['avatarUrl'] as String?,
    role: roleOf(j['role'] as String?),
    isMe: j['isMe'] == true,
    status: j['status'] as String? ?? 'Off',
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
    place: j['place'] as String?,
    updatedAt: _date(j['updatedAt']),
  );

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final MemberRole role;
  final bool isMe;
  final String status;
  final double? lat;
  final double? lng;
  final String? place;
  final DateTime? updatedAt;

  bool get hasPosition => lat != null && lng != null && status != 'Off';
  String get placeLabel => place ?? (hasPosition ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}' : 'Not sharing');
}

class GroupLocationsData {
  const GroupLocationsData({required this.allowed, required this.groupName, this.visibility = LocationVisibility.adminOnly, this.members = const [], this.live = 0, this.stale = 0, this.off = 0});

  factory GroupLocationsData.fromJson(Map<String, dynamic> j) {
    final c = _map(j['counts']);
    return GroupLocationsData(
      allowed: j['allowed'] == true,
      groupName: j['groupName'] as String? ?? '',
      visibility: locVisibilityOf(j['visibility'] as String?),
      members: _list(j['members']).map(MemberLocation.fromJson).toList(),
      live: (c['live'] as num?)?.toInt() ?? 0,
      stale: (c['stale'] as num?)?.toInt() ?? 0,
      off: (c['off'] as num?)?.toInt() ?? 0,
    );
  }

  final bool allowed;
  final String groupName;
  final LocationVisibility visibility;
  final List<MemberLocation> members;
  final int live;
  final int stale;
  final int off;
}

class LocationGroupInfo {
  const LocationGroupInfo({required this.groupId, required this.name, required this.requirement, required this.visibility, required this.status, this.avatarUrl});

  factory LocationGroupInfo.fromJson(Map<String, dynamic> j) => LocationGroupInfo(
    groupId: j['groupId'] as String,
    name: j['name'] as String? ?? 'Group',
    avatarUrl: j['avatarUrl'] as String?,
    requirement: requirementOf(j['requirement'] as String?),
    visibility: locVisibilityOf(j['visibility'] as String?),
    status: j['status'] as String? ?? 'Off',
  );

  final String groupId;
  final String name;
  final String? avatarUrl;
  final LocationRequirement requirement;
  final LocationVisibility visibility;
  final String status;
}

class MyLocationData {
  const MyLocationData({required this.mode, required this.intervalMin, required this.liveActive, required this.groups, this.liveUntil, this.lastLat, this.lastLng, this.lastPlace, this.lastAccuracy, this.lastAt});

  factory MyLocationData.fromJson(Map<String, dynamic> j) {
    final s = _map(j['settings']);
    final l = _map(j['last']);
    return MyLocationData(
      mode: LocationShareMode.values.firstWhere((m) => m.name == s['mode'], orElse: () => LocationShareMode.join),
      intervalMin: (s['intervalMin'] as num?)?.toInt() ?? 10,
      liveUntil: _date(s['liveUntil']),
      liveActive: s['liveActive'] == true,
      groups: _list(j['groups']).map(LocationGroupInfo.fromJson).toList(),
      lastLat: (l['lat'] as num?)?.toDouble(),
      lastLng: (l['lng'] as num?)?.toDouble(),
      lastPlace: l['place'] as String?,
      lastAccuracy: (l['accuracy'] as num?)?.toDouble(),
      lastAt: _date(l['at']),
    );
  }

  final LocationShareMode mode;
  final int intervalMin;
  final DateTime? liveUntil;
  final bool liveActive;
  final List<LocationGroupInfo> groups;
  final double? lastLat;
  final double? lastLng;
  final String? lastPlace;
  final double? lastAccuracy;
  final DateTime? lastAt;
}

class LocationHistoryEntry {
  const LocationHistoryEntry({required this.lat, required this.lng, required this.source, this.place, this.groupName, this.at});

  factory LocationHistoryEntry.fromJson(Map<String, dynamic> j) => LocationHistoryEntry(
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    place: j['place'] as String?,
    source: j['source'] as String? ?? 'manual',
    groupName: j['groupName'] as String?,
    at: _date(j['at']),
  );

  final double lat;
  final double lng;
  final String? place;
  final String source;
  final String? groupName;
  final DateTime? at;

  String get placeLabel => place ?? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  String get sourceLabel => switch (source) {
    'join' => 'Join location${groupName == null ? '' : ' - $groupName'}',
    'live' => 'Live update',
    _ => 'Manual share',
  };
}

class UserReport {
  const UserReport({required this.id, required this.type, required this.reasons, required this.status, this.details = '', this.targetName, this.groupName, this.messagePreview, this.createdAt, this.resolution = ''});

  factory UserReport.fromJson(Map<String, dynamic> j) => UserReport(
    id: j['id'] as String,
    type: j['type'] as String? ?? 'message',
    reasons: [for (final r in (j['reasons'] as List? ?? const [])) '$r'],
    details: j['details'] as String? ?? '',
    status: j['status'] as String? ?? 'open',
    resolution: j['resolution'] as String? ?? '',
    targetName: j['targetName'] as String?,
    groupName: j['groupName'] as String?,
    messagePreview: j['messagePreview'] as String?,
    createdAt: _date(j['createdAt']),
  );

  final String id;
  final String type;
  final List<String> reasons;
  final String details;
  final String status;
  final String resolution;
  final String? targetName;
  final String? groupName;
  final String? messagePreview;
  final DateTime? createdAt;

  String get typeLabel => switch (type) {
    'user' => 'Member',
    'group' => 'Group',
    _ => 'Message',
  };

  String get statusLabel => switch (status) {
    'reviewing' => 'Under review',
    'resolved' => 'Resolved',
    'rejected' => 'Rejected',
    _ => 'Pending',
  };
}
