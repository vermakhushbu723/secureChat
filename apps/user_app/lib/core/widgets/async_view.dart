import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../network/api_client.dart';
import '../network/auth_service.dart';
import '../router/app_routes.dart';

/// Shows [child] only for a logged in user; otherwise a login prompt.
/// Every screen that talks to the server is wrapped in it.
class LoginGate extends StatelessWidget {
  const LoginGate({super.key, required this.child, this.title = 'Login required', this.message});

  final Widget child;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.instance.user,
      builder: (context, user, _) {
        if (user != null) return child;
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ResponsiveBody(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EmptyState(
                    icon: Icons.lock_outline,
                    title: 'Login to continue',
                    message: message ?? 'Groups and messages are synced with your account in real time.',
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Login',
                    onPressed: () => context.push(AppRoutes.loginFrom(GoRouterState.of(context).uri.toString())),
                  ),
                  TextButton(onPressed: () => context.push(AppRoutes.register), child: const Text('Create account')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Loads [load] once, shows a spinner / error with retry / [builder].
class AsyncView<T> extends StatefulWidget {
  const AsyncView({super.key, required this.load, required this.builder, this.empty});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  final Widget? empty;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await widget.load();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final error = _error;
    if (error != null && _data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(
                icon: error is ApiException && error.code == 'OFFLINE' ? Icons.cloud_off : Icons.error_outline,
                title: error is ApiException && error.code == 'NOT_MEMBER' ? 'Not a member' : 'Could not load',
                message: error is ApiException ? error.message : '$error',
              ),
              const SizedBox(height: 12),
              SecondaryButton(label: 'Retry', icon: Icons.refresh, onPressed: reload),
            ],
          ),
        ),
      );
    }
    return widget.builder(context, _data as T, reload);
  }
}

/// Runs [action] and shows the server error as a snack bar.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? done}) async {
  try {
    await action();
    if (done != null && context.mounted) context.showSnack(done);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) context.showSnack(e.message);
    return false;
  }
}
