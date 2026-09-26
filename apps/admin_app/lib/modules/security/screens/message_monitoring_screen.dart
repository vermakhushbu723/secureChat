import '../../../core/core.dart';

class AdminMessageMonitoringScreen extends StatelessWidget {
  const AdminMessageMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = MockData.messages.where((m) => !m.isDeleted).toList();
    return AdminPage(
      title: 'Message Monitoring',
      subtitle: 'Metadata of messages. Private content stays encrypted.',
      children: [
        ResponsiveGrid(
          minItemWidth: 200,
          children: const [
            StatCard(icon: Icons.forum_outlined, label: 'Messages (24h)', value: '284K'),
            StatCard(icon: Icons.lock_outline, label: 'Private share', value: '41%'),
            StatCard(icon: Icons.shortcut, label: 'Forwards (24h)', value: '18.2K'),
            StatCard(icon: Icons.gpp_maybe_outlined, label: 'Auto-blocked', value: '612'),
          ],
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          icon: Icons.privacy_tip_outlined,
          message:
              'Only public messages and flagged content are visible to moderators. Every view is recorded in the audit log.',
        ),
        const SizedBox(height: 16),
        const AdminFilterBar(
          hint: 'Search by user, group or keyword',
          filters: ['All', 'Flagged', 'Forwarded', 'Files', 'Private'],
        ),
        AdminTable(
          columns: const ['Time', 'Sender', 'Group', 'Type', 'Visibility', 'Content', 'Flags', ''],
          rows: [
            for (final m in messages)
              [
                Text(m.time),
                Text(m.senderName),
                const Text('Lucknow Business Community'),
                Icon(iconForMessageType(m.type), size: 20),
                StatusChip(m.visibility.label, tone: Tone.dark),
                SizedBox(
                  width: 220,
                  child: Text(
                    m.isProtected ? 'Encrypted content' : m.text,
                    overflow: TextOverflow.ellipsis,
                    style: m.isProtected ? const TextStyle(fontStyle: FontStyle.italic) : null,
                  ),
                ),
                m.isForwarded ? const StatusChip('Forwarded', tone: Tone.warning) : const Text('-'),
                IconButton(
                  tooltip: 'View chain',
                  icon: const Icon(Icons.account_tree_outlined),
                  onPressed: () => context.go(AdminRoutes.forwardChains),
                ),
              ],
          ],
        ),
      ],
    );
  }
}
