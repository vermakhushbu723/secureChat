import '../../../core/core.dart';
import '../state/message_draft.dart';

/// Per message / file permissions for the next message sent. Options that the
/// chosen security level forbids are shown locked (the server enforces them too).
class PrivacyPermissionScreen extends StatefulWidget {
  const PrivacyPermissionScreen({super.key});

  @override
  State<PrivacyPermissionScreen> createState() => _PrivacyPermissionScreenState();
}

class _PrivacyPermissionScreenState extends State<PrivacyPermissionScreen> {
  final _draft = MessageDraft.instance;
  late MessageVisibility _level = Session.defaultVisibility.value;
  late String _expiry = _draft.expiry;
  late bool _download = _draft.allowDownload;
  late bool _screenshot = _draft.allowScreenshot;

  Widget _perm(IconData icon, String title, {required bool allowedByLevel, bool value = false, ValueChanged<bool>? onChanged}) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: allowedByLevel ? Text(onChanged == null ? 'Always on for this level' : 'Configurable') : Text('Blocked for ${_level.label}'),
      value: allowedByLevel && value,
      onChanged: allowedByLevel ? onChanged : null,
    );
  }

  Future<void> _save() async {
    await MessageDraft.saveDefault(_level);
    _draft.update(expiry: _expiry, allowDownload: _download, allowScreenshot: _screenshot);
    if (!mounted) return;
    context.showSnack('Permissions saved for your next message');
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final public = _level == MessageVisibility.public;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Permission')),
      body: FormPage(
        items: [
          const Text('Security level', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<MessageVisibility>(
            showSelectedIcon: false,
            segments: [for (final v in MessageVisibility.values) ButtonSegment(value: v, label: Text(v.label))],
            selected: {_level},
            onSelectionChanged: (s) => setState(() => _level = s.first),
          ),
          const SectionHeader('Who can view', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          const Card(
            child: ListTile(
              leading: Icon(Icons.groups_outlined),
              title: Text('Authorized members of this group'),
              subtitle: Text('Content is never visible outside the group context'),
            ),
          ),
          const SectionHeader('Allowed actions', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: Column(
              children: [
                _perm(Icons.shortcut, 'Forward (tracked in chain)', allowedByLevel: public, value: true),
                _perm(Icons.copy, 'Copy text', allowedByLevel: public, value: true),
                _perm(Icons.download_outlined, 'Download / save to device', allowedByLevel: public, value: _download, onChanged: (v) => setState(() => _download = v)),
                _perm(Icons.ios_share, 'External share / open with', allowedByLevel: false),
                _perm(Icons.screenshot_outlined, 'Screenshot', allowedByLevel: public, value: _screenshot, onChanged: (v) => setState(() => _screenshot = v)),
                _perm(Icons.videocam_outlined, 'Screen recording', allowedByLevel: _level != MessageVisibility.highlyProtected, value: true),
                SwitchListTile(
                  secondary: const Icon(Icons.water_drop_outlined),
                  title: const Text('Dynamic watermark'),
                  subtitle: const Text('Name, masked ID, date and time'),
                  value: _level == MessageVisibility.highlyProtected,
                  onChanged: null,
                ),
              ],
            ),
          ),
          const SectionHeader('Expiry', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in MessageDraft.expiryLabels.entries)
                ChoiceChip(label: Text(e.value), selected: _expiry == e.key, showCheckmark: false, onSelected: (_) => setState(() => _expiry = e.key)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _expiry == 'view_once'
                ? 'Each member can open the message once; it cannot be forwarded.'
                : _expiry == 'never'
                ? 'The message stays until it is deleted.'
                : 'The message and its files are removed for everyone after ${MessageDraft.expiryLabels[_expiry]}.',
            style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const InfoBanner(icon: Icons.dns_outlined, message: 'Every permission is checked on the server too - hiding a button is never the only protection.'),
        ],
        bottom: PrimaryButton(label: 'Save Permissions', onPressed: _save),
      ),
    );
  }
}
