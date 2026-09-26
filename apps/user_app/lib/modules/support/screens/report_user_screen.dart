import '../../../core/core.dart';
import '../../direct/data/direct_repository.dart';
import '../../direct/widgets/dm_avatar.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/state/groups_controller.dart';
import '../../groups/widgets/group_tile.dart';

/// Report a member (optionally in the context of a group) or a whole group.
class ReportUserScreen extends StatelessWidget {
  const ReportUserScreen({super.key, this.userId, this.groupId}) : assert(userId != null || groupId != null);

  /// Null when reporting the group itself.
  final String? userId;
  final String? groupId;

  bool get _isGroup => userId == null;

  Future<({String name, String? avatarUrl, String subtitle})> _target() async {
    final gid = groupId;
    final uid = userId;
    if (uid == null) {
      final g = await GroupRepository.detail(gid!);
      return (name: g.summary.name, avatarUrl: g.summary.avatarUrl, subtitle: '${g.summary.memberCount} members');
    }
    if (gid != null) {
      final m = await GroupRepository.member(gid, uid);
      return (name: m.displayName, avatarUrl: m.avatarUrl, subtitle: 'Member of ${m.groupName ?? 'your group'}  |  identity hidden');
    }
    final u = await DirectRepository.getUser(uid);
    return (name: u.name, avatarUrl: u.avatarUrl, subtitle: u.username == null ? 'Member' : '@${u.username}');
  }

  @override
  Widget build(BuildContext context) {
    final title = _isGroup ? 'Report Group' : 'Report Member';
    return LoginGate(
      title: title,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AsyncView(load: _target, builder: (context, t, _) => _Form(userId: userId, groupId: groupId, name: t.name, avatarUrl: t.avatarUrl, subtitle: t.subtitle)),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.userId, required this.groupId, required this.name, required this.avatarUrl, required this.subtitle});

  final String? userId;
  final String? groupId;
  final String name;
  final String? avatarUrl;
  final String subtitle;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final Set<String> _reasons = {};
  final _details = TextEditingController();
  late bool _alsoAct = widget.userId != null;
  bool _sending = false;

  bool get _isGroup => widget.userId == null;

  static const _memberOptions = [
    (Icons.report_outlined, 'Spam or fake account'),
    (Icons.sentiment_very_dissatisfied_outlined, 'Harassment or bullying'),
    (Icons.privacy_tip_outlined, 'Leaking private content'),
    (Icons.money_off, 'Fraud or scam'),
    (Icons.contact_phone_outlined, 'Sharing contact details'),
    (Icons.more_horiz, 'Other'),
  ];

  static const _groupOptions = [
    (Icons.report_outlined, 'Spam or scam group'),
    (Icons.dangerous_outlined, 'Illegal or harmful content'),
    (Icons.sentiment_very_dissatisfied_outlined, 'Hate speech or harassment'),
    (Icons.privacy_tip_outlined, 'Leaking private content'),
    (Icons.no_adult_content, 'Adult content'),
    (Icons.more_horiz, 'Other'),
  ];

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await GroupRepository.report(
        type: _isGroup ? 'group' : 'user',
        userId: widget.userId,
        groupId: widget.groupId,
        reasons: _reasons.toList(),
        details: _details.text.trim(),
        alsoBlock: !_isGroup && _alsoAct,
      );
      if (_isGroup && _alsoAct) {
        await GroupRepository.leave(widget.groupId!);
        GroupsController.instance.remove(widget.groupId!);
      }
      if (!mounted) return;
      context.showSnack(
        _isGroup ? 'Group reported${_alsoAct ? ' and you left it' : ''}' : '${widget.name} reported${_alsoAct ? ' and blocked' : ''}',
      );
      context.pushReplacement(AppRoutes.myReports);
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _isGroup ? _groupOptions : _memberOptions;
    return FormPage(
      items: [
        Card(
          child: ListTile(
            leading: _isGroup
                ? GroupAvatar(name: widget.name, avatarUrl: widget.avatarUrl, size: 48)
                : DmAvatar(name: widget.name, avatarUrl: widget.avatarUrl, size: 48),
            title: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(widget.subtitle),
          ),
        ),
        const SectionHeader('Select reasons', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              FilterChip(
                avatar: Icon(o.$1, size: 18, color: _reasons.contains(o.$2) ? context.colors.onPrimary : null),
                label: Text(o.$2),
                showCheckmark: false,
                selected: _reasons.contains(o.$2),
                onSelected: (v) => setState(() => v ? _reasons.add(o.$2) : _reasons.remove(o.$2)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        AppTextField(label: 'Describe the issue', hint: 'What happened?', maxLines: 4, controller: _details),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_isGroup ? 'Leave this group' : 'Block ${widget.name}'),
          subtitle: Text(_isGroup ? 'Exit after reporting' : "Hide this member's messages in shared groups"),
          value: _alsoAct,
          onChanged: (v) => setState(() => _alsoAct = v),
        ),
        const SizedBox(height: 8),
        const InfoBanner(message: 'Reports are confidential. The moderation team reviews them within 48 hours.'),
      ],
      bottom: PrimaryButton(label: 'Submit Report', danger: true, loading: _sending, onPressed: _reasons.isEmpty || _sending ? null : _submit),
    );
  }
}
