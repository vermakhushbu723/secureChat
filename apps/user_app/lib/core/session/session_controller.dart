import 'package:shared/shared.dart';

/// UI-only session state until auth / subscription APIs are wired.
class Session {
  Session._();

  static final loggedIn = ValueNotifier<bool>(false);

  /// Current access of the user. [AccessType.locked] = trial expired, chat locked.
  static final access = ValueNotifier<AccessType>(AccessType.trial);

  /// Default security level pre-selected in the composer.
  static final defaultVisibility = ValueNotifier<MessageVisibility>(MessageVisibility.public);

  /// Days used of the 7-day trial.
  static const trialDayUsed = 4;

  static bool get chatLocked => access.value == AccessType.locked;
}
