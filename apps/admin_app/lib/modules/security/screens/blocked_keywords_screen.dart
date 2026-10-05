import '../../../core/core.dart';

/// Admin "Blocked Keywords": any word, sentence or link the admin adds cannot be sent in
/// 1-to-1 chats or groups. The app disables Send while typing; the server refuses it too.
class AdminBlockedKeywordsScreen extends StatefulWidget {
  const AdminBlockedKeywordsScreen({super.key});

  @override
  State<AdminBlockedKeywordsScreen> createState() => _AdminBlockedKeywordsScreenState();
}

class _AdminBlockedKeywordsScreenState extends State<AdminBlockedKeywordsScreen> {
  final _input = TextEditingController();
  final _test = TextEditingController();
  String _scope = 'all';
  bool _partial = false;
  bool _adding = false;
  String _q = '';
  String _type = 'all';
  int _page = 1;
  int _reload = 0;
  Map<String, dynamic>? _testResult;

  static const _scopeLabels = {'all': '1-to-1 + groups', 'direct': '1-to-1 only', 'groups': 'Groups only'};
  static const _typeIcons = {'word': Icons.text_fields, 'sentence': Icons.short_text, 'link': Icons.link};

  @override
  void dispose() {
    _input.dispose();
    _test.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _reload++);

  Future<void> _add() async {
    final texts = _input.text.split('\n').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    if (texts.isEmpty) return context.showSnack('Type a word, sentence or link');
    setState(() => _adding = true);
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/blocked-terms', {'texts': texts, 'partial': _partial, 'scope': _scope}));
    if (!mounted) return;
    setState(() => _adding = false);
    if (r == null) return;
    final added = (r['added'] as List).length;
    final skipped = (r['skipped'] as List).length;
    context.showSnack('$added added${skipped > 0 ? ', $skipped already in the list' : ''}. Users cannot send them now.');
    _input.clear();
    _refresh();
  }

  Future<void> _runTest() async {
    if (_test.text.trim().isEmpty) return;
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/blocked-terms/test', {'text': _test.text}));
    if (r != null && mounted) setState(() => _testResult = r);
  }

  Future<void> _patch(Map<String, dynamic> t, Map<String, Object?> body, String done) async {
    final r = await runAction(context, () => AdminApi.patch('/blocked-terms/${t['id']}', body), success: done);
    if (r != null) _refresh();
  }

