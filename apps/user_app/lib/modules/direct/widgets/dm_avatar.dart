import '../../../core/core.dart';
import '../data/direct_models.dart';

/// Profile photo (when set) or initials, with an online dot.
class DmAvatar extends StatelessWidget {
  const DmAvatar({super.key, required this.name, this.avatarUrl, this.size = 48, this.online = false});

  DmAvatar.user(DmUser user, {super.key, this.size = 48, bool showOnline = true})
    : name = user.name,
      avatarUrl = user.avatarUrl,
      online = showOnline && user.online;

  final String name;
  final String? avatarUrl;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    if (url == null || url.isEmpty) return AppAvatar(initials: initialsOf(name), size: size, online: online);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Image.network(
              ApiConfig.mediaUrl(url),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => AppAvatar(initials: initialsOf(name), size: size),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size >= 44 ? 10 : 8,
                height: size >= 44 ? 10 : 8,
                decoration: BoxDecoration(
                  color: context.palette.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
