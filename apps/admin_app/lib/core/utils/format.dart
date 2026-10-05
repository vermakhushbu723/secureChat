import 'package:shared/shared.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

DateTime? parseDate(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();

String _two(int n) => n.toString().padLeft(2, '0');

String _time(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${_two(d.minute)} ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "24 Sep 2026"
String fmtDate(Object? v) {
  final d = parseDate(v);
  return d == null ? '-' : '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// "24 Sep, 10:02 AM" (year added when not this year)
String fmtDateTime(Object? v) {
  final d = parseDate(v);
  if (d == null) return '-';
  final year = d.year == DateTime.now().year ? '' : ' ${d.year}';
  return '${d.day} ${_months[d.month - 1]}$year, ${_time(d)}';
}

/// "Just now", "5 min ago", "3 hours ago", "2 days ago", then the date.
String fmtAgo(Object? v) {
  final d = parseDate(v);
  if (d == null) return '-';
  final diff = DateTime.now().difference(d);
  if (diff.isNegative) return fmtDateTime(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
  if (diff.inDays < 7) return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
  return fmtDate(d);
}

/// 12450 -> "12,450"
String fmtNum(Object? v) {
  final n = v is num ? v.round() : int.tryParse('$v') ?? 0;
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String initialsOf(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Access type -> label + tone (trial / free / premium / extended / locked / unclaimed).
String accessLabel(String? a) => switch (a) {
  'unclaimed' => 'Trial not claimed',
  null => '-',
  _ => capitalize(a),
};

Tone accessToneOf(String? a) => switch (a) {
  'premium' => Tone.success,
  'free' || 'extended' => Tone.info,
  'trial' || 'unclaimed' => Tone.warning,
  'locked' => Tone.danger,
  _ => Tone.neutral,
};

String locationLabel(String? r) => switch (r) {
  'mandatory' => 'Mandatory',
  'optional' => 'Optional',
  _ => 'Off',
};

String visibilityLabel(String? v) => switch (v) {
  'groupMembers' => 'Admin + members',
  'nobody' => 'Nobody',
  _ => 'Admin only',
};

String messageModeLabel(String? m) => switch (m) {
  'public' => 'Public',
  'private' => 'Private',
  _ => 'User can select',
};

const ruleLabels = {
  'abuse': 'Abuse',
  'numbers': 'Numbers',
  'numberWords': 'Number words',
  'spam': 'Spam',
  'links': 'Links',
  'personalInfo': 'Personal info',
  'externalContact': 'External contact',
  'keyword': 'Blocked keyword',
  'phone': 'Mobile number',
};
