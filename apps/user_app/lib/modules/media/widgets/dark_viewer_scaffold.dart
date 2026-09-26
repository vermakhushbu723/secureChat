import '../../../core/core.dart';

/// Black full screen scaffold shared by image / video viewers.
class DarkViewerScaffold extends StatelessWidget {
  const DarkViewerScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget> actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: const IconThemeData(color: Colors.white),
        appBarTheme: Theme.of(context).appBarTheme.copyWith(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          actions: actions,
        ),
        body: body,
        bottomNavigationBar: bottom,
      ),
    );
  }
}
