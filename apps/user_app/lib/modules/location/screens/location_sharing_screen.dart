import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/widgets/group_tile.dart';
import '../data/geo.dart';

/// Location privacy: No Location / Join Location / Live Location (interval).
class LocationSharingScreen extends StatelessWidget {
  const LocationSharingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Location Sharing',
      child: Scaffold(
        appBar: AppBar(title: const Text('Location Sharing')),
        body: AsyncView<MyLocationData>(load: GroupRepository.myLocation, builder: (context, data, reload) => _Body(data: data)),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.data});

  final MyLocationData data;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late MyLocationData _d = widget.data;
  late LocationShareMode _mode = _d.mode;
  late int _interval = _d.intervalMin;
  bool _saving = false;

  Future<void> _save(LocationShareMode mode, int interval) async {
    if (mode == LocationShareMode.none && _d.groups.any((g) => g.requirement == LocationRequirement.mandatory)) {
      final ok = await context.confirm(
        title: 'Turn location off?',
        message: 'Groups with mandatory location may restrict your membership while location is off.',
        confirmLabel: 'Turn off',
        danger: true,
      );
      if (!ok) return;
    }
    setState(() {
      _mode = mode;
      _interval = interval;
      _saving = true;
    });
    try {
      final d = await GroupRepository.updateLocationSettings(mode: mode.name, intervalMin: interval);
      if (mode == LocationShareMode.live) {
        // Push a first fix right away so groups see the live status.
        try {
          final pos = await Geo.current();
          await GroupRepository.updateLocation(lat: pos.latitude, lng: pos.longitude, accuracy: pos.accuracy, source: 'live');
        } catch (_) {}
      }
      final fresh = mode == LocationShareMode.live ? await GroupRepository.myLocation() : d;
      if (mounted) {
        setState(() => _d = fresh);
        context.showSnack('Location set to ${mode.label}');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _mode = _d.mode;
          _interval = _d.intervalMin;
        });
        context.showSnack(e.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _d.groups;
    final live = _mode == LocationShareMode.live;
    final on = live && _d.liveActive;
    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Always-visible status, as required for live location.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: on ? context.colors.primary : context.palette.surfaceAlt, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(on ? Icons.share_location : Icons.location_off_outlined, color: on ? context.colors.onPrimary : context.colors.onSurface, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        on ? 'Live location is ON' : _mode.label,
                        style: TextStyle(fontWeight: FontWeight.w800, color: on ? context.colors.onPrimary : context.colors.onSurface),
                      ),
                      Text(
                        on
                            ? 'Updating ${_interval == 0 ? 'manually' : 'every $_interval min'} to ${groups.length} groups'
                                  '${_d.liveUntil == null ? '' : ' until ${formatClock(_d.liveUntil!)}'}'
                            : _mode == LocationShareMode.join
                            ? 'Shared once when you join a group${_d.lastAt == null ? '' : '  |  last ${Geo.ago(_d.lastAt)}'}'
                            : 'Your location is not being updated',
                        style: TextStyle(color: (on ? context.colors.onPrimary : context.colors.onSurface).withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
                if (_saving) SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: on ? context.colors.onPrimary : null)),
              ],
            ),
          ),
          const SectionHeader('Mode', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: RadioGroup<LocationShareMode>(
              groupValue: _mode,
              onChanged: (v) => _saving || v == null ? null : _save(v, _interval),
              child: const Column(
                children: [
                  RadioListTile(
                    value: LocationShareMode.none,
                    title: Text('Mode 1 - No Location'),
                    subtitle: Text('Location OFF. Mandatory-location groups cannot be joined.'),
                  ),
                  Divider(indent: 16),
                  RadioListTile(value: LocationShareMode.join, title: Text('Mode 2 - Join Location'), subtitle: Text('Share once while joining a group')),
                  Divider(indent: 16),
                  RadioListTile(
                    value: LocationShareMode.live,
                    title: Text('Mode 3 - Live Location'),
                    subtitle: Text('Updates at the interval below, status always visible'),
                  ),
                ],
              ),
            ),
          ),
          if (live) ...[
            const SectionHeader('Update interval', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in const [5, 10, 30, 0])
                  ChoiceChip(
                    label: Text(i == 0 ? 'Manual' : 'Every $i min'),
                    selected: _interval == i,
                    showCheckmark: false,
                    onSelected: _saving ? null : (_) => _save(LocationShareMode.live, i),
                  ),
              ],
            ),
          ],
          if (_mode == LocationShareMode.none) ...[
            const SizedBox(height: 16),
            const InfoBanner(
              icon: Icons.warning_amber_rounded,
              tone: Tone.warning,
              message: 'Groups with mandatory location may restrict your membership while location is off.',
            ),
          ],
          const SectionHeader('Groups using your location', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: groups.isEmpty
                ? const ListTile(leading: Icon(Icons.location_off_outlined), title: Text('None of your groups use location'))
                : Column(
                    children: [
                      for (final g in groups)
                        ListTile(
                          onTap: () => context.push(AppRoutes.membersLocationOf(g.groupId)),
                          leading: GroupAvatar(name: g.name, avatarUrl: g.avatarUrl, size: 40),
                          title: Text(g.name, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${g.requirement.label}  |  visible to ${switch (g.visibility) {
                              LocationVisibility.groupMembers => 'admin & members',
                              LocationVisibility.adminOnly => 'admin only',
                              LocationVisibility.nobody => 'nobody',
                            }}  |  you: ${g.status == 'Stale' ? 'last shared' : g.status}',
                          ),
                          trailing: StatusChip(
                            g.requirement == LocationRequirement.mandatory ? 'Required' : 'Optional',
                            tone: g.requirement == LocationRequirement.mandatory ? Tone.warning : Tone.neutral,
                          ),
                        ),
                    ],
                  ),
          ),
          const SectionHeader('More', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: Column(
              children: [
                AppTile(icon: Icons.my_location, title: 'My location', onTap: () => context.push(AppRoutes.myLocation)),
                AppTile(icon: Icons.groups_outlined, title: 'Group members location', onTap: () => context.push(AppRoutes.membersLocation)),
                AppTile(icon: Icons.history, title: 'Location history & status', onTap: () => context.push(AppRoutes.locationHistory)),
                AppTile(icon: Icons.admin_panel_settings_outlined, title: 'Permission', onTap: () => context.push(AppRoutes.locationPermission)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
