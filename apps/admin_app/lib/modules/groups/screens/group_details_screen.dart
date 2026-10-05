import '../../../core/core.dart';
import 'group_list_screen.dart';

class AdminGroupDetailsScreen extends StatefulWidget {
  const AdminGroupDetailsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<AdminGroupDetailsScreen> createState() => _AdminGroupDetailsScreenState();
}

class _AdminGroupDetailsScreenState extends State<AdminGroupDetailsScreen> {
  int _reload = 0;

  void _refresh() => setState(() => _reload++);

  Future<void> _go(String route) async {
    await context.push(route);
    if (mounted) _refresh();
  }

  static String _yes(bool? v) => v == true ? 'On' : 'Off';

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '${widget.groupId}|$_reload',
      load: () => AdminApi.get('/groups/${widget.groupId}'),
      builder: (context, g, _) {
        final suspended = g['status'] == 'suspended';
        final settings = g['settings'] as Map<String, dynamic>? ?? const {};
        final loc = settings['location'] as Map<String, dynamic>? ?? const {};
        final msg = settings['messages'] as Map<String, dynamic>? ?? const {};
        final sec = settings['security'] as Map<String, dynamic>? ?? const {};
        final rules = (settings['contentRules'] as List? ?? const []).length;
        final stats = g['stats'] as Map<String, dynamic>;
        final creator = g['creator'] as Map<String, dynamic>?;
        final premium = g['premium'] as Map<String, dynamic>? ?? const {};
        final invites = (g['invites'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'Group Details',
          showBack: true,
          onRefresh: _refresh,
          actions: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => _go(AdminRoutes.groupEditOf(widget.groupId)),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => _go(AdminRoutes.groupMembersOf(widget.groupId)),
              icon: const Icon(Icons.people_outline),
              label: const Text('Members'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => _go(AdminRoutes.groupLocationOf(widget.groupId)),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Location'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: suspended ? null : context.palette.danger),
              onPressed: () async {
                final ok = await context.confirm(
                  title: suspended ? 'Restore group?' : 'Suspend group?',
                  message: suspended ? 'Members can send messages again.' : 'Members can read but nobody can send messages until you restore it.',
                  confirmLabel: suspended ? 'Restore' : 'Suspend',
                  danger: !suspended,
                );
                if (!ok || !context.mounted) return;
                final r = await runAction(context, () => AdminApi.post('/groups/${widget.groupId}/status', {'suspended': !suspended}), success: suspended ? 'Group restored' : 'Group suspended');
                if (r != null) _refresh();
              },
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
                    AppAvatar(initials: initialsOf(g['name'] as String?), size: 72, inverted: true),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${g['name']}', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          if ((g['description'] as String?)?.isNotEmpty == true) Text('${g['description']}', style: TextStyle(color: context.palette.textSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              StatusChip(capitalize('${g['status']}')),
                              StatusChip('Location ${locationLabel(loc['requirement'] as String?)}', tone: loc['requirement'] == 'mandatory' ? Tone.warning : Tone.neutral),
                              StatusChip('Messages: ${messageModeLabel(msg['messageMode'] as String?)}', tone: Tone.dark),
                              if (premium['active'] == true) StatusChip('Premium (${premium['source'] == 'approved' ? 'admin approved' : 'creator plan'})', tone: Tone.success),
                              StatusChip('${g['category']}', tone: Tone.neutral),
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
                StatCard(icon: Icons.people_outline, label: 'Members', value: fmtNum(stats['members'])),
                StatCard(icon: Icons.forum_outlined, label: 'Messages (7d)', value: fmtNum(stats['messages7d'])),
                StatCard(icon: Icons.gpp_maybe_outlined, label: 'Blocked messages', value: fmtNum(stats['blockedMessages'])),
                StatCard(icon: Icons.share_location, label: 'Sharing location', value: fmtNum(stats['sharingLocation'])),
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
                      InfoRow(label: 'Group ID', value: '${g['id']}', icon: Icons.tag),
                      InfoRow(label: 'Creator', value: creator == null ? '-' : '${creator['name']} (${creator['internalId']})', icon: Icons.person_outline),
                      InfoRow(label: 'Created', value: fmtDate(g['createdAt']), icon: Icons.calendar_today_outlined),
                      InfoRow(label: 'Last message', value: fmtAgo(g['lastMessageAt']), icon: Icons.schedule),
                    ],
                  ),
                ),
                PanelCard(
                  title: 'Location rules',
                  child: Column(
                    children: [
                      InfoRow(label: 'Requirement', value: locationLabel(loc['requirement'] as String?), icon: Icons.location_on_outlined),
                      InfoRow(label: 'Show member location', value: visibilityLabel(loc['visibility'] as String?), icon: Icons.visibility_outlined),
                      InfoRow(
                        label: 'Mode',
                        value: loc['shareMode'] == 'live' ? 'Live, ${loc['liveIntervalMin'] == 0 ? 'manual' : 'every ${loc['liveIntervalMin']} min'}' : 'Location while joining',
                        icon: Icons.update,
                      ),
                    ],
                  ),
                ),
                PanelCard(
                  title: 'Message rules',
                  child: Column(
                    children: [
                      InfoRow(label: 'Message mode', value: messageModeLabel(msg['messageMode'] as String?), icon: Icons.lock_person_outlined),
                      InfoRow(label: 'Who can send', value: msg['whoCanSend'] == 'admins' ? 'Admins only' : 'All members', icon: Icons.send_outlined),
                      InfoRow(label: 'Forwarding', value: sec['publicForwarding'] == true ? (sec['privateForwarding'] == true ? 'Public + private' : 'Public only') : 'Off', icon: Icons.shortcut),
                      InfoRow(label: 'Chain deletion', value: _yes(sec['chainDeletion'] as bool?), icon: Icons.delete_sweep_outlined),
                      InfoRow(label: 'Content rules', value: '$rules of 7 on', icon: Icons.gpp_maybe_outlined),
                      SettingSwitch(
                        icon: Icons.person_search_outlined,
                        title: 'Members can search members',
                        subtitle: 'Owner / admins always can',
                        value: (settings['members'] as Map?)?['memberSearch'] != false,
                        onChanged: (v) async {
                          final r = await runAction(context, () => AdminApi.post('/groups/${widget.groupId}/member-search', {'enabled': v}), success: 'Member search ${v ? 'on' : 'off'}');
                          if (r != null) _refresh();
                        },
                      ),
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
                  for (final l in invites)
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: Text('${l['url']}', style: const TextStyle(fontFamily: 'monospace')),
                      subtitle: Text(
                        '${l['joins']}${(l['maxJoins'] as num) > 0 ? '/${l['maxJoins']}' : ''} joins  |  ${l['expiresAt'] == null ? 'never expires' : 'expires ${fmtDateTime(l['expiresAt'])}'}${l['requireApproval'] == true ? '  |  approval on' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusChip('${l['state']}', tone: l['state'] == 'Revoked' ? Tone.danger : null),
                          if (l['state'] == 'Active')
                            IconButton(
                              tooltip: 'Revoke',
                              icon: Icon(Icons.link_off, color: context.palette.danger),
                              onPressed: () async {
                                final r = await runAction(context, () => AdminApi.post('/invites/${l['code']}/revoke'), success: 'Link ${l['code']} revoked');
                                if (r != null) _refresh();
                              },
                            ),
                        ],
                      ),
                    ),
                  if (invites.isEmpty) const ListTile(title: Text('No invite links')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PanelCard(
              title: 'Access for all members',
              child: Column(
                children: [
                  InfoRow(
                    label: 'Group premium',
                    value: g['premiumApproved'] == true ? 'Approved by admin${g['premiumUntil'] == null ? '' : ' until ${fmtDate(g['premiumUntil'])}'}' : 'Not approved',
                    icon: Icons.workspace_premium_outlined,
                  ),
                  AppTile(
                    icon: g['premiumApproved'] == true ? Icons.remove_circle_outline : Icons.workspace_premium_outlined,
                    title: g['premiumApproved'] == true ? 'Remove group premium' : 'Make group premium (members use it free)',
                    onTap: () async {
                      final approve = g['premiumApproved'] != true;
                      int? days;
                      if (approve) {
                        days = await askDays(context, title: 'Group premium for', options: const [30, 90, 365]);
                        if (days == null) return;
                      }
                      if (!context.mounted) return;
                      final r = await runAction(
                        context,
                        () => AdminApi.post('/groups/${widget.groupId}/access', {'premium': approve, 'days': ?days, 'freeAccess': approve}),
                        success: approve ? 'Group is premium for $days days' : 'Group premium removed',
                      );
                      if (r != null) _refresh();
                    },
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
                onTap: () async {
                  if (await confirmDeleteGroup(context, widget.groupId, '${g['name']}') && context.mounted) context.go(AdminRoutes.groups);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
