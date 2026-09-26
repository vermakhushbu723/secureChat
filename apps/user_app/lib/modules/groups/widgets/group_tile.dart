import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/widgets/dm_avatar.dart';
import '../data/group_models.dart';
import '../state/groups_controller.dart';

/// Group avatar: photo when set, otherwise initials.
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, required this.name, this.avatarUrl, this.size = 44, this.inverted = false});

  final String name;
  final String? avatarUrl;
  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) return AppAvatar(initials: groupInitials(name), size: size, inverted: inverted);
    return DmAvatar(name: name, avatarUrl: avatarUrl, size: size);
  }
}

class GroupTile extends StatelessWidget {
  const GroupTile({super.key, required this.group, this.onTap, this.trailing, this.subtitle});

  final GroupSummary group;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final typing = GroupsController.instance.typingLabel(group.id);
    final unread = group.unreadCount > 0;
    final last = group.lastMessage;
    final preview = subtitle ?? typing ?? last?.preview(AuthService.instance.userId) ?? (group.description.isEmpty ? 'Tap to open chat' : group.description);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minVerticalPadding: 10,
      visualDensity: VisualDensity.standard,
      leading: GroupAvatar(name: group.name, avatarUrl: group.avatarUrl, size: 50),
      title: Row(
        children: [
          Expanded(
            child: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          if (trailing == null)
            Text(
              formatListTime(group.lastMessageAt),
              style: TextStyle(fontSize: 12, color: unread ? context.colors.primary : p.textSecondary, fontWeight: unread ? FontWeight.w600 : FontWeight.w400),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            if (group.location != LocationRequirement.off && subtitle == null) ...[
              Icon(group.location == LocationRequirement.mandatory ? Icons.location_on : Icons.location_on_outlined, size: 14, color: p.textSecondary),
              const SizedBox(width: 4),
            ],
            if (!group.isActive) ...[Icon(Icons.pause_circle_outline, size: 14, color: p.danger), const SizedBox(width: 4)],
            Expanded(
              child: Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: typing != null ? context.colors.primary : (unread ? context.colors.onSurface : null),
                  fontStyle: typing != null || (last?.deleted ?? false) ? FontStyle.italic : FontStyle.normal,
                  fontWeight: unread && typing == null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (trailing == null && group.pinned) Icon(Icons.push_pin, size: 15, color: p.textSecondary),
            if (trailing == null && group.muted) Icon(Icons.volume_off_outlined, size: 16, color: p.textSecondary),
            if (trailing == null && unread)
              Container(
                margin: const EdgeInsets.only(left: 6),
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: group.muted ? p.textSecondary : context.colors.primary, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  group.unreadCount > 99 ? '99+' : '${group.unreadCount}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.onPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
      trailing: trailing,
    );
  }
}
