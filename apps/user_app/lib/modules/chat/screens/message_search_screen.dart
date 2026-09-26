import 'dart:async';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';

class MessageSearchScreen extends StatelessWidget {
  const MessageSearchScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) => LoginGate(title: 'Search messages', child: _Search(groupId: groupId));
}

class _Search extends StatefulWidget {
  const _Search({required this.groupId});

  final String groupId;

  @override
  State<_Search> createState() => _SearchState();
}

class _SearchState extends State<_Search> {
  String _query = '';
  String _filter = 'All';
  DateTime? _day;
  List<GroupMessage> _results = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;

  static const _filters = [
    ('All', Icons.all_inbox_outlined, 'all'),
    ('Text', Icons.chat_bubble_outline, 'text'),
    ('Photos', Icons.image_outlined, 'photos'),
    ('Docs', Icons.description_outlined, 'docs'),
    ('Voice', Icons.mic_none, 'voice'),
    ('Protected', Icons.lock_outline, 'protected'),
  ];

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String v) {
    _query = v.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final q = _query;
    final filter = _filters.firstWhere((f) => f.$1 == _filter).$3;
    try {
      final results = await GroupRepository.search(widget.groupId, q: q, filter: filter);
      if (mounted && q == _query) {
        setState(() {
          _results = results;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, firstDate: DateTime(now.year - 2), lastDate: now, initialDate: _day ?? now);
    setState(() => _day = picked);
  }

  @override
  Widget build(BuildContext context) {
    final results = _day == null
        ? _results
        : _results.where((m) => m.createdAt.year == _day!.year && m.createdAt.month == _day!.month && m.createdAt.day == _day!.day).toList();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          autofocus: true,
          onChanged: _changed,
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        actions: [
          if (_day != null) IconButton(icon: const Icon(Icons.event_busy), tooltip: 'Clear date', onPressed: () => setState(() => _day = null)),
          IconButton(icon: const Icon(Icons.calendar_month_outlined), tooltip: 'Filter by date', onPressed: _pickDay),
        ],
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  return ChoiceChip(
                    avatar: Icon(f.$2, size: 16, color: _filter == f.$1 ? context.colors.onPrimary : null),
                    label: Text(f.$1),
                    showCheckmark: false,
                    selected: _filter == f.$1,
                    onSelected: (_) {
                      setState(() => _filter = f.$1);
                      _search();
                    },
                  );
                },
              ),
            ),
            if (_day != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(alignment: Alignment.centerLeft, child: StatusChip('On ${formatDayHeader(_day!).toLowerCase()}', icon: Icons.event)),
              ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            const Divider(),
            Expanded(
              child: _error != null
                  ? EmptyState(icon: Icons.error_outline, title: 'Search failed', message: _error!)
                  : results.isEmpty && !_loading
                  ? const EmptyState(icon: Icons.search_off, title: 'No results', message: 'No messages match your search.')
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const Divider(indent: 72),
                      itemBuilder: (_, i) {
                        final m = results[i];
                        return ListTile(
                          onTap: () => context.push(AppRoutes.messageInfoOf(widget.groupId, m.id)),
                          leading: AppAvatar(icon: iconForMessageType(m.sharedType), size: 44),
                          title: Row(
                            children: [
                              Expanded(child: Text(m.isMine ? 'You' : m.senderName, style: const TextStyle(fontWeight: FontWeight.w600))),
                              if (m.isProtected) ...[SecurityBadge(m.visibility, compact: true), const SizedBox(width: 6)],
                              Text('${formatListTime(m.createdAt)} ${formatClock(m.createdAt)}', style: TextStyle(fontSize: 11, color: context.palette.textSecondary)),
                            ],
                          ),
                          subtitle: _Highlight(text: m.previewText, query: _query),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final i = query.isEmpty ? -1 : text.toLowerCase().indexOf(query.toLowerCase());
    if (i < 0) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: text.substring(i, i + query.length),
            style: TextStyle(backgroundColor: context.palette.warning.withValues(alpha: 0.35), fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(i + query.length)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
