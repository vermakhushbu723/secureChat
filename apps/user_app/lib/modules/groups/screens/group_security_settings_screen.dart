import '../../../core/core.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import '../widgets/create_steps.dart';

/// Group level security: message mode, forwarding, file security,
/// screen protection and chain deletion. Enforced by the server.
class GroupSecuritySettingsScreen extends StatelessWidget {
  const GroupSecuritySettingsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Group Security',
      child: Scaffold(
        appBar: AppBar(title: const Text('Group Security')),
        body: AsyncView<GroupDetail>(load: () => GroupRepository.detail(groupId), builder: (_, d, _) => _SecurityForm(detail: d)),
      ),
    );
  }
}

class _SecurityForm extends StatefulWidget {
  const _SecurityForm({required this.detail});

  final GroupDetail detail;

  @override
  State<_SecurityForm> createState() => _SecurityFormState();
}

class _SecurityFormState extends State<_SecurityForm> {
  late final GroupSettings _s = widget.detail.settings;
  bool _saving = false;

  Widget _section(String t) => SectionHeader(t, padding: const EdgeInsets.fromLTRB(0, 24, 0, 8));

  Widget _switch(IconData icon, String title, bool value, ValueChanged<bool> onChanged, {String? subtitle}) => SwitchListTile(
    secondary: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    value: value,
    onChanged: (v) => setState(() => onChanged(v)),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await GroupRepository.updateSettings(widget.detail.id, {
        'messages': {'messageMode': _s.messageMode},
        'security': _s.securityJson(),
      });
      if (!mounted) return;
      context.showSnack('Security settings saved');
      if (context.canPop()) context.pop();
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final admin = d.me.isAdmin;
    return FormPage(
      items: [
        InfoBanner(
          icon: Icons.shield_outlined,
          message: 'These rules apply to every member and message in ${d.name}. Every permission is also checked on the server.',
        ),
        if (!admin) ...[const SizedBox(height: 12), const InfoBanner(icon: Icons.lock_outline, message: 'Only group admins can change security settings.')],
        IgnorePointer(
          ignoring: !admin,
          child: Opacity(
            opacity: admin ? 1 : 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section('Message mode'),
                OptionCard(
                  icon: Icons.public,
                  title: 'Public',
                  subtitle: 'Every message is Public - forwarding allowed',
                  selected: _s.messageMode == 'public',
                  onTap: () => setState(() => _s.messageMode = 'public'),
                ),
                OptionCard(
                  icon: Icons.lock_outline,
                  title: 'Private',
                  subtitle: 'Every message is Private - no forward, copy or download',
                  selected: _s.messageMode == 'private',
                  onTap: () => setState(() => _s.messageMode = 'private'),
                ),
                OptionCard(
                  icon: Icons.tune,
                  title: 'User can select',
                  subtitle: 'Sender picks Public, Private or Highly Protected',
                  selected: _s.messageMode == 'user_select',
                  onTap: () => setState(() => _s.messageMode = 'user_select'),
                ),
                _section('Forwarding'),
                Card(
                  child: Column(
                    children: [
                      _switch(Icons.shortcut, 'Public message forwarding', _s.publicForwarding, (v) => _s.publicForwarding = v),
                      const Divider(indent: 56),
                      _switch(Icons.lock_outline, 'Private message forwarding', _s.privateForwarding, (v) => _s.privateForwarding = v, subtitle: 'Normally off'),
                      const Divider(indent: 56),
                      _switch(Icons.account_tree_outlined, 'Track forward chain', _s.trackForwardChain, (v) => _s.trackForwardChain = v),
                    ],
                  ),
                ),
                _section('File security'),
                Card(
                  child: Column(
                    children: [
                      _switch(Icons.phonelink_lock_outlined, 'Open inside app only', _s.openInAppOnly, (v) => _s.openInAppOnly = v, subtitle: 'Secure viewer'),
                      const Divider(indent: 56),
                      _switch(Icons.file_download_off_outlined, 'Download disabled', _s.downloadDisabled, (v) => _s.downloadDisabled = v),
                      const Divider(indent: 56),
                      _switch(Icons.share_outlined, 'External share disabled', _s.externalShareDisabled, (v) => _s.externalShareDisabled = v),
                      const Divider(indent: 56),
                      _switch(Icons.content_copy_outlined, 'Copy disabled for protected content', _s.copyDisabledProtected, (v) => _s.copyDisabledProtected = v),
                      const Divider(indent: 56),
                      AppTile(icon: Icons.folder_shared_outlined, title: 'Protected files & permissions', onTap: () => context.push(AppRoutes.mediaGalleryOf(d.id))),
                    ],
                  ),
                ),
                _section('Screen protection'),
                Card(
                  child: Column(
                    children: [
                      _switch(Icons.screenshot_outlined, 'Screenshot protection', _s.screenshotProtection, (v) => _s.screenshotProtection = v),
                      const Divider(indent: 56),
                      _switch(Icons.videocam_off_outlined, 'Screen recording protection', _s.screenRecordingProtection, (v) => _s.screenRecordingProtection = v),
                      const Divider(indent: 56),
                      _switch(Icons.water_drop_outlined, 'Dynamic watermark', _s.dynamicWatermark, (v) => _s.dynamicWatermark = v, subtitle: 'Name, masked ID, date, time'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const InfoBanner(
                  icon: Icons.info_outline,
                  message: 'Web browsers cannot block screenshots 100%. The Android app uses OS-level secure screens; the web app uses watermark and viewer controls.',
                ),
                _section('Deletion'),
                Card(
                  child: Column(
                    children: [
                      _switch(Icons.delete_sweep_outlined, 'Chain deletion enabled', _s.chainDeletion, (v) => _s.chainDeletion = v,
                          subtitle: 'Delete for everyone removes all forwarded copies'),
                      const Divider(indent: 56),
                      _switch(Icons.timer_outlined, 'Allow delete for everyone after 1 hour', _s.deleteForEveryoneUnlimited, (v) => _s.deleteForEveryoneUnlimited = v),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _section('Content rules'),
        Card(
          child: AppTile(
            icon: Icons.gpp_maybe_outlined,
            title: 'Number, number words, abuse, spam, links',
            subtitle: 'Managed in group settings',
            onTap: () => context.push(AppRoutes.groupSettingsOf(d.id)),
          ),
        ),
      ],
      bottom: admin ? PrimaryButton(label: 'Save Security Settings', loading: _saving, onPressed: _saving ? null : _save) : null,
    );
  }
}
