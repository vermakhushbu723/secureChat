import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../api/admin_api.dart';
import '../router/admin_routes.dart';
import '../session/admin_session.dart';
import '../utils/format.dart';

class _NavItem {
  const _NavItem(this.icon, this.label, this.route, [this.permission]);

  final IconData icon;
  final String label;
  final String route;

  /// Role permission needed to see the page (null = every staff member).
  final String? permission;
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
    _NavItem(Icons.people_outline, 'Users', AdminRoutes.users, 'users'),
    _NavItem(Icons.block, 'Blocked Users', AdminRoutes.blockedUsers, 'users'),
    _NavItem(Icons.person_search_outlined, 'Search Permissions', AdminRoutes.searchPermissions, 'users'),
  ]),
  _NavSection('Groups', [
    _NavItem(Icons.groups_outlined, 'Groups', AdminRoutes.groups, 'groups'),
    _NavItem(Icons.link, 'Invite Links', AdminRoutes.inviteLinks, 'groups'),
  ]),
  _NavSection('Trial & Subscription', [
    _NavItem(Icons.hourglass_bottom, 'Trial Management', AdminRoutes.trials, 'subscriptions'),
    _NavItem(Icons.workspace_premium_outlined, 'Premium Plans', AdminRoutes.plans, 'subscriptions'),
    _NavItem(Icons.more_time, 'Extension Requests', AdminRoutes.extensionRequests, 'subscriptions'),
    _NavItem(Icons.manage_accounts_outlined, 'User Access', AdminRoutes.subscriptions, 'subscriptions'),
  ]),
  _NavSection('Location', [_NavItem(Icons.map_outlined, 'Location Management', AdminRoutes.locations, 'groups')]),
  _NavSection('Message & Content Security', [
    _NavItem(Icons.forum_outlined, 'Message Monitoring', AdminRoutes.messages, 'messages'),
    _NavItem(Icons.account_tree_outlined, 'Forward Chains', AdminRoutes.forwardChains, 'messages'),
    _NavItem(Icons.gavel_outlined, 'Content Moderation', AdminRoutes.moderation, 'messages'),
    _NavItem(Icons.block, 'Blocked Keywords', AdminRoutes.blockedKeywords, 'messages'),
    _NavItem(Icons.pin_outlined, 'Number Filter', AdminRoutes.numberFilter, 'messages'),
    _NavItem(Icons.do_not_disturb_on_outlined, 'Abuse Filter', AdminRoutes.abuseFilter, 'messages'),
    _NavItem(Icons.security_outlined, 'Security Settings', AdminRoutes.security, 'settings'),
  ]),
  _NavSection('Reports & System', [
    _NavItem(Icons.flag_outlined, 'Abuse Reports', AdminRoutes.reports, 'reports'),
    _NavItem(Icons.insights_outlined, 'Reports & Analytics', AdminRoutes.analytics, 'reports'),
    _NavItem(Icons.campaign_outlined, 'Notifications', AdminRoutes.notifications, 'settings'),
    _NavItem(Icons.history, 'Audit Logs', AdminRoutes.auditLogs, 'settings'),
    _NavItem(Icons.badge_outlined, 'Admin / Staff', AdminRoutes.staff),
    _NavItem(Icons.settings_outlined, 'System Settings', AdminRoutes.systemSettings, 'settings'),
  ]),
];

/// Pending extension requests (top bar badge), refreshed every minute.
final pendingRequests = ValueNotifier<int>(0);

