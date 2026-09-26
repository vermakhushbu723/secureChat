/// All route paths of the user app in one place.
///
/// Static constants are the patterns used by the router, helper methods
/// build concrete locations with parameters.
class AppRoutes {
  AppRoutes._();

  // ---------------------------------------------------------------------------
  // 1. Authentication & Onboarding (7)
  // Register -> Verification -> Profile Setup -> Terms -> 7-day trial -> Chats
  // ---------------------------------------------------------------------------
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const register = '/register';
  static const login = '/login';
  static const otp = '/verify';
  static const profileSetup = '/profile-setup';
  static const terms = '/terms';

  /// Pass `from` so the user returns to an invite link after login.
  static String loginFrom(String from) => '$login?from=${Uri.encodeComponent(from)}';
  static String otpFor({required String identifier, String? from, String? devCode}) =>
      Uri(path: otp, queryParameters: {'id': identifier, 'from': ?from, 'dev': ?devCode}).toString();

  // ---------------------------------------------------------------------------
  // 2. User Dashboard & Profile (6) - Chats | Groups | Profile tabs
  // ---------------------------------------------------------------------------
  static const home = '/chats';
  static const groupList = '/groups';
  static const profile = '/profile';
  static const calls = '/calls';
  static const editProfile = '/profile/edit';
  static const accountSecurity = '/profile/security';
  static const settings = '/settings';

  // ---------------------------------------------------------------------------
  // 3. Groups & Group Management (10)
  // Create: Name/Photo -> Description -> Settings -> Create -> Invite Link
  // ---------------------------------------------------------------------------
  static const createGroup = '/group-create';
  static const groupBasicDetails = '/group-create/details';
  static const newGroupSettings = '/group-create/settings';
  static const joinGroup = '/group-join';
  static const joinByCode = '/group/:code'; // app.securechat.in/group/XXXXXX
  static const groupSettings = '/g/:groupId/settings';
  static const groupMembers = '/g/:groupId/members';
  static const memberProfile = '/g/:groupId/members/:memberId';
  static const inviteLink = '/g/:groupId/invite';
  static const locationRequirement = '/g/:groupId/location-requirement';
  static const groupSecurity = '/g/:groupId/security';
  static const groupInfo = '/g/:groupId/info';

  static String joinByCodeOf(String code) => '/group/$code';
  static String groupSettingsOf(String id) => '/g/$id/settings';
  static String groupMembersOf(String id) => '/g/$id/members';
  static String memberProfileOf(String id, String memberId) => '/g/$id/members/$memberId';
  static String inviteLinkOf(String id, {bool created = false}) => '/g/$id/invite${created ? '?created=1' : ''}';
  /// [code] = joining through this invite (not yet a member).
  static String locationRequirementOf(String id, {String? code}) =>
      Uri(path: '/g/$id/location-requirement', queryParameters: {'code': ?code}).toString();
  static String groupSecurityOf(String id) => '/g/$id/security';
  static String groupInfoOf(String id) => '/g/$id/info';

  // ---------------------------------------------------------------------------
  // 4. Chat & Messaging (12) - group chat
  // ---------------------------------------------------------------------------
  static const groupChat = '/chat/:groupId';
  static const messageComposer = '/chat/:groupId/compose';
  static const messageOptions = '/chat/:groupId/message/:messageId/options';
  static const reply = '/chat/:groupId/message/:messageId/reply';
  static const forwardSelection = '/chat/:groupId/forward';
  static const forwardDestination = '/chat/:groupId/forward/destination';
  static const messageSearch = '/chat/:groupId/search';
  static const attachmentSelection = '/chat/:groupId/attach';
  static const voiceMessage = '/chat/:groupId/voice';
  static const messageInfo = '/chat/:groupId/message/:messageId/info';
  static const deletedMessage = '/chat/:groupId/message/:messageId/deleted';
  static const reportMessage = '/chat/:groupId/message/:messageId/report';

  static String groupChatOf(String g) => '/chat/$g';
  static String messageComposerOf(String g) => '/chat/$g/compose';
  static String messageOptionsOf(String g, String m) => '/chat/$g/message/$m/options';
  static String replyOf(String g, String m) => '/chat/$g/message/$m/reply';
  /// [preselect] = message id selected when the screen opens.
  static String forwardSelectionOf(String g, {String? preselect}) =>
      Uri(path: '/chat/$g/forward', queryParameters: {'m': ?preselect}).toString();
  static String forwardDestinationOf(String g, {List<String> messageIds = const []}) => Uri(
    path: '/chat/$g/forward/destination',
    queryParameters: {if (messageIds.isNotEmpty) 'ids': messageIds.join(',')},
  ).toString();
  static String messageSearchOf(String g) => '/chat/$g/search';
  static String attachmentSelectionOf(String g) => '/chat/$g/attach';
  static String voiceMessageOf(String g) => '/chat/$g/voice';
  static String messageInfoOf(String g, String m) => '/chat/$g/message/$m/info';
  static String deletedMessageOf(String g, String m) => '/chat/$g/message/$m/deleted';
  static String reportMessageOf(String g, String m) => '/chat/$g/message/$m/report';

