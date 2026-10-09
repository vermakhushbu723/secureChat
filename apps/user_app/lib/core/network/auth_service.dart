import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shared/shared.dart' show AccessType;

import '../session/session_controller.dart';
import 'api_client.dart';
import 'api_config.dart';
import '../push/push_service.dart';
import 'socket_service.dart';

/// The logged in account (full profile, only ever seen by its owner).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    this.displayName = '',
    this.username,
    this.phone,
    this.email,
    this.about = '',
    this.avatarUrl,
    this.lastSeenVisible = true,
    this.readReceipts = true,
    this.searchable = true,
    this.searchHidden = false,
    this.showContact = false,
    this.subscription = const PlanStatus(),
    this.accountType = 'personal',
    this.businessAddress,
    this.profileCompleted = true,
    this.locationMode = 'join',
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    displayName: j['displayName'] as String? ?? '',
    username: j['username'] as String?,
    phone: j['phone'] as String?,
    email: j['email'] as String?,
    about: j['about'] as String? ?? '',
    avatarUrl: j['avatarUrl'] as String?,
    lastSeenVisible: (j['privacy'] as Map?)?['lastSeen'] != 'nobody',
    readReceipts: (j['privacy'] as Map?)?['readReceipts'] != false,
    searchable: (j['privacy'] as Map?)?['searchable'] != false,
    searchHidden: j['searchHidden'] == true,
    showContact: (j['privacy'] as Map?)?['showContact'] == true,
    subscription: PlanStatus.fromJson(j['subscription'] as Map?),
    accountType: j['accountType'] as String? ?? 'personal',
    businessAddress: j['businessAddress'] as String?,
    profileCompleted: j['profileCompleted'] != false,
    locationMode: (j['locationSettings'] as Map?)?['mode'] as String? ?? 'join',
  );

  final String id;
  final String name;

  /// Name shown to group members (defaults to the first name).
  final String displayName;
  final String? username;
  final String? phone;
  final String? email;
  final String about;
  final String? avatarUrl;
  final bool lastSeenVisible;
  final bool readReceipts;

  /// Settings: anyone can find me by user ID / name in search.
  final bool searchable;

  /// Hidden from every search by the SecureChat team ("Anyone can find me" locked off).
  final bool searchHidden;

  /// Settings: show my mobile number & email to other users.
  final bool showContact;

  /// Trial / premium / extension (from the server, re-evaluated on every refresh).
  final PlanStatus subscription;

  /// 'personal' or 'business' (business: [name] is the business name, [about] the bio).
  final String accountType;
  final String? businessAddress;

  /// False right after the first OTP login until the Personal / Business step is done.
  final bool profileCompleted;

  /// Location sharing mode: none | join | live (Settings: group user location on / off).
  final String locationMode;

  bool get isBusiness => accountType == 'business';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'displayName': displayName,
    'username': username,
    'phone': phone,
    'email': email,
    'about': about,
    'avatarUrl': avatarUrl,
    'privacy': {'lastSeen': lastSeenVisible ? 'everyone' : 'nobody', 'readReceipts': readReceipts, 'searchable': searchable, 'showContact': showContact},
    'searchHidden': searchHidden,
    'subscription': subscription.toJson(),
    'accountType': accountType,
    'businessAddress': businessAddress,
    'profileCompleted': profileCompleted,
    'locationSettings': {'mode': locationMode},
  };
}

/// Plan of the signed in user: 7 day trial, premium, admin extension or locked.
class PlanStatus {
  const PlanStatus({this.access = 'trial', this.daysLeft = 7, this.until});

  factory PlanStatus.fromJson(Map<dynamic, dynamic>? j) => PlanStatus(
    access: j?['access'] as String? ?? 'trial',
    daysLeft: (j?['daysLeft'] as num?)?.toInt() ?? 0,
    until: DateTime.tryParse(j?['until'] as String? ?? '')?.toLocal(),
  );

  /// trial | premium | extended | locked | unclaimed (new account, trial not claimed yet)
  final String access;

  bool get canClaimTrial => access == 'unclaimed';
  final int daysLeft;
  final DateTime? until;

  bool get active => access != 'locked';

  Map<String, dynamic> toJson() => {'access': access, 'daysLeft': daysLeft, 'until': until?.toUtc().toIso8601String()};
}

/// Owns the tokens: persists them, refreshes them and (dis)connects the socket.
class AuthService {
  AuthService._();

  static final instance = AuthService._();

  static const _kAccess = 'auth.access';
  static const _kRefresh = 'auth.refresh';
  static const _kUser = 'auth.user';

  final user = ValueNotifier<AuthUser?>(null);
  final _api = ApiClient.instance;
  // Separate client without interceptors so a refresh can never loop.
  final _raw = Dio(BaseOptions(baseUrl: ApiConfig.apiUrl, connectTimeout: const Duration(seconds: 15)));

  String? _access;
  String? _refresh;
  Completer<bool>? _refreshing;

  String? get accessToken => _access;
  bool get isLoggedIn => _access != null && user.value != null;
  String? get userId => user.value?.id;