/// Layout for all admin pages: permanent sidebar on wide screens, drawer on mobile.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBadge();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _loadBadge());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBadge() async {
    if (!(AdminSession.staff.value?.can('subscriptions') ?? false)) return;
    try {
      final d = await AdminApi.get<Map<String, dynamic>>('/requests', {'status': 'pending', 'limit': 1});
      pendingRequests.value = (d['pending'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  Future<void> _search(BuildContext context, String q) async {
    if (q.trim().length < 2) return;
    try {
      final r = await AdminApi.get<Map<String, dynamic>>('/search', {'q': q.trim()});
      if (!context.mounted) return;
      final users = r['users'] as List? ?? const [];
      final groups = r['groups'] as List? ?? const [];
      final invites = r['invites'] as List? ?? const [];
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Results for "$q"'),
          content: SizedBox(
            width: 460,
            child: users.isEmpty && groups.isEmpty && invites.isEmpty
                ? const Text('No user, group or invite code found.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final u in users)
                        ListTile(
                          leading: AppAvatar(initials: initialsOf(u['name'] as String?), size: 36),
                          title: Text('${u['name']}'),
                          subtitle: Text([u['internalId'], u['phone'], u['email']].where((e) => e != null).join('  |  ')),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push(AdminRoutes.userDetailsOf('${u['id']}'));
                          },
                        ),
                      for (final g in groups)
                        ListTile(
                          leading: const AppAvatar(icon: Icons.groups_outlined, size: 36),
                          title: Text('${g['name']}'),
                          subtitle: Text('${g['memberCount']} members'),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push(AdminRoutes.groupDetailsOf('${g['id']}'));
                          },
                        ),
                      for (final i in invites)
                        ListTile(
                          leading: const AppAvatar(icon: Icons.link, size: 36),
                          title: Text('${i['code']}'),
                          subtitle: Text('Invite link of ${i['groupName']}'),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push(AdminRoutes.groupDetailsOf('${i['groupId']}'));
                          },
                        ),
                    ],
                  ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    } on ApiException catch (e) {
      if (context.mounted) context.showSnack(e.message);
    }
  }

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
            if (wide) ...[const AppLogo(size: 36), const SizedBox(width: 12)],
            const Flexible(child: Text('${AppStrings.appName} Admin', overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (wide)
            SizedBox(
              width: 300,
              height: 42,
              child: TextField(
                textInputAction: TextInputAction.search,
                onSubmitted: (v) => _search(context, v),
                decoration: const InputDecoration(
                  hintText: 'Search user ID, name, group, invite code',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search),
              onPressed: () async {
                final c = TextEditingController();
                final q = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Search'),
                    content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'User ID, name, group, invite code'), onSubmitted: (v) => Navigator.pop(ctx, v)),
                    actions: [FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Search'))],
                  ),
                );
                c.dispose();
                if (q != null && context.mounted) await _search(context, q);
              },
            ),
          ValueListenableBuilder<int>(
            valueListenable: pendingRequests,
            builder: (_, n, _) => IconButton(
              icon: Badge(isLabelVisible: n > 0, label: Text('$n'), child: const Icon(Icons.more_time)),
              tooltip: 'Pending extension requests',
              onPressed: () => context.go(AdminRoutes.extensionRequests),
            ),
          ),
          ValueListenableBuilder<Staff?>(
            valueListenable: AdminSession.staff,
            builder: (_, staff, _) => PopupMenuButton<String>(
              icon: AppAvatar(initials: staff?.initials ?? 'A', size: 34, inverted: true),
              onSelected: (v) async {
                if (v == 'theme') {
                  ThemeController.setMode(Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
                } else if (v == 'logout') {
                  await AdminSession.signOut();
                  if (context.mounted) context.go(AdminRoutes.login);
                } else {
                  context.go(v);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Text('${staff?.name ?? ''}\n${staff?.roleLabel ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600))),
                const PopupMenuItem(value: AdminRoutes.staff, child: Text('My account')),
                const PopupMenuItem(value: 'theme', child: Text('Toggle dark mode')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (wide) ...[
            SizedBox(width: 264, child: Material(color: context.colors.surface, child: sidebar)),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: widget.child),
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
    final staff = AdminSession.staff.value;
    bool allowed(_NavItem i) => i.permission == null || staff == null || staff.can(i.permission!);
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
          for (final s in _sections)
            if (s.items.any(allowed)) ...[
              SectionHeader(s.title, padding: const EdgeInsets.fromLTRB(20, 16, 16, 6)),
              for (final item in s.items.where(allowed))
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
