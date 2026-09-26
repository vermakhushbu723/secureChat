import '../../../core/core.dart';
import '../../direct/widgets/dm_avatar.dart';

/// Profile tab (WhatsApp "You" / Settings style): photo, name, about, then one
/// plain list of settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Profile',
      child: ValueListenableBuilder<AuthUser?>(
        valueListenable: AuthService.instance.user,
        builder: (context, me, _) => me == null ? const SizedBox.shrink() : _body(context, me),
      ),
    );
  }

  Widget _body(BuildContext context, AuthUser me) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          InkWell(
            onTap: () => context.openDetail(AppRoutes.editProfile),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  DmAvatar(name: me.name, avatarUrl: me.avatarUrl, size: 64),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(me.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            ),
                            if (me.isBusiness) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.storefront, size: 18, color: AppColors.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(me.about.isEmpty ? 'Hey there! I am using ${AppStrings.appName}.' : me.about, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
                ],
              ),
            ),
          ),
          Divider(color: p.divider),
          _Item(
            icon: me.isBusiness ? Icons.storefront_outlined : Icons.key_outlined,
            title: 'Account',
            subtitle: [
              if (me.isBusiness) 'Business account' else 'Personal account',
              ?(me.phone ?? me.email),
            ].join('  -  '),
            onTap: () => context.openDetail(AppRoutes.editProfile),
          ),
          _Item(
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Search visibility, group location, blocked',
            onTap: () => context.openDetail(AppRoutes.settings),
          ),
          _Item(
            icon: Icons.chat_outlined,
            title: 'Chats',
            subtitle: 'Theme, default message privacy',
            onTap: () => context.openDetail(AppRoutes.settings),
          ),
          _Item(
            icon: Icons.location_on_outlined,
            title: 'Location',
            subtitle: 'Sharing mode, history',
            onTap: () => context.push(AppRoutes.locationSharing),
          ),
          _Item(icon: Icons.perm_media_outlined, title: 'Media & files', subtitle: 'Photos, documents, protected files', onTap: () => context.push(AppRoutes.mediaGallery)),
          _Item(icon: Icons.star_outline, title: 'Starred messages', onTap: () => context.push(AppRoutes.starredMessages)),
          _Item(icon: Icons.block, title: 'Blocked', onTap: () => context.push(AppRoutes.blockedUsers)),
          _Item(icon: Icons.flag_outlined, title: 'My reports', onTap: () => context.push(AppRoutes.myReports)),
          _Item(icon: Icons.help_outline, title: 'Help', subtitle: 'Help center, terms and privacy policy', onTap: () => context.push(AppRoutes.helpSupport)),
          Divider(color: p.divider),
          _Item(
            icon: Icons.logout,
            title: 'Log out',
            danger: true,
            onTap: () async {
              final ok = await context.confirm(title: 'Log out?', message: 'You can log in again with your mobile number or email.', confirmLabel: 'Log out', danger: true);
              if (ok && context.mounted) {
                await AuthService.instance.logout();
                if (context.mounted) context.go(AppRoutes.welcome);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Plain settings row: icon, title, optional subtitle (no cards, like WhatsApp).
class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, this.subtitle, this.onTap, this.danger = false});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.palette.danger : null;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: color ?? context.palette.textSecondary, size: 24),
      title: Text(title, style: TextStyle(fontSize: 16, color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(fontSize: 13)),
    );
  }
}
