import 'package:file_picker/file_picker.dart';

import '../../../core/core.dart';
import '../data/group_models.dart';
import '../data/group_repository.dart';
import '../state/group_draft.dart';
import '../state/groups_controller.dart';
import '../widgets/create_steps.dart';
import '../widgets/group_tile.dart';

/// Group settings for the creator / group admin.
/// With [groupId] == null it is step 3 of the create flow.
class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({super.key, this.groupId});

  final String? groupId;

  @override
  Widget build(BuildContext context) {
    final id = groupId;
    return LoginGate(
      title: 'Group Settings',
      child: id == null
          ? _SettingsForm(settings: GroupDraft.current.settings)
          : Scaffold(
              appBar: AppBar(title: const Text('Group Settings')),
              body: AsyncView<GroupDetail>(
                load: () => GroupRepository.detail(id),
                builder: (_, d, reload) => _SettingsForm(detail: d, settings: d.settings, reload: reload),
              ),
            ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({required this.settings, this.detail, this.reload});

  final GroupSettings settings;
  final GroupDetail? detail;
  final Future<void> Function()? reload;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late final GroupSettings _s = widget.settings;
  bool _saving = false;

  bool get _creating => widget.detail == null;
  bool get _canManage => _creating || widget.detail!.me.isAdmin;

  Widget _section(String title) => SectionHeader(title, padding: const EdgeInsets.fromLTRB(0, 24, 0, 8));

  String get _interval => _s.liveIntervalMin == 0 ? 'Manual' : '${_s.liveIntervalMin} min';

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      if (_creating) {
        final draft = GroupDraft.current;
        if (draft.photoBytes != null && draft.avatarUrl == null) {
          final media = await GroupRepository.upload(draft.photoBytes!, draft.photoName ?? 'group.jpg', secure: false);
          draft.avatarUrl = media.thumbUrl ?? media.url;
        }
        final created = await GroupRepository.create(
          name: draft.name,
          description: draft.description,
          category: draft.category,
          rules: draft.rules,
          avatarUrl: draft.avatarUrl,
          settings: _s,
          invite: {'expiry': '24h', 'maxJoins': 100, 'requireApproval': _s.approveNewMembers},
        );
        GroupDraft.reset();
        GroupsController.instance.scheduleReload();
        if (!mounted) return;
        context.go(AppRoutes.groupList);
        context.push(AppRoutes.inviteLinkOf(created.group.id, created: true));
      } else {
        await GroupRepository.updateSettings(widget.detail!.id, _s.toJson());
        GroupsController.instance.scheduleReload();
        if (!mounted) return;
        context.showSnack('Group settings saved');
        if (context.canPop()) context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editInfo() async {
    final d = widget.detail!;
    final changed = await showDialog<bool>(context: context, builder: (_) => _EditInfoDialog(detail: d));
    if (changed == true) {
      GroupsController.instance.scheduleReload();
      await widget.reload?.call();
    }
  }

  Future<void> _deleteGroup() async {
    final d = widget.detail!;
    final ok = await context.confirm(
      title: 'Delete group?',
      message: 'All messages and files of this group will be removed for every member.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok || !mounted) return;
    final done = await runAction(context, () => GroupRepository.deleteGroup(d.id), done: 'Group deleted');
    if (done && mounted) {
      GroupsController.instance.remove(d.id);
      context.go(AppRoutes.groupList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final form = FormPage(
      items: [
        if (_creating)
          const CreateSteps(current: 2)
        else ...[
          Card(
            child: ListTile(
              leading: GroupAvatar(name: d!.name, avatarUrl: d.summary.avatarUrl),
              title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${d.summary.memberCount} members  |  created by ${d.createdByName}'),
              trailing: d.me.canEditInfo ? IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit group info', onPressed: _editInfo) : null,
            ),
          ),
          if (!_canManage) ...[
            const SizedBox(height: 12),
            const InfoBanner(icon: Icons.lock_outline, message: 'Only group admins can change these settings.'),
          ],
        ],
        IgnorePointer(
          ignoring: !_canManage,
          child: Opacity(
            opacity: _canManage ? 1 : 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section('Location sharing'),
                OptionCard(
                  icon: Icons.location_off_outlined,
                  title: 'Disabled',
                  subtitle: 'No location is collected for this group',
                  selected: _s.locationRequirement == LocationRequirement.off,
                  onTap: () => setState(() => _s.locationRequirement = LocationRequirement.off),
                ),
                OptionCard(
                  icon: Icons.location_on_outlined,
                  title: 'Optional',
                  subtitle: 'Members may share location if they want',
                  selected: _s.locationRequirement == LocationRequirement.optional,
                  onTap: () => setState(() => _s.locationRequirement = LocationRequirement.optional),
                ),
                OptionCard(
                  icon: Icons.share_location,
                  title: 'Mandatory',
                  subtitle: 'Join completes only after location permission and sharing',
                  selected: _s.locationRequirement == LocationRequirement.mandatory,
                  onTap: () => setState(() => _s.locationRequirement = LocationRequirement.mandatory),
                ),
                if (_s.locationRequirement != LocationRequirement.off) ...[
                  const SizedBox(height: 8),
                  const Text('Location mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<LocationShareMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: LocationShareMode.join, label: Text('Join location')),
                      ButtonSegment(value: LocationShareMode.live, label: Text('Live location')),
                    ],
                    selected: {_s.shareMode},
                    onSelectionChanged: (v) => setState(() => _s.shareMode = v.first),
                  ),
                  if (_s.shareMode == LocationShareMode.live) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final i in const ['5 min', '10 min', '30 min', 'Manual'])
                          ChoiceChip(
                            label: Text(i == 'Manual' ? i : 'Every $i'),
                            selected: _interval == i,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _s.liveIntervalMin = i == 'Manual' ? 0 : int.parse(i.split(' ').first)),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Show member location to', style: TextStyle(fontWeight: FontWeight.w600)),
                  Card(
                    child: RadioGroup<LocationVisibility>(
                      groupValue: _s.locationVisibility,
                      onChanged: (v) => setState(() => _s.locationVisibility = v!),
                      child: const Column(
                        children: [
                          RadioListTile(value: LocationVisibility.adminOnly, title: Text('Admin only')),
                          RadioListTile(value: LocationVisibility.groupMembers, title: Text('Admin and group members')),
                          RadioListTile(value: LocationVisibility.nobody, title: Text('Nobody')),
                        ],
                      ),
                    ),
                  ),
                ],
                _section('Message permissions'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.send_outlined),
                        title: const Text('Who can send messages'),
                        trailing: DropdownButton<String>(
                          value: _s.whoCanSend == 'admins' ? 'Only admins' : 'All members',
                          underline: const SizedBox(),
                          items: const ['All members', 'Only admins'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _s.whoCanSend = v == 'Only admins' ? 'admins' : 'all'),
                        ),
                      ),
                      const Divider(indent: 56),
                      ListTile(
                        leading: const Icon(Icons.lock_person_outlined),
                        title: const Text('Message mode'),
                        trailing: DropdownButton<String>(
                          value: messageModeLabel(_s.messageMode),
                          underline: const SizedBox(),
                          items: const ['Public', 'Private', 'User can select'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _s.messageMode = messageModeValue(v!)),
                        ),
                      ),
                      const Divider(indent: 56),
                      SwitchListTile(
                        secondary: const Icon(Icons.edit_note),
                        title: const Text('Members can edit group info'),
                        value: _s.membersCanEditInfo,
                        onChanged: (v) => setState(() => _s.membersCanEditInfo = v),
                      ),
                      const Divider(indent: 56),
                      SwitchListTile(
                        secondary: const Icon(Icons.photo_library_outlined),
                        title: const Text('Members can send media'),
                        value: _s.membersCanSendMedia,
                        onChanged: (v) => setState(() => _s.membersCanSendMedia = v),
                      ),
                    ],
                  ),
                ),
                _section('Content rules for this group'),
                Card(
                  child: Column(
                    children: [
                      for (final r in ContentRule.values)
                        CheckboxListTile(
                          secondary: Icon(r.icon),
                          title: Text(r.label),
                          subtitle: Text(r.description),
                          value: _s.contentRules.contains(r),
                          onChanged: (v) => setState(() => v! ? _s.contentRules.add(r) : _s.contentRules.remove(r)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const InfoBanner(message: 'Rules turned on globally by the platform admin always apply, even if unchecked here.'),
                _section('Members'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.how_to_reg_outlined),
                        title: const Text('Approve new members'),
                        subtitle: const Text('Admin approval before join'),
                        value: _s.approveNewMembers,
                        onChanged: (v) => setState(() => _s.approveNewMembers = v),
                      ),
                      const Divider(indent: 56),
                      SwitchListTile(
                        secondary: const Icon(Icons.hourglass_top),
                        title: const Text('Restrict new members'),
                        subtitle: const Text('Read only for the first 24 hours'),
                        value: _s.restrictNewMembers,
                        onChanged: (v) => setState(() => _s.restrictNewMembers = v),
                      ),
                      const Divider(indent: 56),
                      SwitchListTile(
                        secondary: const Icon(Icons.person_search_outlined),
                        title: const Text('Members can search members'),
                        subtitle: const Text('Off: members cannot search the member list (admins still can)'),
                        value: _s.memberSearch,
                        onChanged: (v) => setState(() => _s.memberSearch = v),
                      ),
                      const Divider(indent: 56),
                      SwitchListTile(
                        secondary: const Icon(Icons.volume_off_outlined),
                        title: const Text('Mute group (admins only can post)'),
                        value: _s.muteGroup,
                        onChanged: (v) => setState(() => _s.muteGroup = v),
                      ),
                      const Divider(indent: 56),
                      SwitchListTile(
                        secondary: const Icon(Icons.workspace_premium_outlined),
                        title: const Text('Members without premium can use this group'),
                        subtitle: Text(
                          widget.detail == null
                              ? 'While the group is premium, every member can reply and open protected files'
                              : widget.detail!.premiumActive
                              ? 'Premium group (${widget.detail!.premiumSource == 'approved' ? 'approved by admin' : 'your premium'}): every member can reply and open protected files'
                              : 'Works when you have premium or the admin approves this group',
                        ),
                        value: _s.freeAccess,
                        onChanged: (v) => setState(() => _s.freeAccess = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_creating) ...[
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                AppTile(icon: Icons.group_outlined, title: 'Manage members', onTap: () => context.push(AppRoutes.groupMembersOf(d!.id))),
                const Divider(indent: 56),
                AppTile(icon: Icons.link, title: 'Invite links', onTap: () => context.push(AppRoutes.inviteLinkOf(d!.id))),
              ],
            ),
          ),
          _section('Security'),
          Card(
            child: Column(
              children: [
                AppTile(
                  icon: Icons.shield_outlined,
                  title: 'Group security settings',
                  subtitle: 'Forwarding, file security, screen protection, deletion',
                  onTap: () => context.push(AppRoutes.groupSecurityOf(d!.id)),
                ),
                if (d!.me.isOwner) ...[
                  const Divider(indent: 56),
                  AppTile(icon: Icons.delete_forever_outlined, title: 'Delete group', danger: true, onTap: _deleteGroup),
                ],
              ],
            ),
          ),
        ],
      ],
      bottom: _canManage
          ? PrimaryButton(label: _creating ? 'Create Group' : 'Save Settings', icon: Icons.check, loading: _saving, onPressed: _saving ? null : _submit)
          : null,
    );
    return _creating ? Scaffold(appBar: AppBar(title: const Text('Group Settings')), body: form) : form;
  }
}

class _EditInfoDialog extends StatefulWidget {
  const _EditInfoDialog({required this.detail});

  final GroupDetail detail;

  @override
  State<_EditInfoDialog> createState() => _EditInfoDialogState();
}

class _EditInfoDialogState extends State<_EditInfoDialog> {
  late final _name = TextEditingController(text: widget.detail.name);
  late final _description = TextEditingController(text: widget.detail.summary.description);
  late final _rules = TextEditingController(text: widget.detail.rules);
  late String _category = widget.detail.summary.category;
  String? _avatarUrl;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _rules.dispose();
    super.dispose();
  }

  Future<void> _photo() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;
    setState(() => _saving = true);
    try {
      final media = await GroupRepository.upload(await files.first.readAsBytes(), files.first.name, secure: false);
      setState(() => _avatarUrl = media.thumbUrl ?? media.url);
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await GroupRepository.updateInfo(widget.detail.id, {
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'category': _category,
        'rules': _rules.text.trim(),
        'avatarUrl': ?_avatarUrl,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit group info'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _saving ? null : _photo,
                child: GroupAvatar(name: widget.detail.name, avatarUrl: _avatarUrl ?? widget.detail.summary.avatarUrl, size: 80),
              ),
              TextButton(onPressed: _saving ? null : _photo, child: const Text('Change photo')),
              AppTextField(controller: _name, label: 'Group Name', maxLength: 50),
              const SizedBox(height: 8),
              AppTextField(controller: _description, label: 'Description', maxLines: 3, maxLength: 300),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: const ['Business', 'Team / Office', 'Training', 'Community', 'Family', 'Other'].contains(_category) ? _category : 'Other',
                decoration: const InputDecoration(labelText: 'Category'),
                items: const ['Business', 'Team / Office', 'Training', 'Community', 'Family', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 8),
              AppTextField(controller: _rules, label: 'Group rules', maxLines: 3, maxLength: 500),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
