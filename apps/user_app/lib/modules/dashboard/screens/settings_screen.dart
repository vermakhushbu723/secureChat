import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/core.dart';

/// Saved theme choice (dark by default, like WhatsApp dark).
class ThemePrefs {
  ThemePrefs._();

  static const _key = 'theme.mode';

  static Future<void> load() async {
    final saved = (await SharedPreferences.getInstance()).getString(_key);
    ThemeController.setMode(ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.dark));
  }

  static Future<void> save(ThemeMode mode) async {
    ThemeController.setMode(mode);
    await (await SharedPreferences.getInstance()).setString(_key, mode.name);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Settings',
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ValueListenableBuilder<AuthUser?>(
          valueListenable: AuthService.instance.user,
          builder: (context, me, _) => me == null ? const SizedBox.shrink() : _Body(me: me),
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.me});

  final AuthUser me;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final Set<String> _busy = {};

  Future<void> _run(String key, Future<void> Function() action, String done) async {
    setState(() => _busy.add(key));
    try {
      await action();
      if (mounted) context.showSnack(done);
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  Future<void> _pickTheme() async {
    final picked = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: ThemeController.mode.value,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(value: ThemeMode.system, title: Text('System default')),
                RadioListTile(value: ThemeMode.light, title: Text('Light')),
                RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked != null) await ThemePrefs.save(picked);
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final auth = AuthService.instance;
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _Header('Privacy'),
        SwitchListTile(
          secondary: const Icon(Icons.person_search_outlined),
          title: const Text('Anyone can find me'),
          subtitle: const Text('People can search you by user ID or name'),
          value: me.searchable,
          onChanged: _busy.contains('search')
              ? null
              : (v) => _run('search', () => auth.updateProfile({'privacy': {'searchable': v}}), v ? 'People can find you in search' : 'You are hidden from search'),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.share_location_outlined),
          title: const Text('Group user location'),
          subtitle: Text(me.locationMode == 'none' ? 'Off - mandatory-location groups cannot be joined' : 'Shared with groups that use location'),
          value: me.locationMode != 'none',
          onChanged: _busy.contains('loc')
              ? null
              : (v) => _run('loc', () => auth.setGroupLocation(v), v ? 'Group location turned on' : 'Group location turned off'),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.visibility_outlined),
          title: const Text('Last seen & online'),
          subtitle: const Text('Show when you were last online'),
          value: me.lastSeenVisible,
          onChanged: _busy.contains('seen')
              ? null
              : (v) => _run('seen', () => auth.updateProfile({'privacy': {'lastSeen': v ? 'everyone' : 'nobody'}}), 'Saved'),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.done_all),
          title: const Text('Read receipts'),
          subtitle: const Text('Blue ticks for messages you read'),
          value: me.readReceipts,
          onChanged: _busy.contains('read')
              ? null
              : (v) => _run('read', () => auth.updateProfile({'privacy': {'readReceipts': v}}), 'Saved'),
        ),
        ListTile(
          leading: const Icon(Icons.block),
          title: const Text('Blocked contacts'),
          onTap: () => context.push(AppRoutes.blockedUsers),
        ),
        const ListTile(
          leading: Icon(Icons.phone_locked_outlined),
          title: Text('Mobile number & email'),
          subtitle: Text('Never shown to other users'),
        ),
        const _Header('Chats'),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (_, mode, _) => ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: Text(switch (mode) {
              ThemeMode.dark => 'Dark',
              ThemeMode.light => 'Light',
              ThemeMode.system => 'System default',
            }),
            onTap: _pickTheme,
          ),
        ),
        ValueListenableBuilder<MessageVisibility>(
          valueListenable: Session.defaultVisibility,
          builder: (_, v, _) => ListTile(
            leading: const Icon(Icons.lock_person_outlined),
            title: const Text('Default message privacy'),
            subtitle: Text(v.label),
            onTap: () => context.push(AppRoutes.visibilitySelection),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: const Text('Archived chats'),
          onTap: () => context.push(AppRoutes.archivedChats),
        ),
        const _Header('Location'),
        ListTile(leading: const Icon(Icons.my_location), title: const Text('Location sharing'), subtitle: const Text('Live / join mode, interval'), onTap: () => context.push(AppRoutes.locationSharing)),
        ListTile(leading: const Icon(Icons.history), title: const Text('Location history'), onTap: () => context.push(AppRoutes.locationHistory)),
        const _Header('Help'),
        ListTile(leading: const Icon(Icons.help_outline), title: const Text('Help center'), onTap: () => context.push(AppRoutes.helpSupport)),
        ListTile(leading: const Icon(Icons.article_outlined), title: const Text('Terms and privacy policy'), onTap: () => context.push(AppRoutes.policies)),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('App info'),
          subtitle: Text('${AppStrings.appName} for ${me.isBusiness ? 'Business' : 'Personal'} use', style: TextStyle(color: p.textSecondary)),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(text, style: TextStyle(color: context.palette.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}
