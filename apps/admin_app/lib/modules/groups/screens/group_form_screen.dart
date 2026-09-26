import '../../../core/core.dart';

/// Create / edit a group from the admin panel: details, location rules, message rules.
class AdminGroupFormScreen extends StatefulWidget {
  const AdminGroupFormScreen({super.key, this.groupId});

  final String? groupId;

  @override
  State<AdminGroupFormScreen> createState() => _AdminGroupFormScreenState();
}

class _AdminGroupFormScreenState extends State<AdminGroupFormScreen> {
  late final ChatGroup? _g = widget.groupId == null ? null : MockData.groupById(widget.groupId!);
  late LocationRequirement _location = _g?.location ?? LocationRequirement.off;
  late LocationVisibility _visibility = _g?.locationVisibility ?? LocationVisibility.adminOnly;
  late String _mode = _g?.messageMode ?? 'User can select';
  final Set<ContentRule> _rules = {...ContentRule.values};

  @override
  Widget build(BuildContext context) {
    final editing = _g != null;
    return AdminPage(
      title: editing ? 'Edit Group' : 'Create Group',
      subtitle: editing ? _g.name : 'Group creator can be any registered user',
      showBack: true,
      actions: [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () {
            context.showSnack(editing ? 'Group updated' : 'Group created - invite link generated');
            context.go(AdminRoutes.groups);
          },
          icon: const Icon(Icons.check),
          label: Text(editing ? 'Save' : 'Create'),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 380,
          children: [
            PanelCard(
              title: 'Basic details',
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppAvatar(initials: _g?.initials, icon: Icons.groups, size: 64),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                        onPressed: () {},
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Group photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Group name', initialValue: _g?.name),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Description', initialValue: _g?.description, maxLines: 3),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Creator (user ID)',
                    initialValue: editing ? MockData.users.first.internalId : null,
                    prefixIcon: Icons.badge_outlined,
                  ),
                ],
              ),
            ),
            PanelCard(
              title: 'Location rules',
              child: Column(
                children: [
                  RadioGroup<LocationRequirement>(
                    groupValue: _location,
                    onChanged: (v) => setState(() => _location = v!),
                    child: Column(
                      children: [
                        for (final l in LocationRequirement.values) RadioListTile(value: l, title: Text(l.label)),
                      ],
                    ),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Show member location', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  RadioGroup<LocationVisibility>(
                    groupValue: _visibility,
                    onChanged: (v) => setState(() => _visibility = v!),
                    child: const Column(
                      children: [
                        RadioListTile(value: LocationVisibility.adminOnly, title: Text('Admin')),
                        RadioListTile(value: LocationVisibility.groupMembers, title: Text('Admin + Group Members')),
                        RadioListTile(value: LocationVisibility.nobody, title: Text('Nobody')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            PanelCard(
              title: 'Message rules',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_person_outlined),
                    title: const Text('Message mode'),
                    subtitle: DropdownButton<String>(
                      isExpanded: true,
                      value: _mode,
                      underline: const SizedBox(),
                      items: const [
                        'Public',
                        'Private',
                        'User can select',
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _mode = v!),
                    ),
                  ),
                  const AppSwitchTile(icon: Icons.shortcut, title: 'Public message forwarding', value: true),
                  const AppSwitchTile(icon: Icons.delete_sweep_outlined, title: 'Chain deletion', value: true),
                  const AppSwitchTile(icon: Icons.file_download_off_outlined, title: 'Download disabled', value: true),
                  const AppSwitchTile(icon: Icons.screenshot_outlined, title: 'Screen protection', value: true),
                ],
              ),
            ),
            PanelCard(
              title: 'Content rules',
              child: Column(
                children: [
                  for (final r in ContentRule.values)
                    CheckboxListTile(
                      dense: true,
                      secondary: Icon(r.icon),
                      title: Text(r.label),
                      value: _rules.contains(r),
                      onChanged: (v) => setState(() => v! ? _rules.add(r) : _rules.remove(r)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
