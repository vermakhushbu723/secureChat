import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

/// WhatsApp Web style layout: on wide screens lists stay on the left and the
/// opened chat / page is shown on the right. Phones keep full screen pages.
class AppLayout {
  AppLayout._();

  /// Mobile 0-767, tablet 768-1199 (compact rail), desktop 1200+ (200px sidebar).
  static const wideBreakpoint = 768.0;
  static const desktopBreakpoint = 1200.0;

  static const sidebarWidth = 200.0;
  static const listWidth = 320.0;

  /// Chat list column on wide screens: ~32% of the window, 320-520px (WhatsApp Web).
  static double listWidthOf(BuildContext context) => (MediaQuery.sizeOf(context).width * 0.32).clamp(listWidth, 520.0);

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wideBreakpoint;

  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  /// Location shown in the detail pane - lets lists highlight the open item.
  static final currentPath = ValueNotifier<String>('');
}

extension DetailNavigation on BuildContext {
  /// Opens a list item: replaces the right pane on wide screens (no stacking
  /// when switching chats), pushes a full screen page on phones.
  void openDetail(String location) => AppLayout.isWide(this) ? go(location) : push(location);
}

/// Background highlight for the list item that is open in the right pane.
class SelectedHighlight extends StatelessWidget {
  const SelectedHighlight({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLayout.currentPath,
      builder: (context, path, child) {
        final selected = AppLayout.isWide(context) && path == location;
        return Material(color: selected ? context.palette.surfaceAlt : Colors.transparent, child: child);
      },
      child: child,
    );
  }
}
