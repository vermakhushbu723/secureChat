import 'dart:math';
import 'dart:typed_data';

import '../../../core/core.dart';

enum DmType { text, image, video, audio, voice, file, location, contact, sticker }

/// `pending` / `failed` exist only on the device (optimistic sending).
enum DeliveryStatus { pending, sent, delivered, read, failed }

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();

DmType dmTypeOf(String? v) => DmType.values.firstWhere((t) => t.name == v, orElse: () => DmType.text);

DeliveryStatus statusOf(String? v) =>
    DeliveryStatus.values.firstWhere((s) => s.name == v, orElse: () => DeliveryStatus.sent);

final _rand = Random.secure();

/// Unique per message; lets the server de-duplicate retries.
/// Random part uses two 30-bit draws: `1 << 32` overflows to 0 on the web (JS ints).
String newClientMsgId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
    '${_rand.nextInt(1 << 30).toRadixString(36)}${_rand.nextInt(1 << 30).toRadixString(36)}';

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
}

class DmUser {
  const DmUser({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
    this.about = '',
    this.lastSeenAt,
    this.online = false,
    this.isBlocked = false,
    this.phone,
    this.email,
    this.accountType = 'personal',
    this.businessAddress,
  });

  factory DmUser.fromJson(Map<String, dynamic> j) => DmUser(
    id: j['id'] as String,
    name: j['name'] as String? ?? 'User',
    username: j['username'] as String?,
    avatarUrl: j['avatarUrl'] as String?,
    about: j['about'] as String? ?? '',
    lastSeenAt: _date(j['lastSeenAt']),
    online: j['online'] == true,
    isBlocked: j['isBlocked'] == true,
    phone: j['phone'] as String?,
    email: j['email'] as String?,
    accountType: j['accountType'] as String? ?? 'personal',
    businessAddress: j['businessAddress'] as String?,
  );

  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;
  final String about;
  final DateTime? lastSeenAt;
  final bool online;
  final bool isBlocked;

  /// Only present when the user turned on "Show mobile number & email".
  final String? phone;
  final String? email;
  final String accountType;
  final String? businessAddress;

  bool get isBusiness => accountType == 'business';

  String get initials => initialsOf(name);

  DmUser copyWith({bool? online, DateTime? lastSeenAt, bool? isBlocked}) => DmUser(
    id: id,
    name: name,
    username: username,
    avatarUrl: avatarUrl,
    about: about,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    online: online ?? this.online,
    isBlocked: isBlocked ?? this.isBlocked,
    phone: phone,
    email: email,
    accountType: accountType,
    businessAddress: businessAddress,
  );
}

class DmMedia {
  const DmMedia({
    required this.url,
    this.thumbUrl,
    this.mimeType = 'application/octet-stream',
    this.name,
    this.size = 0,
    this.width,
    this.height,
    this.duration,
    this.secure = false,
    this.fileId,
  });

  factory DmMedia.fromJson(Map<String, dynamic> j) => DmMedia(
    url: j['url'] as String? ?? '',
    secure: j['secure'] == true,
    fileId: j['fileId'] as String? ?? j['secureFileId'] as String?,
    thumbUrl: j['thumbUrl'] as String?,
    mimeType: j['mimeType'] as String? ?? 'application/octet-stream',
    name: j['name'] as String?,
    size: (j['size'] as num?)?.toInt() ?? 0,
    width: (j['width'] as num?)?.toInt(),
    height: (j['height'] as num?)?.toInt(),
    duration: (j['duration'] as num?)?.toDouble(),
  );

  final String url;
  final String? thumbUrl;
  final String mimeType;
  final String? name;
  final int size;
  final int? width;
  final int? height;
  final double? duration;

  /// Private / Highly Protected: encrypted, no URL, opened in the secure viewer.
  final bool secure;
  final String? fileId;

  String get fullUrl => ApiConfig.mediaUrl(url);
  String get previewUrl => ApiConfig.mediaUrl(thumbUrl ?? url);

  Map<String, dynamic> toJson() => secure
      ? {'secure': true, 'secureFileId': fileId, 'mimeType': mimeType, 'name': ?name, 'size': size, 'duration': ?duration}
      : {
    'url': url,
    'thumbUrl': ?thumbUrl,
    'mimeType': mimeType,
    'name': ?name,
    'size': size,
    'width': ?width,
    'height': ?height,
    'duration': ?duration,
  };
}

class DmLocation {
  const DmLocation({required this.lat, required this.lng, this.name, this.address});

  factory DmLocation.fromJson(Map<String, dynamic> j) => DmLocation(
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    name: j['name'] as String?,
    address: j['address'] as String?,
  );

  final double lat;
  final double lng;
  final String? name;
  final String? address;

  String get mapsUrl => 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'name': ?name, 'address': ?address};
}

class DmContact {
  const DmContact({required this.name, required this.phone});

