import '../../../core/core.dart';
import 'user_list_screen.dart';

/// View / Edit / Block user, trial status, extend trial, free / premium access, location.
class AdminUserDetailsScreen extends StatefulWidget {
  const AdminUserDetailsScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  late final AppUser u = MockData.userById(widget.userId);
  late AccessType _access = u.access;

  @override
  Widget build(BuildContext context) {
    final blocked = u.status == UserStatus.blocked;
    return AdminPage(
      title: 'User Details',
      showBack: true,
      actions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.push(AdminRoutes.userActivityOf(u.id)),
          icon: const Icon(Icons.timeline),
          label: const Text('Activity'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.push(AdminRoutes.userLocationOf(u.id)),
          icon: const Icon(Icons.location_on_outlined),
          label: const Text('Location'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: blocked ? null : context.palette.danger,
          ),
          onPressed: () => context.confirm(
            title: blocked ? 'Unblock user?' : 'Block user?',
            message: blocked
                ? '${u.name} will regain access.'
                : '${u.name} will lose access to every group immediately.',
            confirmLabel: blocked ? 'Unblock' : 'Block',
            danger: !blocked,
          ),
          icon: Icon(blocked ? Icons.lock_open : Icons.block),
          label: Text(blocked ? 'Unblock' : 'Block'),
        ),
      ],
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 20,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppAvatar(initials: u.initials, size: 80, inverted: true, online: u.isOnline),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      '${u.internalId}  |  ${u.phone}  |  ${u.email}',
                      style: TextStyle(color: context.palette.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        StatusChip(userStatusLabel(u.status)),
                        StatusChip(_access.label, tone: accessTone(_access), icon: Icons.workspace_premium_outlined),
                        StatusChip('Shown as "${u.displayName}"', tone: Tone.neutral, icon: Icons.badge_outlined),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 180,
          children: [
            const StatCard(icon: Icons.groups_outlined, label: 'Groups joined', value: '4'),
            const StatCard(icon: Icons.forum_outlined, label: 'Messages sent', value: '1,284'),
            StatCard(icon: Icons.gpp_maybe_outlined, label: 'Content warnings', value: '${u.warnings}'),
            const StatCard(icon: Icons.flag_outlined, label: 'Reports against', value: '2'),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 360,
          children: [
            PanelCard(
              title: 'Trial & access',
              child: Column(
                children: [
                  InfoRow(label: 'Trial', value: '${u.trialStart} - ${u.trialEnd}', icon: Icons.hourglass_bottom),
                  InfoRow(label: 'Current access', value: _access.label, icon: Icons.verified_user_outlined),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in AccessType.values)
                          ChoiceChip(
                            label: Text(a.label),
                            selected: _access == a,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _access = a),
                          ),
                      ],
                    ),
                  ),
                  AppTile(
                    icon: Icons.more_time,
                    title: 'Extend trial by 7 days',
                    onTap: () => context.showSnack('Trial extended by 7 days'),
                  ),
                  AppTile(
                    icon: Icons.event_repeat,
                    title: 'Extend trial by 30 days',
                    onTap: () => context.showSnack('Trial extended by 30 days'),
                  ),
                ],
              ),
            ),
            PanelCard(
              title: 'Edit profile',
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  AppTextField(label: 'Full name', initialValue: u.name),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Display name (shown to members)', initialValue: u.displayName),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                      onPressed: () => context.showSnack('User updated'),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Groups',
          child: Column(
            children: [
              for (final g in MockData.groups.take(3))
                ListTile(
                  onTap: () => context.push(AdminRoutes.groupDetailsOf(g.id)),
                  leading: AppAvatar(initials: g.initials, size: 36),
                  title: Text(g.name),
                  subtitle: Text('${g.memberCount} members  |  location ${g.location.label.toLowerCase()}'),
                  trailing: const Icon(Icons.chevron_right),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Security actions',
          child: Column(
            children: [
              AppTile(
                icon: Icons.volume_off_outlined,
                title: 'Restrict messaging (read only)',
                onTap: () => context.showSnack('User restricted'),
              ),
              AppTile(
                icon: Icons.logout,
                title: 'Force logout all devices',
                onTap: () => context.showSnack('Sessions revoked'),
              ),
              AppTile(icon: Icons.pause_circle_outline, title: 'Suspend for 7 days', danger: true, onTap: () {}),
              AppTile(icon: Icons.delete_forever_outlined, title: 'Delete account', danger: true, onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }
}
