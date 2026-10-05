import 'dart:async';

import '../../../core/core.dart';

/// Numeric content detection engine: digits, number words, mixed formats
/// and a normalization layer (T H R E E -> THREE, ONE1 -> ONE).
class AdminNumberFilterScreen extends StatefulWidget {
  const AdminNumberFilterScreen({super.key});

  @override
  State<AdminNumberFilterScreen> createState() => _AdminNumberFilterScreenState();
}

class _AdminNumberFilterScreenState extends State<AdminNumberFilterScreen> {
  Map<String, dynamic>? _cs;
  String? _error;
  bool _dirty = false;
  final _test = TextEditingController(text: 'call me on NINE8 seven T H R E E');
  Map<String, dynamic>? _result;
  Timer? _debounce;

  static const _numeric = ['1', '12', '123', '12345', '999', '1000', '9876543210'];
  static const _wordList = ['ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE', 'TEN', 'HUNDRED', 'THOUSAND', 'LAKH', 'CRORE'];
  static const _hindi = ['EK', 'TEEN', 'CHAAR', 'PAANCH', 'CHHE', 'SAAT', 'AATH', 'NAU', 'DAS', 'SAU', 'HAZAAR'];
  static const _mixed = ['ONE1', 'TWO2', 'THREE3', 'NINETY9', '99 NINETY NINE', 'T H R E E', 'O N E'];

  bool get _digits => (_cs?['globalRules'] as List? ?? const []).contains('numbers');
  bool get _words => (_cs?['globalRules'] as List? ?? const []).contains('numberWords');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _test.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cs = await AdminApi.get<Map<String, dynamic>>('/settings/content');
      if (!mounted) return;
      setState(() {
        _cs = cs;
        _error = null;
        _dirty = false;
      });
      _runTest();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _toggleRule(String rule, bool on) => setState(() {
    final rules = {for (final r in (_cs!['globalRules'] as List)) '$r'};
    on ? rules.add(rule) : rules.remove(rule);
    _cs = {..._cs!, 'globalRules': rules.toList()};
    _dirty = true;
  });

  void _set(String key, Object value) => setState(() {
    _cs = {..._cs!, key: value};
    _dirty = true;
  });

