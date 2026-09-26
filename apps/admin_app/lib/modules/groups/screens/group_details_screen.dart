import '../../../core/core.dart';

class AdminGroupDetailsScreen extends StatelessWidget {
  const AdminGroupDetailsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final g = MockData.groupById(groupId);
    final suspended = g.status == 'Suspended';
    final links = MockData.inviteLinks.where((l) => l.group == g.name).toList();
    return AdminPage(
      title: 'Group Details',
      showBack: true,
      actions: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.push(AdminRoutes.groupEditOf(g.id)),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.push(AdminRoutes.groupMembersOf(g.id)),
          icon: const Icon(Icons.people_outline),
          label: const Text('Members'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.push(AdminRoutes.groupLocationOf(g.id)),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Location'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: suspended ? null : context.palette.danger,
          ),
          onPressed: () => context.confirm(
            title: suspended ? 'Restore group?' : 'Suspend group?',
            message: suspended ? 'Members will regain access.' : 'All members will lose access to this group.',
            confirmLabel: suspended ? 'Restore' : 'Suspend',
            danger: !suspended,
          ),
          icon: Icon(suspended ? Icons.play_circle_outline : Icons.pause_circle_outline),
          label: Text(suspended ? 'Restore' : 'Suspend'),
        ),
      ],
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AppAvatar(initials: g.initials, size: 72, inverted: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text(g.description, style: TextStyle(color: context.palette.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusChip(g.status),
                          StatusChip(
                            'Location ${g.location.label}',
                            tone: g.locationRequired ? Tone.warning : Tone.neutral,
                          ),
                          StatusChip('Messages: ${g.messageMode}', tone: Tone.dark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 180,
          children: [
            StatCard(icon: Icons.people_outline, label: 'Members', value: '${g.memberCount}'),
            const StatCard(icon: Icons.forum_outlined, label: 'Messages (7d)', value: '2,418'),
            const StatCard(icon: Icons.gpp_maybe_outlined, label: 'Blocked messages', value: '37'),
            const StatCard(icon: Icons.share_location, label: 'Sharing location', value: '18'),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 340,
          children: [
            PanelCard(
              title: 'Information',
              child: Column(
                children: [
                  InfoRow(label: 'Group ID', value: 'GRP-${g.id.toUpperCase()}', icon: Icons.tag),
                  InfoRow(
                    label: 'Creator',
                    value: '${MockData.users.first.name} (${MockData.users.first.internalId})',
                    icon: Icons.person_outline,
                  ),
                  InfoRow(label: 'Created', value: g.createdOn, icon: Icons.calendar_today_outlined),
                ],
              ),
            ),
            PanelCard(
              title: 'Location rules',
              child: Column(
                children: [
                  InfoRow(label: 'Requirement', value: g.location.label, icon: Icons.location_on_outlined),
                  InfoRow(
                    label: 'Show member location',
                    value: switch (g.locationVisibility) {
                      LocationVisibility.adminOnly => 'Admin',
                      LocationVisibility.groupMembers => 'Admin + members',
                      LocationVisibility.nobody => 'Nobody',
                    },
                    icon: Icons.visibility_outlined,
                  ),
                  const InfoRow(label: 'Mode', value: 'Live, every 10 min', icon: Icons.update),
                ],
              ),
            ),
            PanelCard(
              title: 'Message rules',
              child: Column(
                children: [
                  InfoRow(label: 'Message mode', value: g.messageMode, icon: Icons.lock_person_outlined),
                  const InfoRow(label: 'Forwarding', value: 'Public only', icon: Icons.shortcut),
                  const InfoRow(label: 'Chain deletion', value: 'On', icon: Icons.delete_sweep_outlined),
                  const InfoRow(label: 'Content rules', value: '7 of 7 on', icon: Icons.gpp_maybe_outlined),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Invite links',
          action: 'All links',
          onAction: () => context.go(AdminRoutes.inviteLinks),
          child: Column(
            children: [
              for (final l in links)
                ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(l.url),
                  subtitle: Text('${l.joins}${l.maxJoins > 0 ? '/${l.maxJoins}' : ''} joins  |  expires ${l.expires}'),
                  trailing: StatusChip(l.status),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Danger zone',
          child: AppTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete group',
            danger: true,
            onTap: () => context.confirm(
              title: 'Delete ${g.name}?',
              message: 'All messages, files and invite links of this group will be removed.',
              confirmLabel: 'Delete',
              danger: true,
            ),
          ),
        ),
      ],
    );
  }
}
