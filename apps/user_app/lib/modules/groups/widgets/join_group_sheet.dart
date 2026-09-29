import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../location/data/geo.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import '../state/groups_controller.dart';
import 'group_tile.dart';

/// Invite link opened from a chat / WhatsApp / SMS: set by the `/group/:code` route and
/// picked up by the main shell, which shows the join popup over the chat list.
class PendingJoin {
  PendingJoin._();

  static final code = ValueNotifier<String?>(null);
}

/// Join popup (WhatsApp style): group info, the group's permissions to accept, then join.
/// Location groups turn location on automatically after the member accepts.
Future<void> showJoinGroup(BuildContext context, String code) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _JoinSheet(code: code.toUpperCase()),
  );
}

/// "Join with link": paste an invite link, then the join popup.
Future<void> askInviteLink(BuildContext context) async {
  final controller = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Join with link'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: '${AppStrings.inviteBaseUrl}XXX-XXXXXX', prefixIcon: const Icon(Icons.link)),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Continue')),
      ],
    ),
  );
  controller.dispose();
  if (code == null || !context.mounted) return;
  final parsed = GroupRepository.codeFrom(code);
  if (parsed == null) return context.showSnack('This does not look like an invite link');
  await showJoinGroup(context, parsed);
}

class _JoinSheet extends StatefulWidget {
  const _JoinSheet({required this.code});

  final String code;

  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  InvitePreview? _preview;
  String? _error;
  bool _locationError = false;
  bool _accepted = false;
  bool _joining = false;
  String _progress = '';
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await GroupRepository.invitePreview(widget.code);
      if (!mounted) return;
      setState(() {
        _preview = p;
        _pending = p.membership == 'pending';
        if (!p.usable && p.membership != 'active') _error = 'This invite link is ${p.state.toLowerCase()}. Ask a group admin for a new link.';
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _openChat(String groupId) {
    final router = GoRouter.of(context);
    final wide = AppLayout.isWide(context);
    Navigator.of(context).pop();
    wide ? router.go(AppRoutes.groupChatOf(groupId)) : router.push(AppRoutes.groupChatOf(groupId));
  }

  Future<void> _join() async {
    final p = _preview!;
    setState(() {
      _joining = true;
      _error = null;
      _locationError = false;
    });
    DmLocation? location;
    try {
      if (p.location != LocationRequirement.off) {
        // Accepted the group's location rule: location turns on automatically.
        setState(() => _progress = 'Turning on your location...');
        try {
          final pos = await Geo.current();
          location = DmLocation(lat: pos.latitude, lng: pos.longitude, name: 'Joined here');
          final me = AuthService.instance.user.value;
          if (me != null && me.locationMode == 'none') await AuthService.instance.setGroupLocation(true);
        } catch (e) {
          if (p.location == LocationRequirement.mandatory) {
            setState(() {
              _error = 'This group needs your location. $e';
              _locationError = true;
            });
            return;
          }
        }
      }
      setState(() => _progress = 'Joining...');
      final res = await GroupRepository.join(p.code, location: location, shareMode: location == null ? null : p.shareMode.name);
      GroupsController.instance.scheduleReload();
      if (!mounted) return;
      if (res.status == 'pending') {
        setState(() => _pending = true);
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      _openChat(res.groupId);
      messenger?.showSnackBar(SnackBar(content: Text('You joined ${p.name}')));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _locationError = e.code == 'LOCATION_REQUIRED';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _joining = false;
          _progress = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _preview;
    final pal = context.palette;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        child: p == null
            ? SizedBox(
                height: 220,
                child: Center(
                  child: _error != null
                      ? Padding(padding: const EdgeInsets.all(24), child: InfoBanner(icon: Icons.link_off, tone: Tone.danger, message: _error!))
                      : const CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      children: [
                        Center(child: GroupAvatar(name: p.name, avatarUrl: p.avatarUrl, size: 80)),
                        const SizedBox(height: 12),
                        Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
                        const SizedBox(height: 4),
                        Text('Group  -  ${p.memberCount} members  -  by ${p.createdBy}', textAlign: TextAlign.center, style: TextStyle(color: pal.textSecondary)),
                        if (p.description.isNotEmpty) ...[const SizedBox(height: 10), Text(p.description, textAlign: TextAlign.center)],
                        if (p.membership != 'active' && p.usable && !_pending) ...[
                          const SizedBox(height: 18),
                          const Text('Group permissions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('By joining you accept these rules set by the group admin.', style: TextStyle(color: pal.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          for (final x in p.permissions)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(_iconFor(x.key), size: 20, color: x.key == 'location' ? AppColors.primary : pal.textSecondary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(x.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        if (x.detail.isNotEmpty) Text(x.detail, style: TextStyle(color: pal.textSecondary, fontSize: 13, height: 1.35)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (p.rules.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: pal.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Group rules', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(p.rules, style: const TextStyle(height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _accepted,
                            onChanged: _joining ? null : (v) => setState(() => _accepted = v ?? false),
                            title: const Text('I accept these group permissions'),
                          ),
                        ],
                        if (_pending)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: InfoBanner(
                              icon: Icons.hourglass_top,
                              tone: Tone.success,
                              title: 'Request sent',
                              message: 'A group admin will approve your request. You will be added automatically.',
                            ),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          InfoBanner(icon: _locationError ? Icons.location_off_outlined : Icons.info_outline, tone: Tone.danger, message: _error!),
                        ],
                      ],
                    ),
                  ),
                  Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 12), child: _button(context, p)),
                ],
              ),
      ),
    );
  }

  Widget _button(BuildContext context, InvitePreview p) {
    if (p.membership == 'active') return PrimaryButton(label: 'Open group chat', icon: Icons.chat_outlined, onPressed: () => _openChat(p.groupId));
    if (_pending) return SecondaryButton(label: 'Close', onPressed: () => Navigator.of(context).pop());
    if (!p.usable) return SecondaryButton(label: 'Close', onPressed: () => Navigator.of(context).pop());
    if (!AuthService.instance.isLoggedIn) {
      return PrimaryButton(
        label: 'Log in to join',
        onPressed: () {
          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          router.push(AppRoutes.loginFrom(AppRoutes.joinByCodeOf(p.code)));
        },
      );
    }
    return PrimaryButton(
      label: _joining ? (_progress.isEmpty ? 'Joining...' : _progress) : (_locationError ? 'Try again' : 'Accept & Join'),
      icon: Icons.group_add_outlined,
      loading: _joining,
      onPressed: _accepted && !_joining ? _join : null,
    );
  }

  static IconData _iconFor(String key) => switch (key) {
    'location' => Icons.share_location_outlined,
    'messages' => Icons.chat_outlined,
    'protection' => Icons.shield_outlined,
    'content' => Icons.block,
    'approval' => Icons.how_to_reg_outlined,
    'restricted' => Icons.hourglass_top,
    _ => Icons.visibility_off_outlined,
  };
}
