import '../../../core/core.dart';

class AdminAbuseFilterScreen extends StatefulWidget {
  const AdminAbuseFilterScreen({super.key});

  @override
  State<AdminAbuseFilterScreen> createState() => _AdminAbuseFilterScreenState();
}

class _AdminAbuseFilterScreenState extends State<AdminAbuseFilterScreen> {
  Map<String, dynamic>? _cs;
  String? _error;
  bool _dirty = false;
  final _controller = TextEditingController();
  final _test = TextEditingController();
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _test.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cs = await AdminApi.get<Map<String, dynamic>>('/settings/content');
      if (mounted) {
        setState(() {
          _cs = cs;
          _error = null;
          _dirty = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  List<String> get _words => [for (final w in (_cs!['abuseWords'] as List)) '$w'];

  void _set(String key, Object value) => setState(() {
    _cs = {..._cs!, key: value};
    _dirty = true;
  });

  void _add() {
    final words = _controller.text.split(',').map((w) => w.trim().toUpperCase()).where((w) => w.isNotEmpty);
    if (words.isEmpty) return;
    _set('abuseWords', {..._words, ...words}.toList());
    _controller.clear();
  }

  Future<void> _save() async {
    final c = _cs!;
    final r = await runAction(
      context,
      () => AdminApi.put('/settings/content', {
        for (final k in const ['abuseEnabled', 'abuseWords', 'hinglish', 'misspellings', 'sensitivity', 'maxWarnings', 'muteAfter', 'suspendAfter']) k: c[k],
      }),
      success: 'Filter saved',
    );
    if (r != null) setState(() => _dirty = false);
  }

  Future<void> _runTest() async {
    if (_test.text.trim().isEmpty) return;
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/content/test', {'text': _test.text, 'rules': ['abuse']}));
    if (r != null && mounted) setState(() => _result = r);
  }

  Widget _count(String title, String key, List<int> options, String Function(int) label, IconData icon) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: DropdownButton<int>(
      value: options.contains((_cs![key] as num).toInt()) ? (_cs![key] as num).toInt() : options.first,
      underline: const SizedBox(),
      items: [for (final o in options) DropdownMenuItem(value: o, child: Text(label(o)))],
      onChanged: (v) => _set(key, v!),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_error != null) return ErrorPanel(message: _error!, onRetry: _load);
    if (_cs == null) return const Center(child: CircularProgressIndicator());
    const levels = ['Low', 'Medium', 'High'];
    final sensitivity = ((_cs!['sensitivity'] as num?) ?? 2).toDouble();
    final words = _words;
    return AdminPage(
      title: 'Abuse / Profanity Filter',
      subtitle: 'Block abusive, hateful and spam words (applies in every group)',
      onRefresh: _load,
      actions: [FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _dirty ? _save : null, child: const Text('Save changes'))],
      children: [
        PanelCard(
          title: 'Settings',
          child: Column(
            children: [
              SettingSwitch(icon: Icons.do_not_disturb_on_outlined, title: 'Enable profanity filter', value: _cs!['abuseEnabled'] != false, onChanged: (v) => _set('abuseEnabled', v)),
              SettingSwitch(icon: Icons.translate, title: 'Hindi / Hinglish word list', value: _cs!['hinglish'] == true, onChanged: (v) => _set('hinglish', v)),
              SettingSwitch(
                icon: Icons.auto_fix_high,
                title: 'Detect misspellings and symbols',
                subtitle: 'e.g. b@dw0rd',
                value: _cs!['misspellings'] == true,
                onChanged: (v) => _set('misspellings', v),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.tune),
                    const SizedBox(width: 32),
                    const Expanded(child: Text('Sensitivity (High also catches blocked words inside longer words)')),
                    Text(levels[sensitivity.round().clamp(1, 3) - 1], style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Slider(value: sensitivity.clamp(1, 3), min: 1, max: 3, divisions: 2, onChanged: (v) => _set('sensitivity', v.round())),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Blocked words (${words.length})',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _add(),
                      decoration: const InputDecoration(hintText: 'Add word or phrase (comma separated, word* = starts with)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(color: Colors.white, icon: const Icon(Icons.add), onPressed: _add),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final w in words) InputChip(label: Text(w), onDeleted: () => _set('abuseWords', words.where((x) => x != w).toList()))],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Penalties (automatic)',
          child: Column(
            children: [
              const ListTile(leading: Icon(Icons.looks_one_outlined), title: Text('Every blocked message'), trailing: Text('Warning')),
              _count('Blocked messages in 24 hours before a 24 hour mute', 'muteAfter', const [2, 3, 5, 10, 0], (v) => v == 0 ? 'Off' : '$v', Icons.looks_two_outlined),
              _count('Blocked messages in 7 days before a 7 day suspension', 'suspendAfter', const [3, 5, 10, 20, 0], (v) => v == 0 ? 'Off' : '$v', Icons.looks_3_outlined),
              _count('Warning limit shown to users', 'maxWarnings', const [3, 5, 10], (v) => '$v', Icons.warning_amber_rounded),
            ],
          ),
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
                  Expanded(child: TextField(controller: _test, onSubmitted: (_) => _runTest(), decoration: const InputDecoration(hintText: 'Type a sample message'))),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: _runTest, child: const Text('Test')),
                ],
              ),
              if (_result != null) ...[
                const SizedBox(height: 12),
                InfoBanner(
                  icon: _result!['allowed'] == true ? Icons.check_circle_outline : Icons.gpp_bad_outlined,
                  tone: _result!['allowed'] == true ? Tone.success : Tone.danger,
                  title: _result!['allowed'] == true ? 'ALLOWED' : 'BLOCKED',
                  message: _result!['allowed'] == true ? 'No abusive word found (saved settings).' : 'Abuse filter would block this message.',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
