import 'dart:async';

import '../../../core/core.dart';
import '../../direct/data/direct_repository.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import '../state/groups_controller.dart';
import '../widgets/group_tile.dart';

/// Members list: only the configured display (starting) name is shown.
/// No mobile number, email or user ID.
class GroupMembersScreen extends StatelessWidget {
  const GroupMembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) => LoginGate(title: 'Members', child: _Members(groupId: groupId));
}

class _Members extends StatefulWidget {
  const _Members({required this.groupId});

  final String groupId;

  @override
  State<_Members> createState() => _MembersState();
}

class _MembersState extends State<_Members> {
  GroupDetail? _detail;
  List<GroupMemberInfo> _members = [];
  List<JoinRequest> _requests = [];
  String _query = '';
  bool _loading = true;
  String? _error;
  final List<StreamSubscription<dynamic>> _subs = [];

  String get groupId => widget.groupId;

  @override
  void initState() {
    super.initState();
    _load();
    final ws = SocketService.instance;
    for (final e in const ['group:member:joined', 'group:member:left', 'group:member:updated']) {
      _subs.add(ws.on(e).where((j) => j['groupId'] == groupId).listen((_) => _load()));
    }
    _subs.add(ws.on('group:join_request').where((j) => j['groupId'] == groupId).listen((_) => _load()));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final detail = await GroupRepository.detail(groupId);
      final members = await GroupRepository.members(groupId);
      final requests = detail.me.isAdmin ? await GroupRepository.requests(groupId) : <JoinRequest>[];
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _members = members;
        _requests = requests;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(JoinRequest r, bool approve) async {
    await runAction(
      context,
      () => GroupRepository.decideRequest(groupId, r.userId, approve: approve),
      done: approve ? '${r.displayName} approved' : 'Request declined',
    );
    GroupsController.instance.scheduleReload();
    await _load();
  }

  Future<void> _actions(GroupMemberInfo m) async {
    final me = _detail!.me;
    final canManage = me.isAdmin && m.role != MemberRole.owner && !(m.role == MemberRole.admin && !me.isOwner);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: GroupAvatar(name: m.displayName, avatarUrl: m.avatarUrl, size: 40),
                title: Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(m.presence),
              ),
              const Divider(),
              AppTile(icon: Icons.person_outline, title: 'View member', onTap: () => Navigator.pop(ctx, 'view')),
              if (canManage) ...[
                AppTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: m.role == MemberRole.admin ? 'Dismiss as admin' : 'Make group admin',
                  onTap: () => Navigator.pop(ctx, m.role == MemberRole.admin ? 'demote' : 'promote'),
                ),
                AppTile(
                  icon: m.restricted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                  title: m.restricted ? 'Allow sending messages' : 'Restrict (read only)',
                  onTap: () => Navigator.pop(ctx, m.restricted ? 'unrestrict' : 'restrict'),
                ),
                AppTile(icon: Icons.person_remove_outlined, title: 'Remove from group', danger: true, onTap: () => Navigator.pop(ctx, 'remove')),
              ],
              AppTile(icon: Icons.block, title: 'Block member', danger: true, onTap: () => Navigator.pop(ctx, 'block')),
              AppTile(icon: Icons.flag_outlined, title: 'Report member', danger: true, onTap: () => Navigator.pop(ctx, 'report')),
            ],
          ),
        ),
      ),
    );
    if (!mounted || picked == null) return;
    switch (picked) {
      case 'view':
        context.push(AppRoutes.memberProfileOf(groupId, m.userId));
      case 'report':
        context.push(AppRoutes.reportUserOf(m.userId, groupId: groupId));
      case 'promote':
        await runAction(context, () => GroupRepository.updateMember(groupId, m.userId, role: 'admin'), done: '${m.displayName} is now an admin');
      case 'demote':
        await runAction(context, () => GroupRepository.updateMember(groupId, m.userId, role: 'member'), done: '${m.displayName} is no longer an admin');
      case 'restrict':
        await runAction(context, () => GroupRepository.updateMember(groupId, m.userId, restricted: true), done: '${m.displayName} restricted');
      case 'unrestrict':
        await runAction(context, () => GroupRepository.updateMember(groupId, m.userId, restricted: false), done: '${m.displayName} can send again');
      case 'remove':
        if (await context.confirm(title: 'Remove ${m.displayName}?', message: 'They will no longer see messages from this group.', confirmLabel: 'Remove', danger: true) && mounted) {
          await runAction(context, () => GroupRepository.removeMember(groupId, m.userId), done: 'Member removed');
        }
      case 'block':
        if (await context.confirm(title: 'Block ${m.displayName}?', message: 'You will not see messages from this member in any group.', confirmLabel: 'Block', danger: true) && mounted) {
          await runAction(context, () => DirectRepository.block(m.userId), done: '${m.displayName} blocked');
        }
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final canSearch = d?.me.canSearchMembers ?? true;
    final members = _members.where((m) => !canSearch || _query.isEmpty || m.displayName.toLowerCase().contains(_query.toLowerCase())).toList();
    final showLocation = d != null &&
        d.settings.locationRequirement != LocationRequirement.off &&
        (d.settings.locationVisibility == LocationVisibility.groupMembers || (d.settings.locationVisibility == LocationVisibility.adminOnly && d.me.isAdmin));
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Members'),
            if (d != null) Text('${d.summary.memberCount} members', style: TextStyle(fontSize: 13, color: context.palette.textSecondary)),
          ],
        ),
        actions: [
          if (showLocation)
            IconButton(icon: const Icon(Icons.map_outlined), tooltip: 'Members location', onPressed: () => context.push(AppRoutes.membersLocationOf(groupId))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && d == null
          ? EmptyState(icon: Icons.error_outline, title: 'Could not load members', message: _error!)
          : RefreshIndicator(
              onRefresh: _load,
              child: ResponsiveBody(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: canSearch
                          ? AppSearchField(hint: 'Search by name', onChanged: (v) => setState(() => _query = v.trim()))
                          : InfoBanner(icon: Icons.search_off, message: d?.me.memberSearchBlockedReason ?? 'Member search is turned off in this group.'),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: InfoBanner(icon: Icons.visibility_off_outlined, message: 'Only display names are shown. Numbers, emails and IDs are hidden.'),
                    ),
                    ListTile(
                      leading: const AppAvatar(icon: Icons.link, inverted: true, size: 44),
                      title: const Text('Add members via invite link', style: TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () => context.push(AppRoutes.inviteLinkOf(groupId)),
                    ),
                    if (d!.me.isAdmin && _requests.isNotEmpty) ...[
                      SectionHeader('Join requests (${_requests.length})'),
                      for (final r in _requests)
                        ListTile(
                          leading: GroupAvatar(name: r.displayName, avatarUrl: r.avatarUrl, size: 44),
                          title: Text(r.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(r.locationShared ? 'Location shared  |  via invite link' : 'via invite link'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.close), tooltip: 'Decline', onPressed: () => _decide(r, false)),
                              IconButton.filled(color: Colors.white, icon: const Icon(Icons.check), tooltip: 'Approve', onPressed: () => _decide(r, true)),
                            ],
                          ),
                        ),
                    ],
                    SectionHeader('All members (${members.length})'),
                    for (final m in members)
                      ListTile(
                        onTap: () => context.push(AppRoutes.memberProfileOf(groupId, m.userId)),
                        leading: Stack(
                          children: [
                            GroupAvatar(name: m.displayName, avatarUrl: m.avatarUrl, size: 44),
                            if (m.online)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: context.palette.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                ),
                              ),
                          ],
                        ),
                        title: Text(m.isMe ? 'You (${m.displayName})' : m.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([m.presence, if (m.restricted) 'read only'].join('  |  ')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.role != MemberRole.member) StatusChip(roleLabel(m.role), tone: Tone.dark),
                            if (!m.isMe) IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _actions(m)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
