import '../../../core/core.dart';

/// Forward chain management with internal IDs:
/// original_message_id, parent_message_id, forwarded_message_id, sender, group, time, status.
class AdminForwardChainScreen extends StatefulWidget {
  const AdminForwardChainScreen({super.key});

  @override
  State<AdminForwardChainScreen> createState() => _AdminForwardChainScreenState();
}

class _AdminForwardChainScreenState extends State<AdminForwardChainScreen> {
  String? _deleteFrom;

  List<ForwardNode> _flatten(ForwardNode n) => [n, for (final c in n.children) ..._flatten(c)];

  @override
  Widget build(BuildContext context) {
    const tree = MockData.forwardTree;
    final nodes = _flatten(tree);
    return AdminPage(
      title: 'Forwarding / Chain Management',
      subtitle: 'Track how public messages spread and apply chain deletion',
      children: [
        const AdminFilterBar(hint: 'Search message ID (MSG-...)', filters: ['All', 'Flagged', 'Active', 'Deleted']),
        ResponsiveGrid(
          minItemWidth: 200,
          children: [
            const StatCard(icon: Icons.account_tree_outlined, label: 'Original', value: 'MSG-1001'),
            StatCard(icon: Icons.shortcut, label: 'Forwarded copies', value: '${nodes.length - 1}'),
            StatCard(icon: Icons.groups_2_outlined, label: 'Users reached', value: '${tree.totalCopies}'),
            const StatCard(icon: Icons.flag_outlined, label: 'Reports on chain', value: '3'),
          ],
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Chain tree',
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: ChainTree(node: tree, showIds: true, deletedFrom: _deleteFrom),
        ),
        const SizedBox(height: 16),
        AdminTable(
          columns: const [
            'Message ID',
            'Original ID',
            'Parent ID',
            'Sender',
            'Group',
            'Recipients',
            'Time',
            'Status',
            '',
          ],
          rows: [
            for (final n in nodes)
              [
                Text(
                  n.messageId,
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700),
                ),
                const Text('MSG-1001', style: TextStyle(fontFamily: 'monospace')),
                Text(n.parentId ?? '-', style: const TextStyle(fontFamily: 'monospace')),
                Text(n.from),
                Text(n.to),
                Text('${n.recipients}'),
                Text(n.time),
                const StatusChip('ACTIVE', tone: Tone.success),
                TextButton(
                  onPressed: () => setState(() => _deleteFrom = n.messageId),
                  child: Text('Delete from here', style: TextStyle(color: context.palette.danger)),
                ),
              ],
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => context.showSnack('Further forwarding frozen for MSG-1001'),
              icon: const Icon(Icons.block),
              label: const Text('Stop forwarding'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: context.palette.danger),
              onPressed: () async {
                final ok = await context.confirm(
                  title: 'Delete ${_deleteFrom ?? 'MSG-1001'} and downstream copies?',
                  message:
                      'Status becomes DELETED_FOR_EVERYONE. Copies are marked deleted, the event is kept in audit logs.',
                  confirmLabel: 'Delete chain',
                  danger: true,
                );
                if (ok && context.mounted) setState(() => _deleteFrom ??= 'MSG-1001');
              },
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(_deleteFrom == null ? 'Delete entire chain' : 'Confirm delete from $_deleteFrom'),
            ),
          ],
        ),
      ],
    );
  }
}
