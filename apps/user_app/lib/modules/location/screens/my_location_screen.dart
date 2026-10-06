import 'package:geolocator/geolocator.dart';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/state/group_sender.dart';
import '../data/geo.dart';

/// Current device position. Opened from a group chat it can send the
/// location into that group, and it can start live sharing.
class MyLocationScreen extends StatelessWidget {
  const MyLocationScreen({super.key, this.groupId});

  final String? groupId;

  @override
  Widget build(BuildContext context) => LoginGate(title: 'My Location', child: _Screen(groupId: groupId));
}

class _Screen extends StatefulWidget {
  const _Screen({this.groupId});

  final String? groupId;

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  static const _durations = [(15, '15 min'), (60, '1 hour'), (480, '8 hours'), (0, 'Until I stop')];

  Position? _pos;
  DateTime? _at;
  String? _error;
  bool _locating = false;
  bool _busy = false;
  int _duration = 60;
  bool _liveOn = false;

  @override
  void initState() {
    super.initState();
    _locate();
    GroupRepository.myLocation().then((me) => mounted ? setState(() => _liveOn = me.liveActive) : null).catchError((_) {});
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final p = await Geo.current();
      if (mounted) {
        setState(() {
          _pos = p;
          _at = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _sendCurrent() async {
    final p = _pos;
    final gid = widget.groupId;
    if (p == null) return;
    setState(() => _busy = true);
    try {
      if (gid != null) {
        final blocked = await GroupSender.location(gid, DmLocation(lat: p.latitude, lng: p.longitude, name: 'Current location'));
        if (!mounted) return;
        if (blocked != null) {
          blocked.isContent ? context.push(blocked.restrictionRoute) : context.showSnack(blocked.message);
          return;
        }
        context.showSnack('Current location sent');
        context.pop();
      } else {
        await GroupRepository.updateLocation(lat: p.latitude, lng: p.longitude, accuracy: p.accuracy);
        if (mounted) context.showSnack('Location shared with your location groups');
      }
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareLive() async {
    final p = _pos;
    if (p == null) return;
    setState(() => _busy = true);
    try {
      await GroupRepository.updateLocationSettings(mode: 'live', intervalMin: 10, liveForMinutes: _duration == 0 ? null : _duration);
      await GroupRepository.updateLocation(lat: p.latitude, lng: p.longitude, accuracy: p.accuracy, source: 'live');
      final gid = widget.groupId;
      if (gid != null) await GroupSender.location(gid, DmLocation(lat: p.latitude, lng: p.longitude, name: 'Live location'), live: true);
      if (!mounted) return;
      setState(() => _liveOn = true);
      context.showSnack('Sharing live location ${_durations.firstWhere((d) => d.$1 == _duration).$2.toLowerCase()}');
      if (gid != null) context.pop();
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopLive() async {
    setState(() => _busy = true);
    try {
      await GroupRepository.updateLocationSettings(mode: 'join');
      if (mounted) {
        setState(() => _liveOn = false);
        context.showSnack('Live location stopped');
      }
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _pos;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Location'),
        actions: [IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _locating ? null : _locate)],
      ),
      body: FormPage(
        padding: const EdgeInsets.all(16),
        items: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.mapView),
            child: MapPlaceholder(height: 260, interactive: false, pins: [if (p != null) MapPin(dx: 0.5, dy: 0.55, label: 'You', isMe: true, lat: p.latitude, lng: p.longitude)]),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            InfoBanner(icon: Icons.error_outline, tone: Tone.danger, message: _error!),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => context.push(AppRoutes.locationPermission), icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Location permission'))),
          ] else if (p == null)
            const Card(child: ListTile(leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)), title: Text('Getting your location...')))
          else
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const AppAvatar(icon: Icons.place, inverted: true, size: 44),
                    title: const Text('Current location', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(Geo.coords(p.latitude, p.longitude)),
                  ),
                  const Divider(indent: 16),
                  InfoRow(label: 'Coordinates', value: Geo.coords(p.latitude, p.longitude), icon: Icons.gps_fixed),
                  InfoRow(label: 'Accuracy', value: '+/- ${p.accuracy.round()} m', icon: Icons.radar),
                  InfoRow(label: 'Last updated', value: _at == null ? '-' : formatClock(_at!), icon: Icons.update),
                  InfoRow(label: 'Status', value: _liveOn ? 'Sharing live' : 'Not sharing live', icon: Icons.share_location),
                ],
              ),
            ),
          if (_liveOn) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _busy ? null : _stopLive, icon: const Icon(Icons.stop_circle_outlined), label: const Text('Stop live location')),
          ],
          const SectionHeader('Share live location for', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in _durations)
                ChoiceChip(label: Text(d.$2), selected: _duration == d.$1, showCheckmark: false, onSelected: (_) => setState(() => _duration = d.$1)),
            ],
          ),
        ],
        bottom: Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: widget.groupId != null ? 'Send current' : 'Share current',
                icon: Icons.place_outlined,
                onPressed: p == null || _busy ? null : _sendCurrent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton(label: 'Share live', icon: Icons.share_location, loading: _busy, onPressed: p == null || _busy ? null : _shareLive)),
          ],
        ),
      ),
    );
  }
}
