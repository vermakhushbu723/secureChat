import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../location/data/geo.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import '../state/groups_controller.dart';
import '../widgets/group_tile.dart';

/// Invite link -> (location if the group needs it) -> joined -> welcome page.
/// Opening a link (in the app or from WhatsApp / SMS) joins directly; pasting a
/// link does the same after "Join".
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key, this.code});

  final String? code;

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

enum _Stage { idle, checking, locating, joining, pending, joined, failed }

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  late final _controller = TextEditingController(text: widget.code == null ? '' : '${AppStrings.inviteBaseUrl}${widget.code}');
  InvitePreview? _preview;
  GroupDetail? _group;
  String? _error;
  bool _locationFailed = false;
  _Stage _stage = _Stage.idle;

  @override
  void initState() {
    super.initState();
    if (widget.code != null) WidgetsBinding.instance.addPostFrameCallback((_) => _start(widget.code!));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fail(String message, {bool location = false}) {
    if (!mounted) return;
    setState(() {
      _stage = _Stage.failed;
      _error = message;
      _locationFailed = location;
    });
  }

  /// Verifies the link, then joins straight away when logged in.
  Future<void> _start(String input) async {
    final code = GroupRepository.codeFrom(input);
    if (code == null) return _fail('This does not look like an invite link');
    setState(() {
      _stage = _Stage.checking;
      _error = null;
      _locationFailed = false;
    });
    try {
      final p = await GroupRepository.invitePreview(code);
      if (!mounted) return;
      setState(() => _preview = p);
      if (p.membership == 'active') return _welcome(p.groupId);
      if (p.membership == 'pending') return setState(() => _stage = _Stage.pending);
      if (!p.usable) return _fail('This invite link is ${p.state.toLowerCase()}. Ask a group admin for a new link.');
      if (!AuthService.instance.isLoggedIn) return setState(() => _stage = _Stage.idle);
      await _join(p);
    } on ApiException catch (e) {
      _fail(e.message);
    }
  }

  Future<void> _join(InvitePreview p) async {
    DmLocation? location;
    if (p.location != LocationRequirement.off) {
      setState(() => _stage = _Stage.locating);
      try {
        final pos = await Geo.current();
        location = DmLocation(lat: pos.latitude, lng: pos.longitude, name: 'Joined here');
      } catch (e) {
        // Optional location: join anyway. Mandatory: the group cannot be joined without it.
        if (p.location == LocationRequirement.mandatory) {
          return _fail('This group needs your location to join. $e', location: true);
        }
      }
    }
    if (!mounted) return;
    setState(() => _stage = _Stage.joining);
    try {
      final res = await GroupRepository.join(p.code, location: location, shareMode: location == null ? null : p.shareMode.name);
      GroupsController.instance.scheduleReload();
      if (res.status == 'pending') {
        if (mounted) setState(() => _stage = _Stage.pending);
      } else {
        await _welcome(res.groupId);
      }
    } on ApiException catch (e) {
      _fail(e.message, location: e.code == 'LOCATION_REQUIRED');
    }
  }

  Future<void> _welcome(String groupId) async {
    try {
      final g = await GroupRepository.detail(groupId);
      if (mounted) {
        setState(() {
          _group = g;
          _stage = _Stage.joined;
        });
      }
    } on ApiException catch (_) {
      if (mounted) setState(() => _stage = _Stage.joined);
    }
  }

  void _openChat() {
    final id = _group?.summary.id ?? _preview?.groupId;
    if (id != null) context.go(AppRoutes.groupChatOf(id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_stage == _Stage.joined ? 'Welcome' : 'Join group')),
      body: switch (_stage) {
        _Stage.joined => _Welcome(group: _group, preview: _preview!, onOpen: _openChat),
        _Stage.checking || _Stage.locating || _Stage.joining => _Progress(stage: _stage, preview: _preview),
        _ => _form(context),
      },
    );
  }

  Widget _form(BuildContext context) {
    final p = _preview;
    final loggedIn = AuthService.instance.isLoggedIn;
    return FormPage(
      items: [
        if (p == null) ...[
          const Center(child: FeatureIcon(Icons.group_add_outlined, size: 84)),
          const SizedBox(height: 20),
          Text('Paste the invite link you received', textAlign: TextAlign.center, style: TextStyle(color: context.palette.textSecondary)),
          const SizedBox(height: 20),
          AppTextField(controller: _controller, hint: '${AppStrings.inviteBaseUrl}XXX-XXXXXX', prefixIcon: Icons.link, onSubmitted: _start),
        ] else
          _GroupCard(preview: p),
        const SizedBox(height: 16),
        if (_stage == _Stage.pending)
          const InfoBanner(
            icon: Icons.hourglass_top,
            tone: Tone.success,
            title: 'Request sent',
            message: 'A group admin will approve your request. You will be added automatically.',
          ),
        if (_error != null) ...[
          InfoBanner(icon: _locationFailed ? Icons.location_off_outlined : Icons.link_off, tone: Tone.danger, message: _error!),
          if (_locationFailed) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.locationPermission),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Location permission'),
            ),
          ],
        ],
        if (p != null && !loggedIn && _error == null)
          const InfoBanner(icon: Icons.login, message: 'Log in with your mobile number or email. You will join the group right after.'),
      ],
      bottom: _stage == _Stage.pending
          ? null
          : p != null && !loggedIn
          ? PrimaryButton(label: 'Log in to join', onPressed: () => context.push(AppRoutes.loginFrom(AppRoutes.joinByCodeOf(p.code))))
          : PrimaryButton(
              label: _locationFailed ? 'Try again' : 'Join group',
              icon: Icons.group_add_outlined,
              onPressed: () => p != null && _locationFailed ? _join(p) : _start(p?.code ?? _controller.text),
            ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.preview});

  final InvitePreview preview;

  @override
  Widget build(BuildContext context) {
    final p = preview;
    return Column(
      children: [
        GroupAvatar(name: p.name, avatarUrl: p.avatarUrl, size: 88),
        const SizedBox(height: 12),
        Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        const SizedBox(height: 4),
        Text('Group  -  ${p.memberCount} members', style: TextStyle(color: context.palette.textSecondary)),
        if (p.description.isNotEmpty) ...[const SizedBox(height: 10), Text(p.description, textAlign: TextAlign.center)],
        if (p.location == LocationRequirement.mandatory) ...[
          const SizedBox(height: 12),
          const StatusChip('Location required to join', tone: Tone.warning, icon: Icons.location_on_outlined),
        ],
      ],
    );
  }
}