  /// Loads a saved session on app start.
  Future<void> restore() async {
    _api.accessToken = () => _access;
    _api.refresh = () => refresh();
    final prefs = await SharedPreferences.getInstance();
    _access = prefs.getString(_kAccess);
    _refresh = prefs.getString(_kRefresh);
    final raw = prefs.getString(_kUser);
    if (_access == null || _refresh == null || raw == null) return;
    _setUser(AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    Session.loggedIn.value = true;
    SocketService.instance.connect();
    _listenProfile();
    // Refresh the cached profile; offline start keeps the cached one.
    unawaited(reloadMe().then((_) {}, onError: (Object _) {}));
  }

  Future<AuthUser> login(String identifier, String password) async {
    final data = await _api.post('/auth/login', body: {'identifier': identifier, 'password': password});
    return _save(data as Map<String, dynamic>);
  }

  Future<AuthUser> register({
    required String name,
    required String password,
    String? username,
    String? phone,
    String? email,
  }) async {
    final data = await _api.post(
      '/auth/register',
      body: {
        'name': name,
        'password': password,
        if (username != null && username.isNotEmpty) 'username': username,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    return _save(data as Map<String, dynamic>);
  }

  /// Sends a code to a mobile number or email ID. `devCode` is set when the server
  /// runs without an SMS / email provider; `sentTo` is the normalised number / email.
  Future<({String? devCode, String sentTo})> requestOtp(String identifier) async {
    final data = await _api.post('/auth/otp/request', body: {'identifier': identifier}) as Map;
    return (devCode: data['devCode'] as String?, sentTo: data['sentTo'] as String? ?? identifier);
  }

  /// Login step 1+2: mobile number and email ID -> the code is sent to the email.
  Future<({String? devCode, String sentTo, bool emailed})> requestOtpPair(String phone, String email) async {
    final data = await _api.post('/auth/otp/request', body: {'phone': phone, 'email': email}) as Map;
    return (devCode: data['devCode'] as String?, sentTo: data['sentTo'] as String? ?? email, emailed: data['emailed'] == true);
  }

  Future<({AuthUser user, bool isNew})> verifyOtpPair(String phone, String email, String code) async {
    final data =
        await _api.post('/auth/otp/verify', body: {'phone': phone, 'email': email, 'code': code}) as Map<String, dynamic>;
    return (user: await _save(data), isNew: data['isNew'] == true);
  }

  /// "Claim free trial" popup after signup: starts the 7 day trial.
  Future<AuthUser> claimTrial() async {
    await _api.post('/subscription/claim-trial');
    return reloadMe();
  }

  Future<({AuthUser user, bool isNew})> verifyOtp(String identifier, String code) async {
    final data =
        await _api.post('/auth/otp/verify', body: {'identifier': identifier, 'code': code}) as Map<String, dynamic>;
    return (user: await _save(data), isNew: data['isNew'] == true);
  }

  /// Signup step after the first OTP: Personal (name) or Business (name, address, bio).
  Future<AuthUser> completeProfile(Map<String, dynamic> body) async {
    final me = AuthUser.fromJson(await _api.post('/users/me/profile', body: body) as Map<String, dynamic>);
    await _saveUser(me);
    return me;
  }

  /// Settings toggle: share location with groups (join mode) or not at all.
  Future<AuthUser> setGroupLocation(bool on) async {
    await _api.put('/location/settings', body: {'mode': on ? 'join' : 'none', 'intervalMin': 10});
    return reloadMe();
  }

  Future<AuthUser> reloadMe() async {
    final me = AuthUser.fromJson(await _api.get('/users/me') as Map<String, dynamic>);
    await _saveUser(me);
    return me;
  }

  Future<AuthUser> updateProfile(Map<String, dynamic> patch) async {
    final me = AuthUser.fromJson(await _api.patch('/users/me', body: patch) as Map<String, dynamic>);
    await _saveUser(me);
    return me;
  }

  /// Rotates the token pair. Concurrent callers share one in-flight refresh.
  Future<bool> refresh() {
    final running = _refreshing;
    if (running != null) return running.future;
    final completer = _refreshing = Completer<bool>();
    () async {
      try {
        if (_refresh == null) return completer.complete(false);
        final res = await _raw.post('/auth/refresh', data: {'refreshToken': _refresh});
        final data = (res.data as Map)['data'] as Map<String, dynamic>;
        await _saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
        completer.complete(true);
      } on DioException catch (e) {
        // Only a definitive 401 ends the session; network errors keep it.
        if (e.response?.statusCode == 401) await _clear();
        completer.complete(false);
      } finally {
        _refreshing = null;
      }
    }();
    return completer.future;
  }

  Future<void> logout() async {
    final token = _refresh;
    // This phone / browser stops getting the account's push notifications.
    await PushService.instance.unregister();
    await _clear();
    if (token != null) {
      unawaited(_raw.post('/auth/logout', data: {'refreshToken': token}).then((_) {}, onError: (_) {}));
    }
  }

  Future<AuthUser> _save(Map<String, dynamic> data) async {
    await _saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
    final me = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    await _saveUser(me);
    Session.loggedIn.value = true;
    SocketService.instance.connect();
    _listenProfile();
    return me;
  }

  Future<void> _saveTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    await prefs.setString(_kRefresh, refresh);
  }

  /// Profile changes made on another device or by the admin (plan, privacy...).
  StreamSubscription<Map<String, dynamic>>? _profileSub;
  void _listenProfile() {
    _profileSub ??= SocketService.instance.on('user:updated').listen((data) {
      if (data['id'] == userId && data.containsKey('privacy')) unawaited(_saveUser(AuthUser.fromJson(data)));
    });
  }

  void _setUser(AuthUser? me) {
    user.value = me;
    if (me != null) {
      // Not claimed yet = no access until the user claims the free trial.
      final plan = me.subscription.canClaimTrial ? 'locked' : me.subscription.access;
      Session.access.value = AccessType.values.firstWhere((a) => a.name == plan, orElse: () => AccessType.trial);
    }
  }

  Future<void> _saveUser(AuthUser me) async {
    _setUser(me);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(me.toJson()));
  }

  Future<void> _clear() async {
    _access = null;
    _refresh = null;
    _setUser(null);
    Session.loggedIn.value = false;
    SocketService.instance.disconnect();
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([prefs.remove(_kAccess), prefs.remove(_kRefresh), prefs.remove(_kUser)]);
  }
}