  Future<void> _delete(Map<String, dynamic> t) async {
    if (!await context.confirm(title: 'Remove "${t['text']}"?', message: 'Users can send it again.', confirmLabel: 'Remove', danger: true)) return;
    if (!mounted) return;
    final r = await runAction(context, () => AdminApi.delete('/blocked-terms/${t['id']}'), success: '"${t['text']}" removed');
    if (r != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Blocked Keywords',
      subtitle: 'Words, sentences and links users cannot send in 1-to-1 chats or groups',
      onRefresh: _refresh,
      children: [
        PanelCard(
          title: 'Add keywords',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _input,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'One per line, for example:\nfree recharge\ncall me on whatsapp\nbit.ly',
                  helperText: 'A single word, a full sentence or a link / website. Upper or lower case does not matter.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Block in', style: TextStyle(fontWeight: FontWeight.w600)),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [for (final e in _scopeLabels.entries) ButtonSegment(value: e.key, label: Text(e.value))],
                    selected: {_scope},
                    onSelectionChanged: (s) => setState(() => _scope = s.first),
                  ),
                  FilterChip(
                    label: const Text('Also inside longer words'),
                    tooltip: 'On: "test" also blocks "testing". Off: only the whole word.',
                    selected: _partial,
                    onSelected: (v) => setState(() => _partial = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: _adding ? null : _add,
                  icon: _adding ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.block),
                  label: const Text('Block'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminAsync<Map<String, dynamic>>(
          reloadKey: '$_q|$_type|$_page|$_reload',
          load: () => AdminApi.get('/blocked-terms', {'q': _q, 'type': _type, 'page': _page}),
          builder: (context, d, _) {
            final s = d['stats'] as Map<String, dynamic>;
            final items = (d['items'] as List).cast<Map<String, dynamic>>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResponsiveGrid(
                  minItemWidth: 180,
                  children: [
                    StatCard(icon: Icons.block, label: 'Active keywords', value: fmtNum(s['active'])),
                    StatCard(icon: Icons.text_fields, label: 'Words', value: fmtNum(s['words'])),
                    StatCard(icon: Icons.short_text, label: 'Sentences', value: fmtNum(s['sentences'])),
                    StatCard(icon: Icons.link, label: 'Links', value: fmtNum(s['links'])),
                    StatCard(icon: Icons.gpp_bad_outlined, label: 'Messages stopped', value: fmtNum(s['blockedMessages'])),
                  ],
                ),
                const SizedBox(height: 16),
                AdminFilterBar(
                  hint: 'Search keywords',
                  filters: const {'All': 'all', 'Words': 'word', 'Sentences': 'sentence', 'Links': 'link', 'Turned off': 'inactive'},
                  selected: _type,
                  onSearch: (q) => setState(() {
                    _q = q;
                    _page = 1;
                  }),
                  onChanged: (t) => setState(() {
                    _type = t;
                    _page = 1;
                  }),
                ),
                AdminTable(
                  total: (d['total'] as num).toInt(),
                  page: _page,
                  limit: (d['limit'] as num?)?.toInt() ?? 50,
                  onPage: (p) => setState(() => _page = p),
                  columns: const ['Keyword', 'Type', 'Blocks in', 'Match', 'Stopped', 'Last stopped', 'Added by', 'On', ''],
                  emptyText: 'No blocked keywords yet. Add some above.',
                  rows: [
                    for (final t in items)
                      [
                        SizedBox(width: 260, child: Text('${t['text']}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                        StatusChip(capitalize('${t['type']}'), tone: Tone.neutral, icon: _typeIcons[t['type']]),
                        PopupMenuButton<String>(
                          tooltip: 'Change',
                          initialValue: '${t['scope']}',
                          onSelected: (v) => _patch(t, {'scope': v}, 'Now blocked in ${_scopeLabels[v]!.toLowerCase()}'),
                          itemBuilder: (_) => [for (final e in _scopeLabels.entries) PopupMenuItem(value: e.key, child: Text(e.value))],
                          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(_scopeLabels['${t['scope']}'] ?? '${t['scope']}'), const Icon(Icons.arrow_drop_down)]),
                        ),
                        t['type'] == 'link'
                            ? const Text('Link anywhere')
                            : InkWell(
                                onTap: () => _patch(t, {'partial': t['partial'] != true}, t['partial'] == true ? 'Whole word only' : 'Also inside longer words'),
                                child: Text(t['partial'] == true ? 'Inside words too' : 'Whole word', style: TextStyle(color: context.colors.primary)),
                              ),
                        Text(fmtNum(t['hits'])),
                        Text(t['lastHitAt'] == null ? '-' : fmtAgo(t['lastHitAt'])),
                        Text('${t['createdBy'] ?? '-'}'),
                        Switch(value: t['active'] == true, onChanged: (v) => _patch(t, {'active': v}, v ? '"${t['text']}" blocked again' : '"${t['text']}" turned off')),
                        IconButton(tooltip: 'Remove', icon: Icon(Icons.delete_outline, color: context.palette.danger), onPressed: () => _delete(t)),
                      ],
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Test a message',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: _test, onSubmitted: (_) => _runTest(), decoration: const InputDecoration(hintText: 'Type a message to check'))),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: _runTest, child: const Text('Test')),
                ],
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                InfoBanner(
                  icon: _testResult!['allowed'] == true ? Icons.check_circle_outline : Icons.block,
                  tone: _testResult!['allowed'] == true ? Tone.success : Tone.danger,
                  title: _testResult!['allowed'] == true ? 'Can be sent' : 'Can not send',
                  message: _testResult!['allowed'] == true
                      ? 'No blocked keyword found.'
                      : [
                          if (_testResult!['direct'] != null) '1-to-1: blocked by "${_testResult!['direct']}"',
                          if (_testResult!['groups'] != null) 'Groups: blocked by "${_testResult!['groups']}"',
                          if (_testResult!['direct'] == null) '1-to-1: allowed',
                          if (_testResult!['groups'] == null) 'Groups: allowed',
                        ].join('\n'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
