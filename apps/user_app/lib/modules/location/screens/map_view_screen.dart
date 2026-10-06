import '../../../core/core.dart';
import '../../direct/widgets/media_viewers.dart' show openExternal;
import '../../direct/widgets/dm_avatar.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../data/geo.dart';

/// Full-screen map of the members of one group who share location.
class MapViewScreen extends StatelessWidget {
  const MapViewScreen({super.key, this.groupId, this.userId});

  final String? groupId;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final id = groupId;
    return LoginGate(
      title: 'Map',
      child: id == null
          ? _MyMap()
          : AsyncView<GroupLocationsData>(
              load: () => GroupRepository.groupLocations(id),
              builder: (context, d, reload) => _Map(groupId: id, data: d, focusUserId: userId, reload: reload),
            ),
    );
  }
}

/// Map without a group: my last known position.
class _MyMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AsyncView<MyLocationData>(
      load: GroupRepository.myLocation,
      builder: (context, me, _) => _Map(
        groupId: null,
        data: GroupLocationsData(
          allowed: true,
          groupName: 'My location',
          members: [
            if (me.lastLat != null)
              MemberLocation(userId: 'me', displayName: 'You', isMe: true, status: me.liveActive ? 'Live' : 'Stale', lat: me.lastLat, lng: me.lastLng, place: me.lastPlace, updatedAt: me.lastAt),
          ],
        ),
        reload: () async {},
      ),
    );
  }
}

class _Map extends StatefulWidget {
  const _Map({required this.groupId, required this.data, required this.reload, this.focusUserId});

  final String? groupId;
  final GroupLocationsData data;
  final String? focusUserId;
  final Future<void> Function() reload;

  @override
  State<_Map> createState() => _MapState();
}

class _MapState extends State<_Map> {
  final _search = TextEditingController();
  late String? _selected = widget.focusUserId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final all = widget.data.members.where((m) => m.hasPosition).toList();
    final shown = q.isEmpty ? all : all.where((m) => m.displayName.toLowerCase().contains(q) || (m.place ?? '').toLowerCase().contains(q)).toList();
    if (_selected != null) {
      final i = shown.indexWhere((m) => m.userId == _selected);
      if (i > 0) shown.insert(0, shown.removeAt(i));
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: !widget.data.allowed
                ? const EmptyState(icon: Icons.location_disabled_outlined, title: 'Member locations are hidden', message: 'The group admin does not allow you to see member locations.')
                : MapPlaceholder(
                    radius: 0,
                    showControls: true,
                    fullScreen: true,
                    pins: Geo.pins([for (final m in shown) (lat: m.lat!, lng: m.lng!, label: m.isMe ? 'You' : m.displayName, isMe: m.isMe || m.userId == _selected)]),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Material(
                    color: context.colors.surface,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(24),
                      color: context.colors.surface,
                      child: AppSearchField(hint: 'Search member or place', onChanged: (v) => setState(() => _search.text = v)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: context.colors.surface,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: widget.reload),
                  ),
                ],
              ),
            ),
          ),
          if (shown.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 150,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    scrollDirection: Axis.horizontal,
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final m = shown[i];
                      final selected = _selected == m.userId;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = m.userId),
                        child: Container(
                          width: 250,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: selected ? context.colors.primary : context.palette.divider, width: selected ? 2 : 1),
                            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  DmAvatar(name: m.displayName, avatarUrl: m.avatarUrl, size: 40, online: m.status == 'Live'),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.isMe ? 'You' : m.displayName, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                                        Text(m.placeLabel, style: TextStyle(fontSize: 12, color: context.palette.textSecondary), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: context.palette.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(m.status == 'Live' ? 'Live  |  ${Geo.ago(m.updatedAt)}' : Geo.ago(m.updatedAt), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Directions',
                                    icon: const Icon(Icons.directions_outlined),
                                    onPressed: () => openExternal(context, Geo.mapsUrl(m.lat!, m.lng!)),
                                  ),
                                  if (widget.groupId != null)
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'Open group chat',
                                      icon: const Icon(Icons.chat_outlined),
                                      onPressed: () => context.push(AppRoutes.groupChatOf(widget.groupId!)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
