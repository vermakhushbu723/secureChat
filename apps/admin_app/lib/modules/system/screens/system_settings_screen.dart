import '../../../core/core.dart';

/// Platform configuration: verification, registration, PWA, real-time, storage, maintenance.
class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  State<AdminSystemSettingsScreen> createState() => _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen> {
  String _verification = 'Mobile OTP + Email';

  static const _services = [
    ('REST API', 'Healthy', '42 ms'),
    ('WebSocket (real-time)', 'Healthy', '184,320 connections'),
    ('Moderation engine', 'Healthy', '2.1 ms / message'),
    ('Location service', 'Healthy', '190 live'),
    ('File storage (object)', 'Healthy', '2.4 TB used'),
    ('Notification service', 'Degraded', 'Queue 1,240'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'System Settings',
      subtitle: 'Platform wide configuration',
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.showSnack('System settings saved'),
          child: const Text('Save'),
        ),
      ],
      children: [
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
                    subtitle: DropdownButton<String>(
                      isExpanded: true,
                      value: _verification,
                      underline: const SizedBox(),
                      items: const [
                        'Mobile OTP',
                        'Email',
                        'Mobile OTP + Email',
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _verification = v!),
                    ),
                  ),
                  const AppSwitchTile(icon: Icons.person_add_alt, title: 'Open registration', value: true),
                  const AppSwitchTile(icon: Icons.devices_outlined, title: 'Max 3 devices per user', value: true),
                  const InfoRow(label: 'OTP expiry', value: '5 minutes', icon: Icons.timer_outlined),
                ],
              ),
            ),
            const PanelCard(
              title: 'Platform rules',
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.speaker_notes_off_outlined),
                    title: Text('Direct 1-to-1 chat'),
                    subtitle: Text('Disabled at system level - cannot be enabled'),
                    trailing: StatusChip('Off', tone: Tone.neutral),
                  ),
                  ListTile(
                    leading: Icon(Icons.visibility_off_outlined),
                    title: Text('Hide phone / email / user ID from members'),
                    subtitle: Text('Members see display (starting) name only'),
                    trailing: StatusChip('Enforced', tone: Tone.success),
                  ),
                  AppSwitchTile(
                    icon: Icons.badge_outlined,
                    title: 'Auto starting name (Rahul Sharma -> Rahul)',
                    value: true,
                  ),
                ],
              ),
            ),
            const PanelCard(
              title: 'PWA & apps',
              child: Column(
                children: [
                  AppSwitchTile(icon: Icons.install_mobile_outlined, title: 'Installable PWA', value: true),
                  AppSwitchTile(
                    icon: Icons.android,
                    title: 'Android app - FLAG_SECURE on protected screens',
                    value: true,
                  ),
                  InfoRow(label: 'Minimum app version', value: '1.0.0', icon: Icons.system_update_alt),
                ],
              ),
            ),
            const PanelCard(
              title: 'Storage & retention',
              child: Column(
                children: [
                  InfoRow(label: 'Max file size', value: '100 MB', icon: Icons.upload_file_outlined),
                  InfoRow(label: 'Secure file token expiry', value: '30 minutes', icon: Icons.key_outlined),
                  InfoRow(label: 'Audit log retention', value: '2 years', icon: Icons.history),
                  AppSwitchTile(icon: Icons.construction_outlined, title: 'Maintenance mode'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminTable(
          columns: const ['Service', 'Status', 'Metric'],
          rows: [
            for (final s in _services)
              [
                Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                StatusChip(s.$2, tone: s.$2 == 'Healthy' ? Tone.success : Tone.warning),
                Text(s.$3),
              ],
          ],
        ),
      ],
    );
  }
}
