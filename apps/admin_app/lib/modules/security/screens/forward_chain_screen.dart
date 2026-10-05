import '../../../core/core.dart';

ForwardNode _node(Map<String, dynamic> n) => ForwardNode(
  messageId: '${n['messageId']}',
  parentId: n['parentId'] as String?,
  from: '${n['from']}',
  to: '${n['to']}',
  time: fmtDateTime(n['time']),
  recipients: (n['recipients'] as num?)?.toInt() ?? 0,
  deleted: n['deleted'] == true,
  children: [for (final c in (n['children'] as List? ?? const [])) _node(c as Map<String, dynamic>)],
);

/// Forward chain management with internal IDs:
/// original_message_id, parent_message_id, forwarded_message_id, sender, group, time, status.
class AdminForwardChainScreen extends StatefulWidget {
  const AdminForwardChainScreen({super.key});

  @override
  State<AdminForwardChainScreen> createState() => _AdminForwardChainScreenState();
}

class _AdminForwardChainScreenState extends State<AdminForwardChainScreen> {
  String _q = '';
  String _filter = 'all';
  int _page = 1;
  int _reload = 0;
  String? _selected;
  String? _deleteFrom;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected ??= GoRouterState.of(context).uri.queryParameters['id'];
  }

  void _refresh() => setState(() => _reload++);

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_filter|$_page|$_reload',
      load: () => AdminApi.get('/forward-chains', {'q': _q, 'filter': _filter, 'page': _page}),
      builder: (context, d, _) {
        final chains = (d['items'] as List).cast<Map<String, dynamic>>();
        _selected ??= chains.isEmpty ? null : '${chains.first['id']}';
        return AdminPage(
          title: 'Forwarding / Chain Management',
          subtitle: 'Track how public messages spread and apply chain deletion',
          onRefresh: _refresh,
          children: [
            AdminFilterBar(
              hint: 'Search message ID (MSG-...) or public text',
              filters: const {'All': 'all', 'Reported': 'flagged', 'Active': 'active', 'Stopped': 'frozen', 'Deleted': 'deleted'},
              selected: _filter,
              onSearch: (q) => setState(() {
                _q = q;
                _page = 1;
                _selected = null;
              }),
              onChanged: (f) => setState(() {
                _filter = f;
                _page = 1;
                _selected = null;
              }),
            ),
            AdminTable(
              total: (d['total'] as num).toInt(),
              page: _page,
              onPage: (p) => setState(() => _page = p),
              columns: const ['Original ID', 'Sender', 'Group', 'Message', 'Copies', 'Reports', 'Status', 'Time'],
              onRowTap: (i) => setState(() {
                _selected = '${chains[i]['id']}';
                _deleteFrom = null;
              }),
              emptyText: 'No forwarded messages yet',
              rows: [
                for (final c in chains)
                  [
                    Text('${c['shortId']}', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: c['id'] == _selected ? context.colors.primary : null)),
                    Text('${c['sender']}'),
                    Text('${c['group']}'),
                    SizedBox(width: 200, child: Text('${c['preview']}', overflow: TextOverflow.ellipsis)),
                    Text(fmtNum(c['copies'])),
                    Text(fmtNum(c['reports'])),
                    StatusChip(c['status'] != 'active' ? 'Deleted' : c['frozen'] == true ? 'Stopped' : 'Active', tone: c['status'] != 'active' ? Tone.danger : c['frozen'] == true ? Tone.warning : Tone.success),
                    Text(fmtDateTime(c['at'])),
                  ],
              ],
            ),
            if (_selected != null) ...[
              const SizedBox(height: 16),
              _ChainDetail(
                key: ValueKey('$_selected|$_reload'),
                messageId: _selected!,
                deleteFrom: _deleteFrom,
                onDeleteFrom: (id) => setState(() => _deleteFrom = id),
                onChanged: () => setState(() {
                  _deleteFrom = null;
                  _reload++;
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ChainDetail extends StatelessWidget {
  const _ChainDetail({super.key, required this.messageId, required this.deleteFrom, required this.onDeleteFrom, required this.onChanged});

  final String messageId;
  final String? deleteFrom;
  final ValueChanged<String?> onDeleteFrom;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      load: () => AdminApi.get('/forward-chains/$messageId'),
      builder: (context, c, _) {
        final totals = c['totals'] as Map<String, dynamic>;
        final nodes = (c['nodes'] as List).cast<Map<String, dynamic>>();
        final tree = _node(c['tree'] as Map<String, dynamic>);
        final from = deleteFrom == null ? null : nodes.firstWhere((n) => n['messageId'] == deleteFrom, orElse: () => nodes.first);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              minItemWidth: 200,
              children: [
                StatCard(icon: Icons.account_tree_outlined, label: 'Original', value: '${c['shortRootId']}'),
                StatCard(icon: Icons.shortcut, label: 'Forwarded copies', value: fmtNum(totals['forwards'])),
                StatCard(icon: Icons.groups_2_outlined, label: 'Users reached', value: fmtNum(totals['usersReached'])),
                StatCard(icon: Icons.flag_outlined, label: 'Reports on chain', value: fmtNum(c['reports'])),
              ],
            ),
            const SizedBox(height: 16),
            PanelCard(
              title: 'Chain tree  -  "${c['preview']}"',
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: ChainTree(node: tree, showIds: true, deletedFrom: from == null ? null : '${from['shortId']}'),
            ),
            const SizedBox(height: 16),
            AdminTable(
              columns: const ['Message ID', 'Original ID', 'Parent ID', 'Sender', 'Group', 'Recipients', 'Time', 'Status', ''],
              rows: [
                for (final n in nodes)
                  [
                    Text('${n['shortId']}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                    Text('${c['shortRootId']}', style: const TextStyle(fontFamily: 'monospace')),
                    Text(n['parentId'] == null ? '-' : 'MSG-${'${n['parentId']}'.substring('${n['parentId']}'.length - 6).toUpperCase()}', style: const TextStyle(fontFamily: 'monospace')),
                    Text('${n['from']}'),
                    Text('${n['to']}'),
                    Text(fmtNum(n['recipients'])),
                    Text(fmtDateTime(n['at'])),
                    StatusChip('${n['status']}', tone: n['status'] == 'ACTIVE' ? Tone.success : Tone.danger),
                    n['status'] == 'ACTIVE'
                        ? TextButton(onPressed: () => onDeleteFrom('${n['messageId']}'), child: Text('Delete from here', style: TextStyle(color: context.palette.danger)))
                        : const Text('-'),
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
                  onPressed: () async {
                    final frozen = c['frozen'] == true;
                    final r = await runAction(
                      context,
                      () => AdminApi.post('/forward-chains/$messageId/freeze', {'frozen': !frozen}),
                      success: frozen ? 'Forwarding allowed again for ${c['shortRootId']}' : 'Further forwarding stopped for ${c['shortRootId']}',
                    );
                    if (r != null) onChanged();
                  },
                  icon: Icon(c['frozen'] == true ? Icons.play_arrow_outlined : Icons.block),
                  label: Text(c['frozen'] == true ? 'Allow forwarding' : 'Stop forwarding'),
                ),
                if (deleteFrom != null) TextButton(onPressed: () => onDeleteFrom(null), child: const Text('Cancel selection')),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: context.palette.danger),
                  onPressed: () async {
                    final target = deleteFrom ?? '${c['rootId']}';
                    final label = from == null ? '${c['shortRootId']}' : '${from['shortId']}';
                    final ok = await context.confirm(
                      title: 'Delete $label and downstream copies?',
                      message: 'Status becomes DELETED_FOR_EVERYONE. Copies are removed for every member, the event is kept in audit logs.',
                      confirmLabel: 'Delete chain',
                      danger: true,
                    );
                    if (!ok || !context.mounted) return;
                    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/forward-chains/$target/delete'));
                    if (r == null || !context.mounted) return;
                    context.showSnack('${r['deleted']} copies deleted in ${r['groups']} groups');
                    onChanged();
                  },
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(from == null ? 'Delete entire chain' : 'Confirm delete from ${from['shortId']}'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
