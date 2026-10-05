import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/state/group_sender.dart';

class _Picked {
  _Picked(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
  double progress = 0;

  String get type => GroupSender.typeOf(name);
}

/// Media / file picker with security level.
/// Protected files: Upload -> Encrypt -> Secure storage -> File token -> Open inside app.
class AttachmentSelectionScreen extends StatelessWidget {
  const AttachmentSelectionScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Attach',
      child: Scaffold(
        appBar: AppBar(title: const Text('Attach')),
        body: AsyncView<GroupDetail>(load: () => GroupRepository.detail(groupId), builder: (_, d, _) => _Attach(detail: d)),
      ),
    );
  }
}

class _Attach extends StatefulWidget {
  const _Attach({required this.detail});

  final GroupDetail detail;

  @override
  State<_Attach> createState() => _AttachState();
}

class _AttachState extends State<_Attach> {
  final List<_Picked> _picked = [];
  late MessageVisibility _visibility = widget.detail.settings.messageMode == 'public' ? MessageVisibility.public : MessageVisibility.private;
  final _caption = TextEditingController();
  bool _sending = false;

  static const _maxBytes = 50 * 1024 * 1024;

  bool get _fixed => widget.detail.settings.messageMode != 'user_select';
  MessageVisibility get _effective => switch (widget.detail.settings.messageMode) {
    'public' => MessageVisibility.public,
    'private' => MessageVisibility.private,
    _ => _visibility,
  };

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(FileType type) async {
    try {
      final files = await FilePicker.pickFiles(type: type);
      for (final f in files) {
        final bytes = await f.readAsBytes();
        if (bytes.length > _maxBytes) {
          if (mounted) context.showSnack('${f.name} is larger than 50 MB');
          continue;
        }
        _picked.add(_Picked(f.name, bytes));
      }
      setState(() {});
    } catch (e) {
      if (mounted) context.showSnack('Could not open picker: $e');
    }
  }

  Future<void> _camera() async {
    try {
      final shot = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2048);
      if (shot == null) return;
      _picked.add(_Picked(shot.name.contains('.') ? shot.name : '${shot.name}.jpg', await shot.readAsBytes()));
      setState(() {});
    } catch (e) {
      if (mounted) context.showSnack('Camera unavailable: $e');
    }
  }

  Future<void> _send() async {
    if (cannotSend(context, _caption.text, 'groups')) return;
    setState(() => _sending = true);
    final gid = widget.detail.id;
    var sent = 0;
    for (final (i, f) in _picked.toList().indexed) {
      final blocked = await GroupSender.file(
        gid,
        f.bytes,
        f.name,
        f.type,
        _effective,
        caption: i == 0 ? _caption.text.trim() : '',
        onProgress: (p) => mounted ? setState(() => f.progress = p) : null,
      );
      if (blocked != null) {
        if (mounted) await GroupSender.handle(context, blocked);
        break;
      }
      sent++;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    if (sent == _picked.length) {
      context.showSnack(_effective == MessageVisibility.public ? '$sent file(s) sent' : '$sent file(s) encrypted and sent securely');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gid = widget.detail.id;
    final options = [
      (Icons.description_outlined, 'Document', () => _pick(FileType.any)),
      (Icons.photo_camera_outlined, 'Camera', _camera),
      (Icons.photo_library_outlined, 'Gallery', () => _pick(FileType.image)),
      (Icons.headphones_outlined, 'Audio', () => _pick(FileType.audio)),
      (Icons.location_on_outlined, 'Location', () => context.push(AppRoutes.myLocationFor(gid))),
      (Icons.videocam_outlined, 'Video', () => _pick(FileType.video)),
    ];
    if (!widget.detail.me.canSendMedia) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(icon: Icons.no_photography_outlined, title: 'Media disabled', message: widget.detail.me.sendBlockedMessage ?? 'Members cannot send media in this group.'),
      );
    }
    return FormPage(
      items: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (final o in options)
              InkWell(
                onTap: _sending ? null : o.$3,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [AppAvatar(icon: o.$1, size: 58, inverted: true), const SizedBox(height: 8), Text(o.$2, style: const TextStyle(fontWeight: FontWeight.w600))],
                ),
              ),
          ],
        ),
        SectionHeader('Selected', action: '${_picked.length} file(s)', padding: const EdgeInsets.fromLTRB(0, 20, 0, 8)),
        if (_picked.isEmpty)
          Text('Pick documents, photos, videos or audio above.', style: TextStyle(color: context.palette.textSecondary))
        else
          Card(
            child: Column(
              children: [
                for (final f in _picked)
                  ListTile(
                    leading: f.type == 'image'
                        ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.memory(f.bytes, width: 44, height: 44, fit: BoxFit.cover))
                        : AppAvatar(icon: f.type == 'video' ? Icons.videocam_outlined : f.type == 'audio' ? Icons.audiotrack : Icons.insert_drive_file_outlined, size: 44),
                    title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: _sending ? LinearProgressIndicator(value: f.progress) : Text(formatBytes(f.bytes.length)),
                    trailing: _sending ? null : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _picked.remove(f))),
                  ),
              ],
            ),
          ),
        if (_picked.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppTextField(controller: _caption, label: 'Caption (optional)', hint: 'Add a caption...'),
        ],
        const SectionHeader('File security level', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
        if (_fixed)
          InfoBanner(icon: Icons.lock_person_outlined, message: 'Group admin set message mode to ${messageModeLabel(widget.detail.settings.messageMode)}.')
        else
          SegmentedButton<MessageVisibility>(
            showSelectedIcon: false,
            segments: [for (final v in MessageVisibility.values) ButtonSegment(value: v, icon: Icon(v.icon), label: Text(v.label))],
            selected: {_visibility},
            onSelectionChanged: (s) => setState(() => _visibility = s.first),
          ),
        const SizedBox(height: 12),
        SecurityRulesList(visibility: _effective),
        const SizedBox(height: 12),
        if (_effective.isProtected)
          const InfoBanner(
            icon: Icons.enhanced_encryption_outlined,
            message: 'Files will be encrypted and opened only in the secure viewer. No download, save to gallery, open with or share. No public file URL is created.',
          ),
      ],
      bottom: PrimaryButton(
        label: _picked.isEmpty ? 'Select files' : 'Send ${_picked.length} file(s) as ${_effective.label}',
        icon: Icons.send,
        loading: _sending,
        onPressed: _picked.isEmpty || _sending ? null : _send,
      ),
    );
  }
}
