import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/data/direct_repository.dart';
import '../../direct/widgets/dm_avatar.dart';

/// Blocked members - hidden in direct chats and in every shared group.
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginGate(title: 'Blocked Members', child: _Screen());
}

class _Screen extends StatefulWidget {
  const _Screen();

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  late Future<List<DmUser>> _future = DirectRepository.blockedUsers();

  void _reload() => setState(() => _future = DirectRepository.blockedUsers());

  Future<void> _add() async {
    final picked = await showModalBottomSheet<DmUser>(context: context, isScrollControlled: true, builder: (_) => const _PickUser());
    if (picked == null || !mounted) return;
    final ok = await context.confirm(
      title: 'Block ${picked.name}?',
      message: 'You will not see their messages in direct chats or shared groups. They are not notified.',
      confirmLabel: 'Block',
      danger: true,
    );
    if (!ok || !mounted) return;
    await runAction(context, () => DirectRepository.block(picked.id), done: '${picked.name} blocked');
    _reload();
  }

  Future<void> _unblock(DmUser u) async {
    final ok = await context.confirm(title: 'Unblock ${u.name}?', message: 'They will be able to message you again.', confirmLabel: 'Unblock');
    if (!ok || !mounted) return;
    await runAction(context, () => DirectRepository.unblock(u.id), done: '${u.name} unblocked');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Members'),
        actions: [IconButton(icon: const Icon(Icons.person_add_disabled_outlined), tooltip: 'Block a member', onPressed: _add)],
      ),
      body: FutureBuilder<List<DmUser>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load',
              message: snap.error is ApiException ? (snap.error! as ApiException).message : '${snap.error}',
              action: TextButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final blocked = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ResponsiveBody(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      blocked.isEmpty
                          ? 'No blocked members. Blocked members cannot message you and their messages are hidden in shared groups.'
                          : 'You will not see messages from blocked members in any shared group. They are not notified.',
                      style: TextStyle(color: context.palette.textSecondary),
                    ),
                  ),
                  for (final u in blocked)
                    ListTile(
                      leading: DmAvatar(name: u.name, avatarUrl: u.avatarUrl, size: 44),
                      title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(u.username == null ? 'Blocked' : '@${u.username}'),
                      trailing: TextButton(onPressed: () => _unblock(u), child: const Text('Unblock')),
                    ),
                  ListTile(
                    leading: const AppAvatar(icon: Icons.add, size: 44),
                    title: const Text('Block a member', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: _add,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PickUser extends StatefulWidget {
  const _PickUser();

  @override
  State<_PickUser> createState() => _PickUserState();
}

class _PickUserState extends State<_PickUser> {
  List<DmUser> _results = const [];
  bool _loading = false;
  int _seq = 0;

  Future<void> _search(String q) async {
    final seq = ++_seq;
    if (q.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await DirectRepository.searchUsers(q.trim());
      if (mounted && seq == _seq) setState(() => _results = r);
    } on ApiException catch (_) {
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(alignment: Alignment.centerLeft, child: Text('Select member to block', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: AppSearchField(hint: 'Search by name or username', autofocus: true, onChanged: _search)),
              if (_loading) const LinearProgressIndicator(),
              Expanded(
                child: ListView(
                  children: [
                    for (final u in _results.where((u) => !u.isBlocked))
                      ListTile(
                        leading: DmAvatar(name: u.name, avatarUrl: u.avatarUrl, size: 40),
                        title: Text(u.name),
                        subtitle: Text(u.username == null ? 'Member' : '@${u.username}'),
                        onTap: () => Navigator.pop(context, u),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