  // ---------------------------------------------------------------------------
  // 5. Secure Message, Forwarding & Content Protection (7)
  // ---------------------------------------------------------------------------
  static const visibilitySelection = '/secure/privacy';
  static const privacyPermission = '/secure/permission';
  static const forwardChain = '/secure/:messageId/chain';
  static const forwardedDetails = '/secure/:messageId/forwarded';
  static const deleteForEveryone = '/secure/:messageId/delete-everyone';
  static const chainDeletionStatus = '/secure/:messageId/chain-deletion';
  static const contentRestriction = '/secure/restricted';

  static String forwardChainOf(String m) => '/secure/$m/chain';
  static String forwardedDetailsOf(String m) => '/secure/$m/forwarded';
  static String deleteForEveryoneOf(String m) => '/secure/$m/delete-everyone';
  static String chainDeletionStatusOf(String m) => '/secure/$m/chain-deletion';

  /// [rule] is a [ContentRule] name, or `privateForward` for forward attempts.
  static String contentRestrictionFor(String rule, {int? warnings, int? maxWarnings}) => Uri(
    path: contentRestriction,
    queryParameters: {'rule': rule, 'w': ?warnings?.toString(), 'max': ?maxWarnings?.toString()},
  ).toString();

  // ---------------------------------------------------------------------------
  // 6. File & Media Management (7)
  // ---------------------------------------------------------------------------
  static const mediaGallery = '/media';
  static const imageViewer = '/media/image';
  static const videoViewer = '/media/video';
  static const documentViewer = '/media/document';
  static const secureFileViewer = '/media/secure';
  static const filePermission = '/media/permission';
  static const protectedContent = '/media/protected';

  static String mediaGalleryOf(String groupId) => '$mediaGallery?group=$groupId';
  static String imageViewerOf(String messageId) => '$imageViewer?m=$messageId';
  static String videoViewerOf(String messageId) => '$videoViewer?m=$messageId';
  static String documentViewerOf(String messageId) => '$documentViewer?m=$messageId';
  static String secureFileViewerOf(String fileId) => '$secureFileViewer?file=$fileId';
  static String filePermissionOf(String fileId) => '$filePermission?file=$fileId';
  static String protectedContentOf(String fileId) => '$protectedContent?file=$fileId';

  // ---------------------------------------------------------------------------
  // 7. Location Management (6)
  // ---------------------------------------------------------------------------
  static const locationPermission = '/location/permission';
  static const locationSharing = '/location/sharing';
  static const myLocation = '/location/me';
  static const membersLocation = '/location/members';
  static const mapView = '/location/map';
  static const locationHistory = '/location/history';

  /// Permission screen opened from the join flow returns into the group.
  static String locationPermissionForJoin(String groupId) => '$locationPermission?join=$groupId';
  static String membersLocationOf(String groupId) => '$membersLocation?group=$groupId';
  static String mapViewOf(String groupId, {String? userId}) =>
      Uri(path: mapView, queryParameters: {'group': groupId, 'user': ?userId}).toString();

  /// My Location opened from a group chat can send the location into it.
  static String myLocationFor(String groupId) => '$myLocation?group=$groupId';

  // ---------------------------------------------------------------------------
  // 8. Subscription / Trial / Plans (6)
  // ---------------------------------------------------------------------------
  static const trialStatus = '/subscription/trial';
  static const trialExpired = '/subscription/trial-expired';
  static const extensionRequest = '/subscription/extension';
  static const plans = '/subscription/plans';
  static const checkout = '/subscription/checkout/:planId';
  static const subscriptionStatus = '/subscription/status';

  static String checkoutOf(String planId) => '/subscription/checkout/$planId';

  // ---------------------------------------------------------------------------
  // 9. Notifications, Reports & Support (6)
  // ---------------------------------------------------------------------------
  static const notifications = '/notifications';
  static const myReports = '/support/reports';
  static const reportUser = '/support/report-member/:userId';
  static const blockedUsers = '/support/blocked';
  static const helpSupport = '/support/help';
  static const policies = '/support/policies';

  static String reportUserOf(String userId, {String? groupId}) =>
      Uri(path: '/support/report-member/$userId', queryParameters: {'group': ?groupId}).toString();
  static const reportGroup = '/support/report-group/:groupId';
  static String reportGroupOf(String groupId) => '/support/report-group/$groupId';

  // ---------------------------------------------------------------------------
  // 10. Direct (1-to-1) chat - realtime, backed by the SecureChat API
  // ---------------------------------------------------------------------------
  static const directChats = '/direct';
  static const newDirectChat = '/direct/new';
  static const archivedChats = '/direct/archived';
  static const starredMessages = '/direct/starred';
  static const directSettings = '/direct/settings';
  static const directChat = '/dm/:conversationId';
  static const directInfo = '/dm/:conversationId/info';
  static const directMedia = '/dm/:conversationId/media';
  static const directSearch = '/dm/:conversationId/search';

  static String directChatOf(String id) => '/dm/$id';
  static String directInfoOf(String id) => '/dm/$id/info';
  static String directMediaOf(String id) => '/dm/$id/media';
  static String directSearchOf(String id) => '/dm/$id/search';
}
