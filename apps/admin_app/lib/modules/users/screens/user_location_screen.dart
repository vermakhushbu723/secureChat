import '../../../core/core.dart';

class AdminUserLocationScreen extends StatelessWidget {
  const AdminUserLocationScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final u = MockData.userById(userId);
    return AdminPage(
      title: 'User Location',
      subtitle: u.name,
      showBack: true,
      children: [
        MapPlaceholder(
          height: 360,
          showControls: true,
          pins: [
            const MapPin(dx: 0.25, dy: 0.7, label: '08:30'),
            const MapPin(dx: 0.45, dy: 0.5, label: '09:15'),
            MapPin(dx: 0.7, dy: 0.35, label: u.name.split(' ').first, isMe: true),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 260,
          children: [
            PanelCard(
              title: 'Current',
              child: Column(
                children: [
                  InfoRow(label: 'City', value: u.location, icon: Icons.place_outlined),
                  const InfoRow(label: 'Coordinates', value: '23.2599, 77.4126', icon: Icons.gps_fixed),
                  const InfoRow(label: 'Accuracy', value: '+/- 12 m', icon: Icons.radar),
                  const InfoRow(label: 'Updated', value: '2 min ago', icon: Icons.update),
                ],
              ),
            ),
            const PanelCard(
              title: 'Sharing',
              child: Column(
                children: [
                  InfoRow(label: 'Status', value: 'Sharing', icon: Icons.share_location),
                  InfoRow(label: 'Groups', value: '2 required', icon: Icons.groups_outlined),
                  InfoRow(label: 'Mode', value: 'Duty hours', icon: Icons.schedule),
                  InfoRow(label: 'Device', value: 'Android', icon: Icons.phone_android),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminTable(
          columns: const ['Time', 'Place', 'Coordinates', 'Source'],
          rows: const [
            [Text('24 Sep, 11:30 AM'), Text('MP Nagar, Bhopal'), Text('23.2332, 77.4343'), Text('GPS')],
            [Text('24 Sep, 09:15 AM'), Text('New Market, Bhopal'), Text('23.2336, 77.4010'), Text('GPS')],
            [Text('24 Sep, 08:30 AM'), Text('Home - Arera Colony'), Text('23.2135, 77.4336'), Text('Wi-Fi')],
            [Text('23 Sep, 06:50 PM'), Text('Home - Arera Colony'), Text('23.2135, 77.4336'), Text('Wi-Fi')],
          ],
        ),
      ],
    );
  }
}
