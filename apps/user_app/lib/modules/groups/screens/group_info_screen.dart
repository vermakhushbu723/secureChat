import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import '../state/groups_controller.dart';
import '../widgets/group_tile.dart';

class GroupInfoScreen extends StatelessWidget {
  const GroupInfoScreen({super.key, required this.groupId});

  final String groupId;

  Future<({GroupDetail detail, List<GroupMemberInfo> members, List<GroupMessage> media})> _load() async {
    final results = await Future.wait([
      GroupRepository.detail(groupId),
      GroupRepository.members(groupId),
      GroupRepository.media(groupId, 'media'),
    ]);
    return (
      detail: results[0] as GroupDetail,
      members: results[1] as List<GroupMemberInfo>,
      media: results[2] as List<GroupMessage>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Group info',
      child: Scaffold(
        appBar: AppBar(),
        body: AsyncView(
          load: _load,
          builder: (context, data, reload) => _Info(groupId: groupId, detail: data.detail, members: data.members, media: data.media, reload: reload),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.groupId, required this.detail, required this.members, required this.media, required this.reload});

  final String groupId;
  final GroupDetail detail;
  final List<GroupMemberInfo> members;
  final List<GroupMessage> media;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final g = detail.summary;
    final s = detail.settings;
    final canSeeLocations = s.locationRequirement != LocationRequirement.off &&
        (s.locationVisibility == LocationVisibility.groupMembers || (s.locationVisibility == LocationVisibility.adminOnly && detail.me.isAdmin));
    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Center(child: GroupAvatar(name: g.name, avatarUrl: g.avatarUrl, size: 110, inverted: true)),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(g.name, textAlign: TextAlign.center, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Center(child: Text('Group  |  ${g.memberCount} members', style: TextStyle(color: context.palette.textSecondary))),
          if (!g.isActive) ...[const SizedBox(height: 8), Center(child: StatusChip(g.statusLabel, tone: Tone.danger))],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _Btn(icon: Icons.chat_outlined, label: 'Chat', onTap: () => context.push(AppRoutes.groupChatOf(groupId))),
              _Btn(icon: Icons.search, label: 'Search', onTap: () => context.push(AppRoutes.messageSearchOf(groupId))),
              _Btn(icon: Icons.link, label: 'Invite', onTap: () => context.push(AppRoutes.inviteLinkOf(groupId))),
              if (canSeeLocations) _Btn(icon: Icons.map_outlined, label: 'Locations', onTap: () => context.push(AppRoutes.membersLocationOf(groupId))),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.description.isEmpty ? 'No description' : g.description, style: const TextStyle(fontSize: 15)),
                    if (detail.rules.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Rules: ${detail.rules}', style: TextStyle(color: context.palette.textSecondary, fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Created by ${detail.createdByName}${detail.createdAt == null ? '' : ', ${formatDayHeader(detail.createdAt!).toLowerCase()}'}  |  ${g.category}',
                      style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip('Messages: ${messageModeLabel(s.messageMode)}', tone: Tone.dark, icon: Icons.lock_person_outlined),
                        StatusChip(
                          'Location: ${s.locationRequirement.label}',
                          tone: s.locationRequirement == LocationRequirement.mandatory ? Tone.warning : Tone.neutral,
                          icon: Icons.location_on_outlined,
                        ),
                        if (s.whoCanSend == 'admins' || s.muteGroup)
                          const StatusChip('Only admins can send', tone: Tone.neutral, icon: Icons.campaign_outlined),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SectionHeader('Media, links and docs', action: '${media.length}', onAction: () => context.push(AppRoutes.mediaGalleryOf(groupId))),
          SizedBox(
            height: 84,
            child: media.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No media shared yet', style: TextStyle(color: context.palette.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: media.length.clamp(0, 12),
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final m = media[i];
                      final secure = m.media?.secure == true;
                      return InkWell(
                        onTap: () => secure && m.media?.fileId != null
                            ? context.push(AppRoutes.secureFileViewerOf(m.media!.fileId!))
                            : context.push(m.type == 'video' ? AppRoutes.videoViewerOf(m.id) : AppRoutes.imageViewerOf(m.id)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 84,
                            color: context.palette.surfaceAlt,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (!secure && m.type == 'image' && m.media?.previewUrl != null)
                                  Image.network(m.media!.previewUrl!, fit: BoxFit.cover)
                                else
                                  Center(child: Icon(m.type == 'video' ? Icons.videocam_outlined : Icons.image_outlined, color: context.palette.textSecondary)),
                                if (secure) const Positioned(right: 6, top: 6, child: Icon(Icons.lock, size: 14)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SectionHeader('Settings'),
          GroupedCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_off_outlined),
                title: const Text('Mute notifications'),
                value: g.muted,
                onChanged: (v) async {
                  await runAction(context, () => GroupRepository.updateMyState(groupId, muteSeconds: v ? -1 : 0), done: v ? 'Muted' : 'Unmuted');
                  GroupsController.instance.scheduleReload();
                  await reload();
                },
              ),
              AppTile(icon: Icons.settings_outlined, title: 'Group settings', onTap: () => context.push(AppRoutes.groupSettingsOf(groupId))),
              AppTile(icon: Icons.shield_outlined, title: 'Security settings', onTap: () => context.push(AppRoutes.groupSecurityOf(groupId))),
              AppTile(
                icon: Icons.location_on_outlined,
                title: 'Location',
                subtitle: s.locationRequirement == LocationRequirement.off
                    ? 'Disabled'
                    : '${s.locationRequirement.label}  |  ${detail.me.locationShared ? 'you are sharing' : 'not shared yet'}',
                onTap: () => context.push(
                  s.locationRequirement == LocationRequirement.off ? AppRoutes.locationSharing : AppRoutes.locationRequirementOf(groupId),
                ),
              ),
            ],
          ),
          SectionHeader('${g.memberCount} members', action: 'View all', onAction: () => context.push(AppRoutes.groupMembersOf(groupId))),
          GroupedCard(
            children: [
              for (final m in members.take(5))
                ListTile(
                  onTap: () => context.push(AppRoutes.memberProfileOf(groupId, m.userId)),
                  leading: GroupAvatar(name: m.displayName, avatarUrl: m.avatarUrl, size: 40),
                  title: Text(m.isMe ? 'You' : m.displayName),
                  subtitle: Text(m.presence),
                  trailing: m.role == MemberRole.member ? null : StatusChip(roleLabel(m.role), tone: Tone.dark),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GroupedCard(
            children: [
              AppTile(
                icon: Icons.exit_to_app,
                title: 'Exit group',
                danger: true,
                onTap: () async {
                  final ok = await context.confirm(
                    title: 'Exit group?',
                    message: detail.me.isOwner
                        ? 'You are the creator. Another admin (or the oldest member) becomes the creator.'
                        : 'You will stop receiving messages.',
                    confirmLabel: 'Exit',
                    danger: true,
                  );
                  if (!ok || !context.mounted) return;
                  if (await runAction(context, () => GroupRepository.leave(groupId), done: 'You left ${g.name}') && context.mounted) {
                    GroupsController.instance.remove(groupId);
                    context.go(AppRoutes.groupList);
                  }
                },
              ),
              AppTile(icon: Icons.flag_outlined, title: 'Report group', danger: true, onTap: () => context.push(AppRoutes.reportGroupOf(groupId))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: context.palette.divider), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [Icon(icon), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12))]),
      ),
    );
  }
}
