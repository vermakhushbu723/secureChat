import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/data/direct_repository.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import '../widgets/group_tile.dart';

/// Member view - display name only. No number, email or ID.
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key, required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Member',
      child: Scaffold(
        appBar: AppBar(title: const Text('Member')),
        body: AsyncView<GroupMemberInfo>(
          load: () => GroupRepository.member(groupId, memberId),
          builder: (context, m, reload) => _Profile(groupId: groupId, m: m, reload: reload),
        ),
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.groupId, required this.m, required this.reload});

  final String groupId;
  final GroupMemberInfo m;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final role = roleLabel(m.role);
    Future<void> act(Future<void> Function() fn, String done) async {
      await runAction(context, fn, done: done);
      await reload();
    }

    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 12),
          Center(child: GroupAvatar(name: m.displayName, avatarUrl: m.avatarUrl, size: 110, inverted: true)),
          const SizedBox(height: 14),
          Center(child: Text(m.displayName, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
          const SizedBox(height: 4),
          Center(child: Text(m.presence, style: TextStyle(color: context.palette.textSecondary, fontSize: 13))),
          if (role.isNotEmpty || m.restricted) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                if (role.isNotEmpty) StatusChip(role, tone: Tone.dark),
                if (m.restricted) const StatusChip('Read only', tone: Tone.warning),
              ],
            ),
          ],
          const SectionHeader('In this group'),
          GroupedCard(
            children: [
              InfoRow(label: 'Group', value: m.groupName ?? '', icon: Icons.groups_outlined),
              InfoRow(label: 'Joined', value: m.joinedAt == null ? '-' : formatDayHeader(m.joinedAt!).toLowerCase(), icon: Icons.calendar_today_outlined),
              if (m.about.isNotEmpty) InfoRow(label: m.accountType == 'business' ? 'Bio' : 'About', value: m.about, icon: Icons.info_outline),
              if (m.businessAddress != null) InfoRow(label: 'Business address', value: m.businessAddress!, icon: Icons.storefront_outlined),
              // Shown only when the member turned on "Show mobile number & email".
              if (m.phone != null) InfoRow(label: 'Mobile', value: m.phone!, icon: Icons.phone_outlined),
              if (m.email != null) InfoRow(label: 'Email', value: m.email!, icon: Icons.mail_outline),
              if (m.phone == null && m.email == null) const InfoRow(label: 'Mobile / Email', value: 'Hidden', icon: Icons.visibility_off_outlined),
              if (m.hasLocation)
                AppTile(
                  icon: Icons.location_on_outlined,
                  title: 'View location',
                  subtitle: m.locationPlace ?? '${m.locationLat!.toStringAsFixed(4)}, ${m.locationLng!.toStringAsFixed(4)}',
                  onTap: () => context.push(AppRoutes.mapViewOf(groupId, userId: m.userId)),
                ),
              AppTile(
                icon: Icons.perm_media_outlined,
                title: 'Shared media in group',
                subtitle: '${m.sharedMediaCount} item${m.sharedMediaCount == 1 ? '' : 's'}',
                onTap: () => context.push(AppRoutes.mediaGalleryOf(groupId)),
              ),
            ],
          ),
          if (m.canManage) ...[
            const SectionHeader('Group admin controls'),
            GroupedCard(
              children: [
                AppTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: m.role == MemberRole.admin ? 'Dismiss as admin' : 'Make group admin',
                  onTap: () => act(
                    () => GroupRepository.updateMember(groupId, m.userId, role: m.role == MemberRole.admin ? 'member' : 'admin'),
                    m.role == MemberRole.admin ? '${m.displayName} is no longer an admin' : '${m.displayName} is now an admin',
                  ),
                ),
                AppTile(
                  icon: m.restricted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                  title: m.restricted ? 'Allow sending messages' : 'Restrict member',
                  subtitle: m.restricted ? null : 'Read only in this group',
                  onTap: () => act(
                    () => GroupRepository.updateMember(groupId, m.userId, restricted: !m.restricted),
                    m.restricted ? '${m.displayName} can send again' : '${m.displayName} restricted',
                  ),
                ),
                AppTile(
                  icon: Icons.person_remove_outlined,
                  title: 'Remove from group',
                  danger: true,
                  onTap: () async {
                    final ok = await context.confirm(
                      title: 'Remove ${m.displayName}?',
                      message: 'They will no longer see messages from this group.',
                      confirmLabel: 'Remove',
                      danger: true,
                    );
                    if (!ok || !context.mounted) return;
                    if (await runAction(context, () => GroupRepository.removeMember(groupId, m.userId), done: 'Member removed') && context.mounted) {
                      context.pop();
                    }
                  },
                ),
              ],
            ),
          ],
          if (!m.isMe) ...[
            const SizedBox(height: 16),
            GroupedCard(
              children: [
                AppTile(
                  icon: Icons.block,
                  title: m.isBlocked ? 'Unblock ${m.displayName}' : 'Block ${m.displayName}',
                  danger: true,
                  onTap: () async {
                    if (m.isBlocked) return act(() => DirectRepository.unblock(m.userId), '${m.displayName} unblocked');
                    final ok = await context.confirm(
                      title: 'Block ${m.displayName}?',
                      message: 'You will not see messages from this member in any group.',
                      confirmLabel: 'Block',
                      danger: true,
                    );
                    if (ok && context.mounted) await act(() => DirectRepository.block(m.userId), '${m.displayName} blocked');
                  },
                ),
                AppTile(
                  icon: Icons.flag_outlined,
                  title: 'Report ${m.displayName}',
                  danger: true,
                  onTap: () => context.push(AppRoutes.reportUserOf(m.userId, groupId: groupId)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

