import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/admin_api.dart';

/// Signed in staff member.
class Staff {
  const Staff({required this.id, required this.name, required this.email, required this.role, required this.permissions, this.twoFactor = true});

  factory Staff.fromJson(Map<String, dynamic> j) => Staff(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? 'Admin',
    email: j['email'] as String? ?? '',
    role: j['role'] as String? ?? 'moderator',
    permissions: [for (final p in (j['permissions'] as List? ?? const [])) '$p'],
    twoFactor: j['twoFactor'] != false,
  );

  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> permissions;
  final bool twoFactor;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'role': role, 'permissions': permissions, 'twoFactor': twoFactor};

  String get roleLabel => roleName(role);

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  bool can(String permission) => role == 'super_admin' || permissions.contains(permission);
}

String roleName(String role) => switch (role) {
  'super_admin' => 'Super Admin',
  'moderator' => 'Moderator',
  'support' => 'Support',
  _ => role,
};

/// Admin session (token saved in the browser so a refresh keeps you signed in).
class AdminSession {
  AdminSession._();

  static const _tokenKey = 'admin_token';
  static const _staffKey = 'admin_staff';

  static final loggedIn = ValueNotifier<bool>(false);
  static final staff = ValueNotifier<Staff?>(null);

  static String get name => staff.value?.name ?? 'Admin';
  static String get role => staff.value?.roleLabel ?? '';

  static Future<void> restore() async {
    AdminApi.onUnauthorized = () => signOut(remote: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final raw = prefs.getString(_staffKey);
      if (token == null || raw == null) return;
      AdminApi.token = token;
      staff.value = Staff.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      loggedIn.value = true;
    } catch (_) {
      // Private window / blocked storage: sign in again.
    }
  }

  static Future<void> signIn(Map<String, dynamic> session) async {
    AdminApi.token = session['token'] as String;
    staff.value = Staff.fromJson(session['staff'] as Map<String, dynamic>);
    loggedIn.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, AdminApi.token!);
      await prefs.setString(_staffKey, jsonEncode(staff.value!.toJson()));
    } catch (_) {}
  }

  static void updateStaff(Staff next) {
    staff.value = next;
    SharedPreferences.getInstance().then((p) => p.setString(_staffKey, jsonEncode(next.toJson()))).catchError((_) => false);
  }

  static Future<void> signOut({bool remote = true}) async {
    if (remote && AdminApi.token != null) {
      try {
        await AdminApi.post('/auth/logout');
      } catch (_) {}
    }
    AdminApi.token = null;
    staff.value = null;
    loggedIn.value = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_staffKey);
    } catch (_) {}
  }
}
