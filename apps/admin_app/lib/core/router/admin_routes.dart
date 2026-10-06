/// All route paths of the admin app.
class AdminRoutes {
  AdminRoutes._();

  // Auth
  static const login = '/login';

  // 1. Dashboard
  static const dashboard = '/dashboard';

  // 2. Users
  static const users = '/users';
  static const userDetails = '/users/:userId';
  static const userActivity = '/users/:userId/activity';
  static const userLocation = '/users/:userId/location';
  static const blockedUsers = '/blocked-users';
  static const searchPermissions = '/search-permissions';

  static String userDetailsOf(String id) => '/users/$id';
  static String userActivityOf(String id) => '/users/$id/activity';
  static String userLocationOf(String id) => '/users/$id/location';

  // 3-4. Groups & Group Members
  static const groups = '/groups';
  static const groupCreate = '/groups/new';
  static const groupDetails = '/groups/:groupId';
  static const groupEdit = '/groups/:groupId/edit';
  static const groupMembers = '/groups/:groupId/members';
  static const groupLocation = '/groups/:groupId/location';
  static const inviteLinks = '/invite-links';

  static String groupDetailsOf(String id) => '/groups/$id';
  static String groupEditOf(String id) => '/groups/$id/edit';
  static String groupMembersOf(String id) => '/groups/$id/members';
  static String groupLocationOf(String id) => '/groups/$id/location';

  // 5-7. Trial, Premium Plans, Extension Requests, User Subscription
  static const trials = '/trials';
  static const plans = '/plans';
  static const extensionRequests = '/extension-requests';
  static const subscriptions = '/subscriptions';

  // 8. Location Management
  static const locations = '/locations';

  // 9. Message & Content Security
  static const messages = '/messages';
  static const forwardChains = '/forward-chains';
  static const moderation = '/content-moderation';
  static const blockedKeywords = '/blocked-keywords';
  static const numberFilter = '/number-filter';
  static const abuseFilter = '/abuse-filter';
  static const security = '/security-settings';

  // 10-16. Reports & System
  static const reports = '/abuse-reports';
  static const analytics = '/analytics';
  static const notifications = '/notifications';
  static const auditLogs = '/audit-logs';
  static const staff = '/staff';
  static const systemSettings = '/system-settings';
  static const emailAccounts = '/email-accounts';
}
