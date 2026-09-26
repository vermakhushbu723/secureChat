import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Enums
// -----------------------------------------------------------------------------

/// Message security level chosen by the sender for every message / file.
enum MessageVisibility {
  /// Level 1 - view, forward allowed. Download / screenshot configurable.
  public,

  /// Level 2 - no forward, no download, no external share, no screenshot.
  private,

  /// Level 3 - level 2 + no copy, no recording, dynamic watermark.
  highlyProtected;

  String get label => switch (this) {
    public => 'Public',
    private => 'Private',
    highlyProtected => 'Highly Protected',
  };

  String get levelLabel => switch (this) {
    public => 'Level 1',
    private => 'Level 2',
    highlyProtected => 'Level 3',
  };

  IconData get icon => switch (this) {
    public => Icons.public,
    private => Icons.lock_outline,
    highlyProtected => Icons.admin_panel_settings_outlined,
  };

  bool get canForward => this == public;
  bool get canCopy => this == public;
  bool get isProtected => this != public;
}

enum MessageType { text, image, video, document, voice, location }

enum MessageStatus { active, deletedForEveryone, blocked }

enum UserStatus { active, blocked, suspended, trial }

/// What the user is currently allowed to do.
enum AccessType {
  trial,
  free,
  premium,
  extended,
  locked;

  String get label => switch (this) {
    trial => 'Trial',
    free => 'Free',
    premium => 'Premium',
    extended => 'Extended',
    locked => 'Locked',
  };
}

enum MemberRole { owner, admin, member }

/// Group level location rule set by creator / admin.
enum LocationRequirement {
  off,
  optional,
  mandatory;

  String get label => switch (this) {
    off => 'Disabled',
    optional => 'Optional',
    mandatory => 'Mandatory',
  };
}

/// How the member shares location.
enum LocationShareMode {
  none,
  join,
  live;

  String get label => switch (this) {
    none => 'No Location',
    join => 'Join Location',
    live => 'Live Location',
  };
}

/// Who can see member locations of a group.
enum LocationVisibility { adminOnly, groupMembers, nobody }

/// Content rules applied before a message is sent.
enum ContentRule {
  numbers('Number Blocking', 'Digits like 1, 12, 9876543210', Icons.pin_outlined),
  numberWords('Number Words Blocking', 'ONE, TWO, NINETY9, T H R E E', Icons.text_fields),
  abuse('Abuse / Profanity Filter', 'Bad language and slurs', Icons.do_not_disturb_on_outlined),
  spam('Spam Detection', 'Repeated or promotional content', Icons.report_outlined),
  links('Link Blocking', 'http, www, .com links', Icons.link_off),
  externalContact('External Contact Blocking', 'WhatsApp / Telegram / Insta IDs', Icons.contact_phone_outlined),
  personalInfo('Personal Information Blocking', 'Email, address, ID numbers', Icons.badge_outlined);

  const ContentRule(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

// -----------------------------------------------------------------------------
// Entities
// -----------------------------------------------------------------------------

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.about = 'Available',
    this.status = UserStatus.active,
    this.access = AccessType.trial,
    this.role = MemberRole.member,
    this.isOnline = false,
    this.lastSeen = 'today at 10:30 AM',
    this.location = 'Unknown',
    this.locationEnabled = false,
    this.joinedOn = '12 Sep 2026',
    this.trialStart = '18 Sep 2026',
    this.trialEnd = '25 Sep 2026',
    this.warnings = 0,
  });

  /// Internal user ID - never shown to other group members.
  final String id;

  /// Full legal name - visible only to the user and admins.
  final String name;
  final String phone;
  final String email;
  final String about;
  final UserStatus status;
  final AccessType access;
  final MemberRole role;
  final bool isOnline;
  final String lastSeen;
  final String location;
  final bool locationEnabled;
  final String joinedOn;
  final String trialStart;
  final String trialEnd;
  final int warnings;

  /// Starting name shown to group members, e.g. "Rahul Sharma" -> "Rahul".
  String get displayName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Masked internal ID for watermarks, e.g. "USR-****2041".
  String get maskedId => 'USR-****${internalId.substring(internalId.length - 4)}';

  String get internalId => 'USR-${(100000 + id.codeUnits.fold(0, (a, c) => a * 31 + c) % 900000)}';
}

