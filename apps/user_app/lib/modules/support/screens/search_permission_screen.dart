import '../../../core/core.dart';
import '../../direct/data/direct_repository.dart';

/// Settings -> Search permissions: whether this user can search people (1-to-1) and
/// group members, as set by the SecureChat team and group admins.
class SearchPermissionScreen extends StatefulWidget {
  const SearchPermissionScreen({super.key});

  @override
  State<SearchPermissionScreen> createState() => _SearchPermissionScreenState();
}

class _SearchPermissionScreenState extends State<SearchPermissionScreen> {
  late Future<SearchPermission> _future = DirectRepository.searchPermission();

  Widget _row(BuildContext context, IconData icon, String title, bool on, String? reason, String onText) {
    return ListTile(
      leading: Icon(icon, color: on ? context.palette.success : context.palette.danger),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(on ? onText : (reason ?? 'Turned off')),
      trailing: StatusChip(on ? 'Allowed' : 'Off', tone: on ? Tone.success : Tone.danger, icon: on ? Icons.check : Icons.search_off),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search permissions')),
      body: ResponsiveBody(
        child: FutureBuilder<SearchPermission>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load',
                message: '${snap.error}',
                action: OutlinedButton(onPressed: () => setState(() => _future = DirectRepository.searchPermission()), child: const Text('Retry')),
              );
            }
            final p = snap.data;
            if (p == null) return const Center(child: CircularProgressIndicator());
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      _row(context, Icons.person_search_outlined, 'Find people (1-to-1 chats)', p.users, p.usersReason, 'You can search people by name or username to start a chat.'),
                      const Divider(indent: 56),
                      _row(context, Icons.groups_outlined, 'Search group members', p.members, p.membersReason, 'You can search members inside your groups (unless a group admin turned it off).'),
                      const Divider(indent: 56),
                      _row(
                        context,
                        Icons.visibility_outlined,
                        'Others can find me',
                        !p.hiddenFromSearch,
                        'The SecureChat team hid your profile from search. Nobody can find you by search.',
                        'People can find you in search (you can turn this off in Settings -> Anyone can find me).',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const InfoBanner(
                  icon: Icons.info_outline,
                  message:
                      'The SecureChat team can turn search off for everyone or for one account. A group admin can turn member search off in their group (Group settings -> Members).',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
