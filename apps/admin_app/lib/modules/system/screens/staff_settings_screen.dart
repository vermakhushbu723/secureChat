import '../../../core/core.dart';

class AdminStaffSettingsScreen extends StatelessWidget {
  const AdminStaffSettingsScreen({super.key});

  static const _staff = [
    ('Super Admin', 'admin@securechat.app', 'Super Admin', 'Active', 'Now'),
    ('Moderator 1', 'mod1@securechat.app', 'Moderator', 'Active', '10 min ago'),
    ('Moderator 2', 'mod2@securechat.app', 'Moderator', 'Active', '2 hours ago'),
    ('Support Staff', 'support@securechat.app', 'Support', 'Suspended', '3 days ago'),
  ];

  static const _permissions = ['Users', 'Groups', 'Messages', 'Subscriptions', 'Reports', 'Settings'];
  static const _roles = {
    'Super Admin': [true, true, true, true, true, true],
    'Moderator': [true, true, true, false, true, false],
    'Support': [true, false, false, true, true, false],
  };

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Admin & Staff Settings',
      subtitle: 'Manage staff accounts, roles and permissions',
      actions: [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.showSnack('Invite sent'),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Invite staff'),
        ),
      ],
      children: [
        AdminTable(
          columns: const ['Name', 'Email', 'Role', 'Status', 'Last active', ''],
          rows: [
            for (final s in _staff)
              [
                Row(
                  children: [
                    AppAvatar(
                      initials: s.$1.split(' ').map((e) => e[0]).join(),
                      size: 32,
                      inverted: s.$3 == 'Super Admin',
                    ),
                    const SizedBox(width: 10),
                    Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Text(s.$2),
                StatusChip(s.$3, tone: Tone.dark),
                StatusChip(s.$4),
                Text(s.$5),
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
              ],
          ],
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Role permissions',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Role')),
                for (final p in _permissions) DataColumn(label: Text(p)),
              ],
              rows: [
                for (final r in _roles.entries)
                  DataRow(
                    cells: [
                      DataCell(Text(r.key, style: const TextStyle(fontWeight: FontWeight.w700))),
                      for (final v in r.value) DataCell(Checkbox(value: v, onChanged: (_) {})),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'My admin account',
          child: Column(
            children: [
              const InfoRow(label: 'Name', value: 'Super Admin', icon: Icons.person_outline),
              const InfoRow(label: 'Email', value: 'admin@securechat.app', icon: Icons.mail_outline),
              const AppSwitchTile(icon: Icons.pin_outlined, title: '2-Step verification', value: true),
              AppTile(icon: Icons.password, title: 'Change password', onTap: () {}),
              AppTile(icon: Icons.logout, title: 'Logout', danger: true, onTap: () => context.go(AdminRoutes.login)),
            ],
          ),
        ),
      ],
    );
  }
}
