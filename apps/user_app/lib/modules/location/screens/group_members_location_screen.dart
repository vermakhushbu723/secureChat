import 'dart:async';

import '../../../core/core.dart';
import '../../direct/widgets/dm_avatar.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/state/groups_controller.dart';
import '../data/geo.dart';

/// Member locations of one group - only if the group admin allows members
/// to see them. Names only, never numbers or IDs.
class GroupMembersLocationScreen extends StatelessWidget {
  const GroupMembersLocationScreen({super.key, this.groupId});

  final String? groupId;

  @override
  Widget build(BuildContext context) => LoginGate(title: 'Members Location', child: _Screen(initialGroupId: groupId));
}

class _Screen extends StatefulWidget {
  const _Screen({this.initialGroupId});

  final String? initialGroupId;

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  String? _groupId;
  List<LocationGroupInfo> _groups = const [];
  GroupLocationsData? _data;
  String? _error;
  StreamSubscription<dynamic>? _sub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _groupId = widget.initialGroupId;
    _init();
    _sub = SocketService.instance.on('group:location').listen((e) {
      if (e['groupId'] == _groupId) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 400), _load);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final me = await GroupRepository.myLocation();
      if (!mounted) return;
      setState(() {
        _groups = me.groups;
        _groupId ??= me.groups.isEmpty ? null : me.groups.first.groupId;
      });
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _load() async {
    final id = _groupId;
    if (id == null) return;
    try {
      final d = await GroupRepository.groupLocations(id);
      if (mounted && id == _groupId) {
        setState(() {
          _data = d;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _data = null;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final id = _groupId;
    final names = {for (final g in GroupsController.instance.items) g.id: g.name};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members Location'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _load),
          if (d?.allowed == true && id != null) IconButton(icon: const Icon(Icons.fullscreen), tooltip: 'Map', onPressed: () => context.push(AppRoutes.mapViewOf(id))),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (_groups.isNotEmpty || id != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: DropdownButtonFormField<String>(
                    initialValue: id,
                    isExpanded: true,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.groups_outlined)),
                    items: [
                      for (final g in _groups) DropdownMenuItem(value: g.groupId, child: Text(g.name, overflow: TextOverflow.ellipsis)),
                      if (id != null && !_groups.any((g) => g.groupId == id))
                        DropdownMenuItem(value: id, child: Text(d?.groupName ?? names[id] ?? 'Group', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _groupId = v;
                        _data = null;
                      });
                      _load();
                    },
                  ),
                ),
              if (_error != null)
                Padding(padding: const EdgeInsets.all(24), child: MessageBlock(icon: Icons.location_disabled_outlined, tone: Tone.neutral, title: 'Location unavailable', message: _error!))
              else if (id == null && _groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: MessageBlock(icon: Icons.location_off_outlined, tone: Tone.neutral, title: 'No location groups', message: 'None of your groups use location.'),
                )
              else if (d == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (!d.allowed)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: MessageBlock(
                    icon: Icons.location_disabled_outlined,
                    tone: Tone.neutral,
                    title: 'Member locations are hidden',
                    message: d.visibility == LocationVisibility.nobody
                        ? 'The admin of this group hides member locations from everyone.'
                        : 'The admin of this group allows only admins to see member locations.',
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.mapViewOf(id!)),
                    child: MapPlaceholder(
                      height: 220,
                      pins: Geo.pins([
                        for (final m in d.members.where((m) => m.hasPosition)) (lat: m.lat!, lng: m.lng!, label: m.isMe ? 'You' : m.displayName, isMe: m.isMe),
                      ]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip('${d.live} live', tone: Tone.success, icon: Icons.circle),
                      StatusChip('${d.stale} last shared', tone: Tone.warning, icon: Icons.schedule),
                      StatusChip('${d.off} off', tone: Tone.danger, icon: Icons.location_off_outlined),
                    ],
                  ),
                ),
                const SectionHeader('Members'),
                for (final m in d.members)
                  ListTile(
                    onTap: m.hasPosition ? () => context.push(AppRoutes.mapViewOf(id!, userId: m.userId)) : null,
                    leading: DmAvatar(name: m.displayName, avatarUrl: m.avatarUrl, size: 44),
                    title: Text(m.isMe ? '${m.displayName} (You)' : m.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(m.status == 'Off' ? 'Not sharing' : '${m.placeLabel}  |  ${Geo.ago(m.updatedAt)}'),
                    trailing: StatusChip(
                      m.status == 'Stale' ? 'Last shared' : m.status,
                      tone: switch (m.status) {
                        'Live' => Tone.success,
                        'Stale' => Tone.warning,
                        _ => Tone.danger,
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
