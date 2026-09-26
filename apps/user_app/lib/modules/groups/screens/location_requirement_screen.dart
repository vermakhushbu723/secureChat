import 'package:geolocator/geolocator.dart';

import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../data/group_repository.dart';
import '../state/groups_controller.dart';

/// Mandatory / optional location join:
/// Join Group -> Location Permission -> GPS Location -> Server -> Membership Activated.
/// Without [code] (already a member) it just shares the current location.
class LocationRequirementScreen extends StatelessWidget {
  const LocationRequirementScreen({super.key, required this.groupId, this.code});

  final String groupId;
  final String? code;

  @override
  Widget build(BuildContext context) => LoginGate(title: 'Location Required', child: _LocationJoin(groupId: groupId, code: code));
}

class _LocationJoin extends StatefulWidget {
  const _LocationJoin({required this.groupId, this.code});

  final String groupId;
  final String? code;

  @override
  State<_LocationJoin> createState() => _LocationJoinState();
}

class _LocationJoinState extends State<_LocationJoin> {
  /// -1 = not started, 0..3 = step in progress, 4 = done.
  int _step = -1;
  LocationShareMode _mode = LocationShareMode.join;
  String? _name;
  LocationVisibility _visibility = LocationVisibility.adminOnly;
  String? _failure;
  bool _pending = false;
  String? _joinedGroupId;

  static const _steps = [
    (Icons.my_location, 'Location permission', 'Allow location access'),
    (Icons.gps_fixed, 'GPS location', 'Reading your current position'),
    (Icons.cloud_upload_outlined, 'Sending to server', 'Securely shared with the group'),
    (Icons.verified_outlined, 'Membership activated', 'You are now a member'),
  ];

  bool get _joining => widget.code != null;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      if (_joining) {
        final p = await GroupRepository.invitePreview(widget.code!);
        setState(() {
          _name = p.name;
          _visibility = p.locationVisibility;
          _mode = p.shareMode;
        });
      } else {
        final d = await GroupRepository.detail(widget.groupId);
        setState(() {
          _name = d.name;
          _visibility = d.settings.locationVisibility;
          _mode = d.settings.shareMode;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _failure = e.message);
    }
  }

  Future<void> _start() async {
    setState(() {
      _failure = null;
      _step = 0;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw 'Location services are turned off on this device';
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'Location permission denied. Without it the join cannot be completed.';
      }
      setState(() => _step = 1);
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 25)),
      );
      setState(() => _step = 2);
      final loc = DmLocation(lat: pos.latitude, lng: pos.longitude, name: 'Current location');
      if (_joining) {
        final res = await GroupRepository.join(widget.code!, location: loc, shareMode: _mode == LocationShareMode.live ? 'live' : 'join');
        _joinedGroupId = res.groupId;
        _pending = res.status == 'pending';
      } else {
        if (_mode == LocationShareMode.live) await GroupRepository.updateLocationSettings(mode: 'live', intervalMin: 10);
        await GroupRepository.updateLocation(lat: pos.latitude, lng: pos.longitude, accuracy: pos.accuracy, source: _mode == LocationShareMode.live ? 'live' : 'manual');
      }
      GroupsController.instance.scheduleReload();
      setState(() => _step = 3);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _step = 4);
    } on ApiException catch (e) {
      if (mounted) setState(() => _fail(e.message));
    } catch (e) {
      if (mounted) setState(() => _fail('$e'));
    }
  }

  void _fail(String message) {
    _failure = message;
    _step = -1;
  }

  @override
  Widget build(BuildContext context) {
    final done = _step >= _steps.length;
    return Scaffold(
      appBar: AppBar(title: Text(_joining ? 'Location Required' : 'Share Location')),
      body: FormPage(
        items: [
          const Center(child: FeatureIcon(Icons.share_location_outlined)),
          const SizedBox(height: 20),
          Text(
            _joining ? '${_name ?? 'This group'} requires your location' : 'Share your location with ${_name ?? 'the group'}',
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            switch (_visibility) {
              LocationVisibility.groupMembers => 'Your location will be visible to the group admin and members of this group only.',
              LocationVisibility.nobody => 'Your location is stored for the group but shown to nobody.',
              LocationVisibility.adminOnly => 'Your location will be visible to the group admin only.',
            },
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (_step < 0) ...[
            const Text('Share mode', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: RadioGroup<LocationShareMode>(
                groupValue: _mode,
                onChanged: (v) => setState(() => _mode = v!),
                child: const Column(
                  children: [
                    RadioListTile(value: LocationShareMode.join, title: Text('Join location'), subtitle: Text('Share once while joining')),
                    RadioListTile(value: LocationShareMode.live, title: Text('Live location'), subtitle: Text('Updates every 10 minutes, status always visible')),
                  ],
                ),
              ),
            ),
          ] else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    ListTile(
                      leading: _step > i
                          ? Icon(Icons.check_circle, color: context.palette.success)
                          : _step == i
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Icon(_steps[i].$1, color: context.palette.textSecondary),
                      title: Text(i == 3 && _pending ? 'Request sent' : _steps[i].$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(i == 3 && _pending ? 'Waiting for admin approval' : (i == 3 && !_joining ? 'Location updated' : _steps[i].$3)),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_failure != null) ...[InfoBanner(icon: Icons.error_outline, tone: Tone.danger, message: _failure!), const SizedBox(height: 12)],
          if (_joining)
            const InfoBanner(icon: Icons.warning_amber_rounded, tone: Tone.warning, message: 'Without location permission the join cannot be completed for this group.'),
        ],
        bottom: done
            ? PrimaryButton(
                label: _pending ? 'Done' : 'Open Group Chat',
                icon: _pending ? Icons.check : Icons.chat_outlined,
                onPressed: () => _pending ? context.go(AppRoutes.home) : context.go(AppRoutes.groupChatOf(_joinedGroupId ?? widget.groupId)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(label: 'Allow & Share Location', icon: Icons.my_location, loading: _step >= 0, onPressed: _step >= 0 ? null : _start),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => context.pop(), child: Text(_joining ? 'Cancel join' : 'Cancel')),
                ],
              ),
      ),
    );
  }
}
