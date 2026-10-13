import '../../../core/core.dart';

/// Extension / premium request decided by the platform admin.
class PlanRequest {
  const PlanRequest({required this.id, required this.kind, required this.days, required this.status, this.reason = '', this.createdAt, this.payment});

  factory PlanRequest.fromJson(Map<String, dynamic> j) => PlanRequest(
    id: j['id'] as String,
    kind: j['kind'] as String? ?? 'extension',
    days: (j['days'] as num?)?.toInt() ?? 7,
    status: j['status'] as String? ?? 'pending',
    reason: j['reason'] as String? ?? '',
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal(),
    payment: j['payment'] is Map ? PaymentSent.fromJson(Map<String, dynamic>.from(j['payment'] as Map)) : null,
  );

  final String id;
  final String kind;
  final int days;
  final String status;
  final String reason;
  final DateTime? createdAt;

  /// UPI payment for a plan (null for an extension request).
  final PaymentSent? payment;
}

/// A UPI payment the user sent (checked by the admin before premium starts).
class PaymentSent {
  const PaymentSent({required this.planName, required this.amount, required this.currency, required this.utr, this.payTo});

  factory PaymentSent.fromJson(Map<String, dynamic> j) => PaymentSent(
    planName: j['planName'] as String? ?? 'Premium',
    amount: (j['amount'] as num?) ?? 0,
    currency: j['currency'] as String? ?? 'INR',
    utr: j['utr'] as String? ?? '',
    payTo: j['payTo'] as String?,
  );

  final String planName;
  final num amount;
  final String currency;
  final String utr;
  final String? payTo;

  String get amountLabel => formatMoney(amount, currency);
}

/// "Rs 299" for INR, "299 USD" otherwise.
String formatMoney(num amount, String currency) {
  final v = amount == amount.roundToDouble() ? amount.toInt().toString() : amount.toStringAsFixed(2);
  return currency.toUpperCase() == 'INR' ? 'Rs $v' : '$v ${currency.toUpperCase()}';
}

/// Premium plan created in the admin panel (Premium Plans).
class PremiumPlan {
  const PremiumPlan({required this.id, required this.name, required this.price, required this.currency, required this.period, required this.durationDays, this.features = const [], this.popular = false});

  factory PremiumPlan.fromJson(Map<String, dynamic> j) => PremiumPlan(
    id: j['id'] as String,
    name: j['name'] as String? ?? 'Premium',
    price: (j['price'] as num?) ?? 0,
    currency: j['currency'] as String? ?? 'INR',
    period: j['period'] as String? ?? 'month',
    durationDays: (j['durationDays'] as num?)?.toInt() ?? 30,
    features: [for (final f in (j['features'] as List? ?? const [])) '$f'],
    popular: j['popular'] == true,
  );

  final String id;
  final String name;
  final num price;
  final String currency;
  final String period;
  final int durationDays;
  final List<String> features;
  final bool popular;

  String get priceLabel => formatMoney(price, currency);
  String get periodLabel => switch (period) {
    'month' => 'month',
    'year' => 'year',
    'week' => 'week',
    _ => '$durationDays days',
  };
}

/// UPI details set by the admin (admin panel -> Payments).
class PaymentInfo {
  const PaymentInfo({required this.enabled, this.upiId, this.payeeName = 'SecureChat', this.qrImageUrl, this.instructions = ''});

  factory PaymentInfo.fromJson(Map<String, dynamic> j) => PaymentInfo(
    enabled: j['enabled'] == true,
    upiId: j['upiId'] as String?,
    payeeName: j['payeeName'] as String? ?? 'SecureChat',
    qrImageUrl: j['qrImageUrl'] as String?,
    instructions: j['instructions'] as String? ?? '',
  );

  final bool enabled;
  final String? upiId;
  final String payeeName;
  final String? qrImageUrl;
  final String instructions;

  /// upi://pay link with the plan amount (opens Google Pay / PhonePe / Paytm, and the QR).
  String? upiLink(PremiumPlan plan) => upiId == null
      ? null
      : Uri(scheme: 'upi', host: 'pay', queryParameters: {'pa': upiId, 'pn': payeeName, 'am': plan.price.toString(), 'cu': plan.currency, 'tn': 'SecureChat ${plan.name}'}).toString();
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

  static Future<List<PremiumPlan>> plans() async =>
      [for (final p in (await _api.get('/subscription/plans') as List)) PremiumPlan.fromJson(Map<String, dynamic>.from(p as Map))];

  static Future<PaymentInfo> paymentInfo() async => PaymentInfo.fromJson(Map<String, dynamic>.from(await _api.get('/subscription/payment-info') as Map));

  /// "I have paid": the admin checks the UTR and activates premium.
  static Future<PlanRequest> submitPayment(String planId, String utr) async {
    final data = await _api.post('/subscription/payments', body: {'planId': planId, 'utr': utr}) as Map;
    return PlanRequest.fromJson(Map<String, dynamic>.from(data));
  }

  /// kind: extension | premium
  static Future<PlanRequest> request({required String kind, required int days, String reason = ''}) async {
    final data = await _api.post('/subscription/requests', body: {'kind': kind, 'days': days, 'reason': reason}) as Map;
    return PlanRequest.fromJson(Map<String, dynamic>.from(data));
  }
}
