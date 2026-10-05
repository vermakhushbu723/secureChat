import '../../../core/core.dart';

/// Create / edit a group from the admin panel: details, location rules, message rules.
class AdminGroupFormScreen extends StatefulWidget {
  const AdminGroupFormScreen({super.key, this.groupId});

  final String? groupId;

  @override
  State<AdminGroupFormScreen> createState() => _AdminGroupFormScreenState();
}

class _AdminGroupFormScreenState extends State<AdminGroupFormScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController(text: 'Other');
  final _rules = TextEditingController();
  final _creator = TextEditingController();
  final _avatar = TextEditingController();
  String _location = 'off';
  String _shareMode = 'join';
  int _interval = 10;
  String _visibility = 'adminOnly';
  String _mode = 'user_select';
  String _whoCanSend = 'all';
  bool _approve = false;
  bool _restrictNew = false;
  bool _publicForwarding = true;
  bool _privateForwarding = false;
  bool _chainDeletion = true;
  bool _downloadDisabled = true;
  bool _screenshot = true;
  bool _watermark = true;
  final Set<String> _contentRules = {for (final r in ContentRule.values) r.name};
  bool _loaded = false;
  bool _saving = false;
  String? _loadError;
  String? _groupName;

  bool get _editing => widget.groupId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _load();
    } else {
      _loaded = true;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _category, _rules, _creator, _avatar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final g = await AdminApi.get<Map<String, dynamic>>('/groups/${widget.groupId}');
      final s = g['settings'] as Map<String, dynamic>? ?? const {};
      final loc = s['location'] as Map<String, dynamic>? ?? const {};
      final msg = s['messages'] as Map<String, dynamic>? ?? const {};
      final mem = s['members'] as Map<String, dynamic>? ?? const {};
      final sec = s['security'] as Map<String, dynamic>? ?? const {};
      if (!mounted) return;
      setState(() {
        _groupName = g['name'] as String?;
        _name.text = '${g['name']}';
        _description.text = '${g['description'] ?? ''}';
        _category.text = '${g['category'] ?? 'Other'}';
        _rules.text = '${g['rules'] ?? ''}';
        _creator.text = '${(g['creator'] as Map?)?['internalId'] ?? ''}';
        _avatar.text = '${g['avatarUrl'] ?? ''}';
        _location = '${loc['requirement'] ?? 'off'}';
        _shareMode = '${loc['shareMode'] ?? 'join'}';
        _interval = (loc['liveIntervalMin'] as num?)?.toInt() ?? 10;
        _visibility = '${loc['visibility'] ?? 'adminOnly'}';
        _mode = '${msg['messageMode'] ?? 'user_select'}';
        _whoCanSend = '${msg['whoCanSend'] ?? 'all'}';
        _approve = mem['approveNewMembers'] == true;
        _restrictNew = mem['restrictNewMembers'] == true;
        _publicForwarding = sec['publicForwarding'] != false;
        _privateForwarding = sec['privateForwarding'] == true;
        _chainDeletion = sec['chainDeletion'] != false;
        _downloadDisabled = sec['downloadDisabled'] != false;
        _screenshot = sec['screenshotProtection'] != false;
        _watermark = sec['dynamicWatermark'] != false;
        _contentRules
          ..clear()
          ..addAll([for (final r in (s['contentRules'] as List? ?? const [])) '$r']);
        _loaded = true;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return context.showSnack('Enter the group name');
    if (!_editing && _creator.text.trim().isEmpty) return context.showSnack('Enter the creator (user ID, mobile number or email)');
    setState(() => _saving = true);
    final body = <String, Object?>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'category': _category.text.trim().isEmpty ? 'Other' : _category.text.trim(),
      'rules': _rules.text.trim(),
      'avatarUrl': _avatar.text.trim().isEmpty ? null : _avatar.text.trim(),
      if (_creator.text.trim().isNotEmpty) 'creator': _creator.text.trim(),
      'settings': {
        'location': {'requirement': _location, 'shareMode': _shareMode, 'liveIntervalMin': _interval, 'visibility': _visibility},
        'messages': {'messageMode': _mode, 'whoCanSend': _whoCanSend},
        'members': {'approveNewMembers': _approve, 'restrictNewMembers': _restrictNew},
        'security': {
          'publicForwarding': _publicForwarding,
          'privateForwarding': _privateForwarding,
          'chainDeletion': _chainDeletion,
          'downloadDisabled': _downloadDisabled,
          'screenshotProtection': _screenshot,
          'dynamicWatermark': _watermark,
        },
        'contentRules': _contentRules.toList(),
      },
    };
    final r = await runAction<Map<String, dynamic>>(
      context,
      () => _editing ? AdminApi.patch('/groups/${widget.groupId}', body) : AdminApi.post('/groups', body),
      success: _editing ? 'Group updated' : 'Group created - invite link generated',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (r == null) return;
    final id = _editing ? widget.groupId! : '${(r['group'] as Map)['id']}';
    context.go(AdminRoutes.groupDetailsOf(id));
  }

  Widget _radio<T>(String title, T value, T group, ValueChanged<T> onChanged) =>
      ListTile(dense: true, leading: Icon(value == group ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: value == group ? context.colors.primary : null), title: Text(title), onTap: () => setState(() => onChanged(value)));

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) return ErrorPanel(message: _loadError!, onRetry: () => setState(() => _loadError = null));
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return AdminPage(
      title: _editing ? 'Edit Group' : 'Create Group',
      subtitle: _editing ? _groupName : 'Group creator can be any registered user',
      showBack: true,
      actions: [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
          label: Text(_editing ? 'Save' : 'Create'),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 380,
          children: [
            PanelCard(
              title: 'Basic details',
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  AppTextField(label: 'Group name', controller: _name, maxLength: 50),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Description', controller: _description, maxLines: 3),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Category', controller: _category),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Group rules', controller: _rules, maxLines: 3),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Group photo URL (optional)', controller: _avatar, prefixIcon: Icons.photo_camera_outlined),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: _editing ? 'Creator (change to another member)' : 'Creator (user ID, mobile number or email)',
                    hint: 'SC-4F2A9C',
                    controller: _creator,
                    prefixIcon: Icons.badge_outlined,
                  ),
                ],
              ),
            ),
            PanelCard(
              title: 'Location rules',
              child: Column(
                children: [
                  for (final l in const ['off', 'optional', 'mandatory']) _radio(locationLabel(l), l, _location, (v) => _location = v),
                  if (_location != 'off') ...[
                    const Divider(),
                    ListTile(
                      dense: true,
                      title: const Text('Share mode'),
                      trailing: DropdownButton<String>(
                        value: _shareMode,
                        underline: const SizedBox(),
                        items: const [DropdownMenuItem(value: 'join', child: Text('While joining')), DropdownMenuItem(value: 'live', child: Text('Live'))],
                        onChanged: (v) => setState(() => _shareMode = v!),
                      ),
                    ),
                    if (_shareMode == 'live')
                      ListTile(
                        dense: true,
                        title: const Text('Live update'),
                        trailing: DropdownButton<int>(
                          value: _interval,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('Every 5 min')),
                            DropdownMenuItem(value: 10, child: Text('Every 10 min')),
                            DropdownMenuItem(value: 30, child: Text('Every 30 min')),
                            DropdownMenuItem(value: 0, child: Text('Manual')),
                          ],
                          onChanged: (v) => setState(() => _interval = v!),
                        ),
                      ),
                  ],
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(alignment: Alignment.centerLeft, child: Text('Show member location', style: TextStyle(fontWeight: FontWeight.w600))),
                  ),
                  _radio('Admin', 'adminOnly', _visibility, (v) => _visibility = v),
                  _radio('Admin + Group Members', 'groupMembers', _visibility, (v) => _visibility = v),
                  _radio('Nobody', 'nobody', _visibility, (v) => _visibility = v),
                ],
              ),
            ),
            PanelCard(
              title: 'Message rules',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_person_outlined),
                    title: const Text('Message mode'),
                    subtitle: DropdownButton<String>(
                      isExpanded: true,
                      value: _mode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'public', child: Text('Public')),
                        DropdownMenuItem(value: 'private', child: Text('Private')),
                        DropdownMenuItem(value: 'user_select', child: Text('User can select')),
                      ],
                      onChanged: (v) => setState(() => _mode = v!),
                    ),
                  ),
                  SettingSwitch(icon: Icons.campaign_outlined, title: 'Only admins can send', value: _whoCanSend == 'admins', onChanged: (v) => setState(() => _whoCanSend = v ? 'admins' : 'all')),
                  SettingSwitch(icon: Icons.how_to_reg_outlined, title: 'Approve new members', value: _approve, onChanged: (v) => setState(() => _approve = v)),
                  SettingSwitch(icon: Icons.hourglass_top, title: 'New members read only for 24 hours', value: _restrictNew, onChanged: (v) => setState(() => _restrictNew = v)),
                  SettingSwitch(icon: Icons.shortcut, title: 'Public message forwarding', value: _publicForwarding, onChanged: (v) => setState(() => _publicForwarding = v)),
                  SettingSwitch(icon: Icons.lock_person_outlined, title: 'Private message forwarding', value: _privateForwarding, onChanged: (v) => setState(() => _privateForwarding = v)),
                  SettingSwitch(icon: Icons.delete_sweep_outlined, title: 'Chain deletion', value: _chainDeletion, onChanged: (v) => setState(() => _chainDeletion = v)),
                  SettingSwitch(icon: Icons.file_download_off_outlined, title: 'Download disabled', value: _downloadDisabled, onChanged: (v) => setState(() => _downloadDisabled = v)),
                  SettingSwitch(icon: Icons.screenshot_outlined, title: 'Screen protection', value: _screenshot, onChanged: (v) => setState(() => _screenshot = v)),
                  SettingSwitch(icon: Icons.water_drop_outlined, title: 'Dynamic watermark', value: _watermark, onChanged: (v) => setState(() => _watermark = v)),
                ],
              ),
            ),
            PanelCard(
              title: 'Content rules',
              child: Column(
                children: [
                  for (final r in ContentRule.values)
                    CheckboxListTile(
                      dense: true,
                      secondary: Icon(r.icon),
                      title: Text(r.label),
                      subtitle: Text(r.description),
                      value: _contentRules.contains(r.name),
                      onChanged: (v) => setState(() => v! ? _contentRules.add(r.name) : _contentRules.remove(r.name)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