/// Short automatic progress: link -> location -> joining.
class _Progress extends StatelessWidget {
  const _Progress({required this.stage, this.preview});

  final _Stage stage;
  final InvitePreview? preview;

  @override
  Widget build(BuildContext context) {
    final p = preview;
    final steps = [
      ('Checking invite link', _Stage.checking),
      if (p != null && p.location != LocationRequirement.off) ('Getting your location', _Stage.locating),
      ('Joining group', _Stage.joining),
    ];
    final current = steps.indexWhere((s) => s.$2 == stage);
    return ResponsiveBody(
      maxWidth: 480,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (p != null) _GroupCard(preview: p) else const Center(child: FeatureIcon(Icons.group_add_outlined, size: 84)),
          const SizedBox(height: 32),
          for (final (i, s) in steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: i < current
                        ? Icon(Icons.check_circle, color: context.palette.success)
                        : i == current
                        ? const CircularProgressIndicator(strokeWidth: 2.5)
                        : Icon(Icons.radio_button_unchecked, color: context.palette.textMuted),
                  ),
                  const SizedBox(width: 14),
                  Text(s.$1, style: TextStyle(fontWeight: i == current ? FontWeight.w600 : FontWeight.w400)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown right after joining.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.group, required this.preview, required this.onOpen});

  final GroupDetail? group;
  final InvitePreview preview;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final g = group;
    final name = g?.summary.name ?? preview.name;
    return FormPage(
      items: [
        const SizedBox(height: 12),
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GroupAvatar(name: name, avatarUrl: g?.summary.avatarUrl ?? preview.avatarUrl, size: 104),
              Positioned(
                right: -4,
                bottom: -4,
                child: CircleAvatar(radius: 18, backgroundColor: AppColors.primary, child: const Icon(Icons.check, color: Colors.white, size: 22)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Welcome to $name!', textAlign: TextAlign.center, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'You joined the group  -  ${g?.summary.memberCount ?? preview.memberCount} members',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textSecondary),
        ),
        if ((g?.summary.description ?? preview.description).isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(g?.summary.description ?? preview.description, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
        ],
        if (g != null && g.rules.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Group rules', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(g.rules, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ],
        if (g != null && !g.me.canSend && g.me.sendBlockedMessage != null) ...[
          const SizedBox(height: 16),
          InfoBanner(icon: Icons.info_outline, message: g.me.sendBlockedMessage!),
        ],
      ],
      bottom: PrimaryButton(label: 'Open group chat', icon: Icons.chat_outlined, onPressed: onOpen),
    );
  }
}
