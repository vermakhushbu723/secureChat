import '../../../core/core.dart';
import '../widgets/join_group_sheet.dart';

/// `/group/:code` (invite link from WhatsApp / SMS / browser) and `/group-join`.
/// No separate join page: goes to the chat list and the join popup opens there.
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key, this.code});

  final String? code;

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final code = widget.code;
      if (!AuthService.instance.isLoggedIn) {
        // After login the user comes back to this link and the popup opens.
        context.go(AppRoutes.loginFrom(code == null ? AppRoutes.joinGroup : AppRoutes.joinByCodeOf(code)));
        return;
      }
      // Empty code = ask for a link (menu "Join with link" opened by URL).
      PendingJoin.code.value = code ?? '';
      context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