  factory DmContact.fromJson(Map<String, dynamic> j) =>
      DmContact(name: j['name'] as String? ?? '', phone: j['phone'] as String? ?? '');

  final String name;
  final String phone;

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
}

class DmReply {
  const DmReply({required this.id, required this.senderId, required this.type, required this.text});

  factory DmReply.fromJson(Map<String, dynamic> j) => DmReply(
    id: j['id'] as String,
    senderId: j['senderId'] as String,
    type: dmTypeOf(j['type'] as String?),
    text: j['text'] as String? ?? '',
  );

  final String id;
  final String senderId;
  final DmType type;
  final String text;
}

class DmReaction {
  const DmReaction(this.userId, this.emoji);

  final String userId;
  final String emoji;
}

class DmMessage {
  const DmMessage({
    required this.id,
    required this.conversationId,
    required this.clientMsgId,
    required this.senderId,
    required this.type,
    required this.createdAt,
    this.recipientId = '',
    this.text = '',
    this.media,
    this.location,
    this.contact,
    this.replyTo,
    this.forwarded = false,
    this.forwardCount = 0,
    this.reactions = const [],
    this.edited = false,
    this.deleted = false,
    this.starred = false,
    this.status = DeliveryStatus.sent,
    this.localBytes,
    this.localName,
    this.uploadProgress,
    this.error,
    this.visibility = 'public',
    this.canForward = true,
    this.canCopy = true,
  });

  factory DmMessage.fromJson(Map<String, dynamic> j) => DmMessage(
    id: j['id'] as String,
    conversationId: j['conversationId'] as String,
    clientMsgId: j['clientMsgId'] as String? ?? '',
    senderId: j['senderId'] as String,
    recipientId: j['recipientId'] as String? ?? '',
    type: dmTypeOf(j['type'] as String?),
    text: j['text'] as String? ?? '',
    media: j['media'] is Map ? DmMedia.fromJson(Map<String, dynamic>.from(j['media'] as Map)) : null,
    location: j['location'] is Map ? DmLocation.fromJson(Map<String, dynamic>.from(j['location'] as Map)) : null,
    contact: j['contact'] is Map ? DmContact.fromJson(Map<String, dynamic>.from(j['contact'] as Map)) : null,
    replyTo: j['replyTo'] is Map ? DmReply.fromJson(Map<String, dynamic>.from(j['replyTo'] as Map)) : null,
    forwarded: j['forwarded'] == true,
    forwardCount: (j['forwardCount'] as num?)?.toInt() ?? 0,
    reactions: [
      for (final r in (j['reactions'] as List? ?? const [])) DmReaction('${(r as Map)['userId']}', '${r['emoji']}'),
    ],
    edited: j['edited'] == true,
    deleted: j['deleted'] == true,
    starred: j['starred'] == true,
    status: statusOf(j['status'] as String?),
    createdAt: _date(j['createdAt']) ?? DateTime.now(),
    visibility: j['visibility'] as String? ?? 'public',
    canForward: (j['permissions'] as Map?)?['canForward'] != false,
    canCopy: (j['permissions'] as Map?)?['canCopy'] != false,
  );

  /// Server id; empty while the message is still being sent.
  final String id;
  final String conversationId;
  final String clientMsgId;
  final String senderId;
  final String recipientId;
  final DmType type;
  final String text;
  final DmMedia? media;
  final DmLocation? location;
  final DmContact? contact;
  final DmReply? replyTo;
  final bool forwarded;
  final int forwardCount;
  final List<DmReaction> reactions;
  final bool edited;
  final bool deleted;
  final bool starred;
  final DeliveryStatus status;
  final DateTime createdAt;

  // Local only (optimistic upload preview / progress).
  final Uint8List? localBytes;
  final String? localName;
  final double? uploadProgress;
  final String? error;

  /// public | private | highly_protected (chosen by the sender).
  final String visibility;
  final bool canForward;
  final bool canCopy;

  bool get isProtected => visibility != 'public';
  bool get isPending => id.isEmpty;
  bool get isMine => senderId == AuthService.instance.userId;
  bool get isMedia =>
      const [DmType.image, DmType.video, DmType.audio, DmType.voice, DmType.file, DmType.sticker].contains(type);
  String get key => clientMsgId.isNotEmpty ? clientMsgId : id;

  String? myReaction(String userId) {
    for (final r in reactions) {
      if (r.userId == userId) return r.emoji;
    }
    return null;
  }

  DmMessage copyWith({
    String? id,
    String? text,
    DmMedia? media,
    List<DmReaction>? reactions,
    bool? edited,
    bool? deleted,
    bool? starred,
    DeliveryStatus? status,
    double? uploadProgress,
    String? error,
  }) => DmMessage(
    id: id ?? this.id,
    conversationId: conversationId,
    clientMsgId: clientMsgId,
    senderId: senderId,
    recipientId: recipientId,
    type: type,
    text: text ?? this.text,
    media: media ?? this.media,
    location: location,
    contact: contact,
    replyTo: replyTo,
    forwarded: forwarded,
    forwardCount: forwardCount,
    reactions: reactions ?? this.reactions,
    edited: edited ?? this.edited,
    deleted: deleted ?? this.deleted,
    starred: starred ?? this.starred,
    status: status ?? this.status,
    createdAt: createdAt,
    localBytes: localBytes,
    localName: localName,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    error: error,
    visibility: visibility,
    canForward: canForward,
    canCopy: canCopy,
  );
}

