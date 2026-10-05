// import 'package:flutter/foundation.dart'; // needed only for the local URLs below

/// Backend location. Override at build time:
/// `flutter run --dart-define=API_URL=https://api.securechat.in`
/// Shown in Settings / Profile so testers can check which build they are running.
/// Keep in sync with `version` in pubspec.yaml.
const appVersion = '1.0.9';

class ApiConfig {
  ApiConfig._();

  static const _override = String.fromEnvironment('API_URL');

  /// Live backend (VPS, nginx + SSL).
  static const _production = 'https://prosecurely.online';
  // static const _production = 'https://securechat-backend-wmyj.onrender.com'; // old Render deploy

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return _production;

    // Local backend - uncomment (and comment `return _production;` above) to run against `npm run dev`.
    // Android emulator reaches the host machine through 10.0.2.2.
    // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:4000';
    // return 'http://localhost:4000';
  }

  static String get apiUrl => '$baseUrl/api/v1';

  /// Media paths are stored relative (`/uploads/...`) so any host can serve them.
  static String mediaUrl(String path) => path.startsWith('http') ? path : '$baseUrl$path';
}
