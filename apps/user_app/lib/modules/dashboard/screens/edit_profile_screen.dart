import 'package:file_picker/file_picker.dart';

import '../../../core/core.dart';
import '../../direct/data/direct_repository.dart';
import '../../direct/widgets/dm_avatar.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginGate(title: 'Edit Profile', child: _Form());
}

class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final AuthUser _me = AuthService.instance.user.value!;
  late final _name = TextEditingController(text: _me.name);
  late final _displayName = TextEditingController(text: _me.displayName);
  late final _about = TextEditingController(text: _me.about);
  late final _address = TextEditingController(text: _me.businessAddress ?? '');
  late final _username = TextEditingController(text: _me.username ?? '');
  late String? _avatarUrl = _me.avatarUrl;
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    _about.dispose();
    _address.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTile(icon: Icons.photo_library_outlined, title: 'Choose photo', onTap: () => Navigator.pop(ctx, 'pick')),
            if (_avatarUrl != null) AppTile(icon: Icons.delete_outline, title: 'Remove photo', danger: true, onTap: () => Navigator.pop(ctx, 'remove')),
          ],
        ),
      ),
    );
    if (choice == 'remove') {
      setState(() => _avatarUrl = null);
      return;
    }
    if (choice != 'pick') return;
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final media = await DirectRepository.upload(await files.first.readAsBytes(), files.first.name);
      if (mounted) setState(() => _avatarUrl = media.thumbUrl ?? media.url);
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      context.showSnack('Name is required');
      return;
    }
    setState(() => _saving = true);
    try {
      final username = _username.text.trim().toLowerCase();
      await AuthService.instance.updateProfile({
        'name': name,
        if (_displayName.text.trim().isNotEmpty) 'displayName': _displayName.text.trim(),
        'about': _about.text.trim(),
        if (_me.isBusiness) 'businessAddress': _address.text.trim(),
        if (username.isNotEmpty && username != _me.username) 'username': username,
        'avatarUrl': _avatarUrl,
      });
      if (!mounted) return;
      context.showSnack('Profile updated');
      context.canPop() ? context.pop() : context.go(AppRoutes.profile);
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.code == 'CONFLICT' ? 'That username is taken' : e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: FormPage(
        items: [
          Center(
            child: Stack(
              children: [
                DmAvatar(name: _name.text.isEmpty ? _me.name : _name.text, avatarUrl: _avatarUrl, size: 112),
                if (_uploading) const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: context.colors.surface,
                    shape: CircleBorder(side: BorderSide(color: context.palette.divider)),
                    child: IconButton(icon: const Icon(Icons.photo_camera_outlined), tooltip: 'Change photo', onPressed: _uploading ? null : _pickPhoto),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          AppTextField(
            label: _me.isBusiness ? 'Business name' : 'Full Name',
            controller: _name,
            prefixIcon: _me.isBusiness ? Icons.storefront_outlined : Icons.person_outline,
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Display name (shown to group members)', controller: _displayName, prefixIcon: Icons.badge_outlined, maxLength: 20),
          const SizedBox(height: 8),
          AppTextField(label: 'Username', controller: _username, prefixIcon: Icons.alternate_email),
          const SizedBox(height: 16),
          AppTextField(label: _me.isBusiness ? 'Bio' : 'About', controller: _about, prefixIcon: Icons.info_outline, maxLength: 140),
          if (_me.isBusiness) ...[
            const SizedBox(height: 8),
            AppTextField(label: 'Business address', controller: _address, prefixIcon: Icons.location_on_outlined, maxLines: 2, maxLength: 200),
          ],
          const SizedBox(height: 8),
          AppTextField(label: 'Email', initialValue: _me.email ?? '', prefixIcon: Icons.mail_outline, readOnly: true),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Mobile Number',
            initialValue: _me.phone ?? '',
            prefixIcon: Icons.phone_outlined,
            readOnly: true,
            suffix: TextButton(onPressed: () => context.push(AppRoutes.accountSecurity), child: const Text('Change')),
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            icon: Icons.visibility_off_outlined,
            message: 'Members see only your display name and photo. Mobile, email and user ID are always hidden.',
          ),
        ],
        bottom: PrimaryButton(label: 'Save Changes', loading: _saving, onPressed: _saving || _uploading ? null : _save),
      ),
    );
  }
}
