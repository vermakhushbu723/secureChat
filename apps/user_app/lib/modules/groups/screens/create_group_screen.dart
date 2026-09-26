import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/core.dart';
import '../state/group_draft.dart';
import '../widgets/create_steps.dart';

/// Create Group - step 1: group name and photo.
/// Members are never picked from contacts; they join through the invite link.
class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginGate(title: 'Create Group', child: _CreateGroup());
}

class _CreateGroup extends StatefulWidget {
  const _CreateGroup();

  @override
  State<_CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<_CreateGroup> {
  late final _name = TextEditingController(text: GroupDraft.current.name);

  @override
  void initState() {
    super.initState();
    // A fresh flow starts from an empty draft.
    if (GroupDraft.current.name.isEmpty) GroupDraft.reset();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTile(icon: Icons.photo_camera_outlined, title: 'Take photo', onTap: () => Navigator.pop(ctx, 'camera')),
            AppTile(icon: Icons.photo_library_outlined, title: 'Choose from gallery', onTap: () => Navigator.pop(ctx, 'gallery')),
            if (GroupDraft.current.photoBytes != null)
              AppTile(icon: Icons.delete_outline, title: 'Remove photo', danger: true, onTap: () => Navigator.pop(ctx, 'remove')),
          ],
        ),
      ),
    );
    if (source == null) return;
    final draft = GroupDraft.current;
    if (source == 'remove') {
      setState(() => draft
        ..photoBytes = null
        ..avatarUrl = null);
      return;
    }
    try {
      if (source == 'camera') {
        final shot = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024);
        if (shot == null) return;
        draft.photoBytes = await shot.readAsBytes();
        draft.photoName = shot.name.contains('.') ? shot.name : '${shot.name}.jpg';
      } else {
        final files = await FilePicker.pickFiles(type: FileType.image);
        if (files.isEmpty) return;
        draft.photoBytes = await files.first.readAsBytes();
        draft.photoName = files.first.name;
      }
      draft.avatarUrl = null;
      setState(() {});
    } catch (e) {
      if (mounted) context.showSnack('Could not pick photo: $e');
    }
  }

  void _next() {
    final name = _name.text.trim();
    if (name.isEmpty) return context.showSnack('Enter a group name');
    GroupDraft.current.name = name;
    context.push(AppRoutes.groupBasicDetails);
  }

  @override
  Widget build(BuildContext context) {
    final locked = Session.chatLocked;
    final photo = GroupDraft.current.photoBytes;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: FormPage(
        items: [
          const CreateSteps(current: 0),
          const SizedBox(height: 28),
          if (locked) ...[
            const InfoBanner(
              icon: Icons.lock_clock_outlined,
              tone: Tone.danger,
              title: 'Trial expired',
              message: 'Creating new groups is locked. Request an extension or choose a plan.',
            ),
            const SizedBox(height: 20),
          ],
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  if (photo != null)
                    ClipOval(child: Image.memory(photo, width: 112, height: 112, fit: BoxFit.cover))
                  else
                    const AppAvatar(icon: Icons.groups, size: 112),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: context.colors.primary,
                      child: Icon(Icons.photo_camera_outlined, size: 18, color: context.colors.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: _pickPhoto, child: Text(photo == null ? 'Add group photo' : 'Change group photo'))),
          const SizedBox(height: 16),
          AppTextField(
            controller: _name,
            label: 'Group Name',
            hint: 'e.g. Lucknow Business Community',
            prefixIcon: Icons.edit_outlined,
            maxLength: 50,
          ),
          const SizedBox(height: 8),
          const InfoBanner(
            icon: Icons.link,
            message: 'After creating the group you will get an invite link. Share it on WhatsApp, Telegram, SMS or anywhere.',
          ),
        ],
        bottom: PrimaryButton(
          label: locked ? 'View plans' : 'Next',
          icon: locked ? Icons.workspace_premium_outlined : Icons.arrow_forward,
          onPressed: locked ? () => context.push(AppRoutes.trialExpired) : _next,
        ),
      ),
    );
  }
}
