import '../../../core/core.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import '../state/groups_controller.dart';
import '../widgets/group_tile.dart';

/// Invite link -> Login? -> Join Group -> Location required? -> Join.
/// Opens from app.securechat.in/group/XXXXXX ([code]) or by pasting a link.
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key, this.code});

  final String? code;

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  late final _controller = TextEditingController(text: widget.code == null ? '' : '${AppStrings.inviteBaseUrl}${widget.code}');
  InvitePreview? _preview;
  String? _error;
  bool _loading = false;
  bool _joining = false;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    if (widget.code != null) _open(widget.code!);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(String input) async {
    final code = GroupRepository.codeFrom(input);
    if (code == null) return setState(() => _error = 'This does not look like an invite link');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await GroupRepository.invitePreview(code);
      if (mounted) setState(() => _preview = p);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinNow() async {
    final p = _preview!;
    setState(() => _joining = true);
    try {
      final res = await GroupRepository.join(p.code);
      GroupsController.instance.scheduleReload();
      if (!mounted) return;
      if (res.status == 'pending') {
        setState(() => _requested = true);
      } else {
        context.showSnack('You joined ${p.name}');
        context.go(AppRoutes.groupChatOf(res.groupId));
      }
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _join() {
    final p = _preview!;
    switch (p.location) {
      case LocationRequirement.mandatory:
        context.push(AppRoutes.locationRequirementOf(p.groupId, code: p.code));
      case LocationRequirement.optional:
        showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FeatureIcon(Icons.location_on_outlined, size: 64),
                  const SizedBox(height: 12),
                  const Text('Share your location? (optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Share & Join',
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.locationRequirementOf(p.groupId, code: p.code));
                    },
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: 'Join without location',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _joinNow();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      case LocationRequirement.off:
        _joinNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _preview;
    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      body: ValueListenableBuilder<AuthUser?>(
        valueListenable: AuthService.instance.user,
        builder: (context, user, _) {
          final loggedIn = user != null;
          final member = p?.membership == 'active';
          final pending = _requested || p?.membership == 'pending';
          return FormPage(
            items: [
              if (p == null) ...[
                const Center(child: FeatureIcon(Icons.group_add_outlined, size: 84)),
                const SizedBox(height: 20),
                Text(
                  'Paste the invite link you received on WhatsApp, Telegram or SMS',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.textSecondary),
                ),
                const SizedBox(height: 20),
                AppTextField(controller: _controller, hint: '${AppStrings.inviteBaseUrl}XXX-XXXXXX', prefixIcon: Icons.link),
                const SizedBox(height: 12),
                if (_error != null) ...[InfoBanner(icon: Icons.link_off, tone: Tone.danger, message: _error!), const SizedBox(height: 12)],
                SecondaryButton(label: _loading ? 'Opening...' : 'Open Link', icon: Icons.search, onPressed: _loading ? null : () => _open(_controller.text)),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        GroupAvatar(name: p.name, avatarUrl: p.avatarUrl, size: 80, inverted: true),
                        const SizedBox(height: 12),
                        Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('${p.memberCount} members  |  created by ${p.createdBy}', style: TextStyle(color: context.palette.textSecondary, fontSize: 13)),
                        if (p.description.isNotEmpty) ...[const SizedBox(height: 10), Text(p.description, textAlign: TextAlign.center)],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            StatusChip(
                              'Location: ${p.location.label}',
                              tone: p.location == LocationRequirement.mandatory ? Tone.warning : Tone.neutral,
                              icon: Icons.location_on_outlined,
                            ),
                            StatusChip('Messages: ${messageModeLabel(p.messageMode)}', tone: Tone.dark, icon: Icons.lock_person_outlined),
                            if (p.requireApproval) const StatusChip('Admin approval', tone: Tone.neutral, icon: Icons.how_to_reg_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!p.usable && !member)
                  InfoBanner(
                    icon: Icons.link_off,
                    tone: Tone.danger,
                    title: 'Invite link ${p.state.toLowerCase()}',
                    message: 'Ask a group admin for a new invite link.',
                  )
                else ...[
                  const _Step(done: true, label: 'Invite link verified'),
                  _Step(done: loggedIn, label: loggedIn ? 'Logged in' : 'Login or register'),
                  if (p.location != LocationRequirement.off)
                    _Step(done: member, label: p.location == LocationRequirement.mandatory ? 'Share location (mandatory)' : 'Share location (optional)'),
                  if (p.requireApproval) _Step(done: member, label: pending ? 'Waiting for admin approval' : 'Admin approval'),
                  _Step(done: member, label: member ? 'You are a member' : 'Join group'),
                  if (p.location == LocationRequirement.mandatory && !member) ...[
                    const SizedBox(height: 12),
                    InfoBanner(
                      icon: Icons.share_location,
                      tone: Tone.warning,
                      message: p.locationVisibility == LocationVisibility.groupMembers
                          ? 'This group requires location. Your location will be visible to the admin and members of this group.'
                          : 'This group requires location. Joining completes only after you allow and share your location.',
                    ),
                  ],
                  if (pending) ...[
                    const SizedBox(height: 12),
                    const InfoBanner(
                      icon: Icons.hourglass_top,
                      tone: Tone.success,
                      title: 'Request sent',
                      message: 'A group admin will review your request. You will be notified when you are added.',
                    ),
                  ],
                ],
              ],
            ],
            bottom: p == null
                ? null
                : member
                ? PrimaryButton(label: 'Open Group Chat', icon: Icons.chat_outlined, onPressed: () => context.go(AppRoutes.groupChatOf(p.groupId)))
                : !p.usable || pending
                ? null
                : loggedIn
                ? PrimaryButton(label: 'Join Group', icon: Icons.group_add_outlined, loading: _joining, onPressed: _joining ? null : _join)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PrimaryButton(label: 'Login to Join', onPressed: () => context.push(AppRoutes.loginFrom(AppRoutes.joinByCodeOf(p.code)))),
                      const SizedBox(height: 8),
                      SecondaryButton(
                        label: 'Create account',
                        onPressed: () => context.push('${AppRoutes.register}?from=${Uri.encodeComponent(AppRoutes.joinByCodeOf(p.code))}'),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.done, required this.label});

  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? context.palette.success : context.palette.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontWeight: done ? FontWeight.w600 : FontWeight.w400))),
        ],
      ),
    );
  }
}
