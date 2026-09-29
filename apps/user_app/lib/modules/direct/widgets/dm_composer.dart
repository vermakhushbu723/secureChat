import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/core.dart';
import '../../chat/widgets/chat_input_bar.dart' show pickVisibility;
import '../../groups/data/group_models.dart' show visibilityOf, visibilityValue;
import '../../secure_message/state/message_draft.dart';
import '../data/direct_models.dart';
import '../state/chat_controller.dart';

const _maxUploadBytes = 50 * 1024 * 1024;

/// Message input: text + emoji panel, attachments, voice notes, reply / edit bar.
class DmComposer extends StatefulWidget {
  const DmComposer({super.key, required this.chat});

  final ChatController chat;

  @override
  State<DmComposer> createState() => _DmComposerState();
}

class _DmComposerState extends State<DmComposer> {
  final _text = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _onKey);
  final _recorder = AudioRecorder();

  bool _hasText = false;
  bool _showEmoji = false;
  String? _editingId;

  bool _recording = false;
  DateTime? _recordStart;
  Timer? _recordTimer;
  Duration _recordElapsed = Duration.zero;
  String _recordExt = 'm4a';

  ChatController get chat => widget.chat;

  @override
  void initState() {
    super.initState();
    chat.addListener(_onChatChanged);
    _focus.addListener(() {
      if (_focus.hasFocus && _showEmoji) setState(() => _showEmoji = false);
    });
  }

  /// Entering edit mode pre-fills the input with the message text.
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
    _recordTimer?.cancel();
    _recorder.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String v) {
    final has = v.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
    chat.onComposerChanged(v);
  }

  /// Direct chats need your own trial / premium / extension.
  bool _planOk() {
    if (!Session.chatLocked) return true;
    showPlanRequired(context, 'Your free trial has ended. Upgrade to premium or request an extension to keep chatting.');
    return false;
  }

  /// Lock icon: Public / Private / Highly Protected, right in the chat (no extra page).
  Future<void> _pickPrivacy() async {
    final v = await pickVisibility(context, visibilityOf(chat.visibility));
    if (v != null) chat.setVisibility(visibilityValue(v));
  }

  void _send() {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    if (!_planOk()) return;
    _text.clear();
    setState(() => _hasText = false);
    chat.sendText(text).catchError((Object e) {
      if (mounted) context.showSnack('$e');
    });
  }

  static final _hardwareKeyboard =
      kIsWeb ||
      const [TargetPlatform.windows, TargetPlatform.macOS, TargetPlatform.linux].contains(defaultTargetPlatform);

  /// Web / desktop: Enter sends, Shift+Enter inserts a new line.
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (!_hardwareKeyboard || event is! KeyDownEvent) return KeyEventResult.ignored;
    final enter = event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!enter || HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    _send();
    return KeyEventResult.handled;
  }

  void _toggleEmoji() {
    setState(() => _showEmoji = !_showEmoji);
    _showEmoji ? _focus.unfocus() : _focus.requestFocus();
  }

  // ------------------------------------------------------------ attachments
  Future<void> _openAttachSheet() async {
    if (!_planOk()) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 18,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: [
              for (final (id, icon, label, color) in const [
                ('document', Icons.insert_drive_file, 'Document', Color(0xFF5157AE)),
                ('camera', Icons.photo_camera, 'Camera', Color(0xFFD3396D)),
                ('gallery', Icons.photo, 'Photos', Color(0xFFBF59CF)),
                ('video', Icons.videocam, 'Video', Color(0xFFEC407A)),
                ('audio', Icons.headphones, 'Audio', Color(0xFFF96533)),
                ('location', Icons.location_on, 'Location', Color(0xFF1FA855)),
                ('contact', Icons.person, 'Contact', Color(0xFF009DE2)),
              ])
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(ctx, id),
                  child: SizedBox(
                    width: 78,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 27,
                          backgroundColor: color,
                          child: Icon(icon, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(label, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'document':
        await _pickFiles(FileType.any, DmType.file);
      case 'gallery':
        await _pickFiles(FileType.image, DmType.image, withCaption: true);
      case 'video':
        await _pickFiles(FileType.video, DmType.video, withCaption: true);
      case 'audio':
        await _pickFiles(FileType.audio, DmType.audio);
      case 'camera':
        await _camera();
      case 'location':
        await _shareLocation();
      case 'contact':
        await _shareContact();
    }
  }

  Future<void> _pickFiles(FileType type, DmType msgType, {bool withCaption = false}) async {
    final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(type: type);
    } catch (e) {
      if (mounted) context.showSnack('Could not open picker: $e');
      return;
    }
    for (final f in files) {
      final bytes = await f.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxUploadBytes) {
        context.showSnack('${f.name} is larger than 50 MB');
        continue;
      }
      var caption = '';
      if (withCaption && files.length == 1) {
        final result = await _previewWithCaption(bytes, f.name, msgType);
        if (result == null) return;
        caption = result;
      }
      unawaited(chat.sendFile(bytes, f.name, msgType, caption: caption));
    }
  }

  Future<void> _camera() async {
    if (!_planOk()) return;
    final XFile? shot;
    try {
      shot = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2048);
    } catch (e) {
      if (mounted) context.showSnack('Camera unavailable: $e');
      return;
    }
    if (shot == null) return;
    final bytes = await shot.readAsBytes();
    if (!mounted) return;
    final name = shot.name.contains('.') ? shot.name : '${shot.name}.jpg';
    final caption = await _previewWithCaption(bytes, name, DmType.image);
    if (caption != null) unawaited(chat.sendFile(bytes, name, DmType.image, caption: caption));
  }

  /// Returns the caption, or null when cancelled.
  Future<String?> _previewWithCaption(Uint8List bytes, String name, DmType type) {
    final caption = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(12),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: type == DmType.image
                    ? Image.memory(bytes, height: 280, fit: BoxFit.contain)
                    : Container(
                        height: 160,
                        color: Colors.black87,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam, color: Colors.white, size: 48),
                            Text(name, style: const TextStyle(color: Colors.white70)),
                            Text(formatBytes(bytes.length), style: const TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caption,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Add a caption...'),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, caption.text),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send'),
          ),
        ],
      ),
    ).whenComplete(caption.dispose);
  }

  Future<void> _shareLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw 'Location services are turned off';
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'Location permission denied';
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
      if (!mounted) return;
      final ok = await context.confirm(
        title: 'Send your current location?',
        message:
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}  (±${pos.accuracy.round()} m)',
        confirmLabel: 'Send',
      );
      if (ok) {
        await chat.sendLocation(DmLocation(lat: pos.latitude, lng: pos.longitude, name: 'Current location'));
      }
    } catch (e) {
      if (mounted) context.showSnack('$e');
    }
  }

  Future<void> _shareContact() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final result = await showDialog<DmContact>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty || phone.text.trim().length < 3) return;
              Navigator.pop(ctx, DmContact(name: name.text.trim(), phone: phone.text.trim()));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    if (result != null) await chat.sendContact(result);
  }

  // ------------------------------------------------------------ voice notes
  Future<void> _startRecording() async {
    if (!_planOk()) return;
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) context.showSnack('Microphone permission is required for voice messages');
        return;
      }
      var encoder = kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc;
      if (!await _recorder.isEncoderSupported(encoder)) encoder = AudioEncoder.wav;
      _recordExt = switch (encoder) {
        AudioEncoder.opus => 'webm',
        AudioEncoder.wav => 'wav',
        _ => 'm4a',
      };
      var path = '';
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.$_recordExt';
      }
      await _recorder.start(RecordConfig(encoder: encoder, numChannels: 1, bitRate: 64000), path: path);
      _recordStart = DateTime.now();
      _recordTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) setState(() => _recordElapsed = DateTime.now().difference(_recordStart!));
      });
      chat.setTyping(true, kind: 'recording');
      setState(() {
        _recording = true;
        _recordElapsed = Duration.zero;
      });
    } catch (e) {
      if (mounted) context.showSnack('Cannot record audio: $e');
    }
  }

  Future<void> _stopRecording({required bool send}) async {
    _recordTimer?.cancel();
    chat.setTyping(false, kind: 'recording');
    final elapsed = DateTime.now().difference(_recordStart ?? DateTime.now());
    setState(() => _recording = false);
    try {
      final path = await _recorder.stop();
      if (!send || path == null) return;
      if (elapsed < const Duration(milliseconds: 800)) {
        if (mounted) context.showSnack('Voice message too short');
        return;
      }
      final bytes = await XFile(path).readAsBytes();
      await chat.sendFile(
        bytes,
        'voice_${DateTime.now().millisecondsSinceEpoch}.$_recordExt',
        DmType.voice,
        duration: elapsed.inMilliseconds / 1000,
      );
    } catch (e) {
      if (mounted) context.showSnack('Could not send voice message: $e');
    }
  }

  // --------------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final c = chat.conversation;
    if (c != null && (c.isBlocked || c.blockedMe)) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14)),
          child: c.isBlocked
              ? InkWell(
                  onTap: () => chat.setBlocked(false),
                  child: Text(
                    'You blocked ${c.peer.name}. Tap to unblock.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.textSecondary),
                  ),
                )
              : Text(
                  "You can't send messages to this chat.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.textSecondary),
                ),
        ),
      );
    }

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
            // One-off options chosen in the privacy sheet (same as group chats).
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
                          [if (d.expiry == 'view_once') 'View once' else if (d.expiry != 'never') 'Disappears: ${d.expiryLabel}', if (d.silent) 'Silent'].join('  |  '),
                          style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
                        ),
                      ),
                      InkWell(onTap: () => d.update(expiry: 'never', silent: false), child: Icon(Icons.close, size: 16, color: context.palette.textSecondary)),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: _recording ? _recordingRow(context) : _inputRow(context),
            ),
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

  void _closeContext() {
    if (chat.editing != null) {
      _text.clear();
      _hasText = false;
      chat.startEdit(null);
    } else {
      chat.setReply(null);
    }
  }

  Widget _inputRow(BuildContext context) {
    final editing = chat.editing != null;
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
                  tooltip: 'Privacy: ${visibilityOf(chat.visibility).label}',
                  icon: Icon(visibilityOf(chat.visibility).icon, color: chat.visibility == 'public' ? null : context.colors.primary),
                  onPressed: editing ? null : _pickPrivacy,
                ),
                IconButton(
                  tooltip: 'Emoji',
                  icon: Icon(_showEmoji ? Icons.keyboard_outlined : Icons.emoji_emotions_outlined),
                  onPressed: _toggleEmoji,
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: _changed,
                    decoration: InputDecoration(
                      hintText: chat.visibility == 'public' ? 'Message' : 'Message (${visibilityOf(chat.visibility).label})',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (!editing)
                  IconButton(tooltip: 'Attach', icon: const Icon(Icons.attach_file), onPressed: _openAttachSheet),
                if (!_hasText && !editing)
                  IconButton(tooltip: 'Camera', icon: const Icon(Icons.photo_camera_outlined), onPressed: _camera),
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
            tooltip: _hasText ? 'Send' : 'Record voice message',
            icon: Icon(editing ? Icons.check : (_hasText ? Icons.send : Icons.mic_none)),
            onPressed: _hasText || editing ? _send : _startRecording,
          ),
        ),
      ],
    );
  }

  Widget _recordingRow(BuildContext context) {
    final s = _recordElapsed.inSeconds;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: context.palette.surfaceAlt, borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Cancel',
                  icon: Icon(Icons.delete_outline, color: context.palette.danger),
                  onPressed: () => _stopRecording(send: false),
                ),
                Icon(Icons.fiber_manual_record, color: context.palette.danger, size: 14),
                const SizedBox(width: 8),
                Text(
                  '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Recording...', style: TextStyle(color: context.palette.textSecondary)),
                ),
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
            tooltip: 'Send voice message',
            icon: const Icon(Icons.send),
            onPressed: () => _stopRecording(send: true),
          ),
        ),
      ],
    );
  }
}

class _ContextBar extends StatelessWidget {
  const _ContextBar({required this.chat, required this.onClose});

  final ChatController chat;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final editing = chat.editing;
    final m = editing ?? chat.replyTo!;
    final title = editing != null ? 'Edit message' : (m.isMine ? 'You' : chat.peer?.name ?? '');
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
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
                Text(previewOf(m), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }
}
