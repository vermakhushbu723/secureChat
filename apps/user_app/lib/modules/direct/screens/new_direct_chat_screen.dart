import 'dart:async';

import '../../../core/core.dart';
import '../data/direct_models.dart';
import '../data/direct_repository.dart';
import '../state/conversations_controller.dart';
import '../widgets/dm_avatar.dart';

/// Find a person by name / username / phone and open a chat with them.
class NewDirectChatScreen extends StatefulWidget {
  const NewDirectChatScreen({super.key});

  @override
  State<NewDirectChatScreen> createState() => _NewDirectChatScreenState();
}

class _NewDirectChatScreenState extends State<NewDirectChatScreen> {
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  String? _error;
  List<DmUser> _results = [];
  String? _opening;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() {
      _query = q;
      _error = null;
    });
    if (q.isEmpty) return setState(() => _results = []);
    setState(() => _loading = true);
    try {
      final users = await DirectRepository.searchUsers(q);
      if (mounted && q == _query) setState(() => _results = users);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(DmUser u) async {
    setState(() => _opening = u.id);
    try {
      final conv = await DirectRepository.openWith(u.id);
      ConversationsController.instance.upsert(conv);
      if (!mounted) return;
      // Wide: chat replaces this page on the right. Phone: back returns to the list.
      AppLayout.isWide(context)
          ? context.go(AppRoutes.directChatOf(conv.id))
          : context.pushReplacement(AppRoutes.directChatOf(conv.id));
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = ConversationsController.instance.items.take(8).map((c) => c.peer).toList();
    final showing = _query.isEmpty ? recent : _results;
    return Scaffold(
      appBar: AppBar(title: const Text('New chat')),
      body: ResponsiveBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: AppSearchField(hint: 'Search name, @username or phone', onChanged: _onChanged, autofocus: true),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: InfoBanner(icon: Icons.error_outline, message: _error!),
              ),
            if (_query.isEmpty && recent.isNotEmpty) const SectionHeader('Recent chats'),
            Expanded(
              child: showing.isEmpty
                  ? EmptyState(
                      icon: Icons.person_search_outlined,
                      title: _query.isEmpty ? 'Find people' : 'No one found',
                      message: _query.isEmpty ? 'Search by name, username or phone number.' : 'Try a different name.',
                    )
                  : ListView(
                      children: [
                        for (final u in showing)
                          ListTile(
                            leading: DmAvatar.user(u, size: 44),
                            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              [if (u.username != null) '@${u.username}', if (u.about.isNotEmpty) u.about].join('  •  '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: _opening == u.id
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.chat_bubble_outline),
                            onTap: _opening == null ? () => _open(u) : null,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
