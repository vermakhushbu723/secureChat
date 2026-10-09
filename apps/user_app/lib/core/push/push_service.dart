import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../router/app_router.dart';
import '../router/app_routes.dart';
import '../session/session_controller.dart';

/// Push notifications (Firebase Cloud Messaging) for new 1-to-1 and group messages.
/// After login the device token is sent to the server; on logout it is removed. A tap on a
/// notification opens that chat. While the app is open the socket shows messages, so the
/// system does not show a notification then (Android / web foreground).
class PushService {
  PushService._();

  static final instance = PushService._();

  // Firebase project "proly-9337e" - web app (Android reads android/app/google-services.json).
  static const _web = FirebaseOptions(
    apiKey: 'AIzaSyA8rqgvo4MSaPD-QHI5BvdMn-UbQEaHIjk',
    authDomain: 'proly-9337e.firebaseapp.com',
    projectId: 'proly-9337e',
    storageBucket: 'proly-9337e.firebasestorage.app',
    messagingSenderId: '42726587985',
    appId: '1:42726587985:web:194f2383ebf72f5d220270',
    measurementId: 'G-9QLYTEXNS4',
  );

  // Web Push certificate (Firebase -> Cloud Messaging -> Web configuration).
  static const _vapidKey = 'BGnhPMoaocz_s8sxX2lAISZ2brHKpgBMYl6avIMsPwgDvIBi1WnVf9GLwUfpLyLjpPwZIvCCCsj5RLn-cdvtDlQ';

  bool _ready = false;
  String? _token;
  String? _pendingLink;

  static bool get supported => kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  /// App start: Firebase, tap handling, and registration whenever the user is logged in.
  Future<void> init() async {
    if (!supported) return;
    try {
      await Firebase.initializeApp(options: kIsWeb ? _web : null);
      _ready = true;
    } catch (e) {
      debugPrint('Push: Firebase init failed: $e');
      return;
    }
    final m = FirebaseMessaging.instance;
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    unawaited(m.getInitialMessage().then((msg) => msg == null ? null : _open(msg)));
    m.onTokenRefresh.listen((t) {
      if (Session.loggedIn.value) unawaited(_send(t));
    });
    Session.loggedIn.addListener(_onSession);
    appRouter.routerDelegate.addListener(_flushPending);
    if (Session.loggedIn.value) unawaited(register());
  }

  void _onSession() {
    if (Session.loggedIn.value) unawaited(register());
  }

  /// Asks for permission (Android 13+ / browser) and sends the device token to the server.
  Future<void> register() async {
    if (!_ready) return;
    try {
      final m = FirebaseMessaging.instance;
      final perm = await m.requestPermission();
      if (perm.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await m.getToken(vapidKey: kIsWeb ? _vapidKey : null);
      if (token != null) await _send(token);
    } catch (e) {
      debugPrint('Push: registration failed: $e');
    }
  }

  Future<void> _send(String token) async {
    _token = token;
    await ApiClient.instance.post('/users/me/devices', body: {'token': token, 'platform': kIsWeb ? 'web' : 'android'});
  }

  /// Logout: this device stops getting the account's notifications.
  Future<void> unregister() async {
    final token = _token;
    if (!_ready || token == null) return;
    _token = null;
    try {
      await ApiClient.instance.dio.delete('/users/me/devices', data: {'token': token}, options: Options(sendTimeout: const Duration(seconds: 5)));
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  // ---------------------------------------------------------------- notification tap
  void _open(RemoteMessage msg) {
    final link = msg.data['link'];
    if (link is! String || !link.startsWith('/') || link == '/') return;
    _pendingLink = link;
    _flushPending();
  }

  /// Opens the chat once the app is past the splash / login screens.
  void _flushPending() {
    final link = _pendingLink;
    if (link == null || !Session.loggedIn.value) return;
    final at = appRouter.routerDelegate.currentConfiguration.uri.path;
    if (at == AppRoutes.splash || at.startsWith('/auth') || at.startsWith('/login') || at.startsWith('/welcome')) return;
    _pendingLink = null;
    if (at != link) scheduleMicrotask(() => appRouter.push(link));
  }
}