class DmLastMessage {
  const DmLastMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.text,
    required this.createdAt,
    this.deleted = false,
    this.status = DeliveryStatus.sent,
  });

  factory DmLastMessage.fromJson(Map<String, dynamic> j) => DmLastMessage(
    id: j['id'] as String,
    senderId: j['senderId'] as String,
    type: dmTypeOf(j['type'] as String?),
    text: j['text'] as String? ?? '',
    deleted: j['deleted'] == true,
    status: statusOf(j['status'] as String?),
    createdAt: _date(j['createdAt']) ?? DateTime.now(),
  );

  factory DmLastMessage.of(DmMessage m) => DmLastMessage(
    id: m.id,
    senderId: m.senderId,
    type: m.type,
    text: previewOf(m),
    deleted: m.deleted,
    status: m.status,
    createdAt: m.createdAt,
  );

  final String id;
  final String senderId;
  final DmType type;
  final String text;
  final bool deleted;
  final DeliveryStatus status;
  final DateTime createdAt;

  DmLastMessage copyWith({String? text, bool? deleted, DeliveryStatus? status}) => DmLastMessage(
    id: id,
    senderId: senderId,
    type: type,
    text: text ?? this.text,
    deleted: deleted ?? this.deleted,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}

class DmConversation {
  const DmConversation({
    required this.id,
    required this.peer,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.pinned = false,
    this.archived = false,
    this.muted = false,
    this.isBlocked = false,
    this.blockedMe = false,
  });

  factory DmConversation.fromJson(Map<String, dynamic> j) => DmConversation(
    id: j['id'] as String,
    peer: DmUser.fromJson(Map<String, dynamic>.from(j['peer'] as Map)),
    lastMessage: j['lastMessage'] is Map
        ? DmLastMessage.fromJson(Map<String, dynamic>.from(j['lastMessage'] as Map))
        : null,
    lastMessageAt: _date(j['lastMessageAt']),
    unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
    pinned: j['pinned'] == true,
    archived: j['archived'] == true,
    muted: j['muted'] == true,
    isBlocked: j['isBlocked'] == true,
    blockedMe: j['blockedMe'] == true,
  );

  final String id;
  final DmUser peer;
  final DmLastMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool pinned;
  final bool archived;
  final bool muted;
  final bool isBlocked;
  final bool blockedMe;

  DmConversation copyWith({
    DmUser? peer,
    DmLastMessage? lastMessage,
    bool clearLastMessage = false,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? pinned,
    bool? archived,
    bool? muted,
    bool? isBlocked,
  }) => DmConversation(
    id: id,
    peer: peer ?? this.peer,
    lastMessage: clearLastMessage ? null : (lastMessage ?? this.lastMessage),
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
    pinned: pinned ?? this.pinned,
    archived: archived ?? this.archived,
    muted: muted ?? this.muted,
    isBlocked: isBlocked ?? this.isBlocked,
    blockedMe: blockedMe,
  );
}

/// Same wording as the server's chat list preview.
String previewOf(DmMessage m) {
  if (m.deleted) return 'This message was deleted';
  return switch (m.type) {
    DmType.text => m.text,
    DmType.image => m.text.isNotEmpty ? '📷 ${m.text}' : '📷 Photo',
    DmType.video => m.text.isNotEmpty ? '🎥 ${m.text}' : '🎥 Video',
    DmType.audio => '🎵 Audio',
    DmType.voice => '🎤 Voice message',
    DmType.file => '📄 ${m.media?.name ?? 'File'}',
    DmType.location => '📍 Location',
    DmType.contact => '👤 ${m.contact?.name ?? 'Contact'}',
    DmType.sticker => 'Sticker',
  };
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatDuration(num? seconds) {
  final s = (seconds ?? 0).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

String formatClock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// Chat list time: clock today, "Yesterday", weekday this week, else date.
String formatListTime(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return formatClock(t);
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];
  return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year % 100}';
}

String formatDayHeader(DateTime t) {
  final now = DateTime.now();
  final diff = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  if (diff == 0) return 'TODAY';
  if (diff == 1) return 'YESTERDAY';
  const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  return '${t.day} ${months[t.month - 1]} ${t.year}';
}

String lastSeenLabel(DmUser u) {
  if (u.online) return 'online';
  final t = u.lastSeenAt;
  if (t == null) return 'tap here for contact info';
  final list = formatListTime(t);
  return list.contains(':') ? 'last seen today at $list' : 'last seen $list at ${formatClock(t)}';
}
