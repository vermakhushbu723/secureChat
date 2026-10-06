import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/api/admin_api.dart';
import 'core/session/admin_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await AdminSession.restore();
  runApp(const AdminApp());
  AdminApi.loadMapConfig();
}

