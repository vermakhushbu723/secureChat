import '../../../core/core.dart';

/// MESSAGE & CONTENT SECURITY - configurable at Global, Group or User level.
class AdminSecuritySettingsScreen extends StatefulWidget {
  const AdminSecuritySettingsScreen({super.key});

  @override
  State<AdminSecuritySettingsScreen> createState() => _AdminSecuritySettingsScreenState();
}

class _AdminSecuritySettingsScreenState extends State<AdminSecuritySettingsScreen> {
  String _scope = 'global';
  String? _targetId;
  String? _targetName;
  Map<String, dynamic>? _values;
  final Map<String, bool> _changes = {};
  String? _error;
  bool _loading = false;

  static const _messageSecurity = [
    (Icons.public, 'Enable Public Message', 'publicMessages'),
    (Icons.lock_outline, 'Enable Private Message', 'privateMessages'),
    (Icons.shortcut, 'Allow Public Forwarding', 'publicForwarding'),
    (Icons.lock_person_outlined, 'Allow Private Forwarding', 'privateForwarding'),
    (Icons.account_tree_outlined, 'Chain-Based Deletion', 'chainDeletion'),
    (Icons.delete_sweep_outlined, 'Delete Forwarded Copies', 'deleteForwardedCopies'),
  ];

  static const _fileSecurity = [
    (Icons.file_download_off_outlined, 'Disable File Download', 'downloadDisabled'),
    (Icons.share_outlined, 'Disable External File Sharing', 'externalShareDisabled'),
    (Icons.content_copy_outlined, 'Disable Copy', 'copyDisabled'),
    (Icons.phonelink_lock_outlined, 'Secure File Viewer', 'secureViewer'),
    (Icons.link_off, 'No Direct Public File URL', 'noPublicFileUrl'),
  ];

  static const _screenSecurity = [
    (Icons.screenshot_outlined, 'Screenshot Protection', 'screenshotProtection'),
    (Icons.videocam_off_outlined, 'Screen Recording Protection', 'screenRecordingProtection'),
    (Icons.cast_connected_outlined, 'Block Casting / Mirroring (Android)', 'blockCasting'),
    (Icons.print_disabled_outlined, 'Print Restriction', 'printRestriction'),
    (Icons.water_drop_outlined, 'Dynamic Watermark', 'dynamicWatermark'),
  ];

  /// Keys the chosen scope stores (groups keep their own copy of these settings).
  static const _groupKeys = {
    'publicMessages', 'privateMessages', 'publicForwarding', 'privateForwarding', 'chainDeletion', 'downloadDisabled',
    'externalShareDisabled', 'copyDisabled', 'secureViewer', 'screenshotProtection', 'screenRecordingProtection', 'dynamicWatermark',
  };
  static const _userKeys = {'publicMessages', 'privateMessages', 'publicForwarding', 'privateForwarding'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_scope != 'global' && _targetId == null) {
      setState(() => _values = null);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await AdminApi.get<Map<String, dynamic>>('/settings/security', {'scope': _scope, 'targetId': _targetId});
      if (!mounted) return;
      setState(() {
        _values = Map<String, dynamic>.from(r['values'] as Map);
        _targetName = (r['target'] as Map?)?['name'] as String?;
        _changes.clear();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickTarget() async {
    final path = _scope == 'group' ? '/groups' : '/users';
    final q = await askText(context, title: 'Find ${_scope == 'group' ? 'group' : 'user'}', label: _scope == 'group' ? 'Group name or invite code' : 'Name, user ID, mobile or email', confirm: 'Search');
    if (q == null || q.trim().isEmpty || !mounted) return;
    final res = await runAction<Map<String, dynamic>>(context, () => AdminApi.get(path, {'q': q.trim(), 'limit': 10}));
    if (res == null || !mounted) return;
    final items = (res['items'] as List).cast<Map<String, dynamic>>();
    if (items.isEmpty) return context.showSnack('Nothing found');
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select'),
        children: [
          for (final i in items)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, i),
              child: Text(_scope == 'group' ? '${i['name']} (${i['memberCount']} members)' : '${i['name']} (${i['internalId']})'),
            ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() => _targetId = '${picked['id']}');
    await _load();
  }

  Future<void> _save() async {
    if (_changes.isEmpty) return;
    final r = await runAction(
      context,
      () => AdminApi.put('/settings/security', Map<String, bool>.from(_changes), {'scope': _scope, 'targetId': _targetId}),
      success: '${_scope == 'global' ? 'Global' : _targetName} security settings saved',
    );
    if (r != null) await _load();
  }

  bool _editable(String key) => _scope == 'global' || (_scope == 'group' ? _groupKeys.contains(key) : _userKeys.contains(key));

  Widget _panel(String title, List<(IconData, String, String)> items) => PanelCard(
    title: title,
    child: Column(
      children: [
        for (final i in items)
          SettingSwitch(
            icon: i.$1,
            title: i.$2,
            subtitle: _editable(i.$3) ? null : 'Set in Global',
            value: (_changes[i.$3] ?? _values?[i.$3]) == true,
            onChanged: _editable(i.$3) ? (v) => setState(() => _changes[i.$3] = v) : null,
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Message & Content Security',
      subtitle: 'Every rule is enforced on the server as well',
      onRefresh: _load,
      actions: [FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _changes.isEmpty ? null : _save, child: const Text('Save'))],
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'global', icon: Icon(Icons.public), label: Text('Global')),
                ButtonSegment(value: 'group', icon: Icon(Icons.groups_outlined), label: Text('Group')),
                ButtonSegment(value: 'user', icon: Icon(Icons.person_outline), label: Text('User')),
              ],
              selected: {_scope},
              onSelectionChanged: (s) {
                setState(() {
                  _scope = s.first;
                  _targetId = null;
                  _targetName = null;
                  _changes.clear();
                });
                _load();
              },
            ),
            if (_scope != 'global')
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _pickTarget,
                icon: Icon(_scope == 'group' ? Icons.groups_outlined : Icons.person_search_outlined),
                label: Text(_targetName ?? (_scope == 'group' ? 'Select group' : 'Select user')),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_scope == 'global')
          const InfoBanner(icon: Icons.info_outline, message: 'Global values are the defaults for every new group. Change one group or one user with the Group / User tabs.')
        else if (_scope == 'user')
          const InfoBanner(icon: Icons.info_outline, message: 'User level: message and forwarding rules for one person, on top of the group rules.'),
        const SizedBox(height: 16),
        if (_error != null)
          ErrorPanel(message: _error!, onRetry: _load)
        else if (_loading && _values == null)
          const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()))
        else if (_values == null)
          InfoBanner(icon: Icons.touch_app_outlined, message: 'Select a ${_scope == 'group' ? 'group' : 'user'} to see its settings.')
        else
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
                        subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: SecurityRulesList(visibility: v)),
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
