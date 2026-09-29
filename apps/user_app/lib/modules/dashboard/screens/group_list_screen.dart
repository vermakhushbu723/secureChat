import '../../../core/core.dart';
import '../../groups/widgets/join_group_sheet.dart';
import '../../groups/data/group_models.dart';
import '../../groups/state/groups_controller.dart';
import '../../groups/widgets/group_tile.dart';

/// Groups tab - manage groups the user created or joined.
class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  String _filter = 'All';
  String _query = '';

  static const _filters = ['All', 'Created by me', 'Joined', 'Location', 'Muted'];

  List<GroupSummary> _groups(List<GroupSummary> all) {
    return all.where((g) {
      if (_query.isNotEmpty && !g.name.toLowerCase().contains(_query.toLowerCase())) return false;
      return switch (_filter) {
        'Created by me' => g.role == MemberRole.owner,
        'Joined' => g.role != MemberRole.owner,
        'Location' => g.location != LocationRequirement.off,
        'Muted' => g.muted,
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Groups',
      child: ListenableBuilder(
        listenable: GroupsController.instance,
        builder: (context, _) {
          final list = GroupsController.instance;
          WidgetsBinding.instance.addPostFrameCallback((_) => list.ensureStarted());
          final groups = _groups(list.items);
          return Scaffold(
            appBar: AppBar(
              title: const Text('Groups'),
              actions: [
                IconButton(icon: const Icon(Icons.link), tooltip: 'Join with link', onPressed: () => askInviteLink(context)),
                IconButton(icon: const Icon(Icons.group_add_outlined), tooltip: 'Create group', onPressed: () => context.push(AppRoutes.createGroup)),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'fab-groups',
              onPressed: () => context.push(AppRoutes.createGroup),
              icon: const Icon(Icons.add),
              label: const Text('Create group'),
            ),
            body: ResponsiveBody(
              maxWidth: 760,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: AppSearchField(hint: 'Search groups', onChanged: (v) => setState(() => _query = v)),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ChoiceChip(
                        label: Text(_filters[i]),
                        selected: _filter == _filters[i],
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _filter = _filters[i]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: list.loading
                        ? const Center(child: CircularProgressIndicator())
                        : groups.isEmpty
                        ? const EmptyState(icon: Icons.groups_outlined, title: 'No groups found', message: 'Create a group or join one with an invite link.')
                        : RefreshIndicator(
                            onRefresh: list.load,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 96),
                              itemCount: groups.length,
                              itemBuilder: (_, i) {
                                final g = groups[i];
                                final owner = g.role == MemberRole.owner;
                                return SelectedHighlight(
                                  location: AppRoutes.groupInfoOf(g.id),
                                  child: GroupTile(
                                    group: g,
                                    subtitle: '${g.memberCount} members  |  Location: ${g.location.label}',
                                    onTap: () => context.openDetail(AppRoutes.groupInfoOf(g.id)),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        StatusChip(owner ? 'Creator' : (g.isAdmin ? 'Admin' : 'Member'), tone: owner ? Tone.dark : Tone.neutral),
                                        if (!g.isActive) ...[const SizedBox(height: 4), StatusChip(g.statusLabel)],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
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
