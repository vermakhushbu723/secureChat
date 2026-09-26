import '../../../core/core.dart';

/// Configure: default trial, trial extension, free / premium extension,
/// extension duration, user-wise and group-wise access.
class AdminTrialManagementScreen extends StatefulWidget {
  const AdminTrialManagementScreen({super.key});

  @override
  State<AdminTrialManagementScreen> createState() => _AdminTrialManagementScreenState();
}

class _AdminTrialManagementScreenState extends State<AdminTrialManagementScreen> {
  int _trialDays = AppStrings.trialDays;
  int _extensionDays = 7;
  String _afterExpiry = 'Chat locked (read only)';

  @override
  Widget build(BuildContext context) {
    final trialUsers = [MockData.currentUser, ...MockData.users.where((u) => u.access == AccessType.trial)];
    return AdminPage(
      title: 'Trial Management',
      subtitle: '1,250 users on trial',
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.showSnack('Trial settings saved'),
          child: const Text('Save settings'),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 200,
          children: const [
            StatCard(icon: Icons.hourglass_bottom, label: 'Active trials', value: '1,250'),
            StatCard(icon: Icons.warning_amber_rounded, label: 'Expiring in 2 days', value: '214'),
            StatCard(icon: Icons.hourglass_disabled_outlined, label: 'Expired (30d)', value: '860'),
            StatCard(icon: Icons.trending_up, label: 'Trial to paid', value: '38%', delta: '+3%'),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 380,
          children: [
            PanelCard(
              title: 'Default trial',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Free chat trial for new users'),
                    subtitle: DropdownButton<int>(
                      isExpanded: true,
                      value: _trialDays,
                      underline: const SizedBox(),
                      items: const [
                        3,
                        7,
                        14,
                        30,
                      ].map((d) => DropdownMenuItem(value: d, child: Text('$d days'))).toList(),
                      onChanged: (v) => setState(() => _trialDays = v!),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_clock_outlined),
                    title: const Text('After expiry'),
                    subtitle: DropdownButton<String>(
                      isExpanded: true,
                      value: _afterExpiry,
                      underline: const SizedBox(),
                      items: const [
                        'Chat locked (read only)',
                        'Limited (text only)',
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _afterExpiry = v!),
                    ),
                  ),
                  const AppSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Remind 2 days before expiry',
                    value: true,
                  ),
                ],
              ),
            ),
            PanelCard(
              title: 'Extensions',
              child: Column(
                children: [
                  const AppSwitchTile(icon: Icons.more_time, title: 'Allow trial extension requests', value: true),
                  const AppSwitchTile(icon: Icons.card_giftcard_outlined, title: 'Free extension', value: true),
                  const AppSwitchTile(icon: Icons.workspace_premium_outlined, title: 'Premium extension', value: true),
                  ListTile(
                    leading: const Icon(Icons.timelapse),
                    title: const Text('Default extension duration'),
                    subtitle: DropdownButton<int>(
                      isExpanded: true,
                      value: _extensionDays,
                      underline: const SizedBox(),
                      items: const [7, 15, 30].map((d) => DropdownMenuItem(value: d, child: Text('$d days'))).toList(),
                      onChanged: (v) => setState(() => _extensionDays = v!),
                    ),
                  ),
                  const AppSwitchTile(icon: Icons.repeat, title: 'Max 2 extensions per user', value: true),
                ],
              ),
            ),
            PanelCard(
              title: 'Access scope',
              child: Column(
                children: [
                  AppTile(
                    icon: Icons.manage_accounts_outlined,
                    title: 'User-wise access',
                    subtitle: 'Override trial for a single user',
                    onTap: () => context.go(AdminRoutes.subscriptions),
                  ),
                  AppTile(
                    icon: Icons.groups_outlined,
                    title: 'Group-wise access',
                    subtitle: 'Give all members of a group free / premium access',
                    onTap: () => context.go(AdminRoutes.subscriptions),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const AdminFilterBar(hint: 'Search trial users', filters: ['All', 'Active', 'Expiring', 'Expired']),
        AdminTable(
          total: 1250,
          columns: const ['User', 'User ID', 'Started', 'Ends', 'Status', 'Actions'],
          rows: [
            for (final u in trialUsers)
              [
                Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(u.internalId, style: const TextStyle(fontFamily: 'monospace')),
                Text(u.trialStart),
                Text(u.trialEnd),
                const StatusChip('Trial'),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.showSnack('Extended by $_extensionDays days'),
                      child: const Text('Extend'),
                    ),
                    TextButton(onPressed: () => context.showSnack('Premium granted'), child: const Text('Premium')),
                    TextButton(
                      onPressed: () => context.showSnack('Trial ended'),
                      child: Text('End', style: TextStyle(color: context.palette.danger)),
                    ),
                  ],
                ),
              ],
          ],
        ),
      ],
    );
  }
}
