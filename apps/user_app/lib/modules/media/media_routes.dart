import '../../core/core.dart';
import 'screens/document_viewer_screen.dart';
import 'screens/file_permission_screen.dart';
import 'screens/image_viewer_screen.dart';
import 'screens/media_gallery_screen.dart';
import 'screens/protected_content_warning_screen.dart';
import 'screens/secure_file_viewer_screen.dart';
import 'screens/video_viewer_screen.dart';

String? _q(GoRouterState s, String k) => s.uri.queryParameters[k];

/// Module 6: File & Media Management (7 screens)
/// ?group= gallery, ?m= message for viewers, ?file= protected file id.
final List<RouteBase> mediaRoutes = [
  GoRoute(path: AppRoutes.mediaGallery, builder: (_, s) => MediaGalleryScreen(groupId: _q(s, 'group'))),
  GoRoute(path: AppRoutes.imageViewer, builder: (_, s) => ImageViewerScreen(messageId: _q(s, 'm'))),
  GoRoute(path: AppRoutes.videoViewer, builder: (_, s) => VideoViewerScreen(messageId: _q(s, 'm'))),
  GoRoute(path: AppRoutes.documentViewer, builder: (_, s) => DocumentViewerScreen(messageId: _q(s, 'm'))),
  GoRoute(path: AppRoutes.secureFileViewer, builder: (_, s) => SecureFileViewerScreen(fileId: _q(s, 'file'))),
  GoRoute(path: AppRoutes.filePermission, builder: (_, s) => FilePermissionScreen(fileId: _q(s, 'file'))),
  GoRoute(path: AppRoutes.protectedContent, builder: (_, s) => ProtectedContentWarningScreen(fileId: _q(s, 'file'))),
];
