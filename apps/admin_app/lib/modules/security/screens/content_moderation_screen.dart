import '../../../core/core.dart';

/// Content Control: each rule ON/OFF + blocked message log
/// (count, user, group, date/time, rule triggered, warning count).
class AdminContentModerationScreen extends StatefulWidget {
  const AdminContentModerationScreen({super.key});

  @override
  State<AdminContentModerationScreen> createState() => _AdminContentModerationScreenState();
}

class _AdminContentModerationScreenState extends State<AdminContentModerationScreen> {
  final Set<ContentRule> _enabled = {...ContentRule.values};

  @override
  Widget build(BuildContext context) {
    final log = MockData.blockedMessages;
    return AdminPage(
      title: 'Content Moderation',
      subtitle: 'Message processing: Language -> Abuse -> Number -> Spam -> Allowed / Blocked',
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => context.showSnack('Content policy saved'),
          child: const Text('Save policy'),
        ),
      ],
      children: [
        ResponsiveGrid(
          minItemWidth: 200,
          children: const [
            StatCard(icon: Icons.gpp_bad_outlined, label: 'Blocked today', value: '612'),
            StatCard(icon: Icons.pin_outlined, label: 'Number / words', value: '401'),
            StatCard(icon: Icons.do_not_disturb_on_outlined, label: 'Abuse', value: '118'),
            StatCard(icon: Icons.warning_amber_rounded, label: 'Users with 3+ warnings', value: '27'),
          ],
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Content Control (global)',
          child: Column(
            children: [
              for (final r in ContentRule.values)
                SwitchListTile(
                  secondary: Icon(r.icon),
                  title: Text(r.label),
                  subtitle: Text(r.description),
                  value: _enabled.contains(r),
                  onChanged: (v) => setState(() => v ? _enabled.add(r) : _enabled.remove(r)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const AdminFilterBar(
          hint: 'Search user or group',
          filters: ['All', 'Numbers', 'Number words', 'Abuse', 'Spam', 'Links', 'Contact'],
        ),
        AdminTable(
          total: 18420,
          columns: const ['Date / time', 'User', 'Group', 'Blocked content', 'Rule triggered', 'Warnings', 'Action'],
          rows: [
            for (final b in log)
              [
                Text(b.time),
                Text(b.user, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(b.group),
                SizedBox(width: 200, child: Text(b.text, overflow: TextOverflow.ellipsis)),
                StatusChip(b.rule.label, tone: Tone.danger, icon: b.rule.icon),
                StatusChip('${b.warnings} / 5', tone: b.warnings >= 3 ? Tone.danger : Tone.warning),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: context.showSnack,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'Warning sent', child: Text('Send warning')),
                    PopupMenuItem(value: 'User restricted in group', child: Text('Restrict in group')),
                    PopupMenuItem(value: 'User blocked', child: Text('Block user')),
                    PopupMenuItem(value: 'Group restricted', child: Text('Restrict group')),
                  ],
                ),
              ],
          ],
        ),
      ],
    );
  }
}
