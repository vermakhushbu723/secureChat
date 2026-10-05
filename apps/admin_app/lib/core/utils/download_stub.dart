import 'dart:typed_data';

/// Non-web builds (tests): nothing to save.
Future<void> saveFile(String name, Uint8List bytes, {String mime = 'text/csv'}) async {}
