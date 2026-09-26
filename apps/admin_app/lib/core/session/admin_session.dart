import 'package:shared/shared.dart';

/// UI-only admin session until the admin auth API is wired.
class AdminSession {
  AdminSession._();

  static final loggedIn = ValueNotifier<bool>(false);
  static const name = 'Super Admin';
  static const role = 'Super Admin';
}