class ChatGroup {
  const ChatGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.lastMessage,
    required this.lastTime,
    required this.memberCount,
    this.unread = 0,
    this.location = LocationRequirement.off,
    this.locationVisibility = LocationVisibility.adminOnly,
    this.messageMode = 'User can select',
    this.muted = false,
    this.createdBy = 'Rahul',
    this.createdOn = '02 Sep 2026',
    this.status = 'Active',
    this.inviteCode = 'LKO-8F2K9Q',
  });

  final String id;
  final String name;
  final String description;
  final String lastMessage;
  final String lastTime;
  final int memberCount;
  final int unread;
  final LocationRequirement location;
  final LocationVisibility locationVisibility;
  final String messageMode;
  final bool muted;
  final String createdBy;
  final String createdOn;
  final String status;
  final String inviteCode;

  bool get locationRequired => location == LocationRequirement.mandatory;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.time,
    this.type = MessageType.text,
    this.visibility = MessageVisibility.public,
    this.isMine = false,
    this.isForwarded = false,
    this.forwardCount = 0,
    this.isDeleted = false,
    this.replyTo,
    this.fileName,
    this.fileSize,
    this.duration,
  });

  final String id;
  final String senderId;

  /// Display (starting) name of the sender - never phone / ID.
  final String senderName;
  final String text;
  final String time;
  final MessageType type;
  final MessageVisibility visibility;
  final bool isMine;
  final bool isForwarded;
  final int forwardCount;
  final bool isDeleted;
  final String? replyTo;
  final String? fileName;
  final String? fileSize;
  final String? duration;

  bool get isProtected => visibility.isProtected;
}

/// One node of a forward chain (internal IDs are visible only to admins).
class ForwardNode {
  const ForwardNode({
    required this.messageId,
    required this.parentId,
    required this.from,
    required this.to,
    required this.time,
    this.children = const [],
    this.deleted = false,
    this.recipients = 1,
  });

  final String messageId;
  final String? parentId;
  final String from;
  final String to;
  final String time;
  final List<ForwardNode> children;
  final bool deleted;
  final int recipients;

  int get totalCopies => recipients + children.fold(0, (s, c) => s + c.totalCopies);
}

class ForwardHop {
  const ForwardHop({
    required this.from,
    required this.to,
    required this.group,
    required this.time,
    this.deleted = false,
  });

  final String from;
  final String to;
  final String group;
  final String time;
  final bool deleted;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.kind,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final String kind; // message, group, security, subscription, system
  final bool isRead;
}

class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.isPopular = false,
    this.subscribers = 0,
    this.durationDays = 30,
  });

  final String id;
  final String name;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final int subscribers;
  final int durationDays;
}

class MediaItem {
  const MediaItem({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.date,
    this.visibility = MessageVisibility.public,
    this.sender = 'Rahul',
  });

  final String id;
  final String name;
  final MessageType type;
  final String size;
  final String date;
  final MessageVisibility visibility;
  final String sender;

  bool get isProtected => visibility.isProtected;
}

class InviteLink {
  const InviteLink({
    required this.code,
    required this.group,
    required this.createdBy,
    required this.expires,
    required this.joins,
    required this.maxJoins,
    required this.status,
    this.approval = false,
  });

  final String code;
  final String group;
  final String createdBy;
  final String expires;
  final int joins;
  final int maxJoins;
  final String status; // Active, Expired, Revoked
  final bool approval;

  String get url => 'app.securechat.in/group/$code';
}

class ExtensionRequest {
  const ExtensionRequest({
    required this.id,
    required this.userId,
    required this.user,
    required this.trialExpired,
    required this.reason,
    required this.requested,
    required this.date,
    required this.status,
  });

  final String id;
  final String userId;
  final String user;
  final String trialExpired;
  final String reason;
  final String requested; // 7 days / 30 days / Premium
  final String date;
  final String status; // Pending, Approved, Rejected
}

class BlockedMessage {
  const BlockedMessage({
    required this.user,
    required this.group,
    required this.text,
    required this.rule,
    required this.time,
    required this.warnings,
  });

  final String user;
  final String group;
  final String text;
  final ContentRule rule;
  final String time;
  final int warnings;
}

class LocationRecord {
  const LocationRecord({
    required this.user,
    required this.group,
    required this.place,
    required this.time,
    required this.mode,
    required this.status,
    required this.dx,
    required this.dy,
  });

  final String user;
  final String group;
  final String place;
  final String time;
  final LocationShareMode mode;
  final String status; // Live, Stale, Off
  final double dx;
  final double dy;
}

class ReportItem {
  const ReportItem({
    required this.id,
    required this.title,
    required this.reason,
    required this.reportedBy,
    required this.target,
    required this.date,
    required this.status,
    this.type = 'Message',
  });

  final String id;
  final String title;
  final String reason;
  final String reportedBy;
  final String target;
  final String date;
  final String status; // Pending, Reviewed, Resolved, Rejected
  final String type;
}

class AuditLog {
  const AuditLog({
    required this.actor,
    required this.action,
    required this.target,
    required this.time,
    required this.ip,
  });

  final String actor;
  final String action;
  final String target;
  final String time;
  final String ip;
}
