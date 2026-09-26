import 'package:geolocator/geolocator.dart';

import '../../../core/core.dart';
import '../data/geo.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key, this.joinGroupId});

  /// Set when opened while joining a location-required group.
  final String? joinGroupId;

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  static const _points = [
    (Icons.groups_outlined, 'Join location-based groups', 'Some groups require members to share location.'),
    (Icons.visibility_outlined, 'You stay in control', 'Only members of those groups can see you.'),
    (Icons.pause_circle_outline, 'Pause anytime', 'Stop sharing from settings at any moment.'),
  ];

  LocationPermission? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Geo.permission().then((p) => mounted ? setState(() => _status = p) : null).catchError((_) {});
  }

  String get _statusLabel => switch (_status) {
    LocationPermission.always => 'Allowed all the time',
    LocationPermission.whileInUse => 'Allowed while using the app',
    LocationPermission.deniedForever => 'Blocked - change it in settings',
    LocationPermission.denied => 'Not allowed yet',
    _ => 'Checking...',
  };

  bool get _granted => _status == LocationPermission.always || _status == LocationPermission.whileInUse;

  Future<void> _allow() async {
    setState(() => _busy = true);
    try {
      final p = await Geo.request();
      if (!mounted) return;
      setState(() => _status = p);
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
        context.showSnack('Location permission granted');
        final join = widget.joinGroupId;
        context.pushReplacement(join != null ? AppRoutes.locationRequirementOf(join) : AppRoutes.locationSharing);
      } else {
        context.showSnack('Permission not granted. You can allow it from browser / device settings.');
      }
    } catch (e) {
      if (mounted) context.showSnack('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Permission')),
      body: FormPage(
        items: [
          const SizedBox(height: 8),
          const MessageBlock(
            icon: Icons.location_on_outlined,
            title: 'Allow location access',
            message: '${AppStrings.appName} uses your location only for groups that require it.',
          ),
          const SizedBox(height: 16),
          Center(child: StatusChip(_statusLabel, tone: _granted ? Tone.success : Tone.warning, icon: _granted ? Icons.check_circle : Icons.info_outline)),
          const SizedBox(height: 20),
          for (final p in _points)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AppAvatar(icon: p.$1, size: 44),
              title: Text(p.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(p.$3),
            ),
        ],
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(label: _granted ? 'Continue' : 'Allow while using the app', loading: _busy, onPressed: _busy ? null : _allow),
            const SizedBox(height: 10),
            SecondaryButton(label: 'Location sharing settings', onPressed: () => context.pushReplacement(AppRoutes.locationSharing)),
            const SizedBox(height: 4),
            TextButton(onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home), child: const Text("Don't allow")),
          ],
        ),
      ),
    );
  }
}
