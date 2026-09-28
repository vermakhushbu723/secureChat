import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/core.dart';
import '../../groups/state/group_chat_controller.dart';
import '../../groups/state/group_sender.dart';
import '../../secure_message/state/message_draft.dart';
import 'chat_input_bar.dart' show pickVisibility;

/// Group chat input: privacy level, emoji, attachments, camera, voice,
/// reply / edit bar and the reason when the member may not send.
class GroupComposer extends StatefulWidget {
  const GroupComposer({super.key, required this.chat});

  final GroupChatController chat;

  @override
  State<GroupComposer> createState() => _GroupComposerState();
}

class _GroupComposerState extends State<GroupComposer> {
  final _text = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _onKey);
  bool _hasText = false;
  bool _showEmoji = false;
  String? _editingId;
  MessageVisibility _visibility = Session.defaultVisibility.value;

  GroupChatController get chat => widget.chat;

  static final _hardwareKeyboard =
      kIsWeb || const [TargetPlatform.windows, TargetPlatform.macOS, TargetPlatform.linux].contains(defaultTargetPlatform);

  @override
  void initState() {
    super.initState();
    chat.addListener(_onChatChanged);
    _focus.addListener(() {
      if (_focus.hasFocus && _showEmoji) setState(() => _showEmoji = false);
    });
  }

  void _onChatChanged() {
    final editing = chat.editing;
    if (editing?.id == _editingId) return;
    _editingId = editing?.id;
    if (editing != null) {
      _text.text = editing.text;
      _hasText = true;
      _focus.requestFocus();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    chat.removeListener(_onChatChanged);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (!_hardwareKeyboard || event is! KeyDownEvent) return KeyEventResult.ignored;
    final enter = event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!enter || HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    _send();
    return KeyEventResult.handled;
  }

  void _changed(String v) {
    final has = v.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
    chat.onComposerChanged(v);
  }

  Future<void> _send() async {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    _text.clear();
    setState(() => _hasText = false);
    final blocked = await chat.sendText(text, visibility: _visibility);
    if (blocked != null && mounted) {
      if (blocked.isContent) _text.text = text; // let the user edit it
      await GroupSender.handle(context, blocked);
    }
  }

  /// Attach inside the chat (no extra page): the privacy chosen with the lock icon applies.
  Future<void> _attach() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Row(
                  children: [
                    Icon(chat.visibilityFor(_visibility).icon, size: 18, color: ctx.palette.textSecondary),
                    const SizedBox(width: 6),
                    Text('Sending as ${chat.visibilityFor(_visibility).label}', style: TextStyle(color: ctx.palette.textSecondary)),
                  ],
                ),
              ),
              Wrap(
                spacing: 20,
                runSpacing: 16,
                children: [
                  for (final o in const [
                    ('gallery', Icons.photo_library_outlined, 'Gallery'),
                    ('camera', Icons.photo_camera_outlined, 'Camera'),
                    ('document', Icons.insert_drive_file_outlined, 'Document'),
                    ('audio', Icons.headphones_outlined, 'Audio'),
                    ('location', Icons.location_on_outlined, 'Location'),
                  ])
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(ctx, o.$1),
                      child: SizedBox(
                        width: 68,
                        child: Column(
                          children: [
                            CircleAvatar(radius: 26, backgroundColor: AppColors.primary, foregroundColor: Colors.white, child: Icon(o.$2)),
                            const SizedBox(height: 6),
                            Text(o.$3, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'camera') return _camera();
    if (choice == 'location') {
      context.push(AppRoutes.myLocationFor(chat.groupId));
      return;
    }
    final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        type: switch (choice) {
          'gallery' => FileType.media,
          'audio' => FileType.audio,
          _ => FileType.any,
        },
      );
    } catch (e) {
      if (mounted) context.showSnack('Could not open picker: $e');
      return;
    }
    for (final f in files) {
      if (!mounted) return;
      final bytes = await f.readAsBytes();
      final blocked = await chat.sendFile(bytes, f.name, GroupSender.typeOf(f.name), visibility: _visibility);
      if (blocked != null && mounted) {
        await GroupSender.handle(context, blocked);
        return;
      }
    }
  }

  Future<void> _camera() async {
    final XFile? shot;
    try {
      shot = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2048);
    } catch (e) {
      if (mounted) context.showSnack('Camera unavailable: $e');
      return;
    }
    if (shot == null) return;
    final bytes = await shot.readAsBytes();
    final name = shot.name.contains('.') ? shot.name : '${shot.name}.jpg';
    final blocked = await chat.sendFile(bytes, name, 'image', visibility: _visibility);
    if (mounted) await GroupSender.handle(context, blocked);
  }

  Future<void> _pickPrivacy() async {
    final mode = chat.detail?.settings.messageMode ?? 'user_select';
    if (mode != 'user_select') {
      context.showSnack('Group admin set message mode to ${mode == 'public' ? 'Public' : 'Private'}');
      return;
    }
    final v = await pickVisibility(context, _visibility);
    if (v != null) setState(() => _visibility = v);
  }

  @override
  Widget build(BuildContext context) {
    // The server decides (own plan, or the group's premium when the creator allows it).
    final reason = _blockedReason();
    final needsPlan = chat.detail?.me.sendBlockedCode == 'SUBSCRIPTION_REQUIRED';
    if (reason != null) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(needsPlan ? Icons.workspace_premium_outlined : Icons.lock_outline, color: context.palette.textSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text(reason, style: TextStyle(color: context.palette.textSecondary))),
              if (needsPlan) TextButton(onPressed: () => context.push(AppRoutes.trialStatus), child: const Text('Upgrade')),
            ],
          ),
        ),
      );
    }

    final effective = chat.visibilityFor(_visibility);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.palette.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chat.replyTo != null || chat.editing != null) _ContextBar(chat: chat, onClose: _closeContext),
            ListenableBuilder(
              listenable: MessageDraft.instance,
              builder: (context, _) {
                final d = MessageDraft.instance;
                if (d.expiry == 'never' && !d.silent) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Row(
                    children: [
                      Icon(Icons.tune, size: 14, color: context.palette.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [if (d.expiry != 'never') 'Expiry: ${d.expiryLabel}', if (d.silent) 'Silent'].join('  |  '),
                          style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
                        ),
                      ),
                      InkWell(
                        onTap: () => d.update(expiry: 'never', silent: false),
                        child: Icon(Icons.close, size: 16, color: context.palette.textSecondary),
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 10), child: _inputRow(context, effective)),
            if (_showEmoji)
              EmojiPicker(
                textEditingController: _text,
                onEmojiSelected: (_, _) => _changed(_text.text),
                onBackspacePressed: () => _changed(_text.text),
                config: Config(
                  height: 280,
                  emojiViewConfig: EmojiViewConfig(backgroundColor: context.colors.surface, emojiSizeMax: 28),
                  categoryViewConfig: CategoryViewConfig(
                    initCategory: Category.SMILEYS,
                    backgroundColor: context.colors.surface,
                    indicatorColor: context.colors.primary,
                    iconColorSelected: context.colors.primary,
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(
                    backgroundColor: context.colors.surface,
                    buttonColor: context.colors.surface,
                    buttonIconColor: context.palette.textSecondary,
                  ),
                  searchViewConfig: SearchViewConfig(backgroundColor: context.colors.surface),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _blockedReason() {
    if (chat.removedReason != null) {
      return switch (chat.removedReason) {
        'deleted' => 'This group was deleted.',
        'left' => 'You left this group.',
        _ => 'You are no longer a member of this group.',
      };
    }
    final d = chat.detail;
    if (d == null) return null;
    if (!d.summary.isActive) return 'This group is suspended by the platform admin.';
    if (!d.me.canSend) return d.me.sendBlockedMessage ?? 'You cannot send messages in this group.';
    return null;
  }

  void _closeContext() {
    if (chat.editing != null) {
      _text.clear();
      _hasText = false;
      chat.startEdit(null);
    } else {
      chat.setReply(null);
    }
  }

  Widget _inputRow(BuildContext context, MessageVisibility effective) {
    final editing = chat.editing != null;
    final fixed = (chat.detail?.settings.messageMode ?? 'user_select') != 'user_select';
    final canMedia = chat.detail?.me.canSendMedia ?? true;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: context.palette.surfaceAlt, borderRadius: BorderRadius.circular(22)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Privacy: ${effective.label}${fixed ? ' (set by admin)' : ''}',
                  icon: Icon(effective.icon, color: effective == MessageVisibility.public ? null : context.colors.primary),
                  onPressed: editing ? null : _pickPrivacy,
                ),
                IconButton(
                  tooltip: 'Emoji',
                  icon: Icon(_showEmoji ? Icons.keyboard_outlined : Icons.emoji_emotions_outlined),
                  onPressed: () {
                    setState(() => _showEmoji = !_showEmoji);
                    _showEmoji ? _focus.unfocus() : _focus.requestFocus();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 6,
                    maxLength: 4096,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: _changed,
                    decoration: InputDecoration(
                      hintText: 'Message (${effective.label})',
                      counterText: '',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (!editing) ...[
                  if (canMedia) IconButton(tooltip: 'Attach', icon: const Icon(Icons.attach_file), onPressed: _attach),
                  if (!_hasText && canMedia)
                    IconButton(tooltip: 'Camera', icon: const Icon(Icons.photo_camera_outlined), onPressed: _camera),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton.filled(
            color: Colors.white,
            tooltip: _hasText || editing ? 'Send' : 'Voice message',
            icon: Icon(editing ? Icons.check : (_hasText || !canMedia ? Icons.send : Icons.mic_none)),
            onPressed: _hasText || editing
                ? _send
                : canMedia
                ? () => context.push(AppRoutes.voiceMessageOf(chat.groupId))
                : null,
          ),
        ),
      ],
    );
  }
}

class _ContextBar extends StatelessWidget {
  const _ContextBar({required this.chat, required this.onClose});

  final GroupChatController chat;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final editing = chat.editing;
    final m = editing ?? chat.replyTo!;
    final title = editing != null ? 'Edit message' : (m.isMine ? 'You' : m.senderName);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: context.colors.primary, width: 4)),
      ),
      child: Row(
        children: [
          Icon(editing != null ? Icons.edit_outlined : Icons.reply, size: 20, color: context.palette.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(m.previewText, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }
}
