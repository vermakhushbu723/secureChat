import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../data/geo.dart';

class LocationHistoryScreen extends StatelessWidget {
  const LocationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginGate(title: 'Location History', child: _Screen());
}

class _Screen extends StatefulWidget {
  const _Screen();

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  String _range = 'today';
  late Future<(MyLocationData, ({List<LocationHistoryEntry> items, int updates}))> _future = _load();

  Future<(MyLocationData, ({List<LocationHistoryEntry> items, int updates}))> _load() async =>
      (await GroupRepository.myLocation(), await GroupRepository.history(_range));

  void _reload() => setState(() => _future = _load());

  Future<void> _clear() async {
    final ok = await context.confirm(title: 'Clear history?', message: 'Your location history will be removed permanently.', confirmLabel: 'Clear', danger: true);
    if (!ok || !mounted) return;
    await runAction(context, GroupRepository.clearHistory, done: 'Location history cleared');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        actions: [IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Clear history', onPressed: _clear)],
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load history',
              message: snap.error is ApiException ? (snap.error! as ApiException).message : '${snap.error}',
              action: TextButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final (me, history) = snap.data!;
          final items = history.items;
          final sharing = me.mode != LocationShareMode.none;
          final timeline = items.take(12).toList().reversed.toList();
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ResponsiveBody(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current status', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _Status(icon: Icons.share_location, label: 'Sharing', value: me.liveActive ? 'Live' : sharing ? 'On join' : 'Off', tone: me.liveActive ? Tone.success : sharing ? Tone.neutral : Tone.danger),
                              _Status(icon: Icons.timer_outlined, label: 'Interval', value: me.intervalMin == 0 ? 'Manual' : '${me.intervalMin} min', tone: Tone.neutral),
                              _Status(icon: Icons.update, label: 'Last update', value: Geo.ago(me.lastAt), tone: Tone.neutral),
                              _Status(icon: Icons.groups_outlined, label: 'Groups', value: '${me.groups.length}', tone: Tone.neutral),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'today', label: Text('Today')),
                      ButtonSegment(value: 'week', label: Text('7 days')),
                      ButtonSegment(value: 'month', label: Text('30 days')),
                    ],
                    selected: {_range},
                    onSelectionChanged: (s) {
                      _range = s.first;
                      _reload();
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.mapView),
                    child: MapPlaceholder(
                      height: 160,
                      pins: Geo.pins([
                        for (var i = 0; i < timeline.length; i++)
                          (lat: timeline[i].lat, lng: timeline[i].lng, label: timeline[i].at == null ? '' : formatClock(timeline[i].at!), isMe: i == timeline.length - 1),
                      ]),
                    ),
                  ),
                  SectionHeader('Timeline  |  ${history.updates} updates', padding: const EdgeInsets.fromLTRB(0, 20, 0, 8)),
                  if (items.isEmpty)
                    const Card(child: ListTile(leading: Icon(Icons.location_off_outlined), title: Text('No location updates in this period')))
                  else
                    Card(
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const Divider(indent: 72),
                            ListTile(
                              leading: AppAvatar(
                                icon: switch (items[i].source) {
                                  'live' => Icons.share_location,
                                  'join' => Icons.play_circle_outline,
                                  _ => Icons.place_outlined,
                                },
                                size: 40,
                              ),
                              title: Text(items[i].placeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${items[i].at == null ? '' : '${formatListTime(items[i].at)} ${formatClock(items[i].at!)}'}  |  ${items[i].sourceLabel}'),
                            ),
                          ],
                        ],
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

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.label, required this.value, required this.tone});

  final IconData icon;
  final String label;
  final String value;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == Tone.neutral ? context.colors.onSurface : toneColor(context, tone);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(fontSize: 11, color: context.palette.textSecondary)),
        ],
      ),
    );
  }
}