  void _runTest() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final rules = [if (_digits) 'numbers', if (_words) 'numberWords'];
      if (rules.isEmpty) {
        if (mounted) setState(() => _result = {'allowed': true, 'rule': null, 'tokens': const []});
        return;
      }
      try {
        final r = await AdminApi.post<Map<String, dynamic>>('/content/test', {'text': _test.text, 'rules': rules});
        if (mounted) setState(() => _result = r);
      } catch (_) {}
    });
  }

  Future<void> _save() async {
    final r = await runAction(
      context,
      () => AdminApi.put('/settings/content', {'globalRules': _cs!['globalRules'], 'hindiNumbers': _cs!['hindiNumbers'], 'normalization': _cs!['normalization']}),
      success: 'Number filter saved',
    );
    if (r != null) {
      setState(() => _dirty = false);
      _runTest();
    }
  }

  Widget _chips(List<String> items) => Wrap(spacing: 6, runSpacing: 6, children: [for (final i in items) Chip(label: Text(i, style: const TextStyle(fontFamily: 'monospace')))]);

  @override
  Widget build(BuildContext context) {
    if (_error != null) return ErrorPanel(message: _error!, onRetry: _load);
    if (_cs == null) return const Center(child: CircularProgressIndicator());
    final r = _result;
    return AdminPage(
      title: 'Number Filter',
      subtitle: 'Blocks phone numbers and any numeric content, in every format (global rule for all groups)',
      onRefresh: _load,
      actions: [FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: _dirty ? _save : null, child: const Text('Save'))],
      children: [
        _PhoneProtectionPanel(
          restrictAfter: (_cs!['phoneRestrictAfter'] as num?)?.toInt() ?? 3,
          onRestrictAfter: (v) async {
            final r = await runAction(context, () => AdminApi.put('/settings/content', {'phoneRestrictAfter': v}), success: v == 0 ? 'Automatic restriction off' : 'Read only after $v attempts');
            if (r != null) await _load();
          },
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Rules',
          child: Column(
            children: [
              SettingSwitch(icon: Icons.pin_outlined, title: 'Number Blocking', subtitle: 'Any digit 0-9', value: _digits, onChanged: (v) {
                _toggleRule('numbers', v);
                _runTest();
              }),
              SettingSwitch(icon: Icons.text_fields, title: 'Number Words Blocking', subtitle: 'Includes mixed and spaced formats', value: _words, onChanged: (v) {
                _toggleRule('numberWords', v);
                _runTest();
              }),
              SettingSwitch(icon: Icons.translate, title: 'Hindi number words (ek, teen, paanch...)', value: _cs!['hindiNumbers'] == true, onChanged: (v) => _set('hindiNumbers', v)),
              SettingSwitch(
                icon: Icons.auto_fix_high,
                title: 'Normalization layer',
                subtitle: 'Remove spaces / symbols, join single letters',
                value: _cs!['normalization'] != false,
                onChanged: (v) => _set('normalization', v),
              ),
            ],
          ),
        ),
        if (!_digits && !_words) ...[
          const SizedBox(height: 12),
          const InfoBanner(icon: Icons.info_outline, message: 'Number rules are off globally. Groups can still turn them on in their own content rules.'),
        ],
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 300,
          children: [
            PanelCard(title: 'Numeric', padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: _chips(_numeric)),
            PanelCard(title: 'Number words', padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: _chips(_wordList)),
            PanelCard(title: 'Hindi number words', padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: _chips(_hindi)),
            PanelCard(title: 'Mixed formats', padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: _chips(_mixed)),
          ],
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Test the engine (live server rules${_dirty ? ' - save to test unsaved changes' : ''})',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _test, onChanged: (_) => _runTest(), decoration: const InputDecoration(hintText: 'Type a sample message')),
              const SizedBox(height: 12),
              if (r != null) ...[
                Text(
                  'Normalized tokens: ${(r['tokens'] as List).join('  ')}',
                  style: TextStyle(color: context.palette.textSecondary, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
                InfoBanner(
                  icon: r['allowed'] == true ? Icons.check_circle_outline : Icons.gpp_bad_outlined,
                  tone: r['allowed'] == true ? Tone.success : Tone.danger,
                  title: r['allowed'] == true ? 'ALLOWED' : 'BLOCKED',
                  message: r['allowed'] == true ? 'No numeric content detected.' : 'Rule triggered: ${ruleLabels[r['rule']] ?? r['rule']}',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Mobile number protection: always on for every user in 1-to-1 chats and groups.
class _PhoneProtectionPanel extends StatefulWidget {
  const _PhoneProtectionPanel({required this.restrictAfter, required this.onRestrictAfter});

  final int restrictAfter;
  final ValueChanged<int> onRestrictAfter;

  @override
  State<_PhoneProtectionPanel> createState() => _PhoneProtectionPanelState();
}

class _PhoneProtectionPanelState extends State<_PhoneProtectionPanel> {
  final _text = TextEditingController(text: 'my number is 98 765 43210');
  Map<String, dynamic>? _r;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final r = await runAction<Map<String, dynamic>>(context, () => AdminApi.post('/phone/test', {'text': _text.text}));
    if (r != null && mounted) setState(() => _r = r);
  }

  static String _action(String a) => switch (a) {
    'block_log' => 'BLOCKED + admin log',
    'block' => 'BLOCKED',
    'mask' => 'SENT WITH NUMBERS HIDDEN (****)',
    _ => 'ALLOWED',
  };

  @override
  Widget build(BuildContext context) {
    final r = _r;
    final blocked = r != null && (r['action'] == 'block' || r['action'] == 'block_log');
    return PanelCard(
      title: 'Mobile number protection (always on for everyone)',
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InfoBanner(
            icon: Icons.phonelink_lock_outlined,
            message:
                'In every 1-to-1 chat and group: two or more digits, numbers written in words (English, Hindi, Hinglish), numbers with spaces or symbols (9 8, 9@8, 98-765), '
                'disguised numbers (98O7, ९८७) and numbers split over several messages can not be sent. Contact cards with a number are refused too. '
                'Score: 0-4 allow, 5-7 numbers hidden, 8-12 block, 13+ block + admin log.',
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_clock_outlined),
            title: const Text('Repeated attempts'),
            subtitle: const Text('Blocked attempts within 10 minutes before the user is read only for 1 hour'),
            trailing: DropdownButton<int>(
              value: const [0, 2, 3, 5, 10].contains(widget.restrictAfter) ? widget.restrictAfter : 3,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 2, child: Text('After 2')),
                DropdownMenuItem(value: 3, child: Text('After 3')),
                DropdownMenuItem(value: 5, child: Text('After 5')),
                DropdownMenuItem(value: 10, child: Text('After 10')),
                DropdownMenuItem(value: 0, child: Text('Never')),
              ],
              onChanged: (v) => widget.onRestrictAfter(v!),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _text, onSubmitted: (_) => _test(), decoration: const InputDecoration(hintText: 'Type a message to check'))),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _test, child: const Text('Check')),
            ],
          ),
          if (r != null) ...[
            const SizedBox(height: 12),
            InfoBanner(
              icon: blocked ? Icons.gpp_bad_outlined : r['action'] == 'mask' ? Icons.visibility_off_outlined : Icons.check_circle_outline,
              tone: blocked ? Tone.danger : r['action'] == 'mask' ? Tone.warning : Tone.success,
              title: '${_action('${r['action']}')}  -  risk score ${r['score']}',
              message: (r['reasons'] as List).isEmpty ? 'No number found.' : (r['reasons'] as List).map((e) => '- $e').join('\n'),
            ),
          ],
        ],
      ),
    );
  }
}

