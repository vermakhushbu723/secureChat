import 'dart:typed_data';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../secure_message/state/message_draft.dart';
import '../data/group_repository.dart';
import 'group_chat_controller.dart';

/// Sending from screens outside the chat (full composer, attachments, voice,
/// reply, my location). The chat shows the result through the realtime echo.
class GroupSender {
  GroupSender._();

  static Future<SendBlocked?> _send(String groupId, Map<String, dynamic> payload, MessageVisibility v) async {
    try {
      await GroupRepository.send({
        ...payload,
        ...MessageDraft.instance.payload(v),
        'groupId': groupId,
        'clientMsgId': newClientMsgId(),
      });
      MessageDraft.instance.resetAfterSend();
      return null;
    } on ApiException catch (e) {
      return SendBlocked.from(e);
    }
  }

  static Future<SendBlocked?> text(String groupId, String text, MessageVisibility v, {String? replyToId}) =>
      _send(groupId, {'type': 'text', 'text': text.trim(), 'replyToId': ?replyToId}, v);

  static Future<SendBlocked?> location(String groupId, DmLocation location, {bool live = false}) =>
      _send(groupId, {'type': 'location', 'location': {...location.toJson(), 'live': live}}, MessageVisibility.public);

  /// Uploads (encrypted for protected levels) then sends one message.
  static Future<SendBlocked?> file(
    String groupId,
    Uint8List bytes,
    String name,
    String type,
    MessageVisibility v, {
    String caption = '',
    double? duration,
    void Function(double)? onProgress,
  }) async {
    try {
      final media = await GroupRepository.upload(
        bytes,
        name,
        secure: v != MessageVisibility.public,
        kind: type == 'voice' ? 'voice' : null,
        duration: duration,
        onProgress: onProgress,
      );
      return _send(groupId, {'type': type, 'text': caption, 'media': media.toSendJson()}, v);
    } on ApiException catch (e) {
      return SendBlocked.from(e);
    }
  }

  /// Shows the right feedback for a refused message. Returns true when sent.
  static Future<bool> handle(BuildContext context, SendBlocked? blocked, {String? sent}) async {
    if (blocked == null) {
      if (sent != null && context.mounted) context.showSnack(sent);
      return true;
    }
    if (!context.mounted) return false;
    if (blocked.isContent) {
      context.push(blocked.restrictionRoute);
    } else if (blocked.code == planRequiredCode) {
      await showPlanRequired(context, blocked.message);
    } else {
      context.showSnack(blocked.message);
    }
    return false;
  }

  /// Message type for a picked file name.
  static String typeOf(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext)) return 'image';
    if (const ['mp4', 'mov', 'webm', 'mkv', '3gp'].contains(ext)) return 'video';
    if (const ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus'].contains(ext)) return 'audio';
    return 'file';
  }
}
