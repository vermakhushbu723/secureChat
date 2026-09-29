import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../router/admin_routes.dart';

class _NavItem {
  const _NavItem(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}

class _NavSection {
  const _NavSection(this.title, this.items);

  final String title;
  final List<_NavItem> items;
}

/// Sidebar follows the admin module list of the spec.
const _sections = [
  _NavSection('Overview', [_NavItem(Icons.dashboard_outlined, 'Dashboard', AdminRoutes.dashboard)]),
  _NavSection('Users', [
    _NavItem(Icons.people_outline, 'Users', AdminRoutes.users),
    _NavItem(Icons.block, 'Blocked Users', AdminRoutes.blockedUsers),
  ]),
  _NavSection('Groups', [
    _NavItem(Icons.groups_outlined, 'Groups', AdminRoutes.groups),
    _NavItem(Icons.link, 'Invite Links', AdminRoutes.inviteLinks),
  ]),
  _NavSection('Trial & Subscription', [
    _NavItem(Icons.hourglass_bottom, 'Trial Management', AdminRoutes.trials),
    _NavItem(Icons.workspace_premium_outlined, 'Premium Plans', AdminRoutes.plans),
    _NavItem(Icons.more_time, 'Extension Requests', AdminRoutes.extensionRequests),
    _NavItem(Icons.manage_accounts_outlined, 'User Access', AdminRoutes.subscriptions),
  ]),
  _NavSection('Location', [_NavItem(Icons.map_outlined, 'Location Management', AdminRoutes.locations)]),
  _NavSection('Message & Content Security', [
    _NavItem(Icons.forum_outlined, 'Message Monitoring', AdminRoutes.messages),
    _NavItem(Icons.account_tree_outlined, 'Forward Chains', AdminRoutes.forwardChains),
    _NavItem(Icons.gavel_outlined, 'Content Moderation', AdminRoutes.moderation),
    _NavItem(Icons.pin_outlined, 'Number Filter', AdminRoutes.numberFilter),
    _NavItem(Icons.do_not_disturb_on_outlined, 'Abuse Filter', AdminRoutes.abuseFilter),
    _NavItem(Icons.security_outlined, 'Security Settings', AdminRoutes.security),
  ]),
  _NavSection('Reports & System', [
    _NavItem(Icons.flag_outlined, 'Abuse Reports', AdminRoutes.reports),
    _NavItem(Icons.insights_outlined, 'Reports & Analytics', AdminRoutes.analytics),
    _NavItem(Icons.campaign_outlined, 'Notifications', AdminRoutes.notifications),
    _NavItem(Icons.history, 'Audit Logs', AdminRoutes.auditLogs),
    _NavItem(Icons.badge_outlined, 'Admin / Staff', AdminRoutes.staff),
    _NavItem(Icons.settings_outlined, 'System Settings', AdminRoutes.systemSettings),
  ]),
];

/// Layout for all admin pages: permanent sidebar on wide screens, drawer on mobile.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final location = GoRouterState.of(context).uri.path;
    final sidebar = _Sidebar(location: location, closeOnTap: !wide);

    return Scaffold(
      backgroundColor: context.palette.surfaceAlt,
      appBar: AppBar(
        automaticallyImplyLeading: !wide,
        title: Row(
          children: [
            if (wide) ...[
              const AppLogo(size: 36),
              const SizedBox(width: 12),
            ],
            const Flexible(child: Text('${AppStrings.appName} Admin', overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (wide) const SizedBox(width: 300, child: AppSearchField(hint: 'Search user ID, group, invite code')),
          IconButton(
            icon: const Badge(label: Text('8'), child: Icon(Icons.more_time)),
            tooltip: 'Pending extension requests',
            onPressed: () => context.go(AdminRoutes.extensionRequests),
          ),
          PopupMenuButton<String>(
            icon: const AppAvatar(initials: 'SA', size: 34, inverted: true),
            onSelected: (v) {
              if (v == 'theme') {
                ThemeController.setMode(
                  Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
                );
              } else {
                context.go(v);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: AdminRoutes.staff, child: Text('My account')),
              PopupMenuItem(value: 'theme', child: Text('Toggle dark mode')),
              PopupMenuItem(value: AdminRoutes.login, child: Text('Logout')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (wide) ...[
            SizedBox(
              width: 264,
              child: Material(color: context.colors.surface, child: sidebar),
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location, required this.closeOnTap});

  final String location;
  final bool closeOnTap;

  bool _isActive(String route) => location == route || location.startsWith('$route/');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (closeOnTap)
            const ListTile(
              leading: AppLogo(size: 40),
              title: Text(AppStrings.adminPanel, style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(AppStrings.appName),
            ),
          for (final s in _sections) ...[
            SectionHeader(s.title, padding: const EdgeInsets.fromLTRB(20, 16, 16, 6)),
            for (final item in s.items)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                child: ListTile(
                  dense: true,
                  selected: _isActive(item.route),
                  selectedColor: context.colors.onPrimary,
                  selectedTileColor: context.colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  leading: Icon(item.icon, size: 20),
                  title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    if (closeOnTap) Navigator.of(context).pop();
                    context.go(item.route);
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
