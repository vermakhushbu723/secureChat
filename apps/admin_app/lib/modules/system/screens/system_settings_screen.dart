import '../../../core/core.dart';

/// Platform configuration: verification, registration, PWA, real-time, storage, maintenance.
class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  State<AdminSystemSettingsScreen> createState() => _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen> {
  Map<String, dynamic>? _s;
  final Map<String, Object?> _changes = {};
  String? _error;
  int _healthKey = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await AdminApi.get<Map<String, dynamic>>('/settings/system');
      if (mounted) {
        setState(() {
          _s = s;
          _changes.clear();
          _error = null;
          _healthKey++;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Object? _v(String key) => _changes.containsKey(key) ? _changes[key] : _s?[key];
  void _set(String key, Object? value) => setState(() => _changes[key] = value);

  Future<void> _save() async {
    if (_changes['maintenance'] == true && !await context.confirm(title: 'Turn on maintenance mode?', message: 'The app stops working for every user until you turn it off.', confirmLabel: 'Turn on', danger: true)) return;
    if (!mounted) return;
    final maps = _changes.containsKey('mapsEnabled') || _changes.containsKey('mapsApiKey');
    final r = await runAction(context, () => AdminApi.put('/settings/system', Map<String, Object?>.from(_changes)), success: 'System settings saved');
    if (r == null) return;
    if (maps) await AdminApi.loadMapConfig();
    await _load();
  }

  Widget _drop<T>(String key, List<T> items, String Function(T) label) => DropdownButton<T>(
    isExpanded: true,
    value: items.contains(_v(key)) ? _v(key) as T : items.first,
    underline: const SizedBox(),
    items: [for (final i in items) DropdownMenuItem(value: i, child: Text(label(i)))],
    onChanged: (v) => _set(key, v),
  );

  Widget _numTile(IconData icon, String title, String key, List<int> options, String Function(int) label) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: SizedBox(width: 150, child: _drop<int>(key, options, label)),
  );

  @override
  Widget build(BuildContext context) {
    if (_error != null) return ErrorPanel(message: _error!, onRetry: _load);
    if (_s == null) return const Center(child: CircularProgressIndicator());
    final maintenance = _v('maintenance') == true;
    return AdminPage(
      title: 'System Settings',
      subtitle: 'Platform wide configuration',
      onRefresh: _load,
      actions: [FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _changes.isEmpty ? null : _save, child: const Text('Save'))],
      children: [
        if (_s!['maintenance'] == true) ...[
          const InfoBanner(icon: Icons.construction_outlined, tone: Tone.danger, title: 'Maintenance mode is ON', message: 'Users cannot use the app right now.'),
          const SizedBox(height: 16),
        ],
        ResponsiveGrid(
          minItemWidth: 380,
          children: [
            PanelCard(
              title: 'Registration & login',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('Verification'),
                    subtitle: _drop<String>('verification', const ['mobile', 'email', 'mobile_email'], (v) => const {'mobile': 'Mobile OTP', 'email': 'Email', 'mobile_email': 'Mobile number + email OTP'}[v]!),
                  ),
                  SettingSwitch(icon: Icons.person_add_alt, title: 'Open registration', subtitle: 'Off = no new accounts', value: _v('openRegistration') == true, onChanged: (v) => _set('openRegistration', v)),
                  _numTile(Icons.devices_outlined, 'Max devices per user', 'maxDevices', const [1, 2, 3, 5, 10], (v) => '$v'),
                  _numTile(Icons.timer_outlined, 'OTP expiry', 'otpExpiryMin', const [2, 5, 10, 15], (v) => '$v minutes'),
                ],
              ),
            ),
            PanelCard(
              title: 'Platform rules',
              child: Column(
                children: [
                  SettingSwitch(icon: Icons.chat_outlined, title: 'Direct 1-to-1 chat', subtitle: 'Off = users can only chat in groups', value: _v('directChat') == true, onChanged: (v) => _set('directChat', v)),
                  SettingSwitch(
                    icon: Icons.visibility_off_outlined,
                    title: 'Hide phone / email / user ID from members',
                    subtitle: 'Members see display (starting) name only',
                    value: _v('hideContactFromMembers') == true,
                    onChanged: (v) => _set('hideContactFromMembers', v),
                  ),
                  SettingSwitch(icon: Icons.badge_outlined, title: 'Auto starting name (Rahul Sharma -> Rahul)', value: _v('autoStartingName') == true, onChanged: (v) => _set('autoStartingName', v)),
                ],
              ),
            ),
            PanelCard(
              title: 'PWA & apps',
              child: Column(
                children: [
                  SettingSwitch(icon: Icons.install_mobile_outlined, title: 'Installable PWA', value: _v('pwaInstallable') == true, onChanged: (v) => _set('pwaInstallable', v)),
                  SettingSwitch(icon: Icons.android, title: 'Android app - FLAG_SECURE on protected screens', value: _v('flagSecure') == true, onChanged: (v) => _set('flagSecure', v)),
                  ListTile(
                    leading: const Icon(Icons.system_update_alt),
                    title: const Text('Minimum app version'),
                    trailing: SizedBox(
                      width: 110,
                      child: TextFormField(
                        key: ValueKey('minv${_s!['minAppVersion']}'),
                        initialValue: '${_v('minAppVersion')}',
                        textAlign: TextAlign.center,
                        onChanged: (v) {
                          if (RegExp(r'^\d+\.\d+\.\d+$').hasMatch(v.trim())) _set('minAppVersion', v.trim());
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PanelCard(
              title: 'Google Maps',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingSwitch(
                    icon: Icons.map_outlined,
                    title: 'Show Google Maps',
                    subtitle: 'User app (web + Android) and admin location screens. Off = simple drawn map',
                    value: _v('mapsEnabled') != false,
                    onChanged: (v) => _set('mapsEnabled', v),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextFormField(
                      key: ValueKey('mapkey${_s!['mapsApiKey']}'),
                      initialValue: '${_v('mapsApiKey') ?? ''}',
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Maps JavaScript API key',
                        hintText: 'AIza...',
                        helperText: 'Empty = the key in the server .env (GOOGLE_MAPS_API_KEY)',
                        prefixIcon: Icon(Icons.key_outlined),
                      ),
                      onChanged: (v) => _set('mapsApiKey', v.trim()),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: MapConfig.enabled,
                    builder: (context, on, _) => ListTile(
                      leading: Icon(on ? Icons.check_circle_outline : Icons.info_outline, color: on ? context.palette.success : context.palette.textSecondary),
                      title: Text(on ? 'Google Maps is active' : 'Google Maps is off (no key or turned off)'),
                    ),
                  ),
                ],
              ),
            ),
            PanelCard(
              title: 'Storage & retention',
              child: Column(
                children: [
                  _numTile(Icons.upload_file_outlined, 'Max file size', 'maxFileMb', const [10, 25, 50, 100], (v) => '$v MB'),
                  _numTile(Icons.key_outlined, 'Secure file token expiry', 'fileTokenMin', const [5, 15, 30, 60], (v) => '$v minutes'),
                  _numTile(Icons.history, 'Audit log retention', 'auditRetentionDays', const [90, 365, 730, 1825], (v) => v >= 365 ? '${v ~/ 365} years' : '$v days'),
                  SettingSwitch(icon: Icons.construction_outlined, title: 'Maintenance mode', subtitle: maintenance ? 'App is offline for users' : null, value: maintenance, onChanged: (v) => _set('maintenance', v)),
                  if (maintenance)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextFormField(
                        initialValue: '${_v('maintenanceMessage')}',
                        maxLength: 200,
                        decoration: const InputDecoration(labelText: 'Message shown to users'),
                        onChanged: (v) => _set('maintenanceMessage', v),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminAsync<Map<String, dynamic>>(
          reloadKey: _healthKey,
          load: () => AdminApi.get('/system/health'),
          builder: (context, h, reload) {
            final services = (h['services'] as List).cast<Map<String, dynamic>>();
            final up = (h['uptimeSec'] as num).toInt();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Service health  |  up ${up ~/ 86400}d ${(up % 86400) ~/ 3600}h ${(up % 3600) ~/ 60}m  |  ${h['memoryMb']} MB memory  |  Node ${h['node']}',
                        style: TextStyle(color: context.palette.textSecondary),
                      ),
                    ),
                    IconButton(tooltip: 'Check again', onPressed: reload, icon: const Icon(Icons.refresh)),
                  ],
                ),
                AdminTable(
                  columns: const ['Service', 'Status', 'Metric'],
                  rows: [
                    for (final s in services)
                      [
                        Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        StatusChip('${s['status']}', tone: s['status'] == 'Healthy' ? Tone.success : s['status'] == 'Down' ? Tone.danger : Tone.warning),
                        Text('${s['metric']}'),
                      ],
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
