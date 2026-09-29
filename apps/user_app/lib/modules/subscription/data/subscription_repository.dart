import '../../../core/core.dart';

/// Extension / premium request decided by the platform admin.
class PlanRequest {
  const PlanRequest({required this.id, required this.kind, required this.days, required this.status, this.reason = '', this.createdAt});

  factory PlanRequest.fromJson(Map<String, dynamic> j) => PlanRequest(
    id: j['id'] as String,
    kind: j['kind'] as String? ?? 'extension',
    days: (j['days'] as num?)?.toInt() ?? 7,
    status: j['status'] as String? ?? 'pending',
    reason: j['reason'] as String? ?? '',
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal(),
  );

  final String id;
  final String kind;
  final int days;
  final String status;
  final String reason;
  final DateTime? createdAt;
}

/// Trial / premium / extension of the signed in user.
class PlanDetails {
  const PlanDetails({required this.access, required this.daysLeft, required this.trialDays, this.until, this.trialEndsAt, this.requests = const []});

  factory PlanDetails.fromJson(Map<String, dynamic> j) => PlanDetails(
    access: j['access'] as String? ?? 'trial',
    daysLeft: (j['daysLeft'] as num?)?.toInt() ?? 0,
    trialDays: (j['trialDays'] as num?)?.toInt() ?? 7,
    until: DateTime.tryParse(j['until'] as String? ?? '')?.toLocal(),
    trialEndsAt: DateTime.tryParse(j['trialEndsAt'] as String? ?? '')?.toLocal(),
    requests: [for (final r in (j['requests'] as List? ?? const [])) PlanRequest.fromJson(Map<String, dynamic>.from(r as Map))],
  );

  /// trial | premium | extended | locked
  final String access;
  final int daysLeft;
  final int trialDays;
  final DateTime? until;
  final DateTime? trialEndsAt;
  final List<PlanRequest> requests;

  bool get locked => access == 'locked' || access == 'unclaimed';
  PlanRequest? get pending => requests.where((r) => r.status == 'pending').firstOrNull;
}

class SubscriptionRepository {
  SubscriptionRepository._();

  static final _api = ApiClient.instance;

  static Future<PlanDetails> status() async {
    final data = await _api.get('/subscription') as Map;
    // Keeps the rest of the app (Session.access, composer checks) in sync.
    await AuthService.instance.reloadMe().then((_) {}, onError: (Object _) {});
    return PlanDetails.fromJson(Map<String, dynamic>.from(data));
  }

  /// kind: extension | premium
  static Future<PlanRequest> request({required String kind, required int days, String reason = ''}) async {
    final data = await _api.post('/subscription/requests', body: {'kind': kind, 'days': days, 'reason': reason}) as Map;
    return PlanRequest.fromJson(Map<String, dynamic>.from(data));
  }
}
