import '../../../core/core.dart';

/// MESSAGE & CONTENT SECURITY - configurable at Global, Group or User level.
class AdminSecuritySettingsScreen extends StatefulWidget {
  const AdminSecuritySettingsScreen({super.key});

  @override
  State<AdminSecuritySettingsScreen> createState() => _AdminSecuritySettingsScreenState();
}

class _AdminSecuritySettingsScreenState extends State<AdminSecuritySettingsScreen> {
  String _scope = 'Global';
  String _target = 'Lucknow Business Community';

  static const _messageSecurity = [
    (Icons.public, 'Enable Public Message', true),
    (Icons.lock_outline, 'Enable Private Message', true),
    (Icons.shortcut, 'Allow Public Forwarding', true),
    (Icons.lock_person_outlined, 'Allow Private Forwarding', false),
    (Icons.account_tree_outlined, 'Chain-Based Deletion', true),
    (Icons.delete_sweep_outlined, 'Delete Forwarded Copies', true),
  ];

  static const _fileSecurity = [
    (Icons.file_download_off_outlined, 'Disable File Download', true),
    (Icons.share_outlined, 'Disable External File Sharing', true),
    (Icons.content_copy_outlined, 'Disable Copy', true),
    (Icons.phonelink_lock_outlined, 'Secure File Viewer', true),
    (Icons.link_off, 'No Direct Public File URL', true),
  ];

  static const _screenSecurity = [
    (Icons.screenshot_outlined, 'Screenshot Protection', true),
    (Icons.videocam_off_outlined, 'Screen Recording Protection', true),
    (Icons.cast_connected_outlined, 'Block Casting / Mirroring (Android)', true),
    (Icons.print_disabled_outlined, 'Print Restriction', true),
    (Icons.water_drop_outlined, 'Dynamic Watermark', true),
  ];

  Widget _panel(String title, List<(IconData, String, bool)> items) => PanelCard(
    title: title,
    child: Column(
      children: [for (final i in items) AppSwitchTile(icon: i.$1, title: i.$2, value: i.$3)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Message & Content Security',
      subtitle: 'Every rule is enforced on the server as well',
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.showSnack('$_scope security settings saved'),
          child: const Text('Save'),
        ),
      ],
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'Global', icon: Icon(Icons.public), label: Text('Global')),
                ButtonSegment(value: 'Group', icon: Icon(Icons.groups_outlined), label: Text('Group')),
                ButtonSegment(value: 'User', icon: Icon(Icons.person_outline), label: Text('User')),
              ],
              selected: {_scope},
              onSelectionChanged: (s) => setState(() => _scope = s.first),
            ),
            if (_scope != 'Global')
              SizedBox(
                width: 300,
                child: DropdownButtonFormField<String>(
                  initialValue: _scope == 'Group' ? _target : null,
                  isExpanded: true,
                  hint: const Text('Select'),
                  items: [
                    if (_scope == 'Group')
                      for (final g in MockData.groups)
                        DropdownMenuItem(
                          value: g.name,
                          child: Text(g.name, overflow: TextOverflow.ellipsis),
                        )
                    else
                      for (final u in MockData.users)
                        DropdownMenuItem(value: u.name, child: Text('${u.name} (${u.internalId})')),
                  ],
                  onChanged: (v) => setState(() => _target = v ?? _target),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 360,
          children: [
            _panel('Message security', _messageSecurity),
            _panel('File security', _fileSecurity),
            _panel('Screen protection', _screenSecurity),
            PanelCard(
              title: 'Security levels',
              child: Column(
                children: [
                  for (final v in MessageVisibility.values)
                    ListTile(
                      leading: Icon(v.icon),
                      title: Text('${v.levelLabel} - ${v.label}'),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SecurityRulesList(visibility: v),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          icon: Icons.info_outline,
          message:
              'Web browsers cannot block screenshots 100%. Android uses FLAG_SECURE; web relies on secure viewer, '
              'watermark, copy / print / download restrictions and session controls.',
        ),
      ],
    );
  }
}
