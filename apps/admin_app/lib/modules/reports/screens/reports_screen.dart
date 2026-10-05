import '../../../core/core.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _q = '';
  String _filter = 'pending';
  int _page = 1;
  int _reload = 0;

  static String _status(String s) => switch (s) {
    'open' => 'Pending',
    'reviewing' => 'Under review',
    _ => capitalize(s),
  };

  Map<String, Object?> get _query {
    final type = const {'message', 'user', 'group'}.contains(_filter) ? _filter : null;
    final status = type == null ? _filter : 'all';
    return {'q': _q, 'type': type, 'status': status, 'page': _page};
  }

  Future<void> _review(Map<String, dynamic> r) async {
    final note = TextEditingController(text: '${r['resolution'] ?? ''}');
    final target = r['target'] as Map<String, dynamic>;
    final msg = r['message'] as Map<String, dynamic>?;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${r['title']}'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoRow(label: 'Report', value: '${r['shortId']}  |  ${_status('${r['status']}')}'),
                InfoRow(label: 'Type', value: capitalize('${r['type']}')),
                InfoRow(label: 'Reported by', value: '${(r['reporter'] as Map)['name']}'),
                InfoRow(label: 'Against', value: '${target['name']}${target['internalId'] == null ? '' : ' (${target['internalId']})'}${target['warnings'] == null ? '' : '  |  ${target['warnings']} warnings'}'),
                if (r['group'] != null) InfoRow(label: 'Group', value: '${(r['group'] as Map)['name']}'),
                InfoRow(label: 'Reason', value: (r['reasons'] as List).join(', ')),
                if ((r['details'] as String?)?.isNotEmpty == true) InfoRow(label: 'Details', value: '${r['details']}'),
                if (msg != null) InfoRow(label: 'Message', value: msg['visibility'] == 'public' ? '${msg['text'] ?? '-'}' : 'Encrypted content'),
                InfoRow(label: 'Date', value: fmtDateTime(r['createdAt'])),
                if (r['alsoBlocked'] == true) const InfoRow(label: 'Reporter', value: 'Also blocked this user'),
                const SizedBox(height: 12),
                TextField(controller: note, maxLines: 3, decoration: const InputDecoration(hintText: 'Resolution note')),
              ],
            ),
          ),
        ),
        actions: [
          if (msg?['rootId'] != null)
            TextButton(onPressed: () => Navigator.pop(ctx, 'chain'), child: const Text('View chain')),
          if (target['kind'] == 'user' && target['id'] != null) TextButton(onPressed: () => Navigator.pop(ctx, 'user'), child: const Text('Open user')),
          if (target['kind'] == 'group' && target['id'] != null) TextButton(onPressed: () => Navigator.pop(ctx, 'group'), child: const Text('Open group')),
          if (r['status'] == 'open') TextButton(onPressed: () => Navigator.pop(ctx, 'review'), child: const Text('Mark under review')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'reject'), child: const Text('Reject')),
          if (target['kind'] == 'user') TextButton(onPressed: () => Navigator.pop(ctx, 'warn'), child: const Text('Warn user')),
          if (target['kind'] == 'user') TextButton(onPressed: () => Navigator.pop(ctx, 'block'), child: Text('Block user', style: TextStyle(color: context.palette.danger))),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 40)), onPressed: () => Navigator.pop(ctx, 'resolve'), child: const Text('Resolve')),
        ],
      ),
    );
    final text = note.text.trim();
    note.dispose();
    if (action == null || !mounted) return;
    if (action == 'chain') return context.go('${AdminRoutes.forwardChains}?id=${msg!['rootId']}');
    if (action == 'user') return context.push(AdminRoutes.userDetailsOf('${target['id']}')).then((_) {});
    if (action == 'group') return context.push(AdminRoutes.groupDetailsOf('${target['id']}')).then((_) {});
    final done = await runAction(
      context,
      () => AdminApi.post('/reports/${r['id']}', {'action': action, 'note': text}),
      success: const {'review': 'Marked under review', 'reject': 'Report rejected', 'warn': 'User warned, report resolved', 'block': 'User blocked, report resolved', 'resolve': 'Report resolved'}[action],
    );
    if (done != null) setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminAsync<Map<String, dynamic>>(
      reloadKey: '$_q|$_filter|$_page|$_reload',
      load: () => AdminApi.get('/reports', _query),
      builder: (context, d, _) {
        final s = d['stats'] as Map<String, dynamic>;
        final reports = (d['items'] as List).cast<Map<String, dynamic>>();
        return AdminPage(
          title: 'Reports',
          subtitle: 'Message, group and user reports from the community',
          onRefresh: () => setState(() => _reload++),
          children: [
            ResponsiveGrid(
              minItemWidth: 200,
              children: [
                StatCard(icon: Icons.inbox_outlined, label: 'Pending', value: fmtNum(s['open'])),
                StatCard(icon: Icons.visibility_outlined, label: 'Under review', value: fmtNum(s['reviewing'])),
                StatCard(icon: Icons.check_circle_outline, label: 'Resolved (30d)', value: fmtNum(s['resolved30'])),
                StatCard(icon: Icons.cancel_outlined, label: 'Rejected (30d)', value: fmtNum(s['rejected30'])),
              ],
            ),
            const SizedBox(height: 16),
            AdminFilterBar(
              hint: 'Search reports',
              filters: const {'Pending': 'pending', 'All': 'all', 'Message': 'message', 'Group': 'group', 'User': 'user', 'Resolved': 'resolved', 'Rejected': 'rejected'},
              selected: _filter,
              onSearch: (q) => setState(() {
                _q = q;
                _page = 1;
              }),
              onChanged: (f) => setState(() {
                _filter = f;
                _page = 1;
              }),
            ),
            AdminTable(
              total: (d['total'] as num).toInt(),
              page: _page,
              onPage: (p) => setState(() => _page = p),
              columns: const ['ID', 'Title', 'Type', 'Reported by', 'Against', 'Date', 'Status'],
              onRowTap: (i) => _review(reports[i]),
              emptyText: 'No reports',
              rows: [
                for (final r in reports)
                  [
                    Text('${r['shortId']}', style: const TextStyle(fontFamily: 'monospace')),
                    Text('${r['title']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(capitalize('${r['type']}')),
                    Text('${(r['reporter'] as Map)['name']}'),
                    Text('${(r['target'] as Map)['name']}'),
                    Text(fmtDate(r['createdAt'])),
                    StatusChip(_status('${r['status']}'), tone: r['status'] == 'open' ? Tone.warning : r['status'] == 'reviewing' ? Tone.info : null),
                  ],
              ],
            ),
          ],
        );
      },
    );
  }
}
